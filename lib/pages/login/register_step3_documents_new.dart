import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../functions/functions.dart';
import '../../styles/app_colors.dart';
import '../../components/buttons/primary_button.dart';
import 'registration_status_screen_new.dart';
import '../../services/local_storage_service.dart';

/// Tela #5 - Cadastro - Upload de Documentos (novo design)
class RegisterStep3DocumentsNew extends StatefulWidget {
  final Map<String, dynamic> personalData;
  final Map<String, dynamic> vehicleData;

  const RegisterStep3DocumentsNew({
    super.key,
    required this.personalData,
    required this.vehicleData,
  });

  @override
  State<RegisterStep3DocumentsNew> createState() => _RegisterStep3DocumentsNewState();
}

class _RegisterStep3DocumentsNewState extends State<RegisterStep3DocumentsNew> {
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isRegistered = false;
  String _driverId = '';
  String _loadingMessage = '';

  List<dynamic> _documentTypes = [];
  final Map<String, File?> _selectedFiles = {};
  final Map<String, dynamic> _documentStatus = {};

  @override
  void initState() {
    super.initState();
    _initializeScreen(); // Criar conta e carregar documentos
  }

  Future<void> _initializeScreen() async {
    // Primeiro registra o motorista
    await _registerDriver();

    // Depois carrega os tipos de documentos
    if (_isRegistered) {
      await _loadDocumentTypes();
    }
  }

  Future<void> _registerDriver() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Criando conta...';
    });

    try {
      final registrationData = {
        ...widget.personalData,
        ...widget.vehicleData,
      };

      debugPrint('📤 Dados de registro: $registrationData');

      final result = await driverRegisterWithoutDocuments(registrationData);

      if (result is Map && result['success'] == true) {
        debugPrint('✅ Motorista registrado com sucesso');

        _driverId = result['driverId'] ?? '';
        _isRegistered = true;

        debugPrint('👤 Driver ID: $_driverId');

        try {
          await LocalStorageService.saveDriverSession(
            driverId: _driverId,
            accessToken: '',
            driverData: {
              'id': _driverId,
              'name': widget.personalData['name'] ?? '',
              'email': widget.personalData['email'] ?? '',
              'approve': false,
              'uploadedDocuments': false,
            },
          );

          // Salvar URL da imagem de perfil que veio da API (Cloudflare R2)
          if (result['profileImageUrl'] != null && result['profileImageUrl'].toString().isNotEmpty) {
            await LocalStorageService.saveProfileImagePath(result['profileImageUrl']);
            debugPrint('🖼️ URL da imagem de perfil salva: ${result['profileImageUrl']}');
          }

          debugPrint('💾 Sessão inicial salva localmente');
        } catch (e) {
          debugPrint('❌ Erro ao salvar sessão: $e');
        }

        await _loadDocumentTypes();
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError(result is Map ? (result['message'] ?? 'Erro ao registrar') : result.toString());
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erro ao criar conta: $e');
      debugPrint('❌ Erro no registro: $e');
    }
  }

  Future<void> _loadDocumentTypes() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('📄 Carregando tipos de documentos...');
      var result = await getDocumentTypes();

      if (result == 'success') {
        setState(() {
          _documentTypes = documentTypes;
          _isLoading = false;
        });
        debugPrint('✅ ${_documentTypes.length} tipos de documentos carregados');
      } else {
        setState(() => _isLoading = false);
        _showError('Erro ao carregar documentos obrigatórios');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erro ao carregar documentos: $e');
      debugPrint('❌ Erro: $e');
    }
  }

  Future<void> _pickImage(String documentTypeId, String documentName) async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Selecione a origem',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Câmera'),
                subtitle: const Text('Tirar uma foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.primary),
                ),
                title: const Text('Galeria'),
                subtitle: const Text('Escolher da galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedFiles[documentTypeId] = File(image.path);
        });

        await _uploadDocument(documentTypeId, documentName);
      }
    } catch (e) {
      _showError('Erro ao selecionar imagem: $e');
    }
  }

  Future<void> _uploadDocument(String documentTypeId, String documentName) async {
    final file = _selectedFiles[documentTypeId];
    if (file == null) return;

    if (!_isRegistered) {
      _showError('Aguarde a criação da conta...');
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Enviando $documentName...';
    });

    try {
      final result = await uploadDocument(
        documentTypeId: documentTypeId,
        documentFile: file,
        driverId: _driverId.isNotEmpty ? _driverId : null,
      );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        debugPrint('✅ Documento $documentName enviado com sucesso');

        setState(() {
          _documentStatus[documentTypeId] = {
            'status': 'pending',
            'uploaded': true,
          };
        });

        final allRequiredUploaded = result['allRequiredUploaded'] ?? false;

        if (allRequiredUploaded) {
          try {
            final driverData = await LocalStorageService.getDriverData();
            if (driverData != null) {
              driverData['uploadedDocuments'] = true;
              final token = await LocalStorageService.getAccessToken();
              await LocalStorageService.saveDriverSession(
                driverId: _driverId,
                accessToken: token ?? '',
                driverData: driverData,
              );
              debugPrint('💾 Status atualizado: documentos enviados');
            }
          } catch (e) {
            debugPrint('❌ Erro ao atualizar status local: $e');
          }

          _showSuccessDialog();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$documentName enviado com sucesso!'),
                backgroundColor: AppColors.primary, // Roxo do tema
              ),
            );
          }
        }
      } else {
        _showError(result['message'] ?? 'Erro ao enviar documento');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erro ao enviar documento: $e');
      debugPrint('❌ Erro: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1), // Roxo do tema com 10% opacidade
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.primary, size: 30), // Roxo do tema
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Sucesso!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Todos os documentos foram enviados com sucesso!\n\n'
          'Aguarde a aprovação do administrador. Você receberá uma notificação '
          'quando sua conta for aprovada.',
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: 'Ver Status',
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => RegistrationStatusScreenNew(
                      driverId: _driverId,
                    ),
                  ),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  bool _isDocumentUploaded(String documentTypeId) {
    return _documentStatus[documentTypeId]?['uploaded'] == true;
  }

  String _getDocumentStatus(String documentTypeId) {
    return _documentStatus[documentTypeId]?['status'] ?? 'not_uploaded';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cadastrar',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Step indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepIndicator(1, false, true),
                _buildStepLine(true),
                _buildStepIndicator(2, false, true),
                _buildStepLine(true),
                _buildStepIndicator(3, true, false),
              ],
            ),

            const SizedBox(height: 20),

            // Info banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Envie todos os documentos obrigatórios. As fotos devem estar nítidas e legíveis.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Document list or loading
            if (!_isRegistered || _documentTypes.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _loadingMessage.isEmpty ? 'Criando conta...' : _loadingMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _documentTypes.length,
                  itemBuilder: (context, index) {
                    final docType = _documentTypes[index];
                    final docId = docType['id'].toString();
                    final docName = docType['name'] ?? '';
                    final docDescription = docType['description'] ?? '';
                    final isRequired = docType['required'] == true;
                    final isUploaded = _isDocumentUploaded(docId);
                    final status = _getDocumentStatus(docId);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildDocumentCard(
                        title: docName,
                        description: docDescription,
                        isRequired: isRequired,
                        file: _selectedFiles[docId],
                        isUploaded: isUploaded,
                        status: status,
                        onTap: () => _pickImage(docId, docName),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, bool isActive, bool isCompleted) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? Colors.green
            : isActive
                ? AppColors.primary
                : Colors.grey.shade300,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : Text(
                '$step',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      width: 50,
      height: 2,
      color: isActive ? AppColors.primary : Colors.grey.shade300,
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String description,
    required bool isRequired,
    required File? file,
    required bool isUploaded,
    required String status,
    required VoidCallback onTap,
  }) {
    Color borderColor = Colors.grey.shade300;
    Color backgroundColor = Colors.white;
    IconData icon = Icons.upload_file;
    Color iconColor = Colors.grey.shade400;
    String statusText = 'Toque para enviar';

    if (isUploaded) {
      if (status == 'pending') {
        borderColor = Colors.orange;
        backgroundColor = Colors.orange.shade50;
        icon = Icons.hourglass_empty;
        iconColor = Colors.orange;
        statusText = 'Aguardando análise';
      } else if (status == 'approved') {
        borderColor = Colors.green;
        backgroundColor = Colors.green.shade50;
        icon = Icons.check_circle;
        iconColor = Colors.green;
        statusText = 'Aprovado';
      } else if (status == 'rejected') {
        borderColor = Colors.red;
        backgroundColor = Colors.red.shade50;
        icon = Icons.cancel;
        iconColor = Colors.red;
        statusText = 'Rejeitado - Toque para reenviar';
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
          color: backgroundColor,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isRequired)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'OBRIGATÓRIO',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 13,
                          color: iconColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (file != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  file,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

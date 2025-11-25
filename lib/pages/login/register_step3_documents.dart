import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';
import '../login/approval_status_screen.dart';
import '../../services/local_storage_service.dart';

class RegisterStep3Documents extends StatefulWidget {
  final Map<String, dynamic> personalData;
  final Map<String, dynamic> vehicleData;

  const RegisterStep3Documents({
    super.key,
    required this.personalData,
    required this.vehicleData,
  });

  @override
  State<RegisterStep3Documents> createState() => _RegisterStep3DocumentsState();
}

class _RegisterStep3DocumentsState extends State<RegisterStep3Documents> {
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isRegistered = false;
  String _driverId = '';
  String _error = '';
  String _loadingMessage = '';

  List<dynamic> _documentTypes = [];
  final Map<String, File?> _selectedFiles = {}; // documentTypeId -> File
  final Map<String, dynamic> _documentStatus = {}; // documentTypeId -> status data

  @override
  void initState() {
    super.initState();
    _registerDriver();
  }

  // Primeiro registra o motorista, depois carrega documentos
  Future<void> _registerDriver() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Criando conta...';
    });

    try {
      // Combinar todos os dados
      final registrationData = {
        ...widget.personalData,
        ...widget.vehicleData,
      };

      debugPrint('📤 Dados de registro: $registrationData');

      // Chamar API de registro SEM documentos (novo fluxo)
      final result = await driverRegisterWithoutDocuments(registrationData);

      if (result is Map && result['success'] == true) {
        debugPrint('✅ Motorista registrado com sucesso');

        // Pegar o driver ID do response
        _driverId = result['driverId'] ?? '';
        _isRegistered = true;

        debugPrint('👤 Driver ID: $_driverId');

        // 💾 Salvar sessão local
        try {
          await LocalStorageService.saveDriverSession(
            driverId: _driverId,
            accessToken: '', // Sem token ainda no registro
            driverData: {
              'id': _driverId,
              'name': widget.personalData['name'] ?? '',
              'email': widget.personalData['email'] ?? '',
              'approve': false, // Recém cadastrado, não aprovado
              'uploadedDocuments': false, // Ainda não enviou documentos
            },
          );
          debugPrint('💾 Sessão inicial salva localmente');
        } catch (e) {
          debugPrint('❌ Erro ao salvar sessão: $e');
        }

        // Carregar tipos de documentos
        await _loadDocumentTypes();
      } else {
        setState(() {
          _isLoading = false;
          _error = result is Map ? (result['message'] ?? 'Erro ao registrar') : result.toString();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erro ao criar conta: $e';
      });
      debugPrint('❌ Erro no registro: $e');
    }
  }

  Future<void> _loadDocumentTypes() async {
    try {
      debugPrint('📄 Carregando tipos de documentos...');
      var result = await getDocumentTypes();

      if (result == 'success') {
        setState(() {
          _documentTypes = documentTypes;
          _isLoading = false;
        });
        debugPrint('✅ ${_documentTypes.length} tipos de documentos carregados');
        debugPrint('📋 Lista de documentos:');
        for (var doc in _documentTypes) {
          debugPrint('  - ${doc['name']} (ID: ${doc['id']}, Obrigatório: ${doc['required']})');
        }
      } else {
        setState(() {
          _error = 'Erro ao carregar documentos obrigatórios';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar documentos: $e';
        _isLoading = false;
      });
      debugPrint('❌ Erro: $e');
    }
  }

  Future<void> _pickImage(String documentTypeId, String documentName) async {
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Selecione a origem'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Câmera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
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
          _error = '';
        });

        // Enviar automaticamente após selecionar
        await _uploadDocument(documentTypeId, documentName);
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao selecionar imagem: $e';
      });
    }
  }

  Future<void> _uploadDocument(String documentTypeId, String documentName) async {
    final file = _selectedFiles[documentTypeId];
    if (file == null) return;

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

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        debugPrint('✅ Documento $documentName enviado com sucesso');

        setState(() {
          _documentStatus[documentTypeId] = {
            'status': 'pending',
            'uploaded': true,
          };
        });

        // Verificar se todos documentos obrigatórios foram enviados
        final allRequiredUploaded = result['allRequiredUploaded'] ?? false;

        if (allRequiredUploaded) {
          // 💾 Atualizar status local: documentos enviados
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
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        setState(() {
          _error = result['message'] ?? 'Erro ao enviar documento';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erro ao enviar documento: $e';
      });
      debugPrint('❌ Erro: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            SizedBox(width: 10),
            Expanded(child: Text('Sucesso!')),
          ],
        ),
        content: Text(
          'Todos os documentos foram enviados com sucesso!\n\n'
          'Aguarde a aprovação do administrador. Você receberá uma notificação '
          'quando sua conta for aprovada e poderá fazer login.',
          style: GoogleFonts.notoSans(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fechar dialog
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => ApprovalStatusScreen(
                    driverId: _driverId,
                  ),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
            ),
            child: Text('Ver Status', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
    var media = MediaQuery.of(context).size;

    return Material(
      child: Directionality(
        textDirection: (languageDirection == 'rtl')
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Scaffold(
          body: Stack(
            children: [
              Container(
                height: media.height * 1,
                width: media.width * 1,
                color: page,
                padding: EdgeInsets.fromLTRB(
                  media.width * 0.05,
                  media.height * 0.05,
                  media.width * 0.05,
                  media.height * 0.02,
                ),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Icon(Icons.arrow_back, color: textColor),
                        ),
                        SizedBox(width: media.width * 0.05),
                        Expanded(
                          child: MyText(
                            text: 'Cadastro - Documentos',
                            size: media.width * twenty,
                            fontweight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: media.height * 0.03),

                    // Step indicator
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
                    SizedBox(height: media.height * 0.03),

                    // Form
                    if (!_isRegistered)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 20),
                              MyText(
                                text: _loadingMessage,
                                size: media.width * sixteen,
                                fontweight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // Info box
                              Container(
                                padding: EdgeInsets.all(media.width * 0.03),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.blue),
                                    SizedBox(width: media.width * 0.02),
                                    Expanded(
                                      child: MyText(
                                        text: 'Envie todos os documentos obrigatórios. '
                                            'As fotos devem estar nítidas e legíveis.',
                                        size: media.width * twelve,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: media.height * 0.02),

                              // Lista de documentos
                              ..._documentTypes.map((docType) {
                                final docId = docType['id'].toString();
                                final docName = docType['name'] ?? '';
                                final docDescription = docType['description'] ?? '';
                                final isRequired = docType['required'] == true;
                                final isUploaded = _isDocumentUploaded(docId);
                                final status = _getDocumentStatus(docId);

                                return Column(
                                  children: [
                                    _buildDocumentCard(
                                      title: docName,
                                      description: docDescription,
                                      isRequired: isRequired,
                                      file: _selectedFiles[docId],
                                      isUploaded: isUploaded,
                                      status: status,
                                      onTap: () => _pickImage(docId, docName),
                                    ),
                                    SizedBox(height: media.height * 0.02),
                                  ],
                                );
                              }),

                              // Error message
                              if (_error.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.all(media.width * 0.03),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.red),
                                      SizedBox(width: media.width * 0.02),
                                      Expanded(
                                        child: MyText(
                                          text: _error,
                                          size: media.width * fourteen,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Loading
              if (_isLoading)
                Positioned(
                  top: 0,
                  child: Container(
                    height: media.height * 1,
                    width: media.width * 1,
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(media.width * 0.05),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            SizedBox(height: media.height * 0.02),
                            MyText(
                              text: _loadingMessage,
                              size: media.width * sixteen,
                              fontweight: FontWeight.w600,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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
    var media = MediaQuery.of(context).size;

    Color borderColor = borderLines;
    Color backgroundColor = Colors.transparent;
    IconData leadingIcon = Icons.upload_file;
    Color iconColor = textColor;
    String statusText = 'Toque para enviar';

    if (isUploaded) {
      if (status == 'pending') {
        borderColor = Colors.orange;
        backgroundColor = Colors.orange.shade50;
        leadingIcon = Icons.hourglass_empty;
        iconColor = Colors.orange;
        statusText = 'Aguardando análise';
      } else if (status == 'approved') {
        borderColor = Colors.green;
        backgroundColor = Colors.green.shade50;
        leadingIcon = Icons.check_circle;
        iconColor = Colors.green;
        statusText = 'Aprovado ✓';
      } else if (status == 'rejected') {
        borderColor = Colors.red;
        backgroundColor = Colors.red.shade50;
        leadingIcon = Icons.cancel;
        iconColor = Colors.red;
        statusText = 'Rejeitado - Toque para reenviar';
      }
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        width: media.width * 1,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.2),
          color: backgroundColor,
        ),
        padding: EdgeInsets.all(media.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(leadingIcon, color: iconColor, size: 30),
                SizedBox(width: media.width * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: MyText(
                              text: title,
                              size: media.width * sixteen,
                              fontweight: FontWeight.w600,
                            ),
                          ),
                          if (isRequired)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'OBRIGATÓRIO',
                                style: GoogleFonts.notoSans(
                                  fontSize: 10,
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 5),
                      MyText(
                        text: description,
                        size: media.width * twelve,
                        color: hintColor,
                      ),
                      SizedBox(height: 5),
                      MyText(
                        text: statusText,
                        size: media.width * twelve,
                        color: iconColor,
                        fontweight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (file != null) ...[ SizedBox(height: media.height * 0.02),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  file,
                  height: 150,
                  width: media.width * 0.8,
                  fit: BoxFit.cover,
                ),
              ),
            ],
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
                ? buttonColor
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
      color: isActive ? buttonColor : Colors.grey.shade300,
    );
  }
}

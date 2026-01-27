import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../functions/functions.dart';
import '../../styles/app_colors.dart';
import '../../components/buttons/primary_button.dart';
import '../../services/local_storage_service.dart';

class DocumentUploadScreen extends StatefulWidget {
  final String driverId;

  const DocumentUploadScreen({
    super.key,
    required this.driverId,
  });

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  bool _isLoadingDocumentTypes = false;
  String _error = '';
  String _uploadingDocumentId = ''; // ID do documento que está sendo enviado

  List<dynamic> _documentTypes = [];
  final Map<String, File?> _selectedFiles = {}; // documentTypeId -> File
  final Map<String, dynamic> _documentStatus = {}; // documentTypeId -> status data
  final Map<String, dynamic> _uploadedDocuments = {}; // Documentos já enviados do servidor

  @override
  void initState() {
    super.initState();
    _loadDocumentTypes();
  }

  Future<void> _loadDocumentTypes() async {
    setState(() {
      _isLoadingDocumentTypes = true;
    });

    try {
      // Buscar tipos de documentos
      var result = await getDocumentTypes();

      if (result == 'success') {
        _documentTypes = documentTypes;

        // Buscar status dos documentos do motorista
        await _loadDriverDocumentStatus();

        setState(() {
          _isLoadingDocumentTypes = false;
        });
        debugPrint('✅ ${_documentTypes.length} tipos de documentos carregados');
      } else {
        setState(() {
          _error = 'Erro ao carregar documentos obrigatórios';
          _isLoadingDocumentTypes = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro: $e';
        _isLoadingDocumentTypes = false;
      });
    }
  }

  Future<void> _loadDriverDocumentStatus() async {
    try {
      debugPrint('📊 Carregando status dos documentos do motorista');

      // Usar função existente que busca documentos do motorista logado
      final result = await getUploadedDocuments();

      if (result == 'success' && uploadedDocuments.isNotEmpty) {
        for (var doc in uploadedDocuments) {
          final documentTypeId = doc['document_type_id'].toString();
          final status = doc['status']; // 'pending', 'approved', 'rejected'

          _documentStatus[documentTypeId] = {
            'status': status,
            'uploaded': true,
            'approved': status == 'approved',
            'rejected': status == 'rejected',
            'pending': status == 'pending',
          };

          debugPrint('📄 Documento $documentTypeId: $status');
        }

        debugPrint('✅ ${uploadedDocuments.length} documentos carregados');
      } else {
        debugPrint('ℹ️ Nenhum documento enviado ainda');
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar status dos documentos: $e');
    }
  }

  Future<void> _pickImage(String documentTypeId, String documentName) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedFiles[documentTypeId] = File(image.path);
        });

        // Upload automaticamente após selecionar
        _uploadDocument(documentTypeId, documentName);
      }
    } catch (e) {
      debugPrint('❌ Erro ao capturar imagem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao capturar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery(String documentTypeId, String documentName) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedFiles[documentTypeId] = File(image.path);
        });

        // Upload automaticamente após selecionar
        _uploadDocument(documentTypeId, documentName);
      }
    } catch (e) {
      debugPrint('❌ Erro ao selecionar imagem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadDocument(String documentTypeId, String documentName) async {
    final file = _selectedFiles[documentTypeId];
    if (file == null) return;

    setState(() {
      _uploadingDocumentId = documentTypeId;
    });

    try {
      debugPrint('📤 Enviando documento: $documentName (ID: $documentTypeId) para driver: ${widget.driverId}');

      var result = await uploadDocument(
        documentTypeId: documentTypeId,
        documentFile: file,
        driverId: widget.driverId,
      );

      debugPrint('📥 Resposta do upload: $result');

      if (result is Map && result['success'] == true) {
        debugPrint('✅ Documento $documentName enviado com sucesso!');

        // Atualizar status do documento para "pending" (aguardando análise)
        setState(() {
          _uploadingDocumentId = '';
          _documentStatus[documentTypeId] = {
            'status': 'pending',
            'uploaded': true,
            'approved': false,
            'rejected': false,
            'pending': true,
          };
        });

        // Verificar LOCALMENTE se todos documentos obrigatórios foram enviados
        final requiredDocs = _documentTypes.where((doc) => doc['required'] == true).toList();
        final uploadedRequiredCount = requiredDocs.where((doc) {
          final docId = doc['id'].toString();
          return _documentStatus[docId]?['uploaded'] == true;
        }).length;

        final allRequiredUploaded = uploadedRequiredCount >= requiredDocs.length;

        debugPrint('📊 Progresso: $uploadedRequiredCount/${requiredDocs.length} documentos obrigatórios enviados');

        if (allRequiredUploaded) {
          // 💾 Atualizar status local: documentos enviados
          try {
            final driverData = await LocalStorageService.getDriverData();
            if (driverData != null) {
              driverData['uploadedDocuments'] = true;
              final token = await LocalStorageService.getAccessToken();
              await LocalStorageService.saveDriverSession(
                driverId: widget.driverId,
                accessToken: token ?? '',
                driverData: driverData,
              );
              debugPrint('💾 Status atualizado: documentos enviados');
            }
          } catch (e) {
            debugPrint('❌ Erro ao atualizar status local: $e');
          }

          // Mostrar diálogo e voltar para tela de status
          _showSuccessDialog();
        } else {
          // Apenas mostrar snackbar e permitir continuar enviando
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ $documentName enviado! Continue enviando os demais documentos.'),
                backgroundColor: AppColors.primary,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        setState(() {
          _uploadingDocumentId = '';
        });

        String errorMsg = result is Map ? (result['message'] ?? 'Erro ao enviar documento') : 'Erro desconhecido';
        debugPrint('❌ Erro ao enviar: $errorMsg');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao enviar documento: $e');
      setState(() {
        _uploadingDocumentId = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar documento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.primary, size: 32),
            SizedBox(width: 8),
            Text('Documentos Enviados!'),
          ],
        ),
        content: Text(
          'Todos os documentos obrigatórios foram enviados com sucesso! '
          'Aguarde a aprovação do administrador. Você receberá uma notificação '
          'quando sua conta for aprovada.',
        ),
        actions: [
          PrimaryButton(
            text: 'OK',
            onPressed: () {
              Navigator.of(context).pop(); // Fechar dialog
              Navigator.of(context).pop(); // Voltar para tela de status
            },
          ),
        ],
      ),
    );
  }

  bool _isDocumentUploaded(String documentTypeId) {
    return _documentStatus[documentTypeId]?['uploaded'] == true;
  }

  bool _isDocumentApproved(String documentTypeId) {
    return _documentStatus[documentTypeId]?['approved'] == true;
  }

  bool _isDocumentRejected(String documentTypeId) {
    return _documentStatus[documentTypeId]?['rejected'] == true;
  }

  bool _isDocumentPending(String documentTypeId) {
    return _documentStatus[documentTypeId]?['pending'] == true;
  }

  String _getDocumentStatusText(String documentTypeId) {
    if (_isDocumentApproved(documentTypeId)) return 'Aprovado';
    if (_isDocumentRejected(documentTypeId)) return 'Rejeitado';
    if (_isDocumentPending(documentTypeId)) return 'Em Análise';
    return '';
  }

  Color _getDocumentStatusColor(String documentTypeId) {
    if (_isDocumentApproved(documentTypeId)) return AppColors.primary;
    if (_isDocumentRejected(documentTypeId)) return Colors.red;
    if (_isDocumentPending(documentTypeId)) return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (_error.isNotEmpty && _documentTypes.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Enviar Documentos',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconTheme: IconThemeData(color: Colors.black),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  _error,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                PrimaryButton(
                  text: 'Tentar Novamente',
                  onPressed: _loadDocumentTypes,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Agrupar documentos por categoria se existir
    final requiredDocs = _documentTypes.where((doc) => doc['required'] == true).toList();
    final optionalDocs = _documentTypes.where((doc) => doc['required'] != true).toList();

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
          'Enviar Documentos',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingDocumentTypes
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Carregando documentos...',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informação no topo
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Envie fotos nítidas dos documentos obrigatórios para completar seu cadastro.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Documentos obrigatórios
                  if (requiredDocs.isNotEmpty) ...[
              Text(
                'Documentos Obrigatórios *',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16),
              ...requiredDocs.map((doc) => _buildDocumentCard(doc)),
              SizedBox(height: 24),
            ],

            // Documentos opcionais
            if (optionalDocs.isNotEmpty) ...[
              Text(
                'Documentos Opcionais',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16),
              ...optionalDocs.map((doc) => _buildDocumentCard(doc)),
            ],

            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(dynamic doc) {
    final documentTypeId = doc['id'].toString();
    final documentName = doc['name'] ?? 'Documento';
    final isRequired = doc['required'] == true;
    final isUploaded = _isDocumentUploaded(documentTypeId);
    final isApproved = _isDocumentApproved(documentTypeId);
    final isRejected = _isDocumentRejected(documentTypeId);
    final isPending = _isDocumentPending(documentTypeId);
    final file = _selectedFiles[documentTypeId];
    final canUpload = !isApproved; // Só pode fazer upload se não estiver aprovado
    final isUploading = _uploadingDocumentId == documentTypeId; // Verifica se este documento está sendo enviado

    // Cor da borda baseada no status
    Color borderColor = Colors.grey[300]!;
    Color backgroundColor = const Color(0xFFF5F5F5);

    if (isApproved) {
      borderColor = AppColors.primary;
      backgroundColor = AppColors.primary.withValues(alpha: 0.1);
    } else if (isRejected) {
      borderColor = Colors.red;
      backgroundColor = Colors.red.withValues(alpha: 0.05);
    } else if (isPending) {
      borderColor = Colors.orange;
      backgroundColor = Colors.orange.withValues(alpha: 0.05);
    } else if (isRequired) {
      borderColor = AppColors.primary.withValues(alpha: 0.3);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isApproved ? Icons.check_circle :
                isRejected ? Icons.cancel :
                isPending ? Icons.hourglass_bottom :
                Icons.camera_alt,
                color: _getDocumentStatusColor(documentTypeId),
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      documentName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (isRequired && !isUploaded)
                      Text(
                        'Obrigatório',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              if (isUploaded)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getDocumentStatusColor(documentTypeId).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getDocumentStatusText(documentTypeId),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getDocumentStatusColor(documentTypeId),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          // Mostrar mensagem se rejeitado
          if (isRejected) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Documento rejeitado. Por favor, envie novamente.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (file != null && !isUploaded) ...[
            SizedBox(height: 12),
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

          // Botões de upload ou loading (só mostra se pode fazer upload)
          if (canUpload) ...[
            SizedBox(height: 12),
            if (isUploading)
              Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Enviando...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(documentTypeId, documentName),
                      icon: Icon(Icons.camera_alt, size: 20),
                      label: Text('Câmera'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary, width: 1.5),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImageFromGallery(documentTypeId, documentName),
                      icon: Icon(Icons.photo_library, size: 20),
                      label: Text('Galeria'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary, width: 1.5),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

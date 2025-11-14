// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../functions/functions.dart';
import '../../models/support_ticket.dart';
import '../../services/support_ticket_service.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../noInternet/nointernet.dart';

class TicketDetailsPage extends StatefulWidget {
  final String ticketId;

  const TicketDetailsPage({super.key, required this.ticketId});

  @override
  State<TicketDetailsPage> createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends State<TicketDetailsPage> {
  bool _isLoading = true;
  bool _isSending = false;
  SupportTicket? _ticket;
  final TextEditingController _replyController = TextEditingController();
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTicketDetails();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTicketDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🎫 Carregando detalhes do ticket ${widget.ticketId}...');

      final ticket = await SupportTicketService.getTicketDetails(widget.ticketId);

      if (ticket != null) {
        debugPrint('✅ Ticket carregado com ${ticket.replies.length} respostas');
        debugPrint('🔍 ANTES DO SET STATE:');
        debugPrint('🔍 ID: ${ticket.id}');
        debugPrint('🔍 Subject: ${ticket.subjectName}');
        debugPrint('🔍 Message: "${ticket.message}"');
        debugPrint('🔍 Message isEmpty: ${ticket.message.isEmpty}');
        debugPrint('🔍 Message length: ${ticket.message.length}');
      } else {
        debugPrint('❌ Ticket não encontrado');
      }

      setState(() {
        _ticket = ticket;
        debugPrint('🔧 DENTRO DO SET STATE: _ticket != null = ${_ticket != null}');
        if (_ticket != null) {
          debugPrint('🔧 _ticket.message = "${_ticket!.message}"');
        }
      });
    } catch (e) {
      debugPrint('❌ Erro ao carregar detalhes do ticket: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      debugPrint('📸 _pickImage CHAMADO com source: $source');

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      debugPrint('📸 Resultado do pickImage: ${image?.path ?? "null (cancelado)"}');

      if (image != null) {
        debugPrint('📸 Adicionando imagem à lista: ${image.path}');
        setState(() {
          _selectedImages.add(File(image.path));
        });
        debugPrint('✅ Imagem adicionada com sucesso. Total de imagens: ${_selectedImages.length}');
      } else {
        debugPrint('⚠️ Nenhuma imagem selecionada (usuário cancelou)');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ERRO ao selecionar imagem: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar imagem: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    debugPrint('📸 Abrindo diálogo de seleção de imagem...');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Escolha uma opção',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: Text(
                  'Câmera',
                  style: GoogleFonts.notoSans(),
                ),
                onTap: () {
                  debugPrint('📸 Opção CÂMERA selecionada');
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: Text(
                  'Galeria',
                  style: GoogleFonts.notoSans(),
                ),
                onTap: () {
                  debugPrint('📸 Opção GALERIA selecionada');
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey,
                      child: const Icon(Icons.error, color: Colors.white, size: 50),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, escreva uma mensagem'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      debugPrint('💬 Enviando resposta...');

      final imagePaths = _selectedImages.map((file) => file.path).toList();

      final result = await SupportTicketService.replyToTicket(
        ticketId: widget.ticketId,
        message: _replyController.text.trim(),
        imagePaths: imagePaths.isNotEmpty ? imagePaths : null,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resposta enviada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        _replyController.clear();
        _selectedImages.clear();
        await _loadTicketDetails();

        // Rolar para o final após carregar
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erro ao enviar resposta'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao enviar resposta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar resposta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.blue;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return SafeArea(
      child: Material(
        child: ValueListenableBuilder(
          valueListenable: valueNotifierHome.value,
          builder: (context, value, child) {
            return Directionality(
              textDirection: (languageDirection == 'rtl')
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Stack(
                children: [
                  Container(
                    height: media.height * 1,
                    width: media.width * 1,
                    color: page,
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: EdgeInsets.fromLTRB(
                              media.width * 0.05, media.width * 0.05, media.width * 0.05, 0),
                          child: Column(
                            children: [
                              SizedBox(height: MediaQuery.of(context).padding.top),
                              Stack(
                                children: [
                                  Container(
                                    padding: EdgeInsets.only(bottom: media.width * 0.05),
                                    width: media.width * 1,
                                    alignment: Alignment.center,
                                    child: MyText(
                                      text: 'Detalhes do Ticket',
                                      size: media.width * twenty,
                                      fontweight: FontWeight.w600,
                                    ),
                                  ),
                                  Positioned(
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.pop(context, true);
                                      },
                                      child: Icon(Icons.arrow_back_ios, color: textColor),
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Conteúdo
                        if (_ticket != null) ...[
                          // Debug logging
                          Builder(builder: (context) {
                            debugPrint('🎨 RENDERIZANDO UI DO TICKET');
                            debugPrint('🎨 Ticket ID: ${_ticket!.id}');
                            debugPrint('🎨 Ticket Subject: ${_ticket!.subjectName}');
                            debugPrint('🎨 Ticket Message: "${_ticket!.message}"');
                            debugPrint('🎨 Ticket Status: ${_ticket!.status}');
                            debugPrint('🎨 Ticket Images: ${_ticket!.images.length}');
                            debugPrint('🎨 Ticket Replies: ${_ticket!.replies.length}');
                            return const SizedBox.shrink();
                          }),

                          // Info do ticket
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: media.width * 0.05),
                            padding: EdgeInsets.all(media.width * 0.04),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_ticket!.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(_ticket!.status),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _ticket!.subjectName,
                                        style: GoogleFonts.notoSans(
                                          fontSize: media.width * eighteen,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: media.width * 0.03,
                                        vertical: media.width * 0.015,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(_ticket!.status),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _ticket!.getStatusText(),
                                        style: GoogleFonts.notoSans(
                                          fontSize: media.width * twelve,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: media.width * 0.02),
                                Text(
                                  'Ticket #${_ticket!.id.length > 8 ? _ticket!.id.substring(0, 8) : _ticket!.id}',
                                  style: GoogleFonts.notoSans(
                                    fontSize: media.width * twelve,
                                    color: textColor.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: media.width * 0.03),

                          // Lista de mensagens
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _loadTicketDetails,
                              child: ListView(
                                controller: _scrollController,
                                padding: EdgeInsets.symmetric(horizontal: media.width * 0.05),
                                children: [
                                  // Mensagem inicial do ticket
                                  _buildMessageBubble(
                                    message: _ticket!.message,
                                    images: _ticket!.images,
                                    isDriver: true,
                                    senderName: 'Você',
                                    date: _ticket!.createdAt,
                                    media: media,
                                  ),

                                  // Respostas
                                  ..._ticket!.replies.map((reply) {
                                    return _buildMessageBubble(
                                      message: reply.message,
                                      images: reply.images,
                                      isDriver: reply.isDriver,
                                      senderName: reply.isDriver ? 'Você' : reply.senderName,
                                      date: reply.createdAt,
                                      media: media,
                                    );
                                  }),

                                  SizedBox(height: media.width * 0.02),
                                ],
                              ),
                            ),
                          ),

                          // Campo de resposta
                          Container(
                            padding: EdgeInsets.all(media.width * 0.03),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 5,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Preview das imagens selecionadas
                                if (_selectedImages.isNotEmpty) ...[
                                  SizedBox(
                                    height: media.width * 0.2,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _selectedImages.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          margin: EdgeInsets.only(right: media.width * 0.02),
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.file(
                                                  _selectedImages[index],
                                                  width: media.width * 0.2,
                                                  height: media.width * 0.2,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Positioned(
                                                top: 3,
                                                right: 3,
                                                child: InkWell(
                                                  onTap: () => _removeImage(index),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(3),
                                                    decoration: const BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                      size: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: media.width * 0.02),
                                ],

                                // Campo de texto e botões
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: _showImageSourceDialog,
                                      icon: Icon(
                                        Icons.add_photo_alternate,
                                        color: buttonColor,
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _replyController,
                                        maxLines: null,
                                        decoration: InputDecoration(
                                          hintText: 'Digite sua resposta...',
                                          hintStyle: GoogleFonts.notoSans(
                                            color: textColor.withValues(alpha: 0.5),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(25),
                                            borderSide: BorderSide(color: borderLines),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: media.width * 0.04,
                                            vertical: media.width * 0.02,
                                          ),
                                        ),
                                        style: GoogleFonts.notoSans(
                                          fontSize: media.width * fourteen,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _isSending ? null : _sendReply,
                                      icon: _isSending
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: buttonColor,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Icon(
                                              Icons.send,
                                              color: buttonColor,
                                            ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ] else if (!_isLoading)
                          Expanded(
                            child: Center(
                              child: Text(
                                'Ticket não encontrado',
                                style: GoogleFonts.notoSans(
                                  fontSize: media.width * sixteen,
                                  color: textColor.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // No internet
                  (internet == false)
                      ? Positioned(
                          top: 0,
                          child: NoInternet(
                            onTap: () {
                              setState(() {
                                internetTrue();
                                _loadTicketDetails();
                              });
                            },
                          ),
                        )
                      : Container(),

                  // Loader
                  (_isLoading == true)
                      ? const Positioned(top: 0, child: Loading())
                      : Container(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Converte caminho relativo em URL completa
  String _getFullImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    // Remove a barra inicial se existir
    final path = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;
    return '$url$path';
  }

  Widget _buildMessageBubble({
    required String message,
    required List<String> images,
    required bool isDriver,
    required String senderName,
    required DateTime date,
    required Size media,
  }) {
    debugPrint('💬 _buildMessageBubble CHAMADO');
    debugPrint('💬 Message: "$message"');
    debugPrint('💬 Images: ${images.length}');
    debugPrint('💬 IsDriver: $isDriver');
    debugPrint('💬 Sender: $senderName');

    return Container(
      margin: EdgeInsets.only(bottom: media.width * 0.03),
      child: Row(
        mainAxisAlignment: isDriver ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isDriver) ...[
            CircleAvatar(
              backgroundColor: Colors.blue,
              radius: media.width * 0.05,
              child: Icon(
                Icons.support_agent,
                color: Colors.white,
                size: media.width * 0.05,
              ),
            ),
            SizedBox(width: media.width * 0.02),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(media.width * 0.03),
              decoration: BoxDecoration(
                color: isDriver ? buttonColor.withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDriver ? buttonColor.withValues(alpha: 0.3) : borderLines,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome do remetente
                  Text(
                    senderName,
                    style: GoogleFonts.notoSans(
                      fontSize: media.width * twelve,
                      fontWeight: FontWeight.bold,
                      color: isDriver ? buttonColor : Colors.blue,
                    ),
                  ),
                  SizedBox(height: media.width * 0.01),

                  // Mensagem
                  Text(
                    message,
                    style: GoogleFonts.notoSans(
                      fontSize: media.width * fourteen,
                      color: textColor,
                    ),
                  ),

                  // Imagens
                  if (images.isNotEmpty) ...[
                    SizedBox(height: media.width * 0.02),
                    Wrap(
                      spacing: media.width * 0.02,
                      runSpacing: media.width * 0.02,
                      children: images.map((imageUrl) {
                        final fullImageUrl = _getFullImageUrl(imageUrl);
                        debugPrint('🖼️ Renderizando imagem: $imageUrl -> $fullImageUrl');
                        return InkWell(
                          onTap: () => _showFullImage(fullImageUrl),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              fullImageUrl,
                              width: media.width * 0.25,
                              height: media.width * 0.25,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('❌ Erro ao carregar imagem $fullImageUrl: $error');
                                return Container(
                                  width: media.width * 0.25,
                                  height: media.width * 0.25,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.error, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  SizedBox(height: media.width * 0.01),

                  // Data
                  Text(
                    _formatDate(date),
                    style: GoogleFonts.notoSans(
                      fontSize: media.width * ten,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isDriver) ...[
            SizedBox(width: media.width * 0.02),
            CircleAvatar(
              backgroundColor: buttonColor,
              radius: media.width * 0.05,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: media.width * 0.05,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

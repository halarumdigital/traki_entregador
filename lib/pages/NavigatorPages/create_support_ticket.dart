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

class CreateSupportTicketPage extends StatefulWidget {
  const CreateSupportTicketPage({super.key});

  @override
  State<CreateSupportTicketPage> createState() => _CreateSupportTicketPageState();
}

class _CreateSupportTicketPageState extends State<CreateSupportTicketPage> {
  bool _isLoading = true;
  bool _isSending = false;
  List<TicketSubject> _subjects = [];
  TicketSubject? _selectedSubject;
  final TextEditingController _messageController = TextEditingController();
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // Cor primária roxa do design
  static const Color _primaryPurple = Color(0xFF7C3AED);

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('📋 Carregando assuntos de tickets...');

      final subjects = await SupportTicketService.getTicketSubjects();

      setState(() {
        _subjects = subjects;
      });

      debugPrint('✅ ${subjects.length} assuntos carregados');
    } catch (e) {
      debugPrint('❌ Erro ao carregar assuntos: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
        debugPrint('📷 Imagem adicionada: ${image.path}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao selecionar imagem: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar imagem: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
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

  Future<void> _createTicket() async {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um assunto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_messageController.text.trim().isEmpty) {
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
      debugPrint('🎫 Criando ticket...');

      final imagePaths = _selectedImages.map((file) => file.path).toList();

      final result = await SupportTicketService.createSupportTicket(
        subjectId: _selectedSubject!.id,
        message: _messageController.text.trim(),
        imagePaths: imagePaths.isNotEmpty ? imagePaths : null,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erro ao criar ticket'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao criar ticket: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar ticket: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
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
                                text: 'Novo Ticket',
                                size: media.width * twenty,
                                fontweight: FontWeight.w600,
                              ),
                            ),
                            Positioned(
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Icon(Icons.arrow_back_ios, color: textColor),
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: media.width * 0.05),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Seletor de assunto
                                Text(
                                  'Assunto',
                                  style: GoogleFonts.notoSans(
                                    fontSize: media.width * sixteen,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                SizedBox(height: media.width * 0.02),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: media.width * 0.04),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderLines, width: 1.2),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<TicketSubject>(
                                      isExpanded: true,
                                      hint: Text(
                                        'Selecione o assunto',
                                        style: GoogleFonts.notoSans(
                                          color: textColor.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      value: _selectedSubject,
                                      items: _subjects.map((subject) {
                                        return DropdownMenuItem<TicketSubject>(
                                          value: subject,
                                          child: Text(
                                            subject.name,
                                            style: GoogleFonts.notoSans(
                                              fontSize: media.width * fourteen,
                                              color: textColor,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (TicketSubject? value) {
                                        setState(() {
                                          _selectedSubject = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),

                                // Descrição do assunto selecionado
                                if (_selectedSubject != null &&
                                    _selectedSubject!.description.isNotEmpty) ...[
                                  SizedBox(height: media.width * 0.02),
                                  Container(
                                    padding: EdgeInsets.all(media.width * 0.03),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: media.width * 0.04,
                                          color: Colors.blue.shade700,
                                        ),
                                        SizedBox(width: media.width * 0.02),
                                        Expanded(
                                          child: Text(
                                            _selectedSubject!.description,
                                            style: GoogleFonts.notoSans(
                                              fontSize: media.width * twelve,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                SizedBox(height: media.width * 0.05),

                                // Campo de mensagem
                                Text(
                                  'Mensagem',
                                  style: GoogleFonts.notoSans(
                                    fontSize: media.width * sixteen,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                SizedBox(height: media.width * 0.02),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderLines, width: 1.2),
                                  ),
                                  child: TextField(
                                    controller: _messageController,
                                    maxLines: 6,
                                    decoration: InputDecoration(
                                      hintText: 'Descreva seu problema ou dúvida...',
                                      hintStyle: GoogleFonts.notoSans(
                                        color: textColor.withValues(alpha: 0.5),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.all(media.width * 0.04),
                                    ),
                                    style: GoogleFonts.notoSans(
                                      fontSize: media.width * fourteen,
                                      color: textColor,
                                    ),
                                  ),
                                ),

                                SizedBox(height: media.width * 0.05),

                                // Seção de imagens
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Imagens (opcional)',
                                      style: GoogleFonts.notoSans(
                                        fontSize: media.width * sixteen,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _showImageSourceDialog,
                                      icon: Icon(
                                        Icons.add_photo_alternate,
                                        size: media.width * 0.05,
                                        color: _primaryPurple,
                                      ),
                                      label: Text(
                                        'Adicionar',
                                        style: GoogleFonts.notoSans(
                                          fontSize: media.width * fourteen,
                                          color: _primaryPurple,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                if (_selectedImages.isNotEmpty) ...[
                                  SizedBox(height: media.width * 0.02),
                                  SizedBox(
                                    height: media.width * 0.25,
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
                                                  width: media.width * 0.25,
                                                  height: media.width * 0.25,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Positioned(
                                                top: 5,
                                                right: 5,
                                                child: InkWell(
                                                  onTap: () => _removeImage(index),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: const BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                      size: 16,
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
                                ],

                                SizedBox(height: media.width * 0.1),

                                // Botão de criar ticket
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isSending ? null : _createTicket,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primaryPurple,
                                      padding: EdgeInsets.symmetric(vertical: media.width * 0.045),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: _isSending
                                        ? SizedBox(
                                            height: media.width * 0.05,
                                            width: media.width * 0.05,
                                            child: const CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            'Criar Ticket',
                                            style: GoogleFonts.notoSans(
                                              fontSize: media.width * sixteen,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),

                                SizedBox(height: media.width * 0.1),
                              ],
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
                                _loadSubjects();
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
}

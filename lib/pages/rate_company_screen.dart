import 'package:flutter/material.dart';
import '../services/delivery_service.dart';
import '../styles/styles.dart';
import '../widgets/widgets.dart';

class RateCompanyScreen extends StatefulWidget {
  final String deliveryId;
  final String companyName;

  const RateCompanyScreen({
    super.key,
    required this.deliveryId,
    required this.companyName,
  });

  @override
  State<RateCompanyScreen> createState() => _RateCompanyScreenState();
}

class _RateCompanyScreenState extends State<RateCompanyScreen> {
  int _selectedRating = 0;
  bool _isSubmitting = false;

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma avaliação'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await DeliveryService.rateCompany(
        widget.deliveryId,
        _selectedRating,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avaliação enviada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao enviar avaliação. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao enviar avaliação: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao enviar avaliação. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: page,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(media.width * 0.05),
              color: theme,
              child: Row(
                children: [
                  Icon(
                    Icons.business,
                    color: Colors.white,
                    size: media.width * 0.08,
                  ),
                  SizedBox(width: media.width * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          text: 'Avalie a empresa',
                          size: media.width * twenty,
                          fontweight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        MyText(
                          text: 'Sua opinião é importante',
                          size: media.width * fourteen,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(media.width * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: media.width * 0.05),

                    // Ícone de sucesso
                    Container(
                      width: media.width * 0.25,
                      height: media.width * 0.25,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: media.width * 0.15,
                      ),
                    ),

                    SizedBox(height: media.width * 0.05),

                    // Título
                    MyText(
                      text: 'Entrega Concluída!',
                      size: media.width * twentyfour,
                      fontweight: FontWeight.bold,
                      color: textColor,
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: media.width * 0.03),

                    // Nome da empresa
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: media.width * 0.05,
                        vertical: media.width * 0.03,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.store,
                            color: theme,
                            size: media.width * 0.06,
                          ),
                          SizedBox(width: media.width * 0.02),
                          Flexible(
                            child: MyText(
                              text: widget.companyName,
                              size: media.width * eighteen,
                              fontweight: FontWeight.w600,
                              color: textColor,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: media.width * 0.08),

                    // Pergunta
                    MyText(
                      text: 'Como foi sua experiência com esta empresa?',
                      size: media.width * sixteen,
                      color: textColor,
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: media.width * 0.06),

                    // Estrelas de avaliação
                    Container(
                      padding: EdgeInsets.all(media.width * 0.05),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starNumber = index + 1;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedRating = starNumber;
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: media.width * 0.015,
                              ),
                              child: Icon(
                                _selectedRating >= starNumber
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: media.width * 0.12,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    // Texto da avaliação
                    if (_selectedRating > 0) ...[
                      SizedBox(height: media.width * 0.04),
                      MyText(
                        text: _getRatingText(_selectedRating),
                        size: media.width * sixteen,
                        fontweight: FontWeight.w600,
                        color: _getRatingColor(_selectedRating),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    SizedBox(height: media.width * 0.1),
                  ],
                ),
              ),
            ),

            // Botões de ação
            Container(
              padding: EdgeInsets.all(media.width * 0.05),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Botão Enviar Avaliação
                  Button(
                    onTap: _isSubmitting ? null : _submitRating,
                    text: _isSubmitting ? 'Enviando...' : 'Enviar Avaliação',
                    color: _selectedRating > 0 ? theme : Colors.grey,
                  ),

                  SizedBox(height: media.width * 0.03),

                  // Botão Pular
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            Navigator.pop(context, false);
                          },
                    child: MyText(
                      text: 'Pular avaliação',
                      size: media.width * fourteen,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Muito insatisfeito';
      case 2:
        return 'Insatisfeito';
      case 3:
        return 'Regular';
      case 4:
        return 'Satisfeito';
      case 5:
        return 'Muito satisfeito';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    if (rating <= 2) {
      return Colors.red;
    } else if (rating == 3) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/delivery_service.dart';

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

  // Cores do Figma
  static const Color _backgroundColor = Color(0xFFF9F9FF);
  static const Color _darkTextColor = Color(0xFF1C2340);
  static const Color _grayTextColor = Color(0xFF8A8D9F);
  static const Color _buttonColor = Color(0xFF8719CA);
  static const Color _starActiveColor = Color(0xFFFFD700);

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
    final media = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header - Figma: Roboto Bold 22px, #1C2340
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: media.width * 0.05,
                vertical: 16,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Entrega em Andamento',
                  style: GoogleFonts.roboto(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _darkTextColor,
                  ),
                ),
              ),
            ),

            // Conteúdo scrollável
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Ilustração do Figma
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: media.width * 0.05,
                        vertical: 20,
                      ),
                      child: Image.asset(
                        'assets/images/delivery_success.png',
                        width: media.width * 0.8,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Texto de sucesso - Figma: Roboto Bold 20px, rgba(0,0,0,0.9)
                    Text(
                      'Entrega finalizada com\nsucesso!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtexto - Figma: Roboto 400 14px, #8A8D9F
                    Text(
                      'Deixe sua avaliação sobre a empresa',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: _grayTextColor,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Card de avaliação - Figma: border-radius 10px, padding 22px 32px
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: media.width * 0.05),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 22,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'O que você achou da empresa?',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _darkTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Escolha de 1 a 5 estrelas para classificar',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: _grayTextColor,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Estrelas
                          Row(
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Icon(
                                    _selectedRating >= starNumber
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: _selectedRating >= starNumber
                                        ? _starActiveColor
                                        : Colors.grey.shade300,
                                    size: 40,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Botão de enviar - Figma: #8719CA, border-radius 25px, Roboto Bold 16px
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: media.width * 0.05,
                vertical: 16,
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _buttonColor.withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Enviar Avaliação',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            Navigator.pop(context, false);
                          },
                    child: Text(
                      'Pular avaliação',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: _grayTextColor,
                      ),
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
}

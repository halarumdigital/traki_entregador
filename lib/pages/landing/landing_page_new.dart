import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/buttons/secondary_button.dart';
import '../auth/login_screen_new.dart';
import '../login/register_step1_personal_new.dart';

/// Nova Landing Page baseada no design do Figma
/// Com tema roxo (#8719CA) e layout moderno
class LandingPageNew extends StatelessWidget {
  const LandingPageNew({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Deixar status bar com ícones escuros
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF), // #F9F9FF do Figma
      body: SafeArea(
        child: Column(
          children: [
            // Parte superior - Ilustração
            Expanded(
              flex: 55,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                child: Center(
                  child: Image.asset(
                    'assets/images/landing/illustration.png',
                    width: size.width * 0.85,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Se der erro ao carregar, mostra instruções
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 80,
                            color: AppColors.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Faça HOT RESTART\npara carregar a imagem',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // Parte inferior - Conteúdo
            Expanded(
              flex: 45,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Título
                    Text(
                      'Bem-vindo a Traki',
                      style: AppTextStyles.landingTitle,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 11),

                    // Subtítulo
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 27),
                      child: Text(
                        'Entregue seu pacote ao redor do mundo sem hesitação.',
                        style: AppTextStyles.landingSubtitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),

                    const SizedBox(height: 38),

                    // Botão Entrar
                    PrimaryButton(
                      text: 'Entrar',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreenNew()),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Botão Cadastrar
                    SecondaryButton(
                      text: 'Cadastrar',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterStep1PersonalNew(),
                          ),
                        );
                      },
                    ),

                    const Spacer(),

                    // Home Indicator (barra inferior - estilo iPhone)
                    Container(
                      width: 134,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

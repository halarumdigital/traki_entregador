import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../components/buttons/primary_button.dart';
import 'login_screen_new.dart';

/// Tela #14 - Senha alterada com sucesso
class ForgotPasswordSuccessScreen extends StatelessWidget {
  const ForgotPasswordSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Voltar para login (remover todas as telas do fluxo)
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreenNew()),
              (route) => false,
            );
          },
        ),
        title: const Text(
          'Esqueci senha',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Ilustração
              Image.asset(
                'assets/images/landing/illustration.png',
                width: 250,
                height: 250,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback: ícone de sucesso
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      size: 100,
                      color: AppColors.primary,
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Título
              const Text(
                'Senha alterada',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const Spacer(),

              // Botão Entrar
              PrimaryButton(
                text: 'Entrar',
                onPressed: () {
                  // Ir para tela de login removendo todo o histórico
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreenNew()),
                    (route) => false,
                  );
                },
              ),

              const SizedBox(height: 40),

              // Home Indicator
              Container(
                width: 134,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

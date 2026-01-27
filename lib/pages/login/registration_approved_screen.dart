import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../components/buttons/primary_button.dart';
import '../home_simple.dart';

/// Tela #9 - Cadastro Aprovado
class RegistrationApprovedScreen extends StatelessWidget {
  const RegistrationApprovedScreen({super.key});

  void _handleEnter(BuildContext context) {
    // Navegar para Home
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeSimple()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Cadastro',
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
            children: [
              const Spacer(flex: 2),

              // Ilustração de moto
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/landing/illustration.png',
                    width: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback se não carregar a ilustração
                      return Icon(
                        Icons.delivery_dining,
                        size: 120,
                        color: AppColors.primary.withOpacity(0.5),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Título
              const Text(
                'Cadastro aprovado',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Descrição
              Text(
                'Seu perfil está verificado e pronto para uso. Agora você pode acessar todos os recursos da plataforma.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // Botão Entrar
              PrimaryButton(
                text: 'Entrar',
                onPressed: () => _handleEnter(context),
              ),

              const SizedBox(height: 20),

              // Home indicator
              Center(
                child: Container(
                  width: 134,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
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

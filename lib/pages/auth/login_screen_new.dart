import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../components/buttons/primary_button.dart';
import '../login/register_step1_personal.dart';
import 'forgot_password_email_screen.dart';
import '../../functions/functions.dart';
import '../../services/local_storage_service.dart';
import '../home_simple.dart';

/// Nova tela de Login baseada no design do Figma
/// Com tema roxo (#8719CA)
class LoginScreenNew extends StatefulWidget {
  const LoginScreenNew({super.key});

  @override
  State<LoginScreenNew> createState() => _LoginScreenNewState();
}

class _LoginScreenNewState extends State<LoginScreenNew> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Validar campos
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira seu e-mail ou telefone'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira sua senha'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('🔐 Tentando fazer login com: $email');

      // Chamar a função de login
      var result = await driverLogin(email, email, password, false);

      if (mounted) {
        setState(() => _isLoading = false);

        // Verificar se o login foi bem-sucedido
        if (result == true) {
          debugPrint('✅ Login bem-sucedido! Salvando sessão...');
          debugPrint('📦 userDetails: $userDetails');
          debugPrint('📦 userDetails.keys: ${userDetails.keys}');
          debugPrint('📦 personalData: ${userDetails['personalData']}');
          if (userDetails['personalData'] != null) {
            debugPrint('📦 personalData.keys: ${(userDetails['personalData'] as Map).keys}');
            debugPrint('📦 fullName: ${userDetails['personalData']['fullName']}');
          }

          // Salvar sessão no LocalStorageService
          if (bearerToken.isNotEmpty && userDetails.isNotEmpty) {
            await LocalStorageService.saveDriverSession(
              driverId: userDetails['id'].toString(),
              accessToken: bearerToken[0].token,
              driverData: userDetails,
            );

            // Salvar URL da foto de perfil se disponível
            if (userDetails['personalData'] != null &&
                userDetails['personalData']['profilePicture'] != null &&
                userDetails['personalData']['profilePicture'].toString().isNotEmpty) {
              await LocalStorageService.saveProfileImagePath(
                userDetails['personalData']['profilePicture'],
              );
            }

            debugPrint('✅ Sessão salva com sucesso!');
            debugPrint('💾 Dados salvos - ID: ${userDetails['id']}');
          }

          // Navegar para a tela principal (dashboard)
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeSimple()),
              (route) => false,
            );
          }
        } else if (result is Map && result['blocked'] == true) {
          // Conta bloqueada
          debugPrint('❌ Conta bloqueada');
          _showErrorDialog(
            'Conta Bloqueada',
            result['message'] ?? 'Seu cadastro foi desativado por violações nos termos de uso da Traki, para saber mais entre em contato com o suporte.',
          );
        } else {
          // Erro de login
          String errorMessage = result.toString();
          if (errorMessage == 'no internet') {
            errorMessage = 'Sem conexão com a internet. Verifique sua conexão e tente novamente.';
          }
          debugPrint('❌ Erro ao fazer login: $errorMessage');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Erro inesperado ao fazer login: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer login: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
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
          'Entrar',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Título
              const Text(
                'Bem-vindo de volta',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 8),

              // Subtítulo
              const Text(
                'Entre para continuar',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 40),

              // Campo de E-mail
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Seu e-mail',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.primary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Campo de Senha
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '••••••••••••••••••',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey[400],
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Lembrar sempre + Esqueceu senha
              Row(
                children: [
                  // Checkbox
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() => _rememberMe = value ?? false);
                      },
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Lembrar sempre',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordEmailScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Esqueceu a senha',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Botão Entrar
              PrimaryButton(
                text: 'Entrar',
                onPressed: _isLoading ? null : _handleLogin,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 40),

              // Link para Registro
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Ainda não tem uma conta? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterStep1Personal(),
                          ),
                        );
                      },
                      child: const Text(
                        'Registre-se',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

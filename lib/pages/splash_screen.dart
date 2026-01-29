import 'package:flutter/material.dart';
import '../services/registration_status_service.dart';
import '../services/location_permission_service.dart';
import '../services/driver_block_service.dart';
import '../services/app_version_service.dart';
import '../styles/styles.dart';
import 'landing/landing_page_new.dart';
import 'login/login.dart';
import 'login/approval_status_screen.dart';
import 'home_simple.dart';
import 'update_required_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkNavigationStatus();
  }

  Future<void> _checkNavigationStatus() async {
    // Aguardar um pouco para mostrar splash
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 0. Verificar se precisa atualizar o app
    final versionInfo = await AppVersionService.checkVersion();
    if (versionInfo != null && versionInfo.forceUpdate) {
      debugPrint('🔄 [SplashScreen] Atualização obrigatória necessária');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UpdateRequiredScreen(versionInfo: versionInfo),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    // 1. Primeiro, verificar e solicitar permissões de localização
    await LocationPermissionService.checkAndRequestLocationPermission(context);

    if (!mounted) return;

    // 2. Verificar se o entregador está bloqueado (antes de continuar)
    final blockStatus = await DriverBlockService.checkBlockStatus();
    if (blockStatus != null && blockStatus.isBlocked) {
      debugPrint('🚫 [SplashScreen] Entregador bloqueado detectado');
      if (mounted) {
        await DriverBlockService.showBlockedDialogAndLogout(
          context,
          customMessage: blockStatus.message,
        );
      }
      return;
    }

    if (!mounted) return;

    final status = await RegistrationStatusService.checkNavigationStatus();

    if (!mounted) return;

    // Navegar para tela correta
    switch (status.targetScreen) {
      case DriverScreen.login:
        // Nova landing page com design do Figma
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LandingPageNew()),
        );
        break;

      case DriverScreen.uploadDocuments:
        // Precisamos passar os dados do registro
        // Como já está registrado, não temos personalData/vehicleData aqui
        // Vamos apenas redirecionar para landing page por enquanto
        // TODO: Criar tela específica para continuar upload de documentos
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LandingPageNew()),
        );
        break;

      case DriverScreen.approvalStatus:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ApprovalStatusScreen(
              driverId: status.driverId!,
            ),
          ),
        );
        break;

      case DriverScreen.home:
        // Navegar para tela principal do app
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeSimple()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff8719CA), // Roxo do tema
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff8719CA), // Roxo principal
              Color(0xff6B0FA8), // Roxo mais escuro
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo da Traki
              Image.asset(
                'assets/images/logo.png',
                width: 250,
                height: 250,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback se o logo não carregar
                  return const Icon(
                    Icons.local_shipping,
                    size: 120,
                    color: Colors.white,
                  );
                },
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

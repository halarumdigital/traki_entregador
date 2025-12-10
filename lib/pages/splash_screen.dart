import 'package:flutter/material.dart';
import '../services/registration_status_service.dart';
import '../services/location_permission_service.dart';
import '../services/driver_block_service.dart';
import '../styles/styles.dart';
import 'login/login.dart';
import 'login/approval_status_screen.dart';
import 'home_simple.dart';

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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
        break;

      case DriverScreen.uploadDocuments:
        // Precisamos passar os dados do registro
        // Como já está registrado, não temos personalData/vehicleData aqui
        // Vamos apenas redirecionar para login por enquanto
        // TODO: Criar tela específica para continuar upload de documentos
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Login()),
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
      backgroundColor: page,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [buttonColor, buttonColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo do app
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.local_shipping,
                  size: 60,
                  color: buttonColor,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Fretus Driver',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Seu parceiro de entregas',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 60),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Carregando...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

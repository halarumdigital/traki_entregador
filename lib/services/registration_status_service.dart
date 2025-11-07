import 'package:flutter/material.dart';
import 'local_storage_service.dart';
import '../functions/functions.dart';

class RegistrationStatusService {
  // Verificar qual tela o motorista deve ver
  static Future<DriverNavigationStatus> checkNavigationStatus() async {
    try {
      debugPrint('🔍 Verificando status de navegação...');

      // 1. Verificar se tem sessão salva
      final hasSession = await LocalStorageService.hasActiveSession();
      if (!hasSession) {
        debugPrint('❌ Sem sessão ativa → Login');
        return DriverNavigationStatus.needsLogin();
      }

      // 2. Obter dados salvos
      final driverData = await LocalStorageService.getDriverData();
      if (driverData == null) {
        debugPrint('❌ Sem dados do motorista → Login');
        return DriverNavigationStatus.needsLogin();
      }

      // 3. Verificar status do cadastro
      final driverId = driverData['id'] as String;
      final approve = driverData['approve'] as bool? ?? false;
      final uploadedDocuments = driverData['uploadedDocuments'] as bool? ?? false;

      debugPrint('👤 Driver ID: $driverId');
      debugPrint('✅ Aprovado: $approve');
      debugPrint('📄 Documentos enviados: $uploadedDocuments');

      // 4. Decidir navegação
      if (approve) {
        // Aprovado → Tela principal
        debugPrint('🎉 Aprovado → Home');
        return DriverNavigationStatus.approved(driverId);
      } else if (uploadedDocuments) {
        // Documentos enviados → Aguardando aprovação
        debugPrint('⏳ Documentos enviados → Aguardando aprovação');
        return DriverNavigationStatus.awaitingApproval(driverId);
      } else {
        // Falta enviar documentos
        debugPrint('📤 Falta enviar documentos → Upload');
        return DriverNavigationStatus.needsDocuments(driverId);
      }
    } catch (e) {
      debugPrint('❌ Erro ao verificar status: $e');
      return DriverNavigationStatus.needsLogin();
    }
  }

  // Atualizar dados locais após mudança de status
  static Future<void> refreshDriverData(String driverId) async {
    try {
      debugPrint('🔄 Atualizando dados do motorista: $driverId');

      final data = await getDriverApprovalStatus(driverId);

      // Atualizar dados locais
      final currentData = await LocalStorageService.getDriverData();
      if (currentData != null) {
        currentData['approve'] = data.canLogin;
        currentData['uploadedDocuments'] = data.statistics.uploadedDocuments == data.statistics.totalDocuments;

        final token = await LocalStorageService.getAccessToken();
        await LocalStorageService.saveDriverSession(
          driverId: driverId,
          accessToken: token ?? '',
          driverData: currentData,
        );

        debugPrint('✅ Dados atualizados localmente');
        debugPrint('   - Pode fazer login: ${data.canLogin}');
        debugPrint('   - Documentos enviados: ${data.statistics.uploadedDocuments}/${data.statistics.totalDocuments}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao atualizar dados do motorista: $e');
    }
  }
}

// Classe de status de navegação
class DriverNavigationStatus {
  final DriverScreen targetScreen;
  final String? driverId;

  DriverNavigationStatus._({
    required this.targetScreen,
    this.driverId,
  });

  factory DriverNavigationStatus.needsLogin() {
    return DriverNavigationStatus._(targetScreen: DriverScreen.login);
  }

  factory DriverNavigationStatus.needsDocuments(String driverId) {
    return DriverNavigationStatus._(
      targetScreen: DriverScreen.uploadDocuments,
      driverId: driverId,
    );
  }

  factory DriverNavigationStatus.awaitingApproval(String driverId) {
    return DriverNavigationStatus._(
      targetScreen: DriverScreen.approvalStatus,
      driverId: driverId,
    );
  }

  factory DriverNavigationStatus.approved(String driverId) {
    return DriverNavigationStatus._(
      targetScreen: DriverScreen.home,
      driverId: driverId,
    );
  }
}

enum DriverScreen {
  login,
  uploadDocuments,
  approvalStatus,
  home,
}

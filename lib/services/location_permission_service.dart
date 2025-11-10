import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationPermissionService {
  /// Verifica e solicita permissões de localização ao abrir o app
  /// Retorna true se todas as permissões foram concedidas
  static Future<bool> checkAndRequestLocationPermission(
      BuildContext context) async {
    debugPrint('🔍 Verificando permissões de localização...');

    // 1. Verificar se o serviço de localização está habilitado
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('📍 Serviço de localização habilitado: $serviceEnabled');

    if (!serviceEnabled) {
      // GPS não está ligado - mostrar dialog para usuário habilitar
      debugPrint('⚠️ GPS desligado - mostrando dialog');
      await _showEnableLocationDialog(context);

      // Verificar novamente após o dialog
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Usuário não habilitou o GPS');
        return false;
      }
    }

    // 2. Verificar status da permissão de localização
    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('🔐 Status da permissão: $permission');

    if (permission == LocationPermission.denied) {
      debugPrint('📲 Solicitando permissão de localização...');
      permission = await Geolocator.requestPermission();
      debugPrint('📲 Resultado da solicitação: $permission');

      if (permission == LocationPermission.denied) {
        debugPrint('❌ Permissão negada pelo usuário');
        _showPermissionDeniedDialog(context);
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ Permissão negada permanentemente - direcionando para configurações');
      await _showPermissionDeniedForeverDialog(context);
      return false;
    }

    // 3. Permissão concedida!
    debugPrint('✅ Permissões de localização concedidas com sucesso');
    return true;
  }

  /// Dialog para pedir ao usuário que habilite o GPS
  static Future<void> _showEnableLocationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.location_off, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'GPS Desligado',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para usar o aplicativo, você precisa ativar o GPS do seu dispositivo.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Clique em "Abrir Configurações" para ativar o GPS.',
                        style: TextStyle(fontSize: 14, color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Abrir configurações de localização
                await Geolocator.openLocationSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Abrir Configurações',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Dialog quando o usuário nega a permissão
  static void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Permissão Necessária'),
            ],
          ),
          content: Text(
            'O aplicativo precisa de acesso à sua localização para funcionar corretamente.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Dialog quando a permissão foi negada permanentemente
  static Future<void> _showPermissionDeniedForeverDialog(
      BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.block, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Permissão Bloqueada',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Você negou a permissão de localização permanentemente.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Para usar o aplicativo, você precisa:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '1. Ir em Configurações do aplicativo\n'
                '2. Acessar Permissões\n'
                '3. Ativar a permissão de Localização',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Abrir configurações do app
                await openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Abrir Configurações',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

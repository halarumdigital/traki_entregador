// Arquivo de teste para verificar o funcionamento do Device ID
// Execute com: flutter run test_device_id.dart

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

void main() async {
  print('🧪 Testando obtenção de Device ID...\n');

  try {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceId = '';

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
      print('✅ Android Device ID obtido: $deviceId');
      print('📱 Modelo: ${androidInfo.model}');
      print('📱 Marca: ${androidInfo.brand}');
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? '';
      print('✅ iOS Device ID obtido: $deviceId');
      print('📱 Modelo: ${iosInfo.model}');
      print('📱 Nome: ${iosInfo.name}');
    } else {
      print('⚠️ Plataforma não suportada');
    }

    print('\n📊 Resumo do teste:');
    print('Device ID: ${deviceId.isEmpty ? "Não obtido" : deviceId}');
    print('Comprimento: ${deviceId.length} caracteres');

  } catch (e) {
    print('❌ Erro ao obter Device ID: $e');
  }
}
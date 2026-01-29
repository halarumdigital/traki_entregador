import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../functions/functions.dart';

class AppVersionInfo {
  final bool needsUpdate;
  final bool forceUpdate;
  final String minVersion;
  final String currentVersion;
  final String? updateMessage;
  final String? storeUrl;

  AppVersionInfo({
    required this.needsUpdate,
    required this.forceUpdate,
    required this.minVersion,
    required this.currentVersion,
    this.updateMessage,
    this.storeUrl,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      needsUpdate: json['needsUpdate'] ?? false,
      forceUpdate: json['forceUpdate'] ?? false,
      minVersion: json['minVersion'] ?? '1.0.0',
      currentVersion: json['currentVersion'] ?? '1.0.0',
      updateMessage: json['updateMessage'],
      storeUrl: json['storeUrl'],
    );
  }
}

class AppVersionService {
  /// Verifica se o app precisa de atualização
  /// GET /api/app/version
  static Future<AppVersionInfo?> checkVersion() async {
    try {
      // Obter versão atual do app
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;

      debugPrint('📱 [AppVersionService] Versão atual do app: $appVersion');

      final response = await http.get(
        Uri.parse('${url}api/app/version'),
        headers: {
          'Content-Type': 'application/json',
          'X-App-Version': appVersion,
        },
      );

      debugPrint('📱 [AppVersionService] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('📱 [AppVersionService] Resposta: $data');

        return AppVersionInfo.fromJson(data);
      } else {
        debugPrint('⚠️ [AppVersionService] Erro na resposta: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [AppVersionService] Erro ao verificar versão: $e');
      return null;
    }
  }
}

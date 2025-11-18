import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../functions/functions.dart';
import '../models/notification.dart';
import 'local_storage_service.dart';

class DriverNotificationService {
  /// Buscar todas as notificações do motorista autenticado
  static Future<NotificationsResponse?> getNotifications() async {
    try {
      debugPrint('🔔 Buscando notificações do motorista...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Notificações: Token não encontrado');
        return null;
      }

      final endpoint = '${url}api/v1/driver/notifications';
      debugPrint('🌐 Notificações URL: $endpoint');

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📥 Notificações Status Code: ${response.statusCode}');
      debugPrint('📥 Notificações Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('📋 Notificações Response JSON: $jsonResponse');

        if (jsonResponse['success'] == true) {
          final notificationsResponse = NotificationsResponse.fromJson(jsonResponse);
          debugPrint('✅ ${notificationsResponse.count} notificações carregadas');
          return notificationsResponse;
        } else {
          debugPrint('⚠️ Notificações: success=${jsonResponse['success']}');
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ Não autorizado - Token inválido ou expirado');
        return null;
      } else {
        debugPrint('⚠️ Notificações: Status code diferente de 200: ${response.statusCode}');
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao buscar notificações: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return null;
    }
  }
}

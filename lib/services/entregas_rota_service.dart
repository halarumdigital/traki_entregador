import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../functions/functions.dart';
import '../models/entrega_rota.dart';
import 'local_storage_service.dart';

class EntregasRotaService {
  /// Listar entregas disponíveis nas rotas configuradas pelo motorista
  static Future<List<EntregaRota>> getEntregasDisponiveis({
    required String dataViagem,
  }) async {
    try {
      debugPrint('📦 Buscando entregas disponíveis para $dataViagem...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return [];
      }

      final response = await http.get(
        Uri.parse('${url}api/entregador/entregas-disponiveis?dataViagem=$dataViagem'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('✅ ${data.length} entregas disponíveis carregadas');
        return data.map((json) => EntregaRota.fromJson(json)).toList();
      }

      debugPrint('❌ Erro ao buscar entregas: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ Erro ao buscar entregas disponíveis: $e');
      return [];
    }
  }

  /// Aceitar uma entrega
  static Future<String?> aceitarEntrega(String entregaId) async {
    try {
      debugPrint('📦 Aceitando entrega: $entregaId');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return null;
      }

      final response = await http.post(
        Uri.parse('${url}api/entregador/entregas/$entregaId/aceitar'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');
      debugPrint('📦 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final viagemId = data['viagemId'];
        debugPrint('✅ Entrega aceita! Viagem ID: $viagemId');
        return viagemId;
      }

      debugPrint('❌ Erro ao aceitar entrega: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Erro ao aceitar entrega: $e');
      return null;
    }
  }

  /// Rejeitar uma entrega
  static Future<bool> rejeitarEntrega(String entregaId, {String? motivo}) async {
    try {
      debugPrint('📦 Rejeitando entrega: $entregaId');
      debugPrint('   Motivo: ${motivo ?? "Não informado"}');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return false;
      }

      final body = jsonEncode({
        'motivo': motivo ?? 'Não informado',
      });

      final response = await http.post(
        Uri.parse('${url}api/entregador/entregas/$entregaId/rejeitar'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Entrega rejeitada');
        return true;
      }

      debugPrint('❌ Erro ao rejeitar entrega: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ Erro ao rejeitar entrega: $e');
      return false;
    }
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../functions/functions.dart';
import '../models/rota.dart';
import '../models/minha_rota.dart';
import 'local_storage_service.dart';

class RotasService {
  /// Listar rotas disponíveis para configuração
  static Future<List<Rota>> getRotasDisponiveis() async {
    try {
      debugPrint('🛣️ Buscando rotas disponíveis...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return [];
      }

      debugPrint('🔑 Token: ${token.substring(0, 20)}...');
      debugPrint('🌐 URL: ${url}api/entregador/rotas-disponiveis');

      final response = await http.get(
        Uri.parse('${url}api/entregador/rotas-disponiveis'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');
      debugPrint('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('✅ ${data.length} rotas disponíveis carregadas');
        return data.map((json) => Rota.fromJson(json)).toList();
      }

      debugPrint('❌ Erro ao buscar rotas: ${response.statusCode}');
      debugPrint('❌ Response: ${response.body}');
      return [];
    } catch (e) {
      debugPrint('❌ Erro ao buscar rotas disponíveis: $e');
      return [];
    }
  }

  /// Listar minhas rotas configuradas
  static Future<List<MinhaRota>> getMinhasRotas() async {
    try {
      debugPrint('🛣️ Buscando minhas rotas...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return [];
      }

      debugPrint('🔑 Token: ${token.substring(0, 20)}...');
      debugPrint('🌐 URL: ${url}api/entregador/minhas-rotas');

      final response = await http.get(
        Uri.parse('${url}api/entregador/minhas-rotas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');
      debugPrint('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('✅ ${data.length} rotas configuradas carregadas');
        return data.map((json) => MinhaRota.fromJson(json)).toList();
      }

      debugPrint('❌ Erro ao buscar minhas rotas: ${response.statusCode}');
      debugPrint('❌ Response: ${response.body}');
      return [];
    } catch (e) {
      debugPrint('❌ Erro ao buscar minhas rotas: $e');
      return [];
    }
  }

  /// Configurar capacidade para uma rota
  static Future<MinhaRota?> configurarRota({
    required String rotaId,
    required int capacidadePacotes,
    required double capacidadePesoKg,
    required String horarioSaidaPadrao,
    List<int>? diasSemana,
  }) async {
    try {
      debugPrint('🛣️ Configurando rota...');
      debugPrint('   - Rota ID: $rotaId');
      debugPrint('   - Capacidade: $capacidadePacotes pacotes, $capacidadePesoKg kg');
      debugPrint('   - Horário: $horarioSaidaPadrao');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return null;
      }

      final Map<String, dynamic> bodyData = {
        'rotaId': rotaId,
        'capacidadePacotes': capacidadePacotes,
        'capacidadePesoKg': capacidadePesoKg.toString(),
        'horarioSaidaPadrao': horarioSaidaPadrao,
        'ativo': true,
      };

      // Adicionar dias da semana se fornecido
      if (diasSemana != null && diasSemana.isNotEmpty) {
        bodyData['diasSemana'] = diasSemana;
      }

      final body = jsonEncode(bodyData);

      debugPrint('📤 Body: $body');

      final response = await http.post(
        Uri.parse('${url}api/entregador/rotas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      debugPrint('📥 Status Code: ${response.statusCode}');
      debugPrint('📦 Response: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Rota configurada com sucesso');
        return MinhaRota.fromJson(data);
      }

      debugPrint('❌ Erro ao configurar rota: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Erro ao configurar rota: $e');
      return null;
    }
  }

  /// Atualizar configuração de uma rota
  static Future<MinhaRota?> atualizarRota({
    required String rotaId,
    int? capacidadePacotes,
    double? capacidadePesoKg,
    String? horarioSaidaPadrao,
    List<int>? diasSemana,
    bool? ativo,
  }) async {
    try {
      debugPrint('🛣️ Atualizando rota: $rotaId');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return null;
      }

      final Map<String, dynamic> bodyData = {};
      if (capacidadePacotes != null) bodyData['capacidadePacotes'] = capacidadePacotes;
      if (capacidadePesoKg != null) bodyData['capacidadePesoKg'] = capacidadePesoKg.toString();
      if (horarioSaidaPadrao != null) bodyData['horarioSaidaPadrao'] = horarioSaidaPadrao;
      if (diasSemana != null) bodyData['diasSemana'] = diasSemana;
      if (ativo != null) bodyData['ativo'] = ativo;

      final body = jsonEncode(bodyData);
      debugPrint('📤 Body: $body');

      final response = await http.put(
        Uri.parse('${url}api/entregador/rotas/$rotaId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Rota atualizada com sucesso');
        return MinhaRota.fromJson(data);
      }

      debugPrint('❌ Erro ao atualizar rota: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Erro ao atualizar rota: $e');
      return null;
    }
  }

  /// Remover configuração de rota
  static Future<bool> removerRota(String rotaId) async {
    try {
      debugPrint('🛣️ Removendo rota: $rotaId');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return false;
      }

      final response = await http.delete(
        Uri.parse('${url}api/entregador/rotas/$rotaId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Rota removida com sucesso');
        return true;
      }

      debugPrint('❌ Erro ao remover rota: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ Erro ao remover rota: $e');
      return false;
    }
  }
}

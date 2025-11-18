import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../functions/functions.dart';
import '../models/viagem.dart';
import '../models/entrega_viagem.dart';
import '../models/viagem_coleta.dart';
import 'local_storage_service.dart';

class ViagensService {
  /// Listar minhas viagens
  static Future<List<Viagem>> getMinhasViagens() async {
    try {
      debugPrint('🚗 Buscando minhas viagens...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return [];
      }

      final response = await http.get(
        Uri.parse('${url}api/entregador/viagens'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('✅ ${data.length} viagens carregadas');

        // Log detalhado da primeira viagem para debug
        if (data.isNotEmpty) {
          final primeiraViagem = data[0] as Map<String, dynamic>;
          debugPrint('📋 DEBUG - Campos da primeira viagem:');
          debugPrint('   totalColetas: ${primeiraViagem['total_coletas']}');
          debugPrint('   coletasConcluidas: ${primeiraViagem['coletas_concluidas']}');
          debugPrint('   totalEntregas: ${primeiraViagem['total_entregas']}');
          debugPrint('   entregasConcluidas: ${primeiraViagem['entregas_concluidas']}');
          debugPrint('   rotaNome: ${primeiraViagem['rota_nome']}');
          debugPrint('📋 JSON completo: ${jsonEncode(primeiraViagem)}');
        }

        return data.map((json) => Viagem.fromJson(json)).toList();
      }

      debugPrint('❌ Erro ao buscar viagens: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ Erro ao buscar viagens: $e');
      return [];
    }
  }

  /// Buscar detalhes de uma viagem
  static Future<Viagem?> getViagemDetalhes(String viagemId) async {
    try {
      debugPrint('🚗 Buscando detalhes da viagem: $viagemId');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return null;
      }

      final response = await http.get(
        Uri.parse('${url}api/entregador/viagens/$viagemId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Detalhes da viagem carregados');
        return Viagem.fromJson(data);
      }

      debugPrint('❌ Erro ao buscar detalhes: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Erro ao buscar detalhes da viagem: $e');
      return null;
    }
  }

  /// Iniciar uma viagem
  static Future<bool> iniciarViagem(String viagemId) async {
    try {
      debugPrint('🚗 Iniciando viagem: $viagemId');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return false;
      }

      final response = await http.post(
        Uri.parse('${url}api/entregador/viagens/$viagemId/iniciar'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Viagem iniciada com sucesso');
        return true;
      }

      debugPrint('❌ Erro ao iniciar viagem: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ Erro ao iniciar viagem: $e');
      return false;
    }
  }

  /// Concluir uma viagem (manualmente se necessário)
  static Future<bool> concluirViagem(String viagemId) async {
    try {
      debugPrint('🏁 Concluindo viagem: $viagemId');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return false;
      }

      final response = await http.put(
        Uri.parse('${url}api/viagens-intermunicipais/$viagemId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': 'concluida'}),
      );

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Viagem concluída com sucesso');
        return true;
      }

      debugPrint('❌ Erro ao concluir viagem: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ Erro ao concluir viagem: $e');
      return false;
    }
  }

  /// Listar entregas de uma viagem
  static Future<List<EntregaViagem>> getEntregasViagem(String viagemId) async {
    try {
      debugPrint('📦 Buscando entregas da viagem: $viagemId');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return [];
      }

      final response = await http.get(
        Uri.parse('${url}api/entregador/viagens/$viagemId/entregas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('✅ ${data.length} entregas carregadas');
        debugPrint('📋 JSON das entregas: ${response.body}');
        return data.map((json) => EntregaViagem.fromJson(json)).toList();
      }

      debugPrint('❌ Erro ao buscar entregas: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ Erro ao buscar entregas da viagem: $e');
      return [];
    }
  }

  /// Atualizar status de uma entrega
  static Future<bool> atualizarStatusEntrega({
    required String entregaId,
    required String status,
    String? motivoFalha,
    String? observacoes,
  }) async {
    try {
      debugPrint('📦 Atualizando status da entrega: $entregaId');
      debugPrint('   Status: $status');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return false;
      }

      final Map<String, dynamic> bodyData = {
        'status': status,
      };

      if (motivoFalha != null) bodyData['motivoFalha'] = motivoFalha;
      if (observacoes != null) bodyData['observacoes'] = observacoes;

      final body = jsonEncode(bodyData);
      debugPrint('📤 Body: $body');

      final response = await http.put(
        Uri.parse('${url}api/entregador/entregas-viagem/$entregaId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Status atualizado com sucesso');
        return true;
      }

      debugPrint('❌ Erro ao atualizar status: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ Erro ao atualizar status da entrega: $e');
      return false;
    }
  }

  /// Listar coletas de uma viagem
  static Future<List<ViagemColeta>> getColetasViagem(String viagemId) async {
    try {
      debugPrint('📦 Buscando coletas da viagem: $viagemId');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return [];
      }

      final response = await http.get(
        Uri.parse('${url}api/entregador/viagens/$viagemId/coletas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('✅ ${data.length} coletas carregadas');
        debugPrint('📋 JSON das coletas: ${response.body}');
        return data.map((json) => ViagemColeta.fromJson(json)).toList();
      }

      debugPrint('❌ Erro ao buscar coletas: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ Erro ao buscar coletas da viagem: $e');
      return [];
    }
  }

  /// Atualizar status de uma coleta
  static Future<bool> atualizarStatusColeta({
    required String coletaId,
    required String status,
    String? motivoFalha,
    String? observacoes,
  }) async {
    try {
      debugPrint('📦 Atualizando status da coleta: $coletaId');
      debugPrint('   Status: $status');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return false;
      }

      final Map<String, dynamic> bodyData = {
        'status': status,
      };

      if (motivoFalha != null) bodyData['motivoFalha'] = motivoFalha;
      if (observacoes != null) bodyData['observacoes'] = observacoes;

      final body = jsonEncode(bodyData);
      debugPrint('📤 Body: $body');

      final response = await http.put(
        Uri.parse('${url}api/entregador/coletas/$coletaId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Status da coleta atualizado com sucesso');
        return true;
      }

      debugPrint('❌ Erro ao atualizar status da coleta: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ Erro ao atualizar status da coleta: $e');
      return false;
    }
  }

  /// Atualizar status de uma parada específica
  static Future<bool> atualizarStatusParada({
    required String entregaId,
    required String paradaId,
    required String status,
    String? motivoFalha,
  }) async {
    try {
      debugPrint('📍 Atualizando status da parada: $paradaId');
      debugPrint('   Entrega: $entregaId');
      debugPrint('   Status: $status');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return false;
      }

      final Map<String, dynamic> bodyData = {
        'status': status,
      };

      if (motivoFalha != null) bodyData['motivoFalha'] = motivoFalha;

      final body = jsonEncode(bodyData);
      debugPrint('📤 Body: $body');

      final response = await http.put(
        Uri.parse('${url}api/entregas-intermunicipais/$entregaId/paradas/$paradaId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Status da parada atualizado com sucesso');
        return true;
      }

      debugPrint('❌ Erro ao atualizar status da parada: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ Erro ao atualizar status da parada: $e');
      return false;
    }
  }

  /// Buscar detalhes de uma entrega intermunicipal (incluindo paradas)
  static Future<EntregaViagem?> getEntregaIntermunicipalDetalhes(String entregaId) async {
    try {
      debugPrint('📦 Buscando detalhes da entrega intermunicipal: $entregaId');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return null;
      }

      final response = await http.get(
        Uri.parse('${url}api/entregas-intermunicipais/$entregaId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Detalhes da entrega intermunicipal carregados');
        debugPrint('📍 Número de paradas: ${data['numeroParadas']}');
        return EntregaViagem.fromJson(data);
      }

      debugPrint('❌ Erro ao buscar detalhes: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Erro ao buscar detalhes da entrega intermunicipal: $e');
      return null;
    }
  }
}

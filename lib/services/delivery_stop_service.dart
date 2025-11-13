import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../functions/functions.dart';
import '../models/delivery_stop.dart';
import 'local_storage_service.dart';

/// Service para gerenciar stops de entregas
class DeliveryStopService {
  /// Buscar todos os stops de uma entrega
  static Future<DeliveryStopsResponse> getDeliveryStops(String deliveryId) async {
    try {
      debugPrint('📍 Buscando stops da entrega $deliveryId...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return DeliveryStopsResponse(
          success: false,
          data: [],
          count: 0,
          message: 'Não autenticado',
        );
      }

      final response = await http.get(
        Uri.parse('${url}api/v1/driver/deliveries/$deliveryId/stops'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');
      debugPrint('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final stopsResponse = DeliveryStopsResponse.fromJson(jsonResponse);

        debugPrint('✅ ${stopsResponse.data.length} stop(s) carregado(s)');
        for (var stop in stopsResponse.data) {
          debugPrint('  [${stop.stopOrder}] ${stop.customerName ?? "Sem nome"} - ${stop.statusText}');
        }

        return stopsResponse;
      } else if (response.statusCode == 401) {
        debugPrint('❌ Não autenticado');
        return DeliveryStopsResponse(
          success: false,
          data: [],
          count: 0,
          message: 'Não autenticado',
        );
      } else {
        debugPrint('❌ Erro: Status ${response.statusCode}');
        return DeliveryStopsResponse(
          success: false,
          data: [],
          count: 0,
          message: 'Erro ao buscar paradas',
        );
      }
    } catch (e) {
      debugPrint('❌ Erro inesperado ao buscar stops: $e');
      return DeliveryStopsResponse(
        success: false,
        data: [],
        count: 0,
        message: 'Erro ao buscar paradas: $e',
      );
    }
  }

  /// Marcar chegada em um stop
  static Future<bool> arrivedAtStop(String deliveryId, String stopId) async {
    try {
      debugPrint('📍 Marcando chegada no stop $stopId da entrega $deliveryId...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        throw Exception('Não autenticado');
      }

      final response = await http.post(
        Uri.parse('${url}api/v1/driver/deliveries/$deliveryId/stops/$stopId/arrived'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');
      debugPrint('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          debugPrint('✅ Chegada registrada no stop $stopId');
          return true;
        }
      }

      debugPrint('❌ Falha ao marcar chegada');
      return false;
    } catch (e) {
      debugPrint('❌ Erro ao marcar chegada: $e');
      rethrow;
    }
  }

  /// Marcar conclusão de um stop
  static Future<Map<String, dynamic>> completeStop(String deliveryId, String stopId) async {
    try {
      debugPrint('📍 Marcando conclusão do stop $stopId da entrega $deliveryId...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        throw Exception('Não autenticado');
      }

      final response = await http.post(
        Uri.parse('${url}api/v1/driver/deliveries/$deliveryId/stops/$stopId/complete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');
      debugPrint('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          debugPrint('✅ Stop $stopId concluído');

          final data = jsonResponse['data'];
          return {
            'success': true,
            'hasNextStop': data?['hasNextStop'] ?? data?['has_next_stop'] ?? false,
            'allCompleted': data?['allCompleted'] ?? data?['all_completed'] ?? false,
            'needsReturn': data?['needsReturn'] ?? data?['needs_return'] ?? false,
            'message': jsonResponse['message'] ?? 'Stop concluído',
          };
        }
      }

      debugPrint('❌ Falha ao concluir stop');
      return {
        'success': false,
        'hasNextStop': false,
        'allCompleted': false,
        'needsReturn': false,
        'message': 'Erro ao concluir parada',
      };
    } catch (e) {
      debugPrint('❌ Erro ao concluir stop: $e');
      rethrow;
    }
  }

  /// Buscar stop específico por ID
  static Future<DeliveryStop?> getStop(String deliveryId, String stopId) async {
    try {
      debugPrint('📍 Buscando stop $stopId da entrega $deliveryId...');

      final stopsResponse = await getDeliveryStops(deliveryId);

      if (!stopsResponse.success) {
        return null;
      }

      final stop = stopsResponse.data.firstWhere(
        (s) => s.id == stopId,
        orElse: () => throw Exception('Stop não encontrado'),
      );

      return stop;
    } catch (e) {
      debugPrint('❌ Erro ao buscar stop: $e');
      return null;
    }
  }

  /// Buscar stop atual (primeiro pending ou arrived)
  static Future<DeliveryStop?> getCurrentStop(String deliveryId) async {
    try {
      final stopsResponse = await getDeliveryStops(deliveryId);

      if (!stopsResponse.success || stopsResponse.data.isEmpty) {
        return null;
      }

      // Procurar primeiro stop arrived ou pending
      final current = stopsResponse.data.firstWhere(
        (stop) => stop.isArrived || stop.isPending,
        orElse: () => stopsResponse.data.first,
      );

      return current;
    } catch (e) {
      debugPrint('❌ Erro ao buscar stop atual: $e');
      return null;
    }
  }

  /// Pular um stop (marcar como skipped)
  static Future<bool> skipStop(String deliveryId, String stopId, {String? reason}) async {
    try {
      debugPrint('📍 Pulando stop $stopId da entrega $deliveryId...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        throw Exception('Não autenticado');
      }

      final response = await http.post(
        Uri.parse('${url}api/v1/driver/deliveries/$deliveryId/stops/$stopId/skip'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reason': reason,
        }),
      );

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          debugPrint('✅ Stop $stopId pulado');
          return true;
        }
      }

      debugPrint('❌ Falha ao pular stop');
      return false;
    } catch (e) {
      debugPrint('❌ Erro ao pular stop: $e');
      rethrow;
    }
  }
}

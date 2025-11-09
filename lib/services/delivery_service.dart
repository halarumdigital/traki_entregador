import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../functions/functions.dart';
import 'local_storage_service.dart';

class DeliveryService {
  // Listar entregas disponíveis
  static Future<List<Map<String, dynamic>>> getAvailableDeliveries() async {
    try {
      debugPrint('📦 Buscando entregas disponíveis...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return [];
      }

      final response = await http.get(
        Uri.parse('${url}api/v1/driver/deliveries/available'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          debugPrint('✅ Entregas disponíveis carregadas');
          return List<Map<String, dynamic>>.from(jsonResponse['data']);
        }
      }

      return [];
    } catch (e) {
      debugPrint('❌ Erro ao buscar entregas disponíveis: $e');
      return [];
    }
  }

  // Obter entrega em andamento
  static Future<Map<String, dynamic>?> getCurrentDelivery() async {
    try {
      debugPrint('📦 Buscando entrega atual...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return null;
      }

      final response = await http.get(
        Uri.parse('${url}api/v1/driver/deliveries/current'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          debugPrint('✅ Entrega atual carregada');

          // Mapear campos snake_case para camelCase para compatibilidade com ActiveDeliveryScreen
          final data = jsonResponse['data'] as Map<String, dynamic>;
          return {
            'requestId': data['id'],
            'requestNumber': data['request_number'],
            'companyName': data['company_name'],
            'companyPhone': data['company_phone'],
            'customerName': data['customer_name'],
            'pickupAddress': data['pick_address'],
            'pickupLat': data['pick_lat'],
            'pickupLng': data['pick_lng'],
            'deliveryAddress': data['drop_address'],
            'deliveryLat': data['drop_lat'],
            'deliveryLng': data['drop_lng'],
            'distance': data['total_distance']?.toString(),
            'estimatedTime': data['total_time']?.toString(),
            'driverAmount': data['request_eta_amount']?.toString(),
          };
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Erro ao buscar entrega atual: $e');
      return null;
    }
  }

  // Aceitar entrega
  static Future<Map<String, dynamic>?> acceptDelivery(String deliveryId) async {
    try {
      debugPrint('✅ Aceitando entrega: $deliveryId');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return null;
      }

      final response = await http.post(
        Uri.parse('${url}api/v1/driver/requests/$deliveryId/accept'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');
      debugPrint('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('📋 Response JSON: $jsonResponse');
        if (jsonResponse['success'] == true) {
          debugPrint('✅ Entrega aceita com sucesso');
          debugPrint('📦 Dados da entrega: ${jsonResponse['data']}');
          return jsonResponse['data'];
        } else {
          debugPrint('⚠️ Success = false: ${jsonResponse['message']}');
        }
      } else {
        debugPrint('❌ Status code diferente de 200: ${response.statusCode}');
        debugPrint('❌ Body: ${response.body}');
      }

      return null;
    } catch (e) {
      debugPrint('❌ Erro ao aceitar entrega: $e');
      return null;
    }
  }

  // Rejeitar entrega
  static Future<bool> rejectDelivery(String deliveryId, {String? reason}) async {
    try {
      debugPrint('❌ Rejeitando entrega: $deliveryId');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return false;
      }

      final response = await http.post(
        Uri.parse('${url}api/v1/driver/deliveries/$deliveryId/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: reason != null ? jsonEncode({'reason': reason}) : null,
      );

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('✅ Entrega rejeitada');
        return jsonResponse['success'] == true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Erro ao rejeitar entrega: $e');
      return false;
    }
  }

  // Motorista chegou no local de retirada
  static Future<bool> arrivedAtPickup(String deliveryId) async {
    try {
      debugPrint('📍 Motorista chegou para retirada: $deliveryId');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return false;
      }

      debugPrint('🔑 Token obtido: ${token.substring(0, 20)}...'); // Mostrar primeiros 20 caracteres

      final endpoint = '${url}api/v1/driver/deliveries/$deliveryId/arrived-pickup';
      debugPrint('📡 Chamando endpoint: $endpoint');
      debugPrint('📋 Headers: Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');
      debugPrint('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('✅ Chegada marcada');
        return jsonResponse['success'] == true;
      } else if (response.statusCode == 401) {
        debugPrint('❌ ERRO DE AUTENTICAÇÃO - Token inválido ou expirado');
        debugPrint('❌ Response: ${response.body}');
      } else {
        debugPrint('❌ Status code diferente de 200: ${response.statusCode}');
      }

      return false;
    } catch (e) {
      debugPrint('❌ Erro ao marcar chegada: $e');
      return false;
    }
  }

  // Motorista retirou o pedido
  static Future<bool> pickedUp(String deliveryId) async {
    try {
      debugPrint('📦 Pedido retirado: $deliveryId');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return false;
      }

      debugPrint('🔑 Token obtido: ${token.substring(0, 20)}...');

      final endpoint = '${url}api/v1/driver/deliveries/$deliveryId/picked-up';
      debugPrint('📡 Chamando endpoint: $endpoint');
      debugPrint('📋 Headers: Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');
      debugPrint('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('✅ Retirada marcada');
        return jsonResponse['success'] == true;
      } else if (response.statusCode == 401) {
        debugPrint('❌ ERRO DE AUTENTICAÇÃO - Token inválido ou expirado');
        debugPrint('❌ Response: ${response.body}');
      } else {
        debugPrint('❌ Status code diferente de 200: ${response.statusCode}');
      }

      return false;
    } catch (e) {
      debugPrint('❌ Erro ao marcar retirada: $e');
      return false;
    }
  }

  // Motorista entregou o pedido
  static Future<bool> delivered(String deliveryId) async {
    try {
      debugPrint('✅ Pedido entregue: $deliveryId');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return false;
      }

      debugPrint('🔑 Token obtido: ${token.substring(0, 20)}...');

      final endpoint = '${url}api/v1/driver/deliveries/$deliveryId/delivered';
      debugPrint('📡 Chamando endpoint: $endpoint');
      debugPrint('📋 Headers: Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');
      debugPrint('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('✅ Entrega marcada');
        return jsonResponse['success'] == true;
      } else if (response.statusCode == 401) {
        debugPrint('❌ ERRO DE AUTENTICAÇÃO - Token inválido ou expirado');
        debugPrint('❌ Response: ${response.body}');
      } else {
        debugPrint('❌ Status code diferente de 200: ${response.statusCode}');
      }

      return false;
    } catch (e) {
      debugPrint('❌ Erro ao marcar entrega: $e');
      return false;
    }
  }

  // Completar entrega
  static Future<bool> complete(String deliveryId) async {
    try {
      debugPrint('🎉 Completando entrega: $deliveryId');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return false;
      }

      debugPrint('🔑 Token obtido: ${token.substring(0, 20)}...');

      final endpoint = '${url}api/v1/driver/deliveries/$deliveryId/complete';
      debugPrint('📡 Chamando endpoint: $endpoint');
      debugPrint('📋 Headers: Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');
      debugPrint('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('✅ Entrega completada');
        return jsonResponse['success'] == true;
      } else if (response.statusCode == 401) {
        debugPrint('❌ ERRO DE AUTENTICAÇÃO - Token inválido ou expirado');
        debugPrint('❌ Response: ${response.body}');
      } else {
        debugPrint('❌ Status code diferente de 200: ${response.statusCode}');
      }

      return false;
    } catch (e) {
      debugPrint('❌ Erro ao completar entrega: $e');
      return false;
    }
  }
}

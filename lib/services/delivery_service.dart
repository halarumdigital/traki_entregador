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
      debugPrint('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('📋 Response JSON: $jsonResponse');

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          debugPrint('✅ Entrega atual carregada');

          // Mapear campos snake_case para camelCase para compatibilidade com ActiveDeliveryScreen
          final data = jsonResponse['data'] as Map<String, dynamic>;

          debugPrint('🔍 Mapeando customerWhatsapp: ${data['customer_whatsapp']}');
          debugPrint('🔍 Mapeando deliveryReference: ${data['delivery_reference']}');

          final mappedData = {
            'requestId': data['id'],
            'requestNumber': data['request_number'],
            'companyName': data['company_name'],
            'companyPhone': data['company_phone'],
            'customerName': data['customer_name'],
            'customerWhatsapp': data['customer_whatsapp'],
            'deliveryReference': data['delivery_reference'],
            'pickupAddress': data['pick_address'],
            'pickupLat': data['pick_lat'],
            'pickupLng': data['pick_lng'],
            'deliveryAddress': data['drop_address'],
            'deliveryLat': data['drop_lat'],
            'deliveryLng': data['drop_lng'],
            'distance': data['total_distance']?.toString(),
            'estimatedTime': data['estimated_time']?.toString() ?? data['total_time']?.toString(),
            'driverAmount': data['driver_amount']?.toString() ?? data['request_eta_amount']?.toString(),
          };

          debugPrint('📤 Retornando objeto mapeado: $mappedData');
          return mappedData;
        } else {
          debugPrint('⚠️ Backend retornou success=false ou data=null');
        }
      } else {
        debugPrint('❌ Status code diferente de 200: ${response.statusCode}');
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
      debugPrint('🟢 ========== INICIANDO ACCEPT DELIVERY ==========');
      debugPrint('✅ DeliveryId recebido: $deliveryId');
      debugPrint('🔍 Tipo do deliveryId: ${deliveryId.runtimeType}');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado no LocalStorage');
        return null;
      }

      debugPrint('🔑 Token obtido (primeiros 30 caracteres): ${token.substring(0, token.length > 30 ? 30 : token.length)}...');
      debugPrint('🔑 Tamanho do token: ${token.length} caracteres');

      final endpoint = '${url}api/v1/driver/requests/$deliveryId/accept';
      debugPrint('📡 URL completa: $endpoint');
      debugPrint('📋 Headers que serão enviados:');
      debugPrint('   - Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 ========== RESPOSTA DO SERVIDOR ==========');
      debugPrint('📥 Status Code: ${response.statusCode}');
      debugPrint('📦 Response Body: ${response.body}');
      debugPrint('📋 Response Headers: ${response.headers}');

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
      } else if (response.statusCode == 401) {
        debugPrint('❌ ========== ERRO 401: NÃO AUTORIZADO ==========');
        debugPrint('❌ Possíveis causas:');
        debugPrint('   1. Token expirado ou inválido');
        debugPrint('   2. Backend não reconhece o token');
        debugPrint('   3. Endpoint requer permissões diferentes para entregas relançadas');
        debugPrint('❌ Body da resposta: ${response.body}');
        try {
          final errorJson = jsonDecode(response.body);
          debugPrint('❌ Mensagem de erro: ${errorJson['message'] ?? 'Não especificada'}');
          debugPrint('❌ Detalhes: $errorJson');
        } catch (e) {
          debugPrint('❌ Não foi possível parsear o JSON de erro');
        }
      } else if (response.statusCode == 410) {
        debugPrint('⏰ ========== ERRO 410: ENTREGA EXPIRADA ==========');
        debugPrint('⏰ A entrega já não está mais disponível');
        debugPrint('⏰ Body: ${response.body}');
        return {'error': 'expired', 'message': 'Esta entrega já expirou'};
      } else {
        debugPrint('❌ Status code diferente de 200: ${response.statusCode}');
        debugPrint('❌ Body: ${response.body}');
      }

      debugPrint('🔴 ========== FIM ACCEPT DELIVERY (FALHA) ==========');
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
  static Future<Map<String, dynamic>?> delivered(String deliveryId) async {
    try {
      debugPrint('✅ Pedido entregue: $deliveryId');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return null;
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
        if (jsonResponse['success'] == true) {
          // Retornar dados da resposta incluindo status e needsReturn
          return jsonResponse['data'];
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ ERRO DE AUTENTICAÇÃO - Token inválido ou expirado');
        debugPrint('❌ Response: ${response.body}');
      } else {
        debugPrint('❌ Status code diferente de 200: ${response.statusCode}');
      }

      return null;
    } catch (e) {
      debugPrint('❌ Erro ao marcar entrega: $e');
      return null;
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

  // Iniciar retorno ao ponto de origem
  static Future<Map<String, dynamic>?> startReturn(String deliveryId) async {
    try {
      debugPrint('🔄 Iniciando retorno ao ponto de origem: $deliveryId');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return null;
      }

      debugPrint('🔑 Token obtido: ${token.substring(0, 20)}...');

      final endpoint = '${url}api/v1/driver/deliveries/$deliveryId/start-return';
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
        debugPrint('✅ Retorno iniciado');
        if (jsonResponse['success'] == true) {
          return jsonResponse['data'];
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ ERRO DE AUTENTICAÇÃO - Token inválido ou expirado');
        debugPrint('❌ Response: ${response.body}');
      } else {
        debugPrint('❌ Status code diferente de 200: ${response.statusCode}');
      }

      return null;
    } catch (e) {
      debugPrint('❌ Erro ao iniciar retorno: $e');
      return null;
    }
  }

  // Completar retorno ao ponto de origem
  static Future<Map<String, dynamic>?> completeReturn(String deliveryId) async {
    try {
      debugPrint('✅ Completando retorno ao ponto de origem: $deliveryId');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return null;
      }

      debugPrint('🔑 Token obtido: ${token.substring(0, 20)}...');

      final endpoint = '${url}api/v1/driver/deliveries/$deliveryId/complete-return';
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
        debugPrint('✅ Retorno completado - Entrega finalizada');
        if (jsonResponse['success'] == true) {
          return jsonResponse['data'];
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ ERRO DE AUTENTICAÇÃO - Token inválido ou expirado');
        debugPrint('❌ Response: ${response.body}');
      } else {
        debugPrint('❌ Status code diferente de 200: ${response.statusCode}');
      }

      return null;
    } catch (e) {
      debugPrint('❌ Erro ao completar retorno: $e');
      return null;
    }
  }

  // Obter estatísticas de comissão do motorista
  static Future<Map<String, dynamic>?> getCommissionStats() async {
    try {
      debugPrint('📊 Buscando estatísticas de comissão...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return null;
      }

      final response = await http.get(
        Uri.parse('${url}api/v1/driver/commission-stats'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('📋 Response JSON: $jsonResponse');
        debugPrint('📋 Data: ${jsonResponse['data']}');

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          debugPrint('✅ Estatísticas carregadas com sucesso');
          final data = jsonResponse['data'];
          debugPrint('🔍 Keys do data: ${data.keys}');
          return data;
        }
      }

      debugPrint('⚠️ Não foi possível carregar estatísticas');
      return null;
    } catch (e) {
      debugPrint('❌ Erro ao buscar estatísticas: $e');
      return null;
    }
  }

  // Obter promoções ativas
  static Future<List<Map<String, dynamic>>> getPromotions() async {
    try {
      debugPrint('🎁 Buscando promoções ativas...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return [];
      }

      final response = await http.get(
        Uri.parse('${url}api/v1/driver/promotions'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          debugPrint('✅ Promoções carregadas com sucesso: ${data.length} promoções');
          return data.map((item) => item as Map<String, dynamic>).toList();
        }
      }

      debugPrint('⚠️ Nenhuma promoção encontrada (Status: ${response.statusCode})');
      return [];
    } catch (e) {
      debugPrint('❌ Erro ao buscar promoções: $e');
      return [];
    }
  }

  // Avaliar empresa após entrega
  static Future<Map<String, dynamic>?> rateCompany(String deliveryId, int rating) async {
    try {
      debugPrint('⭐ Avaliando empresa: $deliveryId com $rating estrelas');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return null;
      }

      debugPrint('🔑 Token obtido: ${token.substring(0, 20)}...');

      final endpoint = '${url}api/v1/driver/deliveries/$deliveryId/rate';
      debugPrint('📡 Chamando endpoint: $endpoint');
      debugPrint('📋 Headers: Authorization: Bearer ${token.substring(0, 20)}...');
      debugPrint('📊 Rating: $rating');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'rating': rating,
        }),
      );

      debugPrint('📥 Status Code: ${response.statusCode}');
      debugPrint('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('✅ Avaliação registrada com sucesso');
        if (jsonResponse['success'] == true) {
          return jsonResponse['data'];
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ ERRO DE AUTENTICAÇÃO - Token inválido ou expirado');
        debugPrint('❌ Response: ${response.body}');
      } else if (response.statusCode == 400) {
        debugPrint('❌ ERRO DE VALIDAÇÃO');
        debugPrint('❌ Response: ${response.body}');
      } else {
        debugPrint('❌ Status code diferente de 200: ${response.statusCode}');
      }

      return null;
    } catch (e) {
      debugPrint('❌ Erro ao avaliar empresa: $e');
      return null;
    }
  }
}

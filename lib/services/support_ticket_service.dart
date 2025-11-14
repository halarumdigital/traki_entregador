import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../functions/functions.dart';
import '../models/support_ticket.dart';
import 'local_storage_service.dart';

class SupportTicketService {
  /// Buscar todos os assuntos disponíveis para criar tickets
  static Future<List<TicketSubject>> getTicketSubjects() async {
    try {
      debugPrint('📋 Buscando assuntos de tickets...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Ticket Subjects: Token não encontrado');
        return [];
      }

      final endpoint = '${url}api/v1/driver/ticket-subjects';
      debugPrint('🌐 Ticket Subjects URL: $endpoint');

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📥 Ticket Subjects Status Code: ${response.statusCode}');
      debugPrint('📥 Ticket Subjects Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['subjects'] != null) {
          final List<dynamic> subjectsData = jsonResponse['subjects'];
          final subjects = subjectsData.map((subject) => TicketSubject.fromJson(subject)).toList();

          debugPrint('✅ ${subjects.length} assuntos de tickets carregados');
          return subjects;
        }
      }

      debugPrint('⚠️ Nenhum assunto de ticket encontrado');
      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao buscar assuntos de tickets: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return [];
    }
  }

  /// Criar um novo ticket de suporte
  static Future<Map<String, dynamic>> createSupportTicket({
    required String subjectId,
    required String message,
    List<String>? imagePaths,
  }) async {
    try {
      debugPrint('🎫 Criando novo ticket de suporte...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Create Ticket: Token não encontrado');
        return {'success': false, 'message': 'Token não encontrado'};
      }

      final endpoint = '${url}api/v1/driver/support-tickets';
      debugPrint('🌐 Create Ticket URL: $endpoint');

      var request = http.MultipartRequest('POST', Uri.parse(endpoint));
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['subjectId'] = subjectId;
      request.fields['message'] = message;

      // Adicionar imagens se fornecidas
      if (imagePaths != null && imagePaths.isNotEmpty) {
        debugPrint('📸 Total de imagens a enviar: ${imagePaths.length}');
        for (var i = 0; i < imagePaths.length; i++) {
          debugPrint('📸 Processando imagem $i: ${imagePaths[i]}');
          var file = await http.MultipartFile.fromPath(
            'images',
            imagePaths[i],
          );
          request.files.add(file);
          debugPrint('✅ Imagem $i adicionada ao request: ${file.filename}');
        }
      } else {
        debugPrint('📸 Nenhuma imagem a enviar');
      }

      debugPrint('📤 Enviando ticket com ${request.files.length} arquivo(s)...');
      debugPrint('📤 Fields: ${request.fields}');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 Create Ticket Status Code: ${response.statusCode}');
      debugPrint('📥 Create Ticket Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          debugPrint('✅ Ticket criado com sucesso');
          return {
            'success': true,
            'ticket': jsonResponse['ticket'] != null
                ? SupportTicket.fromJson(jsonResponse['ticket'])
                : null,
          };
        }
      }

      final jsonResponse = jsonDecode(response.body);
      return {
        'success': false,
        'message': jsonResponse['message'] ?? 'Erro ao criar ticket'
      };
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao criar ticket: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return {'success': false, 'message': 'Erro ao criar ticket: $e'};
    }
  }

  /// Buscar todos os tickets do motorista
  static Future<List<SupportTicket>> getMyTickets({String? status}) async {
    try {
      debugPrint('🎫 Buscando tickets do motorista...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Get Tickets: Token não encontrado');
        return [];
      }

      // Construir URL com filtro de status opcional
      var endpoint = '${url}api/v1/driver/support-tickets';
      if (status != null && status.isNotEmpty) {
        endpoint += '?status=$status';
        debugPrint('📋 Filtrando por status: $status');
      }

      debugPrint('🌐 Get Tickets URL: $endpoint');

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📥 Get Tickets Status Code: ${response.statusCode}');
      debugPrint('📥 Get Tickets Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['tickets'] != null) {
          final List<dynamic> ticketsData = jsonResponse['tickets'];
          final tickets = ticketsData.map((item) {
            // A API retorna { ticket: {...}, subject: {...} }
            final ticketData = item['ticket'] ?? item;
            final subjectData = item['subject'];

            // Adicionar o nome do assunto ao ticket
            if (subjectData != null && ticketData['subjectName'] == null) {
              ticketData['subjectName'] = subjectData['name'];
            }

            debugPrint('🔍 Parsing ticket with ID: ${ticketData['id']}');
            final parsedTicket = SupportTicket.fromJson(ticketData);
            debugPrint('✅ Ticket parsed with ID: ${parsedTicket.id}');
            return parsedTicket;
          }).toList();

          debugPrint('✅ ${tickets.length} tickets carregados');
          return tickets;
        }
      }

      debugPrint('⚠️ Nenhum ticket encontrado');
      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao buscar tickets: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return [];
    }
  }

  /// Buscar detalhes de um ticket específico com suas respostas
  static Future<SupportTicket?> getTicketDetails(String ticketId) async {
    try {
      debugPrint('🎫 Buscando detalhes do ticket $ticketId...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Get Ticket Details: Token não encontrado');
        return null;
      }

      final endpoint = '${url}api/v1/driver/support-tickets/$ticketId';
      debugPrint('🌐 Get Ticket Details URL: $endpoint');

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📥 Get Ticket Details Status Code: ${response.statusCode}');
      debugPrint('📥 Get Ticket Details Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          // Caso 1: API retorna um único ticket
          if (jsonResponse['ticket'] != null) {
            var ticketData = jsonResponse['ticket'];

            // Verificar se tem estrutura aninhada {ticket: {...}, subject: {...}}
            if (ticketData['ticket'] != null) {
              ticketData = ticketData['ticket'];
              final subjectData = jsonResponse['ticket']['subject'];

              // Adicionar o nome do assunto ao ticket
              if (subjectData != null && ticketData['subjectName'] == null) {
                ticketData['subjectName'] = subjectData['name'];
              }
            }

            // Adicionar as respostas que vêm no nível superior da resposta
            if (jsonResponse['replies'] != null && jsonResponse['replies'] is List) {
              ticketData['replies'] = jsonResponse['replies'];
            }

            final ticket = SupportTicket.fromJson(ticketData);
            debugPrint('✅ Detalhes do ticket carregados com ${ticket.replies.length} respostas');
            return ticket;
          }

          // Caso 2: API retorna lista de tickets (filtrar pelo ID)
          if (jsonResponse['tickets'] != null && jsonResponse['tickets'] is List) {
            final List<dynamic> ticketsData = jsonResponse['tickets'];

            for (var item in ticketsData) {
              final ticketData = item['ticket'] ?? item;
              final subjectData = item['subject'];

              // Verificar se é o ticket que estamos procurando
              if (ticketData['id'] == ticketId) {
                // Adicionar o nome do assunto ao ticket
                if (subjectData != null && ticketData['subjectName'] == null) {
                  ticketData['subjectName'] = subjectData['name'];
                }

                final ticket = SupportTicket.fromJson(ticketData);
                debugPrint('✅ Detalhes do ticket carregados com ${ticket.replies.length} respostas');
                return ticket;
              }
            }
          }
        }
      }

      debugPrint('⚠️ Ticket não encontrado');
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao buscar detalhes do ticket: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  /// Responder a um ticket
  static Future<Map<String, dynamic>> replyToTicket({
    required String ticketId,
    required String message,
    List<String>? imagePaths,
  }) async {
    try {
      debugPrint('💬 Respondendo ao ticket $ticketId...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Reply Ticket: Token não encontrado');
        return {'success': false, 'message': 'Token não encontrado'};
      }

      // Obter dados do motorista
      final driverId = await LocalStorageService.getDriverId();
      final driverData = await LocalStorageService.getDriverData();
      final driverName = driverData?['name'] ?? '';

      if (driverId == null || driverName.isEmpty) {
        debugPrint('❌ Reply Ticket: Dados do motorista não encontrados');
        return {'success': false, 'message': 'Dados do motorista não encontrados'};
      }

      debugPrint('📝 Driver ID: $driverId');
      debugPrint('📝 Driver Name: $driverName');

      final endpoint = '${url}api/v1/driver/support-tickets/$ticketId/reply';
      debugPrint('🌐 Reply Ticket URL: $endpoint');

      var request = http.MultipartRequest('POST', Uri.parse(endpoint));
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['driverId'] = driverId;
      request.fields['driverName'] = driverName;
      request.fields['message'] = message;

      // Adicionar imagens se fornecidas
      if (imagePaths != null && imagePaths.isNotEmpty) {
        debugPrint('📸 Total de imagens a enviar na resposta: ${imagePaths.length}');
        for (var i = 0; i < imagePaths.length; i++) {
          debugPrint('📸 Processando imagem $i: ${imagePaths[i]}');
          var file = await http.MultipartFile.fromPath(
            'images',
            imagePaths[i],
          );
          request.files.add(file);
          debugPrint('✅ Imagem $i adicionada ao request: ${file.filename}');
        }
      } else {
        debugPrint('📸 Nenhuma imagem a enviar na resposta');
      }

      debugPrint('📤 Enviando resposta com ${request.files.length} arquivo(s)...');
      debugPrint('📤 Fields: ${request.fields}');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 Reply Ticket Status Code: ${response.statusCode}');
      debugPrint('📥 Reply Ticket Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          debugPrint('✅ Resposta enviada com sucesso');
          return {
            'success': true,
            'reply': jsonResponse['reply'] != null
                ? TicketReply.fromJson(jsonResponse['reply'])
                : null,
          };
        }
      }

      final jsonResponse = jsonDecode(response.body);
      return {
        'success': false,
        'message': jsonResponse['message'] ?? 'Erro ao enviar resposta'
      };
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao enviar resposta: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return {'success': false, 'message': 'Erro ao enviar resposta: $e'};
    }
  }
}

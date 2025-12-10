import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../functions/functions.dart';
import 'local_storage_service.dart';

/// Modelo para resposta de status de bloqueio
class BlockStatusResponse {
  final bool success;
  final bool blocked;
  final bool active;
  final bool? approve;
  final String? message;
  final String? blockedAt;

  BlockStatusResponse({
    required this.success,
    required this.blocked,
    required this.active,
    this.approve,
    this.message,
    this.blockedAt,
  });

  factory BlockStatusResponse.fromJson(Map<String, dynamic> json) {
    return BlockStatusResponse(
      success: json['success'] ?? false,
      blocked: json['blocked'] ?? false,
      active: json['active'] ?? true,
      approve: json['approve'],
      message: json['message'],
      blockedAt: json['blockedAt'],
    );
  }

  /// Retorna true se o entregador está bloqueado ou inativo
  bool get isBlocked => blocked || !active;
}

/// Serviço para verificar status de bloqueio do entregador
class DriverBlockService {
  /// Verifica se o entregador está bloqueado
  /// Retorna null se não conseguir verificar (erro de conexão, etc)
  static Future<BlockStatusResponse?> checkBlockStatus() async {
    try {
      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ [DriverBlockService] Token não encontrado');
        return null;
      }

      debugPrint('🔍 [DriverBlockService] Verificando status de bloqueio...');

      final response = await http.get(
        Uri.parse('${url}api/v1/driver/block-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ [DriverBlockService] Timeout na verificação');
          throw Exception('Timeout');
        },
      );

      debugPrint('📥 [DriverBlockService] Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final blockStatus = BlockStatusResponse.fromJson(jsonResponse);

        debugPrint('✅ [DriverBlockService] Resposta recebida:');
        debugPrint('   - Bloqueado: ${blockStatus.blocked}');
        debugPrint('   - Ativo: ${blockStatus.active}');
        debugPrint('   - Aprovado: ${blockStatus.approve}');

        return blockStatus;
      } else if (response.statusCode == 401) {
        debugPrint('❌ [DriverBlockService] 401 - Token inválido');
        return null;
      } else {
        debugPrint('❌ [DriverBlockService] Erro: ${response.statusCode}');
        debugPrint('   Body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [DriverBlockService] Erro: $e');
      return null;
    }
  }

  /// Mostra diálogo de bloqueio e faz logout
  static Future<void> showBlockedDialogAndLogout(
    BuildContext context, {
    String? customMessage,
  }) async {
    final message = customMessage ??
        'Seu cadastro foi desativado por violações nos termos de uso da Traki, para saber mais entre em contato com o suporte.';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.block,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Conta Bloqueada',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.support_agent,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Entre em contato com o suporte para mais informações.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _performLogout(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Realiza o logout do usuário
  static Future<void> _performLogout(BuildContext context) async {
    try {
      debugPrint('🚪 [DriverBlockService] Realizando logout por bloqueio...');

      // Limpar sessão do LocalStorageService
      await LocalStorageService.clearSession();

      // Limpar userDetails
      userDetails.clear();

      // Limpar bearerToken
      bearerToken.clear();

      debugPrint('✅ [DriverBlockService] Dados limpos com sucesso');

      if (context.mounted) {
        // Importar dinamicamente para evitar dependência circular
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ [DriverBlockService] Erro ao fazer logout: $e');
    }
  }

  /// Verifica bloqueio e mostra diálogo se bloqueado
  /// Retorna true se está bloqueado, false se não está
  static Future<bool> checkAndHandleBlock(BuildContext context) async {
    final blockStatus = await checkBlockStatus();

    if (blockStatus != null && blockStatus.isBlocked) {
      if (context.mounted) {
        await showBlockedDialogAndLogout(
          context,
          customMessage: blockStatus.message,
        );
      }
      return true;
    }

    return false;
  }
}

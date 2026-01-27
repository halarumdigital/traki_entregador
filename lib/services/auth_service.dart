import 'dart:convert';
import 'package:http/http.dart' as http;
import '../functions/functions.dart';

/// Serviço de autenticação - recuperação de senha
class AuthService {
  /// Solicitar recuperação de senha - Envia email com token
  /// POST /api/auth/forgot-password
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${url}api/auth/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'E-mail enviado com sucesso',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erro ao enviar e-mail',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: ${e.toString()}',
      };
    }
  }

  /// Verificar se o token de recuperação é válido
  /// POST /api/auth/verify-reset-token
  static Future<Map<String, dynamic>> verifyResetToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${url}api/auth/verify-reset-token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': data['valid'] == true,
          'valid': data['valid'] ?? false,
          'message': data['message'] ?? 'Verificação concluída',
        };
      } else {
        return {
          'success': false,
          'valid': false,
          'message': data['message'] ?? 'Erro ao verificar código',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'valid': false,
        'message': 'Erro de conexão: ${e.toString()}',
      };
    }
  }

  /// Redefinir senha com token
  /// POST /api/auth/reset-password
  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${url}api/auth/reset-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Senha alterada com sucesso',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erro ao alterar senha',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: ${e.toString()}',
      };
    }
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../functions/functions.dart';
import '../models/faq.dart';
import 'local_storage_service.dart';

class FaqService {
  /// Buscar todas as FAQs disponíveis para motoristas (já agrupadas por categoria)
  static Future<List<FaqCategory>> getFaqs() async {
    try {
      debugPrint('❓ Buscando FAQs...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ FAQ: Token não encontrado');
        return [];
      }

      final endpoint = '${url}api/v1/driver/faqs';
      debugPrint('🌐 FAQ URL: $endpoint');

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📥 FAQ Status Code: ${response.statusCode}');
      debugPrint('📥 FAQ Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('📋 FAQ Response JSON: $jsonResponse');

        if (jsonResponse['success'] == true && jsonResponse['faqs'] != null) {
          final List<dynamic> faqsData = jsonResponse['faqs'];
          debugPrint('📋 FAQ Data: $faqsData');

          final categories = faqsData.map((category) => FaqCategory.fromJson(category)).toList();

          final totalFaqs = categories.fold<int>(0, (sum, cat) => sum + cat.items.length);
          debugPrint('✅ ${categories.length} categorias carregadas com $totalFaqs FAQs no total');

          return categories;
        } else {
          debugPrint('⚠️ FAQ: success=${jsonResponse['success']}, faqs=${jsonResponse['faqs']}');
        }
      } else {
        debugPrint('⚠️ FAQ: Status code diferente de 200: ${response.statusCode}');
      }

      debugPrint('⚠️ Nenhuma FAQ encontrada');
      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao buscar FAQs: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return [];
    }
  }
}

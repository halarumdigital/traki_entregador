/// Modelo para representar uma FAQ (Pergunta Frequente)
class Faq {
  final String id;
  final String question;
  final String answer;
  final int displayOrder;

  Faq({
    required this.id,
    required this.question,
    required this.answer,
    required this.displayOrder,
  });

  /// Criar a partir do formato da API
  factory Faq.fromJson(Map<String, dynamic> json) {
    return Faq(
      id: json['id']?.toString() ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      displayOrder: json['displayOrder'] ?? 0,
    );
  }

  /// Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'displayOrder': displayOrder,
    };
  }
}

/// Modelo para representar uma categoria de FAQs
class FaqCategory {
  final String category;
  final List<Faq> items;

  FaqCategory({
    required this.category,
    required this.items,
  });

  /// Criar a partir do formato da API
  factory FaqCategory.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final items = itemsList.map((item) => Faq.fromJson(item)).toList();

    return FaqCategory(
      category: json['category'] ?? '',
      items: items,
    );
  }

  /// Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

/// Modelo para representar uma notificação do motorista
class DriverNotification {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final String type; // 'driver' ou 'city'
  final DateTime? date;
  final DateTime createdAt;

  DriverNotification({
    required this.id,
    required this.title,
    required this.body,
    this.data,
    required this.type,
    this.date,
    required this.createdAt,
  });

  /// Criar a partir do formato da API
  factory DriverNotification.fromJson(Map<String, dynamic> json) {
    return DriverNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: json['data'] as Map<String, dynamic>?,
      type: json['type']?.toString() ?? 'driver',
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  /// Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'data': data,
      'type': type,
      'date': date?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Formatar data de criação para exibição
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Agora';
        }
        return '${difference.inMinutes}m atrás';
      }
      return '${difference.inHours}h atrás';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
    }
  }

  /// Verificar se é uma notificação de cidade
  bool get isCityNotification => type == 'city';

  /// Verificar se é uma notificação específica do motorista
  bool get isDriverNotification => type == 'driver';
}

/// Resposta completa do endpoint de notificações
class NotificationsResponse {
  final bool success;
  final List<DriverNotification> notifications;
  final int count;

  NotificationsResponse({
    required this.success,
    required this.notifications,
    required this.count,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    return NotificationsResponse(
      success: json['success'] ?? false,
      notifications: (json['data'] as List<dynamic>?)
              ?.map((e) => DriverNotification.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': notifications.map((n) => n.toJson()).toList(),
      'count': count,
    };
  }
}

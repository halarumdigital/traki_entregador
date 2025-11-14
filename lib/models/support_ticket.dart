import 'package:flutter/material.dart';

/// Modelo para representar um assunto de ticket de suporte
class TicketSubject {
  final String id;
  final String name;
  final String description;

  TicketSubject({
    required this.id,
    required this.name,
    required this.description,
  });

  /// Criar a partir do formato da API
  factory TicketSubject.fromJson(Map<String, dynamic> json) {
    return TicketSubject(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }

  /// Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

/// Modelo para representar uma resposta de ticket
class TicketReply {
  final String id;
  final String message;
  final List<String> images;
  final bool isDriver;
  final String senderName;
  final DateTime createdAt;

  TicketReply({
    required this.id,
    required this.message,
    required this.images,
    required this.isDriver,
    required this.senderName,
    required this.createdAt,
  });

  /// Criar a partir do formato da API
  factory TicketReply.fromJson(Map<String, dynamic> json) {
    List<String> imagesList = [];

    // Handle single attachmentUrl
    if (json['attachmentUrl'] != null && json['attachmentUrl'] != '') {
      imagesList.add(json['attachmentUrl']);
      debugPrint('🖼️ TicketReply: attachmentUrl encontrado: ${json['attachmentUrl']}');
    }

    // Handle images array (fallback)
    if (json['images'] != null && json['images'] is List) {
      imagesList.addAll(List<String>.from(json['images']));
      debugPrint('🖼️ TicketReply: ${json['images'].length} imagens no array');
    }

    // authorType: "driver" ou "admin"
    final authorType = json['authorType'] ?? '';
    final isDriver = authorType.toLowerCase() == 'driver';

    debugPrint('🖼️ TicketReply: Total de ${imagesList.length} imagens parseadas');

    return TicketReply(
      id: json['id']?.toString() ?? '',
      message: json['message'] ?? '',
      images: imagesList,
      isDriver: isDriver,
      senderName: json['authorName'] ?? json['senderName'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  /// Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'images': images,
      'isDriver': isDriver,
      'senderName': senderName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Modelo para representar um ticket de suporte
class SupportTicket {
  final String id;
  final String subjectId;
  final String subjectName;
  final String message;
  final List<String> images;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<TicketReply> replies;

  SupportTicket({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.message,
    required this.images,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.replies = const [],
  });

  /// Criar a partir do formato da API
  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    List<String> imagesList = [];

    // Handle images array
    if (json['images'] != null) {
      if (json['images'] is List) {
        imagesList = List<String>.from(json['images']);
        debugPrint('🖼️ SupportTicket: ${json['images'].length} imagens no array');
      }
    }

    // Handle single attachmentUrl (convert to array)
    if (json['attachmentUrl'] != null && json['attachmentUrl'] != '') {
      imagesList.add(json['attachmentUrl']);
      debugPrint('🖼️ SupportTicket: attachmentUrl encontrado: ${json['attachmentUrl']}');
    }

    // Handle attachments array
    if (json['attachments'] != null && json['attachments'] is List) {
      debugPrint('🖼️ SupportTicket: ${json['attachments'].length} anexos no array');
      for (var attachment in json['attachments']) {
        if (attachment is String) {
          imagesList.add(attachment);
        } else if (attachment is Map && attachment['url'] != null) {
          imagesList.add(attachment['url']);
        }
      }
    }

    debugPrint('🖼️ SupportTicket: Total de ${imagesList.length} imagens parseadas');

    List<TicketReply> repliesList = [];
    if (json['replies'] != null && json['replies'] is List) {
      debugPrint('💬 SupportTicket: ${json['replies'].length} respostas a parsear');
      repliesList = (json['replies'] as List)
          .map((reply) => TicketReply.fromJson(reply))
          .toList();
    }

    return SupportTicket(
      id: json['id']?.toString() ?? '',
      subjectId: json['subjectId']?.toString() ?? json['subject_id']?.toString() ?? '',
      subjectName: json['subjectName'] ?? json['subject_name'] ?? '',
      message: json['message'] ?? '',
      images: imagesList,
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      replies: repliesList,
    );
  }

  /// Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'message': message,
      'images': images,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'replies': replies.map((reply) => reply.toJson()).toList(),
    };
  }

  /// Obter cor baseada no status
  String getStatusText() {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Aberto';
      case 'pending':
        return 'Pendente';
      case 'resolved':
        return 'Resolvido';
      case 'closed':
        return 'Fechado';
      default:
        return 'Pendente';
    }
  }
}

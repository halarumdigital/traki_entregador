import 'package:flutter/material.dart';
import '../styles/app_colors.dart';

/// Modelo para representar uma parada de entrega
class DeliveryStop {
  final String id;
  final String requestId;
  final int stopOrder;
  final String stopType; // "pickup" ou "delivery"
  final String? customerName;
  final String? customerWhatsapp;
  final String? deliveryReference;
  final String address;
  final double lat;
  final double lng;
  final String status; // "pending", "arrived", "completed", "skipped"
  final DateTime? arrivedAt;
  final DateTime? completedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeliveryStop({
    required this.id,
    required this.requestId,
    required this.stopOrder,
    required this.stopType,
    this.customerName,
    this.customerWhatsapp,
    this.deliveryReference,
    required this.address,
    required this.lat,
    required this.lng,
    required this.status,
    this.arrivedAt,
    this.completedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeliveryStop.fromJson(Map<String, dynamic> json) {
    return DeliveryStop(
      id: json['id']?.toString() ?? '',
      requestId: json['request_id']?.toString() ?? json['requestId']?.toString() ?? '',
      stopOrder: json['stop_order'] ?? json['stopOrder'] ?? 0,
      stopType: json['stop_type'] ?? json['stopType'] ?? 'delivery',
      customerName: json['customer_name'] ?? json['customerName'],
      customerWhatsapp: json['customer_whatsapp'] ?? json['customerWhatsapp'],
      deliveryReference: json['delivery_reference'] ?? json['deliveryReference'],
      address: json['address'] ?? '',
      lat: double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
      lng: double.tryParse(json['lng']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'pending',
      arrivedAt: json['arrived_at'] != null ? DateTime.tryParse(json['arrived_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']) : null,
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'stop_order': stopOrder,
      'stop_type': stopType,
      'customer_name': customerName,
      'customer_whatsapp': customerWhatsapp,
      'delivery_reference': deliveryReference,
      'address': address,
      'lat': lat,
      'lng': lng,
      'status': status,
      'arrived_at': arrivedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Getters úteis
  bool get isPending => status == 'pending';
  bool get isArrived => status == 'arrived';
  bool get isCompleted => status == 'completed';
  bool get isSkipped => status == 'skipped';

  // Status em português
  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'arrived':
        return 'No local';
      case 'completed':
        return 'Concluída';
      case 'skipped':
        return 'Pulada';
      default:
        return 'Desconhecido';
    }
  }

  // Cor do status
  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'arrived':
        return AppColors.primary;
      case 'completed':
        return Colors.green;
      case 'skipped':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Ícone do status
  IconData get statusIcon {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'arrived':
        return Icons.location_on;
      case 'completed':
        return Icons.check_circle;
      case 'skipped':
        return Icons.skip_next;
      default:
        return Icons.help;
    }
  }

  // CopyWith para atualizar campos
  DeliveryStop copyWith({
    String? id,
    String? requestId,
    int? stopOrder,
    String? stopType,
    String? customerName,
    String? customerWhatsapp,
    String? deliveryReference,
    String? address,
    double? lat,
    double? lng,
    String? status,
    DateTime? arrivedAt,
    DateTime? completedAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeliveryStop(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      stopOrder: stopOrder ?? this.stopOrder,
      stopType: stopType ?? this.stopType,
      customerName: customerName ?? this.customerName,
      customerWhatsapp: customerWhatsapp ?? this.customerWhatsapp,
      deliveryReference: deliveryReference ?? this.deliveryReference,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      status: status ?? this.status,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Response da API para buscar stops
class DeliveryStopsResponse {
  final bool success;
  final List<DeliveryStop> data;
  final int count;
  final String? message;

  DeliveryStopsResponse({
    required this.success,
    required this.data,
    required this.count,
    this.message,
  });

  factory DeliveryStopsResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'];
    List<DeliveryStop> stops = [];

    if (dataList != null && dataList is List) {
      stops = dataList.map((item) => DeliveryStop.fromJson(item as Map<String, dynamic>)).toList();
      // Ordenar por stopOrder
      stops.sort((a, b) => a.stopOrder.compareTo(b.stopOrder));
    }

    return DeliveryStopsResponse(
      success: json['success'] ?? false,
      data: stops,
      count: json['count'] ?? stops.length,
      message: json['message'],
    );
  }
}

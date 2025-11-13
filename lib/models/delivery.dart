/// Modelo para representar uma entrega
class Delivery {
  final String requestId;
  final String requestNumber;
  final String? companyName;
  final String? companyPhone;
  final String? customerName;
  final String? customerWhatsapp;
  final String? deliveryReference;
  final String? pickupAddress;
  final double? pickupLat;
  final double? pickupLng;
  final String? deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? distance;
  final String? estimatedTime;
  final String? driverAmount;
  final bool isTripStart;
  final bool needsReturn;
  final String? deliveredAt;
  final String? status;

  // NOVO: Campos para múltiplos stops
  final bool hasMultipleStops;
  final int? stopsCount;

  Delivery({
    required this.requestId,
    required this.requestNumber,
    this.companyName,
    this.companyPhone,
    this.customerName,
    this.customerWhatsapp,
    this.deliveryReference,
    this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    this.distance,
    this.estimatedTime,
    this.driverAmount,
    this.isTripStart = false,
    this.needsReturn = false,
    this.deliveredAt,
    this.status,
    this.hasMultipleStops = false,
    this.stopsCount,
  });

  /// Criar a partir do formato camelCase usado no app
  factory Delivery.fromMap(Map<String, dynamic> map) {
    return Delivery(
      requestId: map['requestId']?.toString() ?? '',
      requestNumber: map['requestNumber']?.toString() ?? '',
      companyName: map['companyName'],
      companyPhone: map['companyPhone'],
      customerName: map['customerName'],
      customerWhatsapp: map['customerWhatsapp'],
      deliveryReference: map['deliveryReference'],
      pickupAddress: map['pickupAddress'],
      pickupLat: map['pickupLat'] != null ? double.tryParse(map['pickupLat'].toString()) : null,
      pickupLng: map['pickupLng'] != null ? double.tryParse(map['pickupLng'].toString()) : null,
      deliveryAddress: map['deliveryAddress'],
      deliveryLat: map['deliveryLat'] != null ? double.tryParse(map['deliveryLat'].toString()) : null,
      deliveryLng: map['deliveryLng'] != null ? double.tryParse(map['deliveryLng'].toString()) : null,
      distance: map['distance'],
      estimatedTime: map['estimatedTime'],
      driverAmount: map['driverAmount'],
      isTripStart: map['isTripStart'] ?? false,
      needsReturn: map['needsReturn'] ?? false,
      deliveredAt: map['deliveredAt'],
      status: map['status'],
      hasMultipleStops: map['hasMultipleStops'] ?? false,
      stopsCount: map['stopsCount'],
    );
  }

  /// Criar a partir do formato snake_case da API
  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      requestId: json['id']?.toString() ?? '',
      requestNumber: json['request_number']?.toString() ?? '',
      companyName: json['company_name'],
      companyPhone: json['company_phone'],
      customerName: json['customer_name'],
      customerWhatsapp: json['customer_whatsapp'],
      deliveryReference: json['delivery_reference'],
      pickupAddress: json['pick_address'],
      pickupLat: json['pick_lat'] != null ? double.tryParse(json['pick_lat'].toString()) : null,
      pickupLng: json['pick_lng'] != null ? double.tryParse(json['pick_lng'].toString()) : null,
      deliveryAddress: json['drop_address'],
      deliveryLat: json['drop_lat'] != null ? double.tryParse(json['drop_lat'].toString()) : null,
      deliveryLng: json['drop_lng'] != null ? double.tryParse(json['drop_lng'].toString()) : null,
      distance: json['total_distance']?.toString(),
      estimatedTime: json['estimated_time']?.toString() ?? json['total_time']?.toString(),
      driverAmount: json['driver_amount']?.toString() ?? json['request_eta_amount']?.toString(),
      isTripStart: json['is_trip_start'] ?? false,
      needsReturn: json['needs_return'] ?? false,
      deliveredAt: json['delivered_at'],
      status: json['status'],
      hasMultipleStops: json['has_multiple_stops'] ?? false,
      stopsCount: json['stops_count'],
    );
  }

  /// Converter para Map no formato camelCase
  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'requestNumber': requestNumber,
      'companyName': companyName,
      'companyPhone': companyPhone,
      'customerName': customerName,
      'customerWhatsapp': customerWhatsapp,
      'deliveryReference': deliveryReference,
      'pickupAddress': pickupAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'deliveryAddress': deliveryAddress,
      'deliveryLat': deliveryLat,
      'deliveryLng': deliveryLng,
      'distance': distance,
      'estimatedTime': estimatedTime,
      'driverAmount': driverAmount,
      'isTripStart': isTripStart,
      'needsReturn': needsReturn,
      'deliveredAt': deliveredAt,
      'status': status,
      'hasMultipleStops': hasMultipleStops,
      'stopsCount': stopsCount,
    };
  }

  /// Converter para JSON no formato snake_case
  Map<String, dynamic> toJson() {
    return {
      'id': requestId,
      'request_number': requestNumber,
      'company_name': companyName,
      'company_phone': companyPhone,
      'customer_name': customerName,
      'customer_whatsapp': customerWhatsapp,
      'delivery_reference': deliveryReference,
      'pick_address': pickupAddress,
      'pick_lat': pickupLat,
      'pick_lng': pickupLng,
      'drop_address': deliveryAddress,
      'drop_lat': deliveryLat,
      'drop_lng': deliveryLng,
      'total_distance': distance,
      'estimated_time': estimatedTime,
      'driver_amount': driverAmount,
      'is_trip_start': isTripStart,
      'needs_return': needsReturn,
      'delivered_at': deliveredAt,
      'status': status,
      'has_multiple_stops': hasMultipleStops,
      'stops_count': stopsCount,
    };
  }

  // Helpers
  String get id => requestId;

  String get totalDistance => distance ?? '0';

  String get estimatedAmount => driverAmount ?? '0';

  Delivery copyWith({
    String? requestId,
    String? requestNumber,
    String? companyName,
    String? companyPhone,
    String? customerName,
    String? customerWhatsapp,
    String? deliveryReference,
    String? pickupAddress,
    double? pickupLat,
    double? pickupLng,
    String? deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
    String? distance,
    String? estimatedTime,
    String? driverAmount,
    bool? isTripStart,
    bool? needsReturn,
    String? deliveredAt,
    String? status,
    bool? hasMultipleStops,
    int? stopsCount,
  }) {
    return Delivery(
      requestId: requestId ?? this.requestId,
      requestNumber: requestNumber ?? this.requestNumber,
      companyName: companyName ?? this.companyName,
      companyPhone: companyPhone ?? this.companyPhone,
      customerName: customerName ?? this.customerName,
      customerWhatsapp: customerWhatsapp ?? this.customerWhatsapp,
      deliveryReference: deliveryReference ?? this.deliveryReference,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLat: deliveryLat ?? this.deliveryLat,
      deliveryLng: deliveryLng ?? this.deliveryLng,
      distance: distance ?? this.distance,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      driverAmount: driverAmount ?? this.driverAmount,
      isTripStart: isTripStart ?? this.isTripStart,
      needsReturn: needsReturn ?? this.needsReturn,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      status: status ?? this.status,
      hasMultipleStops: hasMultipleStops ?? this.hasMultipleStops,
      stopsCount: stopsCount ?? this.stopsCount,
    );
  }
}

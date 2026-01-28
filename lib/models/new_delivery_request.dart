class NewDeliveryRequest {
  final String requestId;
  final String companyName;
  final String companyLogo;
  final double deliveryValue;
  final String estimatedDistance;
  final String estimatedTime;
  final String pickupAddress;
  final String dropAddress;
  final int timeoutSeconds;

  NewDeliveryRequest({
    required this.requestId,
    required this.companyName,
    this.companyLogo = '',
    required this.deliveryValue,
    required this.estimatedDistance,
    required this.estimatedTime,
    required this.pickupAddress,
    required this.dropAddress,
    this.timeoutSeconds = 60,
  });

  factory NewDeliveryRequest.fromJson(Map<String, dynamic> json) {
    return NewDeliveryRequest(
      requestId: json['request_id'] ?? '',
      companyName: json['company_name'] ?? '',
      companyLogo: json['company_logo'] ?? '',
      deliveryValue: (json['delivery_value'] ?? 0).toDouble(),
      estimatedDistance: json['estimated_distance'] ?? '',
      estimatedTime: json['estimated_time'] ?? '',
      pickupAddress: json['pickup_address'] ?? '',
      dropAddress: json['drop_address'] ?? '',
      timeoutSeconds: json['timeout_seconds'] ?? 60,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'company_name': companyName,
      'company_logo': companyLogo,
      'delivery_value': deliveryValue,
      'estimated_distance': estimatedDistance,
      'estimated_time': estimatedTime,
      'pickup_address': pickupAddress,
      'drop_address': dropAddress,
      'timeout_seconds': timeoutSeconds,
    };
  }

  String get formattedValue => 'R\$ ${deliveryValue.toStringAsFixed(2)}';
}

/// Model para paradas de entrega (múltiplos endereços de entrega)
class Parada {
  final String id;
  final int ordem;
  final String logradouro;
  final String numero;
  final String? complemento;
  final String bairro;
  final String cidade;
  final String cep;
  final String enderecoCompleto;
  final String? destinatarioNome;
  final String? destinatarioTelefone;
  final double? latitude;
  final double? longitude;
  final String status; // pendente, a_caminho, entregue, falhou
  final DateTime? dataEntrega;
  final String? motivoFalha;

  Parada({
    required this.id,
    required this.ordem,
    required this.logradouro,
    required this.numero,
    this.complemento,
    required this.bairro,
    required this.cidade,
    required this.cep,
    required this.enderecoCompleto,
    this.destinatarioNome,
    this.destinatarioTelefone,
    this.latitude,
    this.longitude,
    required this.status,
    this.dataEntrega,
    this.motivoFalha,
  });

  factory Parada.fromJson(Map<String, dynamic> json) {
    return Parada(
      id: json['id']?.toString() ?? '',
      ordem: int.tryParse(json['ordem']?.toString() ?? '0') ?? 0,
      logradouro: json['logradouro']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      complemento: json['complemento']?.toString(),
      bairro: json['bairro']?.toString() ?? '',
      cidade: json['cidade']?.toString() ?? '',
      cep: json['cep']?.toString() ?? '',
      enderecoCompleto: json['enderecoCompleto']?.toString() ?? '',
      destinatarioNome: json['destinatarioNome']?.toString(),
      destinatarioTelefone: json['destinatarioTelefone']?.toString(),
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      status: json['status']?.toString() ?? 'pendente',
      dataEntrega: json['dataEntrega'] != null
          ? DateTime.tryParse(json['dataEntrega'])
          : null,
      motivoFalha: json['motivoFalha']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ordem': ordem,
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'cep': cep,
      'enderecoCompleto': enderecoCompleto,
      'destinatarioNome': destinatarioNome,
      'destinatarioTelefone': destinatarioTelefone,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'dataEntrega': dataEntrega?.toIso8601String(),
      'motivoFalha': motivoFalha,
    };
  }

  // Getters úteis
  bool get isPendente => status == 'pendente';
  bool get isACaminho => status == 'a_caminho';
  bool get isEntregue => status == 'entregue';
  bool get isFalhou => status == 'falhou';

  String get statusFormatado {
    switch (status) {
      case 'pendente':
        return 'Pendente';
      case 'a_caminho':
        return 'A Caminho';
      case 'entregue':
        return 'Entregue';
      case 'falhou':
        return 'Falhou';
      default:
        return status;
    }
  }

  Parada copyWith({
    String? id,
    int? ordem,
    String? logradouro,
    String? numero,
    String? complemento,
    String? bairro,
    String? cidade,
    String? cep,
    String? enderecoCompleto,
    String? destinatarioNome,
    String? destinatarioTelefone,
    double? latitude,
    double? longitude,
    String? status,
    DateTime? dataEntrega,
    String? motivoFalha,
  }) {
    return Parada(
      id: id ?? this.id,
      ordem: ordem ?? this.ordem,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      complemento: complemento ?? this.complemento,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      cep: cep ?? this.cep,
      enderecoCompleto: enderecoCompleto ?? this.enderecoCompleto,
      destinatarioNome: destinatarioNome ?? this.destinatarioNome,
      destinatarioTelefone: destinatarioTelefone ?? this.destinatarioTelefone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      dataEntrega: dataEntrega ?? this.dataEntrega,
      motivoFalha: motivoFalha ?? this.motivoFalha,
    );
  }
}

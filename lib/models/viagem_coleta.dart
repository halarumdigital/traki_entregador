/// Modelo para coletas de uma viagem intermunicipal
class ViagemColeta {
  final String id;
  final String viagemId;
  final String entregaId;
  final String empresaNome;
  final String enderecoColeta;
  final double? latitude;
  final double? longitude;
  final String? pontoReferenciaColeta;
  final String status; // pendente, a_caminho, chegou, coletado, falhou
  final int quantidadePacotes;
  final double pesoKg;
  final DateTime? horarioChegada;
  final DateTime? horarioColeta;
  final String? fotoComprovanteUrl;
  final String? observacoes;
  final String? motivoFalha;
  final DateTime createdAt;
  final DateTime updatedAt;

  ViagemColeta({
    required this.id,
    required this.viagemId,
    required this.entregaId,
    required this.empresaNome,
    required this.enderecoColeta,
    this.latitude,
    this.longitude,
    this.pontoReferenciaColeta,
    required this.status,
    required this.quantidadePacotes,
    required this.pesoKg,
    this.horarioChegada,
    this.horarioColeta,
    this.fotoComprovanteUrl,
    this.observacoes,
    this.motivoFalha,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ViagemColeta.fromJson(Map<String, dynamic> json) {
    return ViagemColeta(
      id: json['id']?.toString() ?? '',
      viagemId: json['viagem_id']?.toString() ?? json['viagemId']?.toString() ?? '',
      entregaId: json['entrega_id']?.toString() ?? json['entregaId']?.toString() ?? '',
      empresaNome: json['empresa_nome']?.toString() ?? json['empresaNome']?.toString() ?? '',
      enderecoColeta: json['endereco_completo']?.toString() ?? json['enderecoColeta']?.toString() ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      pontoReferenciaColeta: json['ponto_referencia']?.toString() ?? json['pontoReferenciaColeta']?.toString(),
      status: json['status']?.toString() ?? 'pendente',
      quantidadePacotes: int.tryParse(json['quantidade_pacotes']?.toString() ?? json['quantidadePacotes']?.toString() ?? '0') ?? 0,
      pesoKg: json['peso_kg'] != null
          ? double.tryParse(json['peso_kg'].toString()) ?? 0.0
          : json['pesoKg'] != null
              ? double.tryParse(json['pesoKg'].toString()) ?? 0.0
              : 0.0,
      horarioChegada: json['horario_chegada'] != null
          ? DateTime.tryParse(json['horario_chegada'])
          : json['horarioChegada'] != null
              ? DateTime.tryParse(json['horarioChegada'])
              : null,
      horarioColeta: json['horario_coleta'] != null
          ? DateTime.tryParse(json['horario_coleta'])
          : json['horarioColeta'] != null
              ? DateTime.tryParse(json['horarioColeta'])
              : null,
      fotoComprovanteUrl: json['foto_comprovante_url']?.toString() ?? json['fotoComprovanteUrl']?.toString(),
      observacoes: json['observacoes']?.toString(),
      motivoFalha: json['motivo_falha']?.toString() ?? json['motivoFalha']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
          : json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'viagemId': viagemId,
      'entregaId': entregaId,
      'empresaNome': empresaNome,
      'enderecoColeta': enderecoColeta,
      'latitude': latitude,
      'longitude': longitude,
      'pontoReferenciaColeta': pontoReferenciaColeta,
      'status': status,
      'quantidadePacotes': quantidadePacotes,
      'pesoKg': pesoKg,
      'horarioChegada': horarioChegada?.toIso8601String(),
      'horarioColeta': horarioColeta?.toIso8601String(),
      'fotoComprovanteUrl': fotoComprovanteUrl,
      'observacoes': observacoes,
      'motivoFalha': motivoFalha,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Getters úteis
  bool get isPendente => status == 'pendente';
  bool get isACaminho => status == 'a_caminho';
  bool get isChegou => status == 'chegou';
  bool get isColetado => status == 'coletado';
  bool get isFalhou => status == 'falhou';

  String get statusFormatado {
    switch (status) {
      case 'pendente':
        return 'Pendente';
      case 'a_caminho':
        return 'A Caminho';
      case 'chegou':
        return 'Chegou';
      case 'coletado':
        return 'Coletado';
      case 'falhou':
        return 'Falhou';
      default:
        return status;
    }
  }

  ViagemColeta copyWith({
    String? id,
    String? viagemId,
    String? entregaId,
    String? empresaNome,
    String? enderecoColeta,
    double? latitude,
    double? longitude,
    String? pontoReferenciaColeta,
    String? status,
    int? quantidadePacotes,
    double? pesoKg,
    DateTime? horarioChegada,
    DateTime? horarioColeta,
    String? fotoComprovanteUrl,
    String? observacoes,
    String? motivoFalha,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ViagemColeta(
      id: id ?? this.id,
      viagemId: viagemId ?? this.viagemId,
      entregaId: entregaId ?? this.entregaId,
      empresaNome: empresaNome ?? this.empresaNome,
      enderecoColeta: enderecoColeta ?? this.enderecoColeta,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      pontoReferenciaColeta: pontoReferenciaColeta ?? this.pontoReferenciaColeta,
      status: status ?? this.status,
      quantidadePacotes: quantidadePacotes ?? this.quantidadePacotes,
      pesoKg: pesoKg ?? this.pesoKg,
      horarioChegada: horarioChegada ?? this.horarioChegada,
      horarioColeta: horarioColeta ?? this.horarioColeta,
      fotoComprovanteUrl: fotoComprovanteUrl ?? this.fotoComprovanteUrl,
      observacoes: observacoes ?? this.observacoes,
      motivoFalha: motivoFalha ?? this.motivoFalha,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

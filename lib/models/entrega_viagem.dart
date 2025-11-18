import 'parada.dart';

/// Model para entregas dentro de uma viagem
class EntregaViagem {
  final String id;
  final String viagemId;
  final String entregaId;
  final String numeroPedido;
  final String empresaNome;
  final String enderecoEntrega;
  final double? latitude;
  final double? longitude;
  final String? destinatarioNome;
  final String? destinatarioTelefone;
  final String status;
  final int ordemEntrega;
  final DateTime? horarioPrevisto;
  final DateTime? horarioChegada;
  final DateTime? horarioEntrega;
  final String? observacoes;
  final String? motivoFalha;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Parada>? paradas;
  final int? numeroParadas;

  EntregaViagem({
    required this.id,
    required this.viagemId,
    required this.entregaId,
    required this.numeroPedido,
    required this.empresaNome,
    required this.enderecoEntrega,
    this.latitude,
    this.longitude,
    this.destinatarioNome,
    this.destinatarioTelefone,
    required this.status,
    required this.ordemEntrega,
    this.horarioPrevisto,
    this.horarioChegada,
    this.horarioEntrega,
    this.observacoes,
    this.motivoFalha,
    required this.createdAt,
    required this.updatedAt,
    this.paradas,
    this.numeroParadas,
  });

  factory EntregaViagem.fromJson(Map<String, dynamic> json) {
    List<Parada>? paradasList;
    if (json['paradas'] != null) {
      final paradasData = json['paradas'] as List<dynamic>;
      paradasList = paradasData.map((p) => Parada.fromJson(p)).toList();
    }

    return EntregaViagem(
      id: json['id']?.toString() ?? '',
      viagemId: json['viagem_id']?.toString() ?? json['viagemId']?.toString() ?? '',
      entregaId: json['entrega_id']?.toString() ?? json['entregaId']?.toString() ?? '',
      numeroPedido: json['numero_pedido']?.toString() ?? json['numeroPedido']?.toString() ?? '',
      empresaNome: json['empresa_nome']?.toString() ?? json['empresaNome']?.toString() ?? '',
      enderecoEntrega: json['endereco_completo']?.toString() ?? json['enderecoEntrega']?.toString() ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      destinatarioNome: json['destinatario_nome']?.toString() ?? json['destinatarioNome']?.toString(),
      destinatarioTelefone: json['destinatario_telefone']?.toString() ?? json['destinatarioTelefone']?.toString(),
      status: json['status']?.toString() ?? 'pendente',
      ordemEntrega: int.tryParse(json['ordem_entrega']?.toString() ?? json['ordemEntrega']?.toString() ?? '0') ?? 0,
      horarioPrevisto: json['horario_previsto'] != null
          ? DateTime.tryParse(json['horario_previsto'])
          : json['horarioPrevisto'] != null
              ? DateTime.tryParse(json['horarioPrevisto'])
              : null,
      horarioChegada: json['horario_chegada'] != null
          ? DateTime.tryParse(json['horario_chegada'])
          : json['horarioChegada'] != null
              ? DateTime.tryParse(json['horarioChegada'])
              : null,
      horarioEntrega: json['horario_entrega'] != null
          ? DateTime.tryParse(json['horario_entrega'])
          : json['horarioEntrega'] != null
              ? DateTime.tryParse(json['horarioEntrega'])
              : null,
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
      paradas: paradasList,
      numeroParadas: json['numero_paradas'] != null
          ? int.tryParse(json['numero_paradas']?.toString() ?? '0')
          : json['numeroParadas'] != null
              ? int.tryParse(json['numeroParadas']?.toString() ?? '0')
              : paradasList?.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'viagemId': viagemId,
      'entregaId': entregaId,
      'numeroPedido': numeroPedido,
      'empresaNome': empresaNome,
      'enderecoEntrega': enderecoEntrega,
      'latitude': latitude,
      'longitude': longitude,
      'destinatarioNome': destinatarioNome,
      'destinatarioTelefone': destinatarioTelefone,
      'status': status,
      'ordemEntrega': ordemEntrega,
      'horarioPrevisto': horarioPrevisto?.toIso8601String(),
      'horarioChegada': horarioChegada?.toIso8601String(),
      'horarioEntrega': horarioEntrega?.toIso8601String(),
      'observacoes': observacoes,
      'motivoFalha': motivoFalha,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'paradas': paradas?.map((p) => p.toJson()).toList(),
      'numeroParadas': numeroParadas,
    };
  }

  // Getters úteis
  bool get isPendente => status == 'pendente';
  bool get isACaminho => status == 'a_caminho';
  bool get isChegou => status == 'chegou';
  bool get isEntregue => status == 'entregue';
  bool get isFalha => status == 'falhou' || status == 'falha';

  String get statusFormatado {
    switch (status) {
      case 'pendente':
        return 'Pendente';
      case 'a_caminho':
        return 'A Caminho';
      case 'chegou':
        return 'Chegou';
      case 'entregue':
        return 'Entregue';
      case 'falhou':
      case 'falha':
        return 'Falha';
      default:
        return status;
    }
  }

  // Helpers para múltiplas paradas
  bool get temMultiplasParadas => (numeroParadas ?? 0) > 1;
  int get paradasEntregues => paradas?.where((p) => p.isEntregue).length ?? 0;
  int get paradasPendentes => paradas?.where((p) => p.isPendente).length ?? 0;
  double get progressoParadas {
    if (paradas == null || paradas!.isEmpty) return 0.0;
    return (paradasEntregues / paradas!.length) * 100;
  }

  EntregaViagem copyWith({
    String? id,
    String? viagemId,
    String? entregaId,
    String? numeroPedido,
    String? empresaNome,
    String? enderecoEntrega,
    double? latitude,
    double? longitude,
    String? destinatarioNome,
    String? destinatarioTelefone,
    String? status,
    int? ordemEntrega,
    DateTime? horarioPrevisto,
    DateTime? horarioChegada,
    DateTime? horarioEntrega,
    String? observacoes,
    String? motivoFalha,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Parada>? paradas,
    int? numeroParadas,
  }) {
    return EntregaViagem(
      id: id ?? this.id,
      viagemId: viagemId ?? this.viagemId,
      entregaId: entregaId ?? this.entregaId,
      numeroPedido: numeroPedido ?? this.numeroPedido,
      empresaNome: empresaNome ?? this.empresaNome,
      enderecoEntrega: enderecoEntrega ?? this.enderecoEntrega,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      destinatarioNome: destinatarioNome ?? this.destinatarioNome,
      destinatarioTelefone: destinatarioTelefone ?? this.destinatarioTelefone,
      status: status ?? this.status,
      ordemEntrega: ordemEntrega ?? this.ordemEntrega,
      horarioPrevisto: horarioPrevisto ?? this.horarioPrevisto,
      horarioChegada: horarioChegada ?? this.horarioChegada,
      horarioEntrega: horarioEntrega ?? this.horarioEntrega,
      observacoes: observacoes ?? this.observacoes,
      motivoFalha: motivoFalha ?? this.motivoFalha,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paradas: paradas ?? this.paradas,
      numeroParadas: numeroParadas ?? this.numeroParadas,
    );
  }
}

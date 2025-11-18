/// Model para viagens do motorista
class Viagem {
  final String id;
  final String entregadorId;
  final String rotaId;
  final String rotaNome;
  final String cidadeOrigemNome;
  final String cidadeDestinoNome;
  final String dataViagem;
  final String status;
  final int capacidadePacotesTotal;
  final String capacidadePesoKgTotal;
  final int pacotesAceitos;
  final String pesoAceitoKg;
  final String horarioSaidaPlanejado;
  final DateTime? horarioSaidaReal;
  final DateTime? horarioChegadaPrevisto;
  final DateTime? horarioChegadaReal;
  final int totalColetas;
  final int coletasConcluidas;
  final int totalEntregas;
  final int entregasConcluidas;
  final DateTime createdAt;
  final DateTime updatedAt;

  Viagem({
    required this.id,
    required this.entregadorId,
    required this.rotaId,
    required this.rotaNome,
    required this.cidadeOrigemNome,
    required this.cidadeDestinoNome,
    required this.dataViagem,
    required this.status,
    required this.capacidadePacotesTotal,
    required this.capacidadePesoKgTotal,
    required this.pacotesAceitos,
    required this.pesoAceitoKg,
    required this.horarioSaidaPlanejado,
    this.horarioSaidaReal,
    this.horarioChegadaPrevisto,
    this.horarioChegadaReal,
    required this.totalColetas,
    required this.coletasConcluidas,
    required this.totalEntregas,
    required this.entregasConcluidas,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Viagem.fromJson(Map<String, dynamic> json) {
    return Viagem(
      id: json['id']?.toString() ?? '',
      entregadorId: json['entregador_id']?.toString() ?? json['entregadorId']?.toString() ?? '',
      rotaId: json['rota_id']?.toString() ?? json['rotaId']?.toString() ?? '',
      rotaNome: json['rota_nome']?.toString() ?? json['rotaNome']?.toString() ?? '',
      cidadeOrigemNome: json['cidade_origem_nome']?.toString() ?? json['cidadeOrigemNome']?.toString() ?? '',
      cidadeDestinoNome: json['cidade_destino_nome']?.toString() ?? json['cidadeDestinoNome']?.toString() ?? '',
      dataViagem: json['data_viagem']?.toString() ?? json['dataViagem']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      capacidadePacotesTotal: int.tryParse(json['capacidade_pacotes_total']?.toString() ?? json['capacidadePacotesTotal']?.toString() ?? '0') ?? 0,
      capacidadePesoKgTotal: json['capacidade_peso_kg_total']?.toString() ?? json['capacidadePesoKgTotal']?.toString() ?? '0',
      pacotesAceitos: int.tryParse(json['pacotes_aceitos']?.toString() ?? json['pacotesAceitos']?.toString() ?? '0') ?? 0,
      pesoAceitoKg: json['peso_aceito_kg']?.toString() ?? json['pesoAceitoKg']?.toString() ?? '0',
      horarioSaidaPlanejado: json['horario_saida_planejado']?.toString() ?? json['horarioSaidaPlanejado']?.toString() ?? '08:00',
      horarioSaidaReal: json['horario_saida_real'] != null
          ? DateTime.tryParse(json['horario_saida_real'])
          : json['horarioSaidaReal'] != null
              ? DateTime.tryParse(json['horarioSaidaReal'])
              : null,
      horarioChegadaPrevisto: json['horario_chegada_previsto'] != null
          ? DateTime.tryParse(json['horario_chegada_previsto'])
          : json['horarioChegadaPrevisto'] != null
              ? DateTime.tryParse(json['horarioChegadaPrevisto'])
              : null,
      horarioChegadaReal: json['horario_chegada_real'] != null
          ? DateTime.tryParse(json['horario_chegada_real'])
          : json['horarioChegadaReal'] != null
              ? DateTime.tryParse(json['horarioChegadaReal'])
              : null,
      totalColetas: int.tryParse(json['total_coletas']?.toString() ?? json['totalColetas']?.toString() ?? '0') ?? 0,
      coletasConcluidas: int.tryParse(json['coletas_concluidas']?.toString() ?? json['coletasConcluidas']?.toString() ?? '0') ?? 0,
      totalEntregas: int.tryParse(json['total_entregas']?.toString() ?? json['totalEntregas']?.toString() ?? '0') ?? 0,
      entregasConcluidas: int.tryParse(json['entregas_concluidas']?.toString() ?? json['entregasConcluidas']?.toString() ?? '0') ?? 0,
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
      'entregadorId': entregadorId,
      'rotaId': rotaId,
      'rotaNome': rotaNome,
      'cidadeOrigemNome': cidadeOrigemNome,
      'cidadeDestinoNome': cidadeDestinoNome,
      'dataViagem': dataViagem,
      'status': status,
      'capacidadePacotesTotal': capacidadePacotesTotal,
      'capacidadePesoKgTotal': capacidadePesoKgTotal,
      'pacotesAceitos': pacotesAceitos,
      'pesoAceitoKg': pesoAceitoKg,
      'horarioSaidaPlanejado': horarioSaidaPlanejado,
      'horarioSaidaReal': horarioSaidaReal?.toIso8601String(),
      'horarioChegadaPrevisto': horarioChegadaPrevisto?.toIso8601String(),
      'horarioChegadaReal': horarioChegadaReal?.toIso8601String(),
      'totalColetas': totalColetas,
      'coletasConcluidas': coletasConcluidas,
      'totalEntregas': totalEntregas,
      'entregasConcluidas': entregasConcluidas,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helpers
  String get statusFormatado {
    switch (status) {
      case 'agendada':
        return 'Agendada';
      case 'em_coleta':
        return 'Em Coleta';
      case 'em_transito':
        return 'Em Trânsito';
      case 'em_entrega':
        return 'Em Entrega';
      case 'concluida':
        return 'Concluída';
      case 'cancelada':
        return 'Cancelada';
      default:
        return status;
    }
  }

  double get capacidadePesoKgTotalDouble => double.tryParse(capacidadePesoKgTotal) ?? 0.0;
  double get pesoAceitoKgDouble => double.tryParse(pesoAceitoKg) ?? 0.0;

  double get percentualCapacidadePacotes {
    if (capacidadePacotesTotal == 0) return 0.0;
    return (pacotesAceitos / capacidadePacotesTotal) * 100;
  }

  double get percentualCapacidadePeso {
    if (capacidadePesoKgTotalDouble == 0) return 0.0;
    return (pesoAceitoKgDouble / capacidadePesoKgTotalDouble) * 100;
  }

  bool get podeIniciar => status == 'agendada';
  bool get emAndamento => ['em_coleta', 'em_transito', 'em_entrega'].contains(status);
  bool get concluida => status == 'concluida';
  bool get cancelada => status == 'cancelada';

  DateTime? get dataViagemDate {
    try {
      return DateTime.parse(dataViagem);
    } catch (e) {
      return null;
    }
  }
}

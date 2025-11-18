/// Model para entregas disponíveis nas rotas
class EntregaRota {
  final String id;
  final String numeroPedido;
  final String empresaId;
  final String empresaNome;
  final String? empresaTelefone;
  final String rotaId;
  final String rotaNome;
  final String dataAgendada;
  final String enderecoColetaCompleto;
  final String enderecoEntregaCompleto;
  final String? destinatarioNome;
  final String? destinatarioTelefone;
  final int quantidadePacotes;
  final String pesoTotalKg;
  final String valorTotal;
  final String status;
  final String? descricaoConteudo;
  final DateTime createdAt;

  EntregaRota({
    required this.id,
    required this.numeroPedido,
    required this.empresaId,
    required this.empresaNome,
    this.empresaTelefone,
    required this.rotaId,
    required this.rotaNome,
    required this.dataAgendada,
    required this.enderecoColetaCompleto,
    required this.enderecoEntregaCompleto,
    this.destinatarioNome,
    this.destinatarioTelefone,
    required this.quantidadePacotes,
    required this.pesoTotalKg,
    required this.valorTotal,
    required this.status,
    this.descricaoConteudo,
    required this.createdAt,
  });

  factory EntregaRota.fromJson(Map<String, dynamic> json) {
    return EntregaRota(
      id: json['id']?.toString() ?? '',
      numeroPedido: json['numeroPedido']?.toString() ?? '',
      empresaId: json['empresaId']?.toString() ?? '',
      empresaNome: json['empresaNome']?.toString() ?? '',
      empresaTelefone: json['empresaTelefone']?.toString(),
      rotaId: json['rotaId']?.toString() ?? '',
      rotaNome: json['rotaNome']?.toString() ?? '',
      dataAgendada: json['dataAgendada']?.toString() ?? '',
      enderecoColetaCompleto: json['enderecoColetaCompleto']?.toString() ?? '',
      enderecoEntregaCompleto: json['enderecoEntregaCompleto']?.toString() ?? '',
      destinatarioNome: json['destinatarioNome']?.toString(),
      destinatarioTelefone: json['destinatarioTelefone']?.toString(),
      quantidadePacotes: int.tryParse(json['quantidadePacotes']?.toString() ?? '0') ?? 0,
      pesoTotalKg: json['pesoTotalKg']?.toString() ?? '0',
      valorTotal: json['valorTotal']?.toString() ?? '0',
      status: json['status']?.toString() ?? '',
      descricaoConteudo: json['descricaoConteudo']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numeroPedido': numeroPedido,
      'empresaId': empresaId,
      'empresaNome': empresaNome,
      'empresaTelefone': empresaTelefone,
      'rotaId': rotaId,
      'rotaNome': rotaNome,
      'dataAgendada': dataAgendada,
      'enderecoColetaCompleto': enderecoColetaCompleto,
      'enderecoEntregaCompleto': enderecoEntregaCompleto,
      'destinatarioNome': destinatarioNome,
      'destinatarioTelefone': destinatarioTelefone,
      'quantidadePacotes': quantidadePacotes,
      'pesoTotalKg': pesoTotalKg,
      'valorTotal': valorTotal,
      'status': status,
      'descricaoConteudo': descricaoConteudo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Helpers
  double get pesoTotalKgDouble => double.tryParse(pesoTotalKg) ?? 0.0;
  double get valorTotalDouble => double.tryParse(valorTotal) ?? 0.0;

  DateTime? get dataAgendadaDate {
    try {
      return DateTime.parse(dataAgendada);
    } catch (e) {
      return null;
    }
  }

  String get statusFormatado {
    switch (status) {
      case 'aguardando_motorista':
        return 'Disponível';
      case 'motorista_aceito':
        return 'Aceita';
      case 'coletado':
        return 'Coletada';
      case 'em_transito':
        return 'Em Trânsito';
      case 'entregue':
        return 'Entregue';
      default:
        return status;
    }
  }
}

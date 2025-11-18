/// Model para rotas configuradas pelo motorista
class MinhaRota {
  final String id;
  final String rotaId;
  final String rotaNome;
  final String cidadeOrigemNome;
  final String cidadeDestinoNome;
  final String distanciaKm;
  final int tempoEstimadoMinutos;
  final int capacidadePacotes;
  final String capacidadePesoKg;
  final String horarioSaidaPadrao;
  final List<int> diasSemana;
  final bool ativo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MinhaRota({
    required this.id,
    required this.rotaId,
    required this.rotaNome,
    required this.cidadeOrigemNome,
    required this.cidadeDestinoNome,
    required this.distanciaKm,
    required this.tempoEstimadoMinutos,
    required this.capacidadePacotes,
    required this.capacidadePesoKg,
    required this.horarioSaidaPadrao,
    this.diasSemana = const [],
    required this.ativo,
    this.createdAt,
    this.updatedAt,
  });

  factory MinhaRota.fromJson(Map<String, dynamic> json) {
    List<int> diasSemana = [];
    if (json['diasSemana'] != null) {
      print('📅 DEBUG MinhaRota - diasSemana raw: ${json['diasSemana']}');
      print('📅 DEBUG MinhaRota - diasSemana type: ${json['diasSemana'].runtimeType}');

      if (json['diasSemana'] is List) {
        diasSemana = (json['diasSemana'] as List)
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((e) => e > 0 && e <= 7)
            .toList();
      }

      print('📅 DEBUG MinhaRota - diasSemana parsed: $diasSemana');
    }

    return MinhaRota(
      id: json['id']?.toString() ?? '',
      rotaId: json['rotaId']?.toString() ?? '',
      rotaNome: json['rotaNome']?.toString() ?? '',
      cidadeOrigemNome: json['cidadeOrigemNome']?.toString() ?? '',
      cidadeDestinoNome: json['cidadeDestinoNome']?.toString() ?? '',
      distanciaKm: json['distanciaKm']?.toString() ?? '0',
      tempoEstimadoMinutos: int.tryParse(json['tempoEstimadoMinutos']?.toString() ?? '0') ?? 0,
      capacidadePacotes: int.tryParse(json['capacidadePacotes']?.toString() ?? '0') ?? 0,
      capacidadePesoKg: json['capacidadePesoKg']?.toString() ?? '0',
      horarioSaidaPadrao: json['horarioSaidaPadrao']?.toString() ?? '08:00',
      diasSemana: diasSemana,
      ativo: json['ativo'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rotaId': rotaId,
      'rotaNome': rotaNome,
      'cidadeOrigemNome': cidadeOrigemNome,
      'cidadeDestinoNome': cidadeDestinoNome,
      'distanciaKm': distanciaKm,
      'tempoEstimadoMinutos': tempoEstimadoMinutos,
      'capacidadePacotes': capacidadePacotes,
      'capacidadePesoKg': capacidadePesoKg,
      'horarioSaidaPadrao': horarioSaidaPadrao,
      'diasSemana': diasSemana,
      'ativo': ativo,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Helpers
  String get tempoEstimadoFormatado {
    final horas = tempoEstimadoMinutos ~/ 60;
    final minutos = tempoEstimadoMinutos % 60;
    if (horas > 0) {
      return '${horas}h${minutos > 0 ? ' ${minutos}min' : ''}';
    }
    return '${minutos}min';
  }

  String get diasSemanaFormatado {
    if (diasSemana.isEmpty) return 'Seg-Sex';

    const Map<int, String> diasAbrev = {
      1: 'SEG',
      2: 'TER',
      3: 'QUA',
      4: 'QUI',
      5: 'SEX',
      6: 'SÁB',
      7: 'DOM',
    };

    return diasSemana.map((d) => diasAbrev[d] ?? '').where((s) => s.isNotEmpty).join(', ');
  }

  double get distanciaKmDouble => double.tryParse(distanciaKm) ?? 0.0;
  double get capacidadePesoKgDouble => double.tryParse(capacidadePesoKg) ?? 0.0;
}

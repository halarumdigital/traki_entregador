/// Model para rotas intermunicipais disponíveis
class Rota {
  final String id;
  final String nomeRota;
  final String cidadeOrigemId;
  final String cidadeOrigemNome;
  final String cidadeDestinoId;
  final String cidadeDestinoNome;
  final String distanciaKm;
  final int tempoEstimadoMinutos;
  final bool ativo;

  Rota({
    required this.id,
    required this.nomeRota,
    required this.cidadeOrigemId,
    required this.cidadeOrigemNome,
    required this.cidadeDestinoId,
    required this.cidadeDestinoNome,
    required this.distanciaKm,
    required this.tempoEstimadoMinutos,
    required this.ativo,
  });

  factory Rota.fromJson(Map<String, dynamic> json) {
    return Rota(
      id: json['id']?.toString() ?? '',
      nomeRota: json['nomeRota']?.toString() ?? '',
      cidadeOrigemId: json['cidadeOrigemId']?.toString() ?? '',
      cidadeOrigemNome: json['cidadeOrigemNome']?.toString() ?? '',
      cidadeDestinoId: json['cidadeDestinoId']?.toString() ?? '',
      cidadeDestinoNome: json['cidadeDestinoNome']?.toString() ?? '',
      distanciaKm: json['distanciaKm']?.toString() ?? '0',
      tempoEstimadoMinutos: int.tryParse(json['tempoEstimadoMinutos']?.toString() ?? '0') ?? 0,
      ativo: json['ativo'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomeRota': nomeRota,
      'cidadeOrigemId': cidadeOrigemId,
      'cidadeOrigemNome': cidadeOrigemNome,
      'cidadeDestinoId': cidadeDestinoId,
      'cidadeDestinoNome': cidadeDestinoNome,
      'distanciaKm': distanciaKm,
      'tempoEstimadoMinutos': tempoEstimadoMinutos,
      'ativo': ativo,
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

  double get distanciaKmDouble => double.tryParse(distanciaKm) ?? 0.0;
}

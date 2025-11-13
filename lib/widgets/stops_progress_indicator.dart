import 'package:flutter/material.dart';

/// Widget para exibir o progresso das paradas de entrega
class StopsProgressIndicator extends StatelessWidget {
  final int totalStops;
  final int completedStops;
  final int currentStopNumber;

  const StopsProgressIndicator({
    super.key,
    required this.totalStops,
    required this.completedStops,
    required this.currentStopNumber,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalStops > 0 ? completedStops / totalStops : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade100,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Informações de progresso
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Parada atual
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Parada $currentStopNumber de $totalStops',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Contador de concluídas
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: progress == 1.0 ? Colors.green : Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completedStops/$totalStops',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Barra de progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 20,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? Colors.green : Colors.blue,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Texto de porcentagem
          Text(
            '${(progress * 100).toStringAsFixed(0)}% concluído',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

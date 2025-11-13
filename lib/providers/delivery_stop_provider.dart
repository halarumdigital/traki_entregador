import 'package:flutter/material.dart';
import '../models/delivery_stop.dart';
import '../services/delivery_stop_service.dart';

/// Provider para gerenciar stops de entregas
class DeliveryStopProvider extends ChangeNotifier {
  // Cache de stops por delivery ID
  final Map<String, List<DeliveryStop>> _stopsByDelivery = {};

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Obter stops de uma entrega específica
  List<DeliveryStop> getStops(String deliveryId) {
    return _stopsByDelivery[deliveryId] ?? [];
  }

  /// Obter stop atual (primeiro pending ou arrived)
  DeliveryStop? getCurrentStop(String deliveryId) {
    final stops = getStops(deliveryId);
    if (stops.isEmpty) return null;

    // Procurar primeiro stop arrived ou pending
    try {
      return stops.firstWhere(
        (stop) => stop.isArrived || stop.isPending,
      );
    } catch (e) {
      // Se não encontrar, retornar o primeiro
      return stops.first;
    }
  }

  /// Verificar se tem próximo stop
  bool hasNextStop(String deliveryId, String currentStopId) {
    final stops = getStops(deliveryId);
    final currentIndex = stops.indexWhere((s) => s.id == currentStopId);

    if (currentIndex == -1) return false;

    return stops
        .skip(currentIndex + 1)
        .any((stop) => stop.isPending || stop.isArrived);
  }

  /// Obter próximo stop pendente
  DeliveryStop? getNextStop(String deliveryId, String currentStopId) {
    final stops = getStops(deliveryId);
    final currentIndex = stops.indexWhere((s) => s.id == currentStopId);

    if (currentIndex == -1) return null;

    try {
      return stops.skip(currentIndex + 1).firstWhere(
            (stop) => stop.isPending,
          );
    } catch (e) {
      return null;
    }
  }

  /// Contar stops por status
  Map<String, int> getStopsCounts(String deliveryId) {
    final stops = getStops(deliveryId);

    return {
      'total': stops.length,
      'pending': stops.where((s) => s.isPending).length,
      'arrived': stops.where((s) => s.isArrived).length,
      'completed': stops.where((s) => s.isCompleted).length,
      'skipped': stops.where((s) => s.isSkipped).length,
    };
  }

  /// Progresso em porcentagem (0.0 a 1.0)
  double getProgress(String deliveryId) {
    final stops = getStops(deliveryId);
    if (stops.isEmpty) return 0.0;

    final completed = stops.where((s) => s.isCompleted).length;
    return completed / stops.length;
  }

  /// Carregar stops de uma entrega
  Future<void> loadStops(String deliveryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await DeliveryStopService.getDeliveryStops(deliveryId);

      if (response.success) {
        _stopsByDelivery[deliveryId] = response.data;
        _debugPrintStops(deliveryId);
        debugPrint('✅ ${response.data.length} stop(s) carregado(s) para entrega $deliveryId');
      } else {
        _error = response.message ?? 'Erro ao carregar paradas';
        debugPrint('❌ Erro ao carregar stops: $_error');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Erro ao carregar stops: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marcar chegada em um stop
  Future<void> arrivedAtStop(String deliveryId, String stopId) async {
    try {
      final success = await DeliveryStopService.arrivedAtStop(deliveryId, stopId);

      if (success) {
        // Atualizar stop localmente
        final stops = _stopsByDelivery[deliveryId];
        if (stops != null) {
          final index = stops.indexWhere((s) => s.id == stopId);
          if (index != -1) {
            stops[index] = stops[index].copyWith(
              status: 'arrived',
              arrivedAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            notifyListeners();
          }
        }

        // Recarregar para garantir sincronia com o servidor
        await loadStops(deliveryId);
      } else {
        throw Exception('Falha ao marcar chegada');
      }
    } catch (e) {
      debugPrint('❌ Erro ao marcar chegada: $e');
      rethrow;
    }
  }

  /// Completar um stop
  Future<Map<String, dynamic>> completeStop(String deliveryId, String stopId) async {
    try {
      final result = await DeliveryStopService.completeStop(deliveryId, stopId);

      if (result['success'] == true) {
        // Atualizar stop localmente
        final stops = _stopsByDelivery[deliveryId];
        if (stops != null) {
          final index = stops.indexWhere((s) => s.id == stopId);
          if (index != -1) {
            stops[index] = stops[index].copyWith(
              status: 'completed',
              completedAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            notifyListeners();
          }
        }

        // Recarregar para garantir sincronia com o servidor
        await loadStops(deliveryId);

        return result;
      } else {
        throw Exception(result['message'] ?? 'Falha ao completar stop');
      }
    } catch (e) {
      debugPrint('❌ Erro ao completar stop: $e');
      rethrow;
    }
  }

  /// Pular um stop
  Future<void> skipStop(String deliveryId, String stopId, {String? reason}) async {
    try {
      final success = await DeliveryStopService.skipStop(deliveryId, stopId, reason: reason);

      if (success) {
        // Atualizar stop localmente
        final stops = _stopsByDelivery[deliveryId];
        if (stops != null) {
          final index = stops.indexWhere((s) => s.id == stopId);
          if (index != -1) {
            stops[index] = stops[index].copyWith(
              status: 'skipped',
              notes: reason,
              updatedAt: DateTime.now(),
            );
            notifyListeners();
          }
        }

        // Recarregar para garantir sincronia com o servidor
        await loadStops(deliveryId);
      } else {
        throw Exception('Falha ao pular stop');
      }
    } catch (e) {
      debugPrint('❌ Erro ao pular stop: $e');
      rethrow;
    }
  }

  /// Limpar stops de uma entrega (quando entrega for concluída)
  void clearStops(String deliveryId) {
    _stopsByDelivery.remove(deliveryId);
    notifyListeners();
  }

  /// Limpar todos os stops
  void clearAll() {
    _stopsByDelivery.clear();
    _error = null;
    notifyListeners();
  }

  /// Debug: imprimir stops
  void _debugPrintStops(String deliveryId) {
    final stops = getStops(deliveryId);

    debugPrint('═══════════════════════════════════════');
    debugPrint('📍 STOPS DA ENTREGA $deliveryId: ${stops.length}');
    for (var stop in stops) {
      final name = stop.customerName ?? "Sem nome";
      final address = stop.address.length > 40 ? '${stop.address.substring(0, 40)}...' : stop.address;
      debugPrint('  [${stop.stopOrder}] $name');
      debugPrint('      Status: ${stop.statusText}');
      debugPrint('      Endereço: $address');
    }
    debugPrint('═══════════════════════════════════════');
  }
}

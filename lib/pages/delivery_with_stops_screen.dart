import 'package:flutter/material.dart';
import '../models/delivery.dart';
import '../models/delivery_stop.dart';
import '../widgets/delivery_stops_list.dart';
import '../widgets/stops_progress_indicator.dart';
import '../services/delivery_service.dart';
import 'rate_company_screen.dart';

/// Tela para mostrar uma entrega com múltiplos stops
class DeliveryWithStopsScreen extends StatefulWidget {
  final Delivery delivery;

  const DeliveryWithStopsScreen({
    super.key,
    required this.delivery,
  });

  @override
  State<DeliveryWithStopsScreen> createState() => _DeliveryWithStopsScreenState();
}

class _DeliveryWithStopsScreenState extends State<DeliveryWithStopsScreen> {
  List<DeliveryStop> _stops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Buscar stops da API
    _loadStopsFromAPI();
  }

  /// Carrega os stops fazendo parsing do deliveryAddress
  Future<void> _loadStopsFromAPI() async {
    setState(() {
      _isLoading = true;
    });

    debugPrint('🔍 ===== CARREGANDO STOPS DO DELIVERY ADDRESS =====');
    debugPrint('🔍 deliveryId: ${widget.delivery.requestId}');
    debugPrint('🔍 deliveryAddress: ${widget.delivery.deliveryAddress}');

    // Não existe endpoint GET /stops, então parseamos diretamente do deliveryAddress
    _parseStopsFromAddressFallback();
  }

  /// Faz parsing do deliveryAddress para extrair os stops
  void _parseStopsFromAddressFallback() {
    final deliveryAddress = widget.delivery.deliveryAddress ?? '';

    if (deliveryAddress.isEmpty || !deliveryAddress.contains(' | ')) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final stopStrings = deliveryAddress.split(' | ');
    final stops = <DeliveryStop>[];

    for (int i = 0; i < stopStrings.length; i++) {
      final stopString = stopStrings[i].trim();
      if (stopString.isEmpty) continue;

      String? customerName;
      String? customerWhatsapp;
      String? deliveryReference;
      String address = stopString;

      // Extrair nome do cliente (primeiro par de colchetes)
      final nameMatch = RegExp(r'^\[(.*?)\]').firstMatch(address);
      if (nameMatch != null) {
        customerName = nameMatch.group(1);
        address = address.replaceFirst(nameMatch.group(0)!, '').trim();
      }

      // Extrair WhatsApp se existir [WhatsApp: xxxxxx]
      final whatsappMatch = RegExp(r'\[WhatsApp:\s*([^\]]+)\]').firstMatch(address);
      if (whatsappMatch != null) {
        customerWhatsapp = whatsappMatch.group(1)?.trim();
        address = address.replaceFirst(whatsappMatch.group(0)!, '').trim();
      }

      // Extrair referência se existir [Ref: xxxxx]
      final refMatch = RegExp(r'\[Ref:\s*([^\]]+)\]').firstMatch(address);
      if (refMatch != null) {
        deliveryReference = refMatch.group(1)?.trim();
        address = address.replaceFirst(refMatch.group(0)!, '').trim();
      }

      // Limpar o endereço - remover coordenadas e informações extras
      // Remover padrões como "Joaçaba - SC, Brasil" deixando apenas rua, número e bairro
      address = address
          .replaceAll(RegExp(r',?\s*Brasil$', caseSensitive: false), '')
          .replaceAll(RegExp(r',?\s*SC\b', caseSensitive: false), '')
          .replaceAll(RegExp(r',?\s*Joaçaba\s*-?\s*', caseSensitive: false), '')
          .trim();

      // Se não encontrou WhatsApp específico, usar o WhatsApp geral da entrega
      if (customerWhatsapp == null || customerWhatsapp.isEmpty) {
        customerWhatsapp = widget.delivery.customerWhatsapp;
      }

      stops.add(DeliveryStop(
        id: '${widget.delivery.requestId}_stop_$i',
        requestId: widget.delivery.requestId,
        stopOrder: i + 1,
        stopType: 'delivery',
        customerName: customerName,
        customerWhatsapp: customerWhatsapp,
        deliveryReference: deliveryReference,
        address: address,
        lat: 0.0,
        lng: 0.0,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      debugPrint('📍 Stop ${i + 1} criado:');
      debugPrint('   - Nome: $customerName');
      debugPrint('   - WhatsApp: $customerWhatsapp');
      debugPrint('   - Ref: $deliveryReference');
      debugPrint('   - Endereço: $address');
    }

    setState(() {
      _stops = stops;
      _isLoading = false;
    });

    debugPrint('✅ ${stops.length} stops criados do parsing do deliveryAddress');
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar loading enquanto carrega
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.delivery.requestNumber),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Mostrar mensagem se não houver stops
    if (_stops.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.delivery.requestNumber),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Nenhuma parada encontrada'),
        ),
      );
    }

    // Calcular contagens e stop atual
    final completedCount = _stops.where((s) => s.status == 'completed').length;
    final currentStop = _stops.firstWhere(
      (s) => s.status == 'pending' || s.status == 'arrived',
      orElse: () => _stops.last,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.delivery.requestNumber),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadStopsFromAPI();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadStopsFromAPI();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informações da entrega
              _buildDeliveryInfo(),

              const SizedBox(height: 16),

              // Indicador de progresso
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StopsProgressIndicator(
                  totalStops: _stops.length,
                  completedStops: completedCount,
                  currentStopNumber: currentStop.stopOrder,
                ),
              ),

              const SizedBox(height: 24),

              // Lista de paradas
              DeliveryStopsList(
                stops: _stops,
                currentStopId: currentStop.id,
                onStopTap: (stop) {
                  // Tap na parada - pode abrir detalhes ou navegar
                  debugPrint('Tapped on stop ${stop.stopOrder}');
                },
                onArrivedPressed: (stop) {
                  _handleArrived(stop);
                },
                onCompletePressed: (stop) {
                  _handleComplete(stop);
                },
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildDeliveryInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.blue.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.delivery.companyName ?? 'Empresa',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.delivery.pickupAddress ?? 'Endereço de retirada',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget? _buildBottomBar() {
    // Verificar se todas as paradas foram concluídas
    final allCompleted = _stops.every((s) => s.status == 'completed');

    if (!allCompleted) {
      return null;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _handleCompleteDelivery(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Finalizar Entrega',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _handleCompleteDelivery() async {
    try {
      debugPrint('🎉 Finalizando entrega: ${widget.delivery.requestId}');

      // Chamar API para completar a entrega
      final success = await DeliveryService.complete(widget.delivery.requestId);

      if (!mounted) return;

      if (success) {
        debugPrint('✅ Entrega finalizada com sucesso');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Entrega finalizada com sucesso!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Aguardar um momento antes de mostrar a tela de avaliação
        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;

        // Mostrar tela de avaliação da empresa
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RateCompanyScreen(
              deliveryId: widget.delivery.requestId,
              companyName: widget.delivery.companyName ?? 'Empresa',
            ),
          ),
        );

        if (!mounted) return;

        // Voltar para home após avaliação
        Navigator.pop(context, true); // true indica que completou
      } else {
        debugPrint('❌ Erro ao finalizar entrega');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao finalizar entrega. Tente novamente.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao finalizar entrega: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao finalizar entrega. Tente novamente.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleArrived(DeliveryStop stop) {
    setState(() {
      final index = _stops.indexWhere((s) => s.id == stop.id);
      if (index == -1) return;

      _stops[index] = stop.copyWith(
        status: 'arrived',
        arrivedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chegada registrada na parada ${stop.stopOrder}'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleComplete(DeliveryStop stop) async {
    try {
      debugPrint('📦 Marcando parada ${stop.stopOrder} como entregue...');

      // Chamar API para marcar como entregue
      final response = await DeliveryService.delivered(widget.delivery.requestId);

      if (response != null) {
        debugPrint('✅ Resposta da API: $response');

        final status = response['status'];
        final allStopsCompleted = response['allStopsCompleted'] ?? false;

        // Atualizar estado local
        setState(() {
          final index = _stops.indexWhere((s) => s.id == stop.id);
          if (index != -1) {
            _stops[index] = stop.copyWith(
              status: 'completed',
              completedAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
        });

        if (allStopsCompleted && status == 'completed') {
          // Todas as paradas foram completadas
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Todas as paradas concluídas!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else if (status == 'in_progress') {
          // Ainda há paradas pendentes
          final nextStop = response['nextStop'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Parada ${stop.stopOrder} concluída! Siga para o próximo ponto.'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          if (nextStop != null) {
            debugPrint('📍 Próximo stop: ${nextStop['customerName']} - ${nextStop['address']}');
          }
        }
      } else {
        debugPrint('❌ Erro ao marcar entrega via API');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao registrar entrega. Tente novamente.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao completar parada: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao registrar entrega. Tente novamente.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

}

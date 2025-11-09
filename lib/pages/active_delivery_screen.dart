import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/delivery_service.dart';
import '../styles/styles.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final Map<String, dynamic> delivery;

  const ActiveDeliveryScreen({Key? key, required this.delivery}) : super(key: key);

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  late Map<String, dynamic> _delivery;
  bool _isProcessing = false;

  // Status da entrega
  String _currentStatus = 'accepted'; // accepted, arrived, picked_up, delivered, completed

  @override
  void initState() {
    super.initState();
    _delivery = widget.delivery;
    debugPrint('📦 Tela de entrega ativa carregada: ${_delivery}');
  }

  String _formatCurrency(dynamic value) {
    try {
      if (value == null) return '0.00';
      final numValue = value is num ? value : double.tryParse(value.toString()) ?? 0.0;
      return numValue.toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }

  Future<void> _updateStatus(String newStatus, String deliveryId) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    bool success = false;

    try {
      switch (newStatus) {
        case 'arrived':
          success = await DeliveryService.arrivedAtPickup(deliveryId);
          break;
        case 'picked_up':
          success = await DeliveryService.pickedUp(deliveryId);
          break;
        case 'delivered':
          success = await DeliveryService.delivered(deliveryId);
          break;
        case 'completed':
          success = await DeliveryService.complete(deliveryId);
          break;
      }

      if (!mounted) return;

      if (success) {
        setState(() {
          _currentStatus = newStatus;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_getStatusMessage(newStatus)),
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Se completou, voltar para tela anterior
        if (newStatus == 'completed') {
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pop(context, true); // true indica que completou
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar status. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao atualizar status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar status. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'arrived':
        return 'Chegada marcada com sucesso!';
      case 'picked_up':
        return 'Retirada confirmada!';
      case 'delivered':
        return 'Entrega confirmada!';
      case 'completed':
        return 'Entrega concluída com sucesso!';
      default:
        return 'Status atualizado!';
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Aceita';
      case 'arrived':
        return 'No Local de Retirada';
      case 'picked_up':
        return 'Pedido Retirado';
      case 'delivered':
        return 'Pedido Entregue';
      case 'completed':
        return 'Concluída';
      default:
        return 'Desconhecido';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.blue;
      case 'arrived':
        return Colors.orange;
      case 'picked_up':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível abrir o Google Maps'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao abrir Google Maps: $e');
    }
  }

  Future<void> _openWaze(double lat, double lng) async {
    final url = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível abrir o Waze'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao abrir Waze: $e');
    }
  }

  void _showNavigationOptions({required bool isPickup}) {
    final address = isPickup
        ? (_delivery['pickupAddress'] ?? 'Local de retirada')
        : (_delivery['deliveryAddress'] ?? _delivery['dropoffAddress'] ?? 'Local de entrega');
    final lat = isPickup ? _delivery['pickupLat'] : _delivery['deliveryLat'];
    final lng = isPickup ? _delivery['pickupLng'] : _delivery['deliveryLng'];
    final locationName = isPickup
        ? (_delivery['companyName'] ?? 'Empresa')
        : (_delivery['customerName'] ?? 'Cliente');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.navigation, color: Colors.blue, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Traçar Rota',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPickup ? 'Ir para o local de retirada:' : 'Ir para o local de entrega:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isPickup ? Icons.business : Icons.person,
                        color: Colors.blue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locationName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Escolha o aplicativo de navegação:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.map, color: Colors.white),
            label: const Text('Google Maps', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _openGoogleMaps(
                lat is double ? lat : double.tryParse(lat?.toString() ?? '0') ?? 0.0,
                lng is double ? lng : double.tryParse(lng?.toString() ?? '0') ?? 0.0,
              );
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.navigation, color: Colors.white),
            label: const Text('Waze', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _openWaze(
                lat is double ? lat : double.tryParse(lat?.toString() ?? '0') ?? 0.0,
                lng is double ? lng : double.tryParse(lng?.toString() ?? '0') ?? 0.0,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: buttonColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Voltar para Home sem fechar a entrega
            Navigator.pop(context, false); // false indica que não completou
          },
        ),
        title: const Text(
          'Entrega em Andamento',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header com status atual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: buttonColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_currentStatus),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusLabel(_currentStatus),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pedido #${_delivery['requestNumber'] ?? 'N/A'}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Valor da entrega
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Valor da Entrega',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'R\$ ${_formatCurrency(_delivery['driverAmount'] ?? _delivery['estimatedAmount'])}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mostrar apenas local de RETIRADA quando status é "accepted" ou "arrived"
                  if (_currentStatus == 'accepted' || _currentStatus == 'arrived')
                    _buildLocationCard(
                      title: 'Local de Retirada',
                      icon: Icons.store,
                      iconColor: Colors.blue,
                      name: _delivery['companyName'] ?? 'Empresa',
                      address: _delivery['pickupAddress'] ?? '',
                      phone: _delivery['companyPhone'],
                      onNavigate: () => _showNavigationOptions(isPickup: true),
                    ),

                  // Mostrar apenas local de ENTREGA quando status é "picked_up" ou "delivered"
                  if (_currentStatus == 'picked_up' || _currentStatus == 'delivered')
                    _buildLocationCard(
                      title: 'Local de Entrega',
                      icon: Icons.person,
                      iconColor: Colors.orange,
                      name: _delivery['customerName'] ?? 'Cliente',
                      address: _delivery['deliveryAddress'] ?? _delivery['dropoffAddress'] ?? '',
                      onNavigate: () => _showNavigationOptions(isPickup: false),
                    ),

                  const SizedBox(height: 24),

                  // Informações adicionais
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoBox(
                          Icons.straighten,
                          '${_delivery['distance'] ?? '0'} km',
                          'Distância',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoBox(
                          Icons.access_time,
                          '${_delivery['estimatedTime'] ?? '0'} min',
                          'Tempo Estimado',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Botões de atualização de status
                  const Text(
                    'Atualizar Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_isProcessing)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    _buildStatusButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String name,
    required String address,
    String? phone,
    required VoidCallback onNavigate,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.place, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          if (phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onNavigate,
              icon: const Icon(Icons.navigation, color: Colors.white),
              label: const Text(
                'Traçar Rota',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: textColor.withOpacity(0.7), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButtons() {
    final deliveryId = _delivery['requestId'] ?? _delivery['deliveryId'] ?? '';

    return Column(
      children: [
        if (_currentStatus == 'accepted')
          _buildStatusButton(
            label: 'Cheguei no Local de Retirada',
            icon: Icons.location_on,
            color: Colors.orange,
            onPressed: () => _updateStatus('arrived', deliveryId),
          ),
        if (_currentStatus == 'arrived')
          _buildStatusButton(
            label: 'Retirei o Pedido',
            icon: Icons.check_box,
            color: Colors.purple,
            onPressed: () => _updateStatus('picked_up', deliveryId),
          ),
        if (_currentStatus == 'picked_up')
          _buildStatusButton(
            label: 'Entreguei o Pedido',
            icon: Icons.done_all,
            color: Colors.green,
            onPressed: () => _updateStatus('delivered', deliveryId),
          ),
        if (_currentStatus == 'delivered')
          _buildStatusButton(
            label: 'Concluir Entrega',
            icon: Icons.celebration,
            color: Colors.teal,
            onPressed: () => _updateStatus('completed', deliveryId),
          ),
      ],
    );
  }

  Widget _buildStatusButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

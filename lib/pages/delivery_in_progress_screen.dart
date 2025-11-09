import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../styles/styles.dart';
import '../services/delivery_service.dart';

class DeliveryInProgressScreen extends StatefulWidget {
  final Map<String, dynamic> delivery;

  const DeliveryInProgressScreen({Key? key, required this.delivery}) : super(key: key);

  @override
  State<DeliveryInProgressScreen> createState() => _DeliveryInProgressScreenState();
}

class _DeliveryInProgressScreenState extends State<DeliveryInProgressScreen> {
  Map<String, dynamic>? _currentDelivery;
  bool _isLoading = false;
  String _currentStatus = 'accepted';

  @override
  void initState() {
    super.initState();
    _currentDelivery = widget.delivery;
    _currentStatus = widget.delivery['status'] ?? 'accepted';
  }

  Future<void> _updateStatus(String action, String newStatus) async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success = false;
      final deliveryId = _currentDelivery!['id'] ?? _currentDelivery!['deliveryId'];

      switch (action) {
        case 'arrived':
          success = await DeliveryService.arrivedAtPickup(deliveryId);
          break;
        case 'picked':
          success = await DeliveryService.pickedUp(deliveryId);
          break;
        case 'delivered':
          success = await DeliveryService.delivered(deliveryId);
          break;
        case 'complete':
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
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Status atualizado com sucesso!')),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Se completou, volta para a home
        if (action == 'complete') {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
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
          _isLoading = false;
        });
      }
    }
  }

  void _showNavigationOptions(double lat, double lng, String title) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.map, color: Colors.green),
              ),
              title: const Text('Google Maps'),
              subtitle: const Text('Abrir no Google Maps'),
              onTap: () async {
                Navigator.pop(context);
                await _openGoogleMaps(lat, lng);
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.navigation, color: Colors.blue),
              ),
              title: const Text('Waze'),
              subtitle: const Text('Abrir no Waze'),
              onTap: () async {
                Navigator.pop(context);
                await _openWaze(lat, lng);
              },
            ),
          ],
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: page,
      appBar: AppBar(
        backgroundColor: buttonColor,
        title: const Text(
          'Entrega em Andamento',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: _currentDelivery == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status atual
                  _buildStatusTimeline(),
                  const SizedBox(height: 24),

                  // Informações da empresa
                  _buildSectionTitle('Empresa'),
                  _buildInfoCard(
                    icon: Icons.business,
                    color: Colors.blue,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentDelivery!['companyName'] ?? 'Empresa',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Endereços
                  _buildSectionTitle('Endereços'),
                  _buildInfoCard(
                    icon: Icons.place,
                    color: Colors.green,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Retirada:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              icon: const Icon(Icons.navigation, size: 16),
                              label: const Text('Navegar'),
                              onPressed: () => _showNavigationOptions(
                                _currentDelivery!['pickupLat'] ?? 0.0,
                                _currentDelivery!['pickupLng'] ?? 0.0,
                                'Ir para Local de Retirada',
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _currentDelivery!['pickupAddress'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'Entrega:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              icon: const Icon(Icons.navigation, size: 16),
                              label: const Text('Navegar'),
                              onPressed: () => _showNavigationOptions(
                                _currentDelivery!['deliveryLat'] ?? 0.0,
                                _currentDelivery!['deliveryLng'] ?? 0.0,
                                'Ir para Local de Entrega',
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _currentDelivery!['deliveryAddress'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Informações da entrega
                  _buildSectionTitle('Detalhes'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSmallInfoCard(
                          Icons.straighten,
                          '${_currentDelivery!['distance'] ?? '0'} km',
                          'Distância',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSmallInfoCard(
                          Icons.access_time,
                          '${_currentDelivery!['estimatedTime'] ?? '0'} min',
                          'Tempo',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Valor
                  _buildInfoCard(
                    icon: Icons.attach_money,
                    color: Colors.green,
                    content: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Valor da Entrega',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'R\$ ${_currentDelivery!['driverAmount'] ?? '0.00'}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botões de ação
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    _buildActionButtons(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textColor.withOpacity(0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildSmallInfoCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
            style: TextStyle(
              fontSize: 12,
              color: textColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final steps = [
      {'status': 'accepted', 'label': 'Aceita', 'icon': Icons.check_circle},
      {'status': 'arrived', 'label': 'Chegou', 'icon': Icons.location_on},
      {'status': 'picked', 'label': 'Retirou', 'icon': Icons.inventory},
      {'status': 'delivered', 'label': 'Entregou', 'icon': Icons.done_all},
      {'status': 'completed', 'label': 'Concluída', 'icon': Icons.celebration},
    ];

    final currentIndex = steps.indexWhere((s) => s['status'] == _currentStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status da Entrega',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length, (index) {
              final isActive = index <= currentIndex;
              final step = steps[index];

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isActive ? buttonColor : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        step['icon'] as IconData,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? buttonColor : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    switch (_currentStatus) {
      case 'accepted':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _updateStatus('arrived', 'arrived'),
                icon: const Icon(Icons.location_on, color: Colors.white),
                label: const Text(
                  'Cheguei no Local de Retirada',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'arrived':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _updateStatus('picked', 'picked'),
                icon: const Icon(Icons.inventory, color: Colors.white),
                label: const Text(
                  'Retirei o Pedido',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'picked':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _updateStatus('delivered', 'delivered'),
                icon: const Icon(Icons.done_all, color: Colors.white),
                label: const Text(
                  'Entreguei o Pedido',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'delivered':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _updateStatus('complete', 'completed'),
                icon: const Icon(Icons.celebration, color: Colors.white),
                label: const Text(
                  'Concluir Entrega',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'completed':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.celebration, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text(
                'Entrega Concluída!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

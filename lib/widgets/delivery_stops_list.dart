import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/delivery_stop.dart';

/// Widget de lista de stops de uma entrega
class DeliveryStopsList extends StatelessWidget {
  final List<DeliveryStop> stops;
  final String? currentStopId;
  final Function(DeliveryStop) onStopTap;
  final Function(DeliveryStop)? onArrivedPressed;
  final Function(DeliveryStop)? onCompletePressed;

  const DeliveryStopsList({
    super.key,
    required this.stops,
    this.currentStopId,
    required this.onStopTap,
    this.onArrivedPressed,
    this.onCompletePressed,
  });

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Nenhuma parada encontrada',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stops.length,
      itemBuilder: (context, index) {
        final stop = stops[index];
        final isCurrent = stop.id == currentStopId;

        return _StopCard(
          stop: stop,
          isCurrent: isCurrent,
          onTap: () => onStopTap(stop),
          onArrivedPressed: onArrivedPressed != null && stop.isPending
              ? () => onArrivedPressed!(stop)
              : null,
          onCompletePressed: onCompletePressed != null && stop.isArrived
              ? () => onCompletePressed!(stop)
              : null,
        );
      },
    );
  }
}

/// Card individual de um stop
class _StopCard extends StatelessWidget {
  final DeliveryStop stop;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback? onArrivedPressed;
  final VoidCallback? onCompletePressed;

  const _StopCard({
    required this.stop,
    required this.isCurrent,
    required this.onTap,
    this.onArrivedPressed,
    this.onCompletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isCurrent ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent
            ? const BorderSide(color: Colors.blue, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Número da parada
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: stop.statusColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${stop.stopOrder}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Nome do cliente
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.customerName ?? 'Cliente não informado',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stop.statusText,
                          style: TextStyle(
                            fontSize: 13,
                            color: stop.statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ícone de status
                  Icon(
                    stop.statusIcon,
                    color: stop.statusColor,
                    size: 28,
                  ),

                  // Badge "ATUAL"
                  if (isCurrent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ATUAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Endereço
              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stop.address,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // WhatsApp (se disponível)
              if (stop.customerWhatsapp != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      stop.customerWhatsapp!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],

              // Referência (se disponível)
              if (stop.deliveryReference != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stop.deliveryReference!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Botões de navegação e contato
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Google Maps
                  _ActionButton(
                    icon: Icons.map,
                    label: 'Maps',
                    color: Colors.green,
                    onTap: () => _openMaps(stop.address),
                  ),
                  // Waze
                  _ActionButton(
                    icon: Icons.navigation,
                    label: 'Waze',
                    color: Colors.blue,
                    onTap: () => _openWaze(stop.address),
                  ),
                  // WhatsApp
                  if (stop.customerWhatsapp != null)
                    _ActionButton(
                      icon: Icons.phone,
                      label: 'WhatsApp',
                      color: Colors.green.shade700,
                      onTap: () => _openWhatsApp(stop.customerWhatsapp!),
                    ),
                ],
              ),

              // Botões de ação
              if (onArrivedPressed != null || onCompletePressed != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (onArrivedPressed != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onArrivedPressed,
                          icon: const Icon(Icons.location_on, size: 18),
                          label: const Text('Cheguei'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    if (onArrivedPressed != null && onCompletePressed != null)
                      const SizedBox(width: 8),
                    if (onCompletePressed != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onCompletePressed,
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Entreguei'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Métodos para abrir aplicativos externos
  void _openMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    // Abre Google Maps com navegação direta da localização atual até o destino
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$encodedAddress&travelmode=driving');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openWaze(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    // Abre Waze com navegação direta da localização atual até o destino
    final url = Uri.parse('https://waze.com/ul?q=$encodedAddress&navigate=yes');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openWhatsApp(String phone) async {
    // Remover caracteres especiais do telefone
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

/// Botão de ação personalizado
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../models/delivery.dart';
import '../../services/delivery_service.dart';
import '../../styles/app_colors.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';
import '../active_delivery_screen.dart';
import '../delivery_with_stops_screen.dart';

class EntregasAtivasScreen extends StatefulWidget {
  const EntregasAtivasScreen({super.key});

  @override
  State<EntregasAtivasScreen> createState() => _EntregasAtivasScreenState();
}

class _EntregasAtivasScreenState extends State<EntregasAtivasScreen> {
  bool _isLoading = true;
  List<Delivery> _entregas = [];

  @override
  void initState() {
    super.initState();
    _loadEntregas();
  }

  Future<void> _loadEntregas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Busca apenas entregas ativas
      final entregasData = await DeliveryService.getCurrentDeliveries();
      final entregas = entregasData.map((data) => Delivery.fromMap(data)).toList();
      setState(() {
        _entregas = entregas;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar entregas ativas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _abrirEntrega(Delivery entrega) async {
    // Verificar se a entrega tem múltiplas paradas
    final hasMultipleStops = entrega.deliveryAddress?.contains(' | ') ?? false;

    dynamic resultado;

    if (hasMultipleStops) {
      // Entrega com múltiplas paradas
      resultado = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeliveryWithStopsScreen(delivery: entrega),
        ),
      );
    } else {
      // Entrega normal - usar ActiveDeliveryScreen
      resultado = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActiveDeliveryScreen(
            delivery: {
              'id': entrega.requestId,
              'requestId': entrega.requestId,
              'requestNumber': entrega.requestNumber,
              'companyName': entrega.companyName,
              'companyPhone': entrega.companyPhone,
              'customerName': entrega.customerName,
              'customerWhatsapp': entrega.customerWhatsapp,
              'deliveryReference': entrega.deliveryReference,
              'pickupAddress': entrega.pickupAddress,
              'pickupLat': entrega.pickupLat,
              'pickupLng': entrega.pickupLng,
              'deliveryAddress': entrega.deliveryAddress,
              'dropoffAddress': entrega.deliveryAddress,
              'deliveryLat': entrega.deliveryLat,
              'deliveryLng': entrega.deliveryLng,
              'distance': entrega.distance,
              'estimatedTime': entrega.estimatedTime,
              'driverAmount': entrega.driverAmount,
              'status': entrega.status,
              'isTripStart': entrega.isTripStart,
              'needsReturn': entrega.needsReturn,
            },
          ),
        ),
      );
    }

    if (resultado == true) {
      _loadEntregas();
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Material(
      child: Scaffold(
        backgroundColor: page,
        body: Column(
          children: [
            // AppBar customizado
            Container(
              padding: EdgeInsets.only(
                left: media.width * 0.05,
                right: media.width * 0.05,
                top: MediaQuery.of(context).padding.top + media.width * 0.05,
                bottom: media.width * 0.05,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: media.width * 0.1,
                      width: media.width * 0.1,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: media.width * 0.05,
                      ),
                    ),
                  ),
                  SizedBox(width: media.width * 0.03),
                  Expanded(
                    child: MyText(
                      text: 'Minhas Entregas',
                      size: media.width * twenty,
                      fontweight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Badge de informação
            Container(
              margin: EdgeInsets.all(media.width * 0.04),
              padding: EdgeInsets.all(media.width * 0.04),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: media.width * 0.05),
                  SizedBox(width: media.width * 0.03),
                  Expanded(
                    child: MyText(
                      text: 'Entregas rápidas na mesma cidade que estão ativas',
                      size: media.width * fourteen,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),

            // Conteúdo
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : _entregas.isEmpty
                      ? _buildEmptyState(media)
                      : RefreshIndicator(
                          onRefresh: _loadEntregas,
                          child: ListView.builder(
                            padding: EdgeInsets.all(media.width * 0.05),
                            itemCount: _entregas.length,
                            itemBuilder: (context, index) {
                              return _buildEntregaCard(_entregas[index], media);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Size media) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: media.width * 0.2,
            color: Colors.grey[400],
          ),
          SizedBox(height: media.width * 0.05),
          MyText(
            text: 'Nenhuma entrega ativa',
            size: media.width * sixteen,
            color: textColor.withOpacity(0.7),
          ),
          SizedBox(height: media.width * 0.03),
          MyText(
            text: 'Suas entregas aceitas aparecerão aqui',
            size: media.width * fourteen,
            color: textColor.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildEntregaCard(Delivery entrega, Size media) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (entrega.status?.toLowerCase()) {
      case 'aceita':
      case 'accepted':
      case 'assigned':
        statusColor = Colors.orange;
        statusIcon = Icons.local_shipping;
        statusText = 'Aceita';
        break;
      case 'coleta':
      case 'em coleta':
      case 'aguardando_coleta':
        statusColor = Colors.orange;
        statusIcon = Icons.inventory_2;
        statusText = 'Coleta';
        break;
      case 'em andamento':
      case 'in_progress':
      case 'arrived':
      case 'arrived_at_pickup':
        statusColor = AppColors.primary;
        statusIcon = Icons.directions_car;
        statusText = 'Em Andamento';
        break;
      case 'coletada':
      case 'picked_up':
      case 'in_transit':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Coletada';
        break;
      case 'pending':
      case 'aguardando':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Aguardando';
        break;
      default:
        // Para status desconhecido, mostrar o status original ou "Em Andamento"
        statusColor = Colors.orange;
        statusIcon = Icons.local_shipping;
        statusText = entrega.status ?? 'Em Andamento';
    }

    return Container(
      margin: EdgeInsets.only(bottom: media.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _abrirEntrega(entrega),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Container(
              padding: EdgeInsets.all(media.width * 0.04),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(media.width * 0.03),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      statusIcon,
                      color: Colors.white,
                      size: media.width * 0.06,
                    ),
                  ),
                  SizedBox(width: media.width * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          text: entrega.companyName ?? 'Entrega',
                          size: media.width * sixteen,
                          fontweight: FontWeight.bold,
                          color: textColor,
                        ),
                        MyText(
                          text: statusText,
                          size: media.width * fourteen,
                          color: statusColor,
                          fontweight: FontWeight.w600,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: media.width * 0.04, color: Colors.grey),
                ],
              ),
            ),

            // Informações da entrega
            Padding(
              padding: EdgeInsets.all(media.width * 0.04),
              child: Column(
                children: [
                  // Endereço de coleta
                  if (entrega.pickupAddress != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, color: Colors.blue, size: media.width * 0.05),
                        SizedBox(width: media.width * 0.02),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MyText(
                                text: 'Coleta',
                                size: media.width * twelve,
                                color: textColor.withOpacity(0.6),
                              ),
                              MyText(
                                text: entrega.pickupAddress!,
                                size: media.width * fourteen,
                                color: textColor,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  if (entrega.pickupAddress != null && entrega.deliveryAddress != null)
                    SizedBox(height: media.width * 0.03),

                  // Endereço de entrega
                  if (entrega.deliveryAddress != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.flag, color: Colors.green, size: media.width * 0.05),
                        SizedBox(width: media.width * 0.02),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MyText(
                                text: 'Entrega',
                                size: media.width * twelve,
                                color: textColor.withOpacity(0.6),
                              ),
                              MyText(
                                text: entrega.deliveryAddress!,
                                size: media.width * fourteen,
                                color: textColor,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  // Número de paradas (se houver)
                  if (entrega.hasMultipleStops && entrega.stopsCount != null && entrega.stopsCount! > 0) ...[
                    SizedBox(height: media.width * 0.03),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: media.width * 0.03,
                        vertical: media.width * 0.02,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pin_drop, size: media.width * 0.04, color: Colors.purple),
                          SizedBox(width: media.width * 0.02),
                          MyText(
                            text: '${entrega.stopsCount} parada(s)',
                            size: media.width * twelve,
                            fontweight: FontWeight.w600,
                            color: textColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

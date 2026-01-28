import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/delivery_service.dart';
import 'rate_company_screen.dart';
import 'delivery_with_stops_screen.dart';
import '../models/delivery.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final Map<String, dynamic> delivery;

  const ActiveDeliveryScreen({super.key, required this.delivery});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  late Map<String, dynamic> _delivery;
  bool _isProcessing = false;
  String _currentStatus = 'accepted';

  @override
  void initState() {
    super.initState();
    _delivery = widget.delivery;
    _initializeStatus();
    debugPrint('Tela de entrega ativa carregada: $_delivery');
    debugPrint('Logo URL: ${_delivery['companyLogoUrl'] ?? _delivery['company_logo_url'] ?? 'NAO ENCONTRADA'}');
    debugPrint('Status inicial: $_currentStatus');
  }

  void _initializeStatus() {
    // Mapear status do backend para status local
    final backendStatus = _delivery['status']?.toString().toLowerCase() ?? '';
    debugPrint('Status do backend: $backendStatus');

    switch (backendStatus) {
      case 'accepted':
      case 'assigned':
        _currentStatus = 'accepted';
        break;
      case 'arrived':
      case 'arrived_at_pickup':
        _currentStatus = 'arrived';
        break;
      case 'picked_up':
      case 'in_transit':
        _currentStatus = 'picked_up';
        break;
      case 'delivered':
        _currentStatus = 'delivered';
        break;
      case 'delivered_awaiting_return':
        _currentStatus = 'delivered_awaiting_return';
        break;
      case 'returning':
        _currentStatus = 'returning';
        break;
      case 'completed':
        _currentStatus = 'completed';
        break;
      default:
        // Fallback: usar isTripStart para determinar se já foi retirado
        final isTripStart = _delivery['isTripStart'] == true;
        _currentStatus = isTripStart ? 'picked_up' : 'accepted';
        debugPrint('Status nao reconhecido, usando fallback: isTripStart=$isTripStart -> $_currentStatus');
    }
  }

  String _cleanAddress(String address) {
    String cleanedAddress = address;
    cleanedAddress = cleanedAddress.replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
    cleanedAddress = cleanedAddress.replaceAll(RegExp(r'\[WhatsApp:\s*[^\]]+\]\s*'), '');
    cleanedAddress = cleanedAddress.replaceAll(RegExp(r'\[Ref:\s*[^\]]+\]\s*'), '');
    cleanedAddress = cleanedAddress.replaceAll(RegExp(r'^\[.*?\]\s*'), '');
    return cleanedAddress.trim();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'E!';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2 ? '${name[0].toUpperCase()}!' : name.toUpperCase();
  }

  Future<void> _updateStatus(String newStatus, String deliveryId) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    bool success = false;
    Map<String, dynamic>? responseData;

    try {
      switch (newStatus) {
        case 'arrived':
          success = await DeliveryService.arrivedAtPickup(deliveryId);
          break;
        case 'picked_up':
          success = await DeliveryService.pickedUp(deliveryId);
          break;
        case 'delivered':
          responseData = await DeliveryService.delivered(deliveryId);
          success = responseData != null;
          break;
        case 'start_return':
          responseData = await DeliveryService.startReturn(deliveryId);
          success = responseData != null;
          break;
        case 'complete_return':
          responseData = await DeliveryService.completeReturn(deliveryId);
          success = responseData != null;
          break;
        case 'completed':
          success = await DeliveryService.complete(deliveryId);
          break;
      }

      if (!mounted) return;

      if (success) {
        if (newStatus == 'delivered' && responseData != null) {
          final needsReturn = (responseData['needsReturn'] == true ||
                               responseData['needsReturn'] == 'true' ||
                               responseData['needs_return'] == true ||
                               responseData['needs_return'] == 'true');
          final status = responseData['status'];

          if (needsReturn && status == 'delivered_awaiting_return') {
            setState(() => _currentStatus = 'delivered_awaiting_return');
            _showSnackBar('Produto entregue! Voce precisa retornar ao ponto de origem.', Colors.orange, Icons.warning_amber);
          } else {
            setState(() => _currentStatus = newStatus);
            _showSnackBar(_getStatusMessage(newStatus), Colors.green, Icons.check_circle);
          }
        } else if (newStatus == 'start_return' && responseData != null) {
          setState(() => _currentStatus = 'returning');
          _showSnackBar('Retorno iniciado! Volte ao ponto de retirada.', Colors.blue, Icons.u_turn_left);
        } else if (newStatus == 'complete_return' && responseData != null) {
          setState(() => _currentStatus = 'completed');
          _showSnackBar('Entrega finalizada com sucesso!', Colors.green, Icons.check_circle);
          await _showRatingScreen(deliveryId);
        } else {
          setState(() => _currentStatus = newStatus);
          _showSnackBar(_getStatusMessage(newStatus), Colors.green, Icons.check_circle);

          if (newStatus == 'picked_up') {
            await _checkMultipleStops();
          }

          if (newStatus == 'completed') {
            await _showRatingScreen(deliveryId);
          }
        }
      } else {
        _showSnackBar('Erro ao atualizar status. Tente novamente.', Colors.red, Icons.error);
      }
    } catch (e) {
      debugPrint('Erro ao atualizar status: $e');
      if (mounted) {
        _showSnackBar('Erro ao atualizar status. Tente novamente.', Colors.red, Icons.error);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showRatingScreen(String deliveryId) async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RateCompanyScreen(
            deliveryId: deliveryId,
            companyName: _delivery['companyName'] ?? 'Empresa',
          ),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _checkMultipleStops() async {
    final dropoffAddress = _delivery['dropoffAddress'] ??
                          _delivery['dropoff_address'] ??
                          _delivery['deliveryAddress'] ??
                          _delivery['delivery_address'] ?? '';
    final hasMultipleStops = dropoffAddress.toString().contains(' | ');

    if (hasMultipleStops) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        final stopsCount = dropoffAddress.toString().split(' | ').length;
        final delivery = Delivery(
          requestId: _delivery['id']?.toString() ??
                     _delivery['_id']?.toString() ??
                     _delivery['deliveryId']?.toString() ??
                     _delivery['requestId']?.toString() ?? '',
          requestNumber: _delivery['requestNumber']?.toString() ?? '',
          companyName: _delivery['companyName'],
          customerName: _delivery['customerName'],
          customerWhatsapp: _delivery['customerWhatsapp'],
          deliveryReference: _delivery['deliveryReference'],
          pickupAddress: _delivery['pickupAddress'],
          pickupLat: _delivery['pickupLat'] != null ? double.tryParse(_delivery['pickupLat'].toString()) : null,
          pickupLng: _delivery['pickupLng'] != null ? double.tryParse(_delivery['pickupLng'].toString()) : null,
          deliveryAddress: dropoffAddress.toString(),
          deliveryLat: _delivery['deliveryLat'] != null ? double.tryParse(_delivery['deliveryLat'].toString()) : null,
          deliveryLng: _delivery['deliveryLng'] != null ? double.tryParse(_delivery['deliveryLng'].toString()) : null,
          distance: _delivery['distance']?.toString(),
          estimatedTime: _delivery['estimatedTime']?.toString(),
          driverAmount: _delivery['driverAmount']?.toString(),
          isTripStart: true,
          hasMultipleStops: true,
          stopsCount: stopsCount,
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => DeliveryWithStopsScreen(delivery: delivery)),
        );
      }
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'arrived': return 'Chegada marcada com sucesso!';
      case 'picked_up': return 'Retirada confirmada!';
      case 'delivered': return 'Entrega confirmada!';
      case 'completed': return 'Entrega concluida com sucesso!';
      default: return 'Status atualizado!';
    }
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erro ao abrir Google Maps: $e');
    }
  }

  Future<void> _openWaze(double lat, double lng) async {
    final url = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erro ao abrir Waze: $e');
    }
  }

  void _showMapOptions(double lat, double lng) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Abrir com',
                  style: GoogleFonts.notoSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.map, color: Colors.white),
                  ),
                  title: Text(
                    'Google Maps',
                    style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Navegacao pelo Google',
                    style: GoogleFonts.notoSans(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openGoogleMaps(lat, lng);
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFF33CCFF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.navigation, color: Colors.white),
                  ),
                  title: Text(
                    'Waze',
                    style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Navegacao com alertas de transito',
                    style: GoogleFonts.notoSans(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openWaze(lat, lng);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final whatsappUrl = Uri.parse('https://wa.me/$cleanNumber');
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erro ao abrir WhatsApp: $e');
    }
  }

  void _navigateToLocation({required bool isPickup}) {
    final lat = isPickup ? _delivery['pickupLat'] : _delivery['deliveryLat'];
    final lng = isPickup ? _delivery['pickupLng'] : _delivery['deliveryLng'];

    if (lat != null && lng != null) {
      _showMapOptions(
        lat is double ? lat : double.tryParse(lat.toString()) ?? 0.0,
        lng is double ? lng : double.tryParse(lng.toString()) ?? 0.0,
      );
    }
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Cancelar Entrega?'),
          ],
        ),
        content: const Text('Tem certeza que deseja cancelar esta entrega? Esta acao nao pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nao'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, false);
            },
            child: const Text('Sim, Cancelar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    final isPickupPhase = _currentStatus == 'accepted' || _currentStatus == 'arrived' || _currentStatus == 'returning';
    final companyName = (_delivery['companyName'] ?? 'Empresa').toString();
    final companyLogoUrl = (_delivery['companyLogoUrl'] ?? _delivery['company_logo_url'] ?? '').toString().trim();

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Stack(
        children: [
          // Fundo
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey.shade200,
          ),

          // Card principal com botao acima
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botao de navegacao acima do modal
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToLocation(isPickup: isPickupPhase),
                    icon: const Icon(Icons.map, color: Colors.white),
                    label: Text(
                      'Abrir Mapa',
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      elevation: 4,
                    ),
                  ),
                ),

                // Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Header com empresa/cliente
                      Padding(
                        padding: EdgeInsets.all(media.width * 0.045),
                        child: Row(
                          children: [
                            // Logo
                            Container(
                              width: media.width * 0.13,
                              height: media.width * 0.13,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: companyLogoUrl.isNotEmpty
                                  ? Image.network(
                                      companyLogoUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: SizedBox(
                                            width: media.width * 0.05,
                                            height: media.width * 0.05,
                                            child: const CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        );
                                      },
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          _getInitials(companyName),
                                          style: GoogleFonts.notoSans(
                                            fontSize: media.width * 0.055,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        _getInitials(companyName),
                                        style: GoogleFonts.notoSans(
                                          fontSize: media.width * 0.055,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                            ),
                            SizedBox(width: media.width * 0.03),
                            // Nome, rating e WhatsApp
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isPickupPhase ? companyName : (_delivery['customerName'] ?? 'Cliente'),
                                    style: GoogleFonts.notoSans(
                                      fontSize: media.width * 0.045,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.star, size: media.width * 0.035, color: const Color(0xFFFFD700)),
                                      const SizedBox(width: 3),
                                      Text(
                                        '5.00',
                                        style: GoogleFonts.notoSans(fontSize: media.width * 0.03, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // WhatsApp da empresa
                            if (_getPhoneNumber(isPickupPhase).isNotEmpty)
                              GestureDetector(
                                onTap: () => _openWhatsApp(_getPhoneNumber(isPickupPhase)),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF25D366),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.phone, color: Colors.white, size: media.width * 0.045),
                                      const SizedBox(width: 4),
                                      Text(
                                        'WhatsApp',
                                        style: GoogleFonts.notoSans(
                                          color: Colors.white,
                                          fontSize: media.width * 0.03,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            SizedBox(width: media.width * 0.02),
                            // Botao Cancelar
                            TextButton(
                              onPressed: _showCancelConfirmation,
                              child: Text(
                                'Cancelar',
                                style: GoogleFonts.notoSans(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: Colors.grey.shade200),
                      // Endereco
                      Padding(
                        padding: EdgeInsets.all(media.width * 0.045),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPickupPhase
                                  ? (_currentStatus == 'returning' ? 'Voltar para Retirada' : 'Local de Retirada')
                                  : 'Local de Entrega',
                              style: GoogleFonts.notoSans(
                                fontSize: media.width * 0.032,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: media.width * 0.02),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: media.width * 0.08,
                                  height: media.width * 0.08,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF9C27B0),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(Icons.location_on, color: Colors.white, size: media.width * 0.045),
                                ),
                                SizedBox(width: media.width * 0.03),
                                Expanded(
                                  child: Text(
                                    isPickupPhase
                                        ? _cleanAddress(_delivery['pickupAddress'] ?? '')
                                        : _cleanAddress(_delivery['deliveryAddress'] ?? _delivery['dropoffAddress'] ?? ''),
                                    style: GoogleFonts.notoSans(
                                      fontSize: media.width * 0.036,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Referencia (se houver e for entrega)
                            if (!isPickupPhase && (_delivery['deliveryReference'] ?? '').toString().isNotEmpty) ...[
                              SizedBox(height: media.width * 0.03),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: Color(0xFF9C27B0), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Ref: ${_delivery['deliveryReference']}',
                                        style: GoogleFonts.notoSans(
                                          fontSize: media.width * 0.032,
                                          color: const Color(0xFF9C27B0),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Aviso de retorno
                      if (_delivery['needsReturn'] == true || _delivery['needs_return'] == true)
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: media.width * 0.045),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF9C27B0), width: 2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber, color: Color(0xFF9C27B0)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Esta entrega possui volta',
                                  style: GoogleFonts.notoSans(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF9C27B0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: media.width * 0.03),
                      // Botao de acao
                      Padding(
                        padding: EdgeInsets.fromLTRB(media.width * 0.045, 0, media.width * 0.045, media.width * 0.06),
                        child: _buildActionButton(media),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Botao voltar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context, false),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPhoneNumber(bool isPickupPhase) {
    if (isPickupPhase) {
      return (_delivery['companyPhone'] ?? '').toString();
    }
    return (_delivery['customerWhatsapp'] ?? '').toString();
  }

  Widget _buildActionButton(Size media) {
    if (_isProcessing) {
      return const Center(child: CircularProgressIndicator());
    }

    final deliveryId = _delivery['requestId'] ?? _delivery['deliveryId'] ?? '';
    String buttonText;
    VoidCallback onPressed;

    switch (_currentStatus) {
      case 'accepted':
        buttonText = 'CHEGUEI';
        onPressed = () => _updateStatus('arrived', deliveryId);
        break;
      case 'arrived':
        buttonText = 'RETIREI O PEDIDO';
        onPressed = () => _updateStatus('picked_up', deliveryId);
        break;
      case 'picked_up':
        buttonText = 'ENTREGUEI';
        onPressed = () => _updateStatus('delivered', deliveryId);
        break;
      case 'delivered':
        buttonText = 'CONCLUIR ENTREGA';
        onPressed = () => _updateStatus('completed', deliveryId);
        break;
      case 'delivered_awaiting_return':
        buttonText = 'INICIAR RETORNO';
        onPressed = () => _updateStatus('start_return', deliveryId);
        break;
      case 'returning':
        buttonText = 'CHEGUEI DE VOLTA';
        onPressed = () => _updateStatus('complete_return', deliveryId);
        break;
      default:
        buttonText = 'CONTINUAR';
        onPressed = () {};
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9C27B0),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: media.width * 0.04),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(
          buttonText,
          style: GoogleFonts.notoSans(
            fontSize: media.width * 0.04,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

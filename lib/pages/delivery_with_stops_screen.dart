import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/delivery.dart';
import '../models/delivery_stop.dart';
import '../services/delivery_service.dart';
import '../styles/app_colors.dart';
import 'rate_company_screen.dart';

/// Tela para mostrar uma entrega com múltiplos stops
/// Design igual à tela de entrega única (ActiveDeliveryScreen)
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
  bool _isProcessing = false;
  int _currentStopIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStopsFromAPI();
  }

  Future<void> _loadStopsFromAPI() async {
    setState(() {
      _isLoading = true;
    });

    debugPrint('🔍 ===== CARREGANDO STOPS DO DELIVERY ADDRESS =====');
    debugPrint('🔍 deliveryId: ${widget.delivery.requestId}');
    debugPrint('🔍 deliveryAddress: ${widget.delivery.deliveryAddress}');

    _parseStopsFromAddressFallback();
  }

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

      final nameMatch = RegExp(r'^\[(.*?)\]').firstMatch(address);
      if (nameMatch != null) {
        customerName = nameMatch.group(1);
        address = address.replaceFirst(nameMatch.group(0)!, '').trim();
      }

      final whatsappMatch = RegExp(r'\[WhatsApp:\s*([^\]]+)\]').firstMatch(address);
      if (whatsappMatch != null) {
        customerWhatsapp = whatsappMatch.group(1)?.trim();
        address = address.replaceFirst(whatsappMatch.group(0)!, '').trim();
      }

      final refMatch = RegExp(r'\[Ref:\s*([^\]]+)\]').firstMatch(address);
      if (refMatch != null) {
        deliveryReference = refMatch.group(1)?.trim();
        address = address.replaceFirst(refMatch.group(0)!, '').trim();
      }

      address = address
          .replaceAll(RegExp(r',?\s*Brasil$', caseSensitive: false), '')
          .replaceAll(RegExp(r',?\s*SC\b', caseSensitive: false), '')
          .replaceAll(RegExp(r',?\s*Joaçaba\s*-?\s*', caseSensitive: false), '')
          .trim();

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
        status: i == 0 ? 'pending' : 'pending',
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
      // Encontrar o primeiro stop pendente
      _currentStopIndex = _stops.indexWhere((s) => s.status != 'completed');
      if (_currentStopIndex < 0) _currentStopIndex = 0;
    });

    debugPrint('✅ ${stops.length} stops criados do parsing do deliveryAddress');
  }

  DeliveryStop? get _currentStop {
    if (_stops.isEmpty || _currentStopIndex >= _stops.length) return null;
    return _stops[_currentStopIndex];
  }

  int get _completedCount => _stops.where((s) => s.status == 'completed').length;

  String _getInitials(String name) {
    if (name.isEmpty) return 'E!';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2 ? '${name[0].toUpperCase()}!' : name.toUpperCase();
  }

  Future<void> _openGoogleMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$encodedAddress&travelmode=driving');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erro ao abrir Google Maps: $e');
    }
  }

  Future<void> _openWaze(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url = Uri.parse('https://waze.com/ul?q=$encodedAddress&navigate=yes');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erro ao abrir Waze: $e');
    }
  }

  void _showMapOptions(String address) {
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
                    'Navegação pelo Google',
                    style: GoogleFonts.notoSans(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openGoogleMaps(address);
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
                    'Navegação com alertas de trânsito',
                    style: GoogleFonts.notoSans(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openWaze(address);
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

  Future<void> _handleDeliverCurrentStop() async {
    if (_isProcessing || _currentStop == null) return;

    setState(() => _isProcessing = true);

    try {
      debugPrint('📦 Marcando parada ${_currentStop!.stopOrder} como entregue...');

      final response = await DeliveryService.delivered(widget.delivery.requestId);

      if (response != null) {
        debugPrint('✅ Resposta da API: $response');

        final status = response['status'];
        final allStopsCompleted = response['allStopsCompleted'] ?? false;

        setState(() {
          _stops[_currentStopIndex] = _currentStop!.copyWith(
            status: 'completed',
            completedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        });

        if (allStopsCompleted && status == 'completed') {
          _showSnackBar('Todas as entregas concluídas!', Colors.green, Icons.check_circle);
          await _handleCompleteDelivery();
        } else {
          // Salvar número da parada concluída
          final completedStopNumber = _completedCount;

          // Mover para a próxima parada
          final nextIndex = _stops.indexWhere((s) => s.status != 'completed');
          if (nextIndex >= 0 && nextIndex < _stops.length) {
            setState(() {
              _currentStopIndex = nextIndex;
            });
            _showSnackBar(
              'Entrega $completedStopNumber concluída! Siga para a próxima.',
              Colors.green,
              Icons.check_circle,
            );
          } else {
            // Todas as paradas foram completadas
            await _handleCompleteDelivery();
          }
        }
      } else {
        _showSnackBar('Erro ao registrar entrega. Tente novamente.', Colors.red, Icons.error);
      }
    } catch (e) {
      debugPrint('❌ Erro ao completar parada: $e');
      _showSnackBar('Erro ao registrar entrega. Tente novamente.', Colors.red, Icons.error);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleCompleteDelivery() async {
    try {
      debugPrint('🎉 Finalizando entrega: ${widget.delivery.requestId}');

      final success = await DeliveryService.complete(widget.delivery.requestId);

      if (!mounted) return;

      if (success) {
        debugPrint('✅ Entrega finalizada com sucesso');

        _showSnackBar('Entrega finalizada com sucesso!', Colors.green, Icons.check_circle);

        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;

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

        Navigator.pop(context, true);
      } else {
        _showSnackBar('Erro ao finalizar entrega. Tente novamente.', Colors.red, Icons.error);
      }
    } catch (e) {
      debugPrint('❌ Erro ao finalizar entrega: $e');
      if (mounted) {
        _showSnackBar('Erro ao finalizar entrega. Tente novamente.', Colors.red, Icons.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade200,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_stops.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          title: Text(widget.delivery.requestNumber),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Nenhuma parada encontrada'),
        ),
      );
    }

    final currentStop = _currentStop;
    if (currentStop == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade200,
        body: const Center(
          child: Text('Todas as entregas concluídas!'),
        ),
      );
    }

    final companyName = widget.delivery.companyName ?? 'Empresa';
    final customerName = currentStop.customerName ?? 'Cliente';
    final address = currentStop.address;
    final reference = currentStop.deliveryReference;
    final whatsapp = currentStop.customerWhatsapp ?? '';

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

          // Card principal com botão acima
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botão de navegação acima do modal
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: () => _showMapOptions(address),
                    icon: const Icon(Icons.map, color: Colors.white),
                    label: Text(
                      'Abrir Mapa',
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
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
                        color: Colors.black.withOpacity(0.1),
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

                      // Indicador de progresso
                      Container(
                        margin: EdgeInsets.all(media.width * 0.045),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_shipping, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Entrega ${currentStop.stopOrder} de ${_stops.length}',
                              style: GoogleFonts.notoSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$_completedCount/${_stops.length}',
                                style: GoogleFonts.notoSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Header com empresa/cliente
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: media.width * 0.045),
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
                              child: Center(
                                child: Text(
                                  _getInitials(customerName),
                                  style: GoogleFonts.notoSans(
                                    fontSize: media.width * 0.055,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: media.width * 0.03),
                            // Nome e empresa
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customerName,
                                    style: GoogleFonts.notoSans(
                                      fontSize: media.width * 0.045,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    companyName,
                                    style: GoogleFonts.notoSans(
                                      fontSize: media.width * 0.03,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // WhatsApp
                            if (whatsapp.isNotEmpty)
                              GestureDetector(
                                onTap: () => _openWhatsApp(whatsapp),
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
                          ],
                        ),
                      ),
                      SizedBox(height: media.width * 0.03),
                      Divider(height: 1, color: Colors.grey.shade200),

                      // Endereço
                      Padding(
                        padding: EdgeInsets.all(media.width * 0.045),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Local de Entrega',
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
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(Icons.location_on, color: Colors.white, size: media.width * 0.045),
                                ),
                                SizedBox(width: media.width * 0.03),
                                Expanded(
                                  child: Text(
                                    address,
                                    style: GoogleFonts.notoSans(
                                      fontSize: media.width * 0.036,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Referência (se houver)
                            if (reference != null && reference.isNotEmpty) ...[
                              SizedBox(height: media.width * 0.03),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Ref: $reference',
                                        style: GoogleFonts.notoSans(
                                          fontSize: media.width * 0.032,
                                          color: AppColors.primary,
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

                      SizedBox(height: media.width * 0.03),

                      // Botão de ação
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

          // Botão voltar
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
                      color: Colors.black.withOpacity(0.1),
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

  Widget _buildActionButton(Size media) {
    if (_isProcessing) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleDeliverCurrentStop,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: media.width * 0.04),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(
          'ENTREGUEI',
          style: GoogleFonts.notoSans(
            fontSize: media.width * 0.04,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

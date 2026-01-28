import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../styles/styles.dart';
import '../services/delivery_service.dart';
import '../services/notification_service.dart';
import '../pages/active_delivery_screen.dart';

class DeliveryRequestDialog extends StatefulWidget {
  final Map<String, dynamic> data;

  const DeliveryRequestDialog({super.key, required this.data});

  @override
  State<DeliveryRequestDialog> createState() => _DeliveryRequestDialogState();
}

class _DeliveryRequestDialogState extends State<DeliveryRequestDialog> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  bool _isProcessing = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<String>? _cancelSubscription;
  StreamSubscription<Map<String, String>>? _takenSubscription;
  late final String? _requestId;
  late final int _initialSeconds;

  bool _hasMultipleStops() {
    final dropoffAddress = widget.data['dropoffAddress'] ?? '';
    return dropoffAddress.contains(' | ');
  }

  String _getFirstStopAddress() {
    final dropoffAddress = widget.data['dropoffAddress'] ?? '';
    String firstAddress;

    if (dropoffAddress.contains(' | ')) {
      firstAddress = dropoffAddress.split(' | ')[0];
    } else {
      firstAddress = dropoffAddress;
    }

    firstAddress = firstAddress.replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
    firstAddress = firstAddress.replaceAll(RegExp(r'\[WhatsApp:\s*[^\]]+\]\s*'), '');
    firstAddress = firstAddress.replaceAll(RegExp(r'\[Ref:\s*[^\]]+\]\s*'), '');
    firstAddress = firstAddress
        .replaceAll(RegExp(r',?\s*Brasil$', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*SC\b', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*Joaçaba\s*-?\s*', caseSensitive: false), '')
        .trim();

    final regex = RegExp(r'^\[.*?\]\s*');
    return firstAddress.replaceAll(regex, '');
  }

  int _getStopsCount() {
    final dropoffAddress = widget.data['dropoffAddress'] ?? '';
    if (dropoffAddress.contains(' | ')) {
      return dropoffAddress.split(' | ').length;
    }
    return 1;
  }

  @override
  void initState() {
    super.initState();
    debugPrint('===== MODAL DE ENTREGA ABERTO =====');
    debugPrint('Dados recebidos no modal: ${widget.data}');

    _requestId = _resolveRequestId(widget.data);
    final cancelledBeforeInit = _requestId != null &&
        NotificationService.consumePendingCancellation(_requestId);

    if (cancelledBeforeInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleDeliveryCancelled();
      });
      return;
    }

    _startCountdown();
    _startNotificationSound();
    _listenForCancellation();
    _listenForDeliveryTaken();
  }

  String? _resolveRequestId(Map<String, dynamic> data) {
    final candidates = [
      data['deliveryId'],
      data['delivery_id'],
      data['requestId'],
      data['request_id'],
      data['id'],
    ];

    for (final value in candidates) {
      if (value == null) continue;
      final parsed = value.toString();
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }
    return null;
  }

  void _listenForCancellation() {
    _cancelSubscription = NotificationService.onDeliveryCancelled.listen((cancelledRequestId) {
      final currentRequestId = _requestId;
      if (currentRequestId == null || cancelledRequestId == currentRequestId) {
        NotificationService.consumePendingCancellation(currentRequestId ?? '');
        _handleDeliveryCancelled();
      }
    });
  }

  void _listenForDeliveryTaken() {
    _takenSubscription = NotificationService.onDeliveryTaken.listen((data) {
      final takenRequestId = data['requestId'];
      final takenRequestNumber = data['requestNumber'];
      final currentRequestId = _requestId;

      if (currentRequestId == null || takenRequestId == currentRequestId) {
        _handleDeliveryTaken(takenRequestNumber);
      }
    });
  }

  void _handleDeliveryTaken(String? requestNumber) {
    _timer?.cancel();
    _audioPlayer.stop();

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('A entrega foi aceita por outro entregador')),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleDeliveryCancelled() {
    _timer?.cancel();
    _audioPlayer.stop();

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.cancel, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Esta entrega foi cancelada pela empresa')),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _startNotificationSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('audio/request_sound.mp3'));
    } catch (e) {
      debugPrint('Erro ao iniciar som de notificacao: $e');
    }
  }

  void _startCountdown() {
    try {
      final timeout = widget.data['acceptanceTimeout'];
      final timeoutSeconds = timeout is int ? timeout : int.tryParse(timeout?.toString() ?? '30') ?? 30;
      _initialSeconds = timeoutSeconds;
      _timeLeft = Duration(seconds: timeoutSeconds);

      if (_timeLeft.isNegative || _timeLeft.inSeconds == 0) {
        _timeLeft = Duration.zero;
        Future.microtask(() {
          if (mounted) Navigator.pop(context);
        });
        return;
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _timeLeft -= const Duration(seconds: 1);
          if (_timeLeft.isNegative || _timeLeft.inSeconds == 0) {
            timer.cancel();
            Navigator.pop(context);
          }
        });
      });
    } catch (e) {
      _initialSeconds = 30;
      _timeLeft = const Duration(seconds: 30);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _timeLeft -= const Duration(seconds: 1);
          if (_timeLeft.isNegative) {
            timer.cancel();
            Navigator.pop(context);
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cancelSubscription?.cancel();
    _takenSubscription?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
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

  String _getInitials(String name) {
    if (name.isEmpty) return 'E!';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2 ? '${name[0].toUpperCase()}!' : name.toUpperCase();
  }

  Future<void> _acceptDelivery() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final deliveryId = _requestId;
      if (deliveryId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nao foi possivel identificar esta entrega.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final result = await DeliveryService.acceptDelivery(deliveryId);
      if (!mounted) return;

      if (result != null) {
        if (result['error'] == 'expired') {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Esta entrega ja expirou'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        if (result['error'] == 'delivery_in_progress') {
          Navigator.pop(context);
          _showDeliveryInProgressDialog(result);
          return;
        }

        final updatedDelivery = await DeliveryService.getCurrentDelivery();
        if (mounted) {
          // Merge logo URL from notification data if not present in updatedDelivery
          final deliveryData = Map<String, dynamic>.from(updatedDelivery ?? result);
          final companyLogoUrl = widget.data['companyLogoUrl'] ?? widget.data['company_logo_url'];
          debugPrint('Logo URL da notificacao: $companyLogoUrl');
          if (companyLogoUrl != null && companyLogoUrl.toString().isNotEmpty) {
            deliveryData['companyLogoUrl'] = companyLogoUrl;
            deliveryData['company_logo_url'] = companyLogoUrl;
            debugPrint('Logo URL adicionada ao deliveryData: $companyLogoUrl');
          }

          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActiveDeliveryScreen(delivery: deliveryData),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('Entrega aceita!')),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao aceitar entrega.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao aceitar entrega.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showDeliveryInProgressDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.orange, size: 32),
            SizedBox(width: 8),
            Expanded(
              child: Text('Entrega em Andamento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Text(result['message'] ?? 'Voce ja possui uma entrega em andamento.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          if (result['activeDeliveryId'] != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
              onPressed: () async {
                Navigator.pop(context);
                final activeDelivery = await DeliveryService.getCurrentDelivery();
                if (activeDelivery != null && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ActiveDeliveryScreen(delivery: activeDelivery)),
                  );
                }
              },
              child: const Text('Ver Entrega Ativa', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Future<void> _rejectDelivery() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final deliveryId = _requestId;
      if (deliveryId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nao foi possivel identificar esta entrega.'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      await DeliveryService.rejectDelivery(deliveryId);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Fundo semi-transparente
          GestureDetector(
            onTap: () {},
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),

          // Conteudo principal
          Column(
            children: [
              const Spacer(),
              _buildTimerCircle(media),
              SizedBox(height: media.width * 0.04),
              _buildMainCard(media),
              SizedBox(height: media.width * 0.06),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCircle(Size media) {
    final circleSize = media.width * 0.22;
    final progress = _initialSeconds > 0 ? _timeLeft.inSeconds / _initialSeconds : 0.0;

    return Container(
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: circleSize - 8,
            height: circleSize - 8,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 5,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
            ),
          ),
          Text(
            '${_timeLeft.inSeconds}',
            style: GoogleFonts.notoSans(
              fontSize: media.width * 0.1,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF9C27B0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard(Size media) {
    final companyName = (widget.data['companyName'] ?? '').toString().trim();
    final displayName = companyName.isEmpty ? 'Empresa' : companyName;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: media.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          // Header
          Padding(
            padding: EdgeInsets.all(media.width * 0.045),
            child: _buildHeader(media, displayName),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // Indicador de múltiplas paradas
          if (_hasMultipleStops())
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: media.width * 0.025, horizontal: media.width * 0.045),
              color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.route,
                    color: const Color(0xFF9C27B0),
                    size: media.width * 0.05,
                  ),
                  SizedBox(width: media.width * 0.02),
                  Text(
                    '${_getStopsCount()} paradas',
                    style: GoogleFonts.notoSans(
                      fontSize: media.width * 0.038,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF9C27B0),
                    ),
                  ),
                ],
              ),
            ),

          // Enderecos
          Padding(
            padding: EdgeInsets.all(media.width * 0.045),
            child: Column(
              children: [
                _buildAddressItem(
                  media: media,
                  label: 'Retirada',
                  address: widget.data['pickupAddress'] ?? '',
                  isPickup: true,
                ),
                SizedBox(height: media.width * 0.04),
                _buildAddressItem(
                  media: media,
                  label: 'Entrega',
                  address: _getFirstStopAddress(),
                  isPickup: false,
                ),
              ],
            ),
          ),

          // Botoes
          Padding(
            padding: EdgeInsets.fromLTRB(media.width * 0.045, 0, media.width * 0.045, media.width * 0.045),
            child: _buildButtons(media),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Size media, String companyName) {
    final companyLogoUrl = (widget.data['companyLogoUrl'] ?? widget.data['company_logo_url'] ?? '').toString().trim();
    final hasLogo = companyLogoUrl.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo ou Avatar com iniciais
        Container(
          width: media.width * 0.13,
          height: media.width * 0.13,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasLogo
              ? Image.network(
                  companyLogoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        _getInitials(companyName),
                        style: GoogleFonts.notoSans(
                          fontSize: media.width * 0.055,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: media.width * 0.06,
                        height: media.width * 0.06,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black54,
                        ),
                      ),
                    );
                  },
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

        // Nome e rating
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                companyName,
                style: GoogleFonts.notoSans(
                  fontSize: media.width * 0.042,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.star, size: media.width * 0.035, color: const Color(0xFFFFD700)),
                  SizedBox(width: 3),
                  Text(
                    '5.00',
                    style: GoogleFonts.notoSans(fontSize: media.width * 0.03, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Valor e tempo/distancia
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'R\$ ${_formatCurrency(widget.data['estimatedAmount'])}',
              style: GoogleFonts.notoSans(
                fontSize: media.width * 0.042,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, size: media.width * 0.028, color: Colors.grey.shade400),
                SizedBox(width: 2),
                Text(
                  '${widget.data['estimatedTime'] ?? '0'} min(${widget.data['distance'] ?? '0'} km)',
                  style: GoogleFonts.notoSans(fontSize: media.width * 0.026, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressItem({
    required Size media,
    required String label,
    required String address,
    required bool isPickup,
  }) {
    final color = isPickup ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: media.width * 0.065,
          height: media.width * 0.065,
          decoration: BoxDecoration(
            color: color,
            borderRadius: isPickup ? BorderRadius.circular(6) : BorderRadius.circular(media.width * 0.0325),
          ),
          child: Center(
            child: isPickup
                ? Container(
                    width: media.width * 0.02,
                    height: media.width * 0.02,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  )
                : Icon(Icons.location_on, size: media.width * 0.038, color: Colors.white),
          ),
        ),
        SizedBox(width: media.width * 0.025),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.notoSans(
                  fontSize: media.width * 0.026,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 3),
              Text(
                address,
                style: GoogleFonts.notoSans(
                  fontSize: media.width * 0.032,
                  color: Colors.black87,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(Size media) {
    if (_isProcessing) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ElevatedButton(
            onPressed: _acceptDelivery,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: media.width * 0.038),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chevron_right, size: media.width * 0.05),
                Text(
                  'ACEITAR',
                  style: GoogleFonts.notoSans(fontSize: media.width * 0.035, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: media.width * 0.025),
        SizedBox(
          width: media.width * 0.22,
          child: OutlinedButton(
            onPressed: _rejectDelivery,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black54,
              padding: EdgeInsets.symmetric(vertical: media.width * 0.038),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Text(
              'Rejeitar',
              style: GoogleFonts.notoSans(fontSize: media.width * 0.035, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }
}

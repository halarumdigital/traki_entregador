import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/new_delivery_request.dart';

class NewDeliveryNotification extends StatefulWidget {
  final NewDeliveryRequest deliveryRequest;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const NewDeliveryNotification({
    super.key,
    required this.deliveryRequest,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<NewDeliveryNotification> createState() =>
      _NewDeliveryNotificationState();
}

class _NewDeliveryNotificationState extends State<NewDeliveryNotification>
    with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.deliveryRequest.timeoutSeconds;
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.deliveryRequest.timeoutSeconds),
    )..forward();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        widget.onReject();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
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
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),

          // Conteúdo principal
          Column(
            children: [
              const Spacer(),

              // Círculo do contador de tempo
              _buildTimerCircle(media),

              SizedBox(height: media.width * 0.04),

              // Card principal
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
    final progress = _remainingSeconds / widget.deliveryRequest.timeoutSeconds;

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
          // Progress indicator circular
          SizedBox(
            width: circleSize - 8,
            height: circleSize - 8,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 5,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF4CAF50),
              ),
            ),
          ),
          // Número do contador
          Text(
            '$_remainingSeconds',
            style: GoogleFonts.notoSans(
              fontSize: media.width * 0.1,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard(Size media) {
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
          // Header com informações do usuário/empresa
          Padding(
            padding: EdgeInsets.all(media.width * 0.045),
            child: _buildHeader(media),
          ),

          // Linha divisória
          Divider(height: 1, color: Colors.grey.shade200),

          // Endereços
          Padding(
            padding: EdgeInsets.all(media.width * 0.045),
            child: Column(
              children: [
                // Verified Pickup
                _buildAddressItem(
                  media: media,
                  label: 'Verified Pickup',
                  address: widget.deliveryRequest.pickupAddress,
                  isPickup: true,
                ),

                SizedBox(height: media.width * 0.04),

                // Verified Drop At
                _buildAddressItem(
                  media: media,
                  label: 'Verified Drop At',
                  address: widget.deliveryRequest.dropAddress,
                  isPickup: false,
                ),
              ],
            ),
          ),

          // Botões
          Padding(
            padding: EdgeInsets.fromLTRB(
              media.width * 0.045,
              0,
              media.width * 0.045,
              media.width * 0.045,
            ),
            child: _buildButtons(media),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Size media) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo/Avatar amarelo com iniciais
        Container(
          width: media.width * 0.13,
          height: media.width * 0.13,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              _getInitials(widget.deliveryRequest.companyName),
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
                widget.deliveryRequest.companyName,
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
                  Icon(
                    Icons.star,
                    size: media.width * 0.035,
                    color: const Color(0xFFFFD700),
                  ),
                  SizedBox(width: 3),
                  Text(
                    '5.00',
                    style: GoogleFonts.notoSans(
                      fontSize: media.width * 0.03,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Valor e tempo/distância
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              widget.deliveryRequest.formattedValue,
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
                Icon(
                  Icons.access_time,
                  size: media.width * 0.028,
                  color: Colors.grey.shade400,
                ),
                SizedBox(width: 2),
                Text(
                  '${widget.deliveryRequest.estimatedTime}(${widget.deliveryRequest.estimatedDistance})',
                  style: GoogleFonts.notoSans(
                    fontSize: media.width * 0.026,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2
        ? '${name[0]}!'
        : name.toUpperCase();
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
        // Ícone
        Container(
          width: media.width * 0.065,
          height: media.width * 0.065,
          decoration: BoxDecoration(
            color: color,
            borderRadius: isPickup
                ? BorderRadius.circular(6)
                : BorderRadius.circular(media.width * 0.0325),
          ),
          child: Center(
            child: isPickup
                ? Container(
                    width: media.width * 0.02,
                    height: media.width * 0.02,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  )
                : Icon(
                    Icons.location_on,
                    size: media.width * 0.038,
                    color: Colors.white,
                  ),
          ),
        ),

        SizedBox(width: media.width * 0.025),

        // Label e Endereço
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
    return Row(
      children: [
        // Botão Aceitar
        Expanded(
          flex: 3,
          child: ElevatedButton(
            onPressed: () {
              _timer?.cancel();
              widget.onAccept();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black87,
              padding: EdgeInsets.symmetric(vertical: media.width * 0.038),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chevron_right,
                  size: media.width * 0.05,
                ),
                Text(
                  'ACCEPT RIDE',
                  style: GoogleFonts.notoSans(
                    fontSize: media.width * 0.035,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(width: media.width * 0.025),

        // Botão Skip
        SizedBox(
          width: media.width * 0.22,
          child: OutlinedButton(
            onPressed: () {
              _timer?.cancel();
              widget.onReject();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black54,
              padding: EdgeInsets.symmetric(vertical: media.width * 0.038),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Text(
              'Skip',
              style: GoogleFonts.notoSans(
                fontSize: media.width * 0.035,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Função helper para mostrar a notificação como overlay
void showNewDeliveryNotification(
  BuildContext context, {
  required NewDeliveryRequest deliveryRequest,
  required Function() onAccept,
  required Function() onReject,
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: false,
      pageBuilder: (context, animation, secondaryAnimation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: NewDeliveryNotification(
            deliveryRequest: deliveryRequest,
            onAccept: () {
              Navigator.of(context).pop();
              onAccept();
            },
            onReject: () {
              Navigator.of(context).pop();
              onReject();
            },
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    ),
  );
}

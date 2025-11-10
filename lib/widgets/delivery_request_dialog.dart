import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../styles/styles.dart';
import '../services/delivery_service.dart';
import '../pages/active_delivery_screen.dart';

class DeliveryRequestDialog extends StatefulWidget {
  final Map<String, dynamic> data;

  const DeliveryRequestDialog({Key? key, required this.data}) : super(key: key);

  @override
  State<DeliveryRequestDialog> createState() => _DeliveryRequestDialogState();
}

class _DeliveryRequestDialogState extends State<DeliveryRequestDialog> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  bool _isProcessing = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _startNotificationSound();
  }

  Future<void> _startNotificationSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Tocar em loop
      await _audioPlayer.play(AssetSource('audio/request_sound.mp3'));
      debugPrint('🔊 Som de notificação iniciado em loop');
    } catch (e) {
      debugPrint('❌ Erro ao iniciar som de notificação: $e');
    }
  }

  void _startCountdown() {
    try {
      // Backend envia acceptanceTimeout em segundos, não expiresAt
      final timeout = widget.data['acceptanceTimeout'];
      final timeoutSeconds = timeout is int ? timeout : int.tryParse(timeout?.toString() ?? '30') ?? 30;
      _timeLeft = Duration(seconds: timeoutSeconds);

      if (_timeLeft.isNegative || _timeLeft.inSeconds == 0) {
        _timeLeft = Duration.zero;
        Future.microtask(() {
          if (mounted) {
            Navigator.pop(context);
          }
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
      debugPrint('❌ Erro ao iniciar countdown: $e');
      // Fallback para 30 segundos
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
    _audioPlayer.stop();
    _audioPlayer.dispose();
    debugPrint('🔇 Som de notificação parado');
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

  Future<void> _acceptDelivery() async {
    if (_isProcessing) {
      debugPrint('⚠️ Já está processando uma ação');
      return;
    }

    debugPrint('🔵 BOTÃO ACEITAR CLICADO');
    debugPrint('📋 DeliveryId: ${widget.data['deliveryId']}');
    debugPrint('📋 RequestId: ${widget.data['requestId']}');
    debugPrint('📋 Request Number: ${widget.data['requestNumber']}');
    debugPrint('📋 Dados completos: ${widget.data}');

    setState(() {
      _isProcessing = true;
    });

    try {
      // Para entregas relançadas, o backend envia 'requestId' ao invés de 'deliveryId'
      final deliveryId = widget.data['deliveryId'] ?? widget.data['requestId'];
      debugPrint('✅ Chamando DeliveryService.acceptDelivery com ID: $deliveryId');

      final result = await DeliveryService.acceptDelivery(
        deliveryId,
      );

      if (!mounted) return;

      if (result != null) {
        // Verificar se é erro de expiração
        if (result['error'] == 'expired') {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.timer_off, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Esta entrega já expirou e não está mais disponível'),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }

        debugPrint('✅ Entrega aceita! Buscando dados atualizados...');

        // Buscar dados atualizados do backend
        final updatedDelivery = await DeliveryService.getCurrentDelivery();

        if (!mounted) return;

        Navigator.pop(context);

        // Navigate to active delivery screen com dados atualizados
        if (updatedDelivery != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActiveDeliveryScreen(delivery: updatedDelivery),
            ),
          );
        } else {
          // Fallback: usar dados do accept se não conseguir buscar atualizados
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActiveDeliveryScreen(delivery: result),
            ),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Entrega aceita com sucesso!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao aceitar entrega. Tente novamente.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Erro ao aceitar entrega: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao aceitar entrega. Tente novamente.'),
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

  Future<void> _rejectDelivery() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint('❌ Rejeitando entrega: ${widget.data['deliveryId']}');

      final success = await DeliveryService.rejectDelivery(
        widget.data['deliveryId'],
      );

      if (!mounted) return;

      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrega rejeitada'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao rejeitar entrega: $e');
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: buttonColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.local_shipping,
              color: buttonColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Nova Entrega!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Empresa
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (widget.data['companyName'] ?? '').trim().isEmpty
                            ? 'Empresa'
                            : widget.data['companyName'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Endereços
              _buildAddressRow(
                Icons.place,
                Colors.green,
                'Retirada',
                widget.data['pickupAddress'] ?? '',
              ),
              const SizedBox(height: 8),
              _buildAddressRow(
                Icons.flag,
                Colors.red,
                'Entrega',
                widget.data['dropoffAddress'] ?? '',
              ),
              const SizedBox(height: 16),

              // Informações da entrega
              Row(
                children: [
                  Expanded(
                    child: _buildInfoBox(
                      Icons.straighten,
                      '${widget.data['distance'] ?? '0'} km',
                      'Distância',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoBox(
                      Icons.access_time,
                      '${widget.data['estimatedTime'] ?? '0'} min',
                      'Tempo',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Valor
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Center(
                  child: Text(
                    'R\$ ${_formatCurrency(widget.data['estimatedAmount'])}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Countdown
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _timeLeft.inSeconds <= 10
                      ? Colors.red.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _timeLeft.inSeconds <= 10 ? Colors.red : Colors.orange,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer,
                      color: _timeLeft.inSeconds <= 10 ? Colors.red : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tempo restante: ${_timeLeft.inSeconds}s',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _timeLeft.inSeconds <= 10 ? Colors.red : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_isProcessing)
          const Center(
            child: CircularProgressIndicator(),
          )
        else ...[
          TextButton(
            onPressed: _rejectDelivery,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Rejeitar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _acceptDelivery,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Aceitar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAddressRow(IconData icon, Color color, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: textColor.withOpacity(0.7), size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
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
}

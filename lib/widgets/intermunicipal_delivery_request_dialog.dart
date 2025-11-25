import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../styles/styles.dart';
import '../services/entregas_rota_service.dart';
import '../pages/NavigatorPages/viagem_ativa_screen.dart';

class IntermunicipalDeliveryRequestDialog extends StatefulWidget {
  final Map<String, dynamic> data;

  const IntermunicipalDeliveryRequestDialog({
    super.key,
    required this.data,
  });

  @override
  State<IntermunicipalDeliveryRequestDialog> createState() =>
      _IntermunicipalDeliveryRequestDialogState();
}

class _IntermunicipalDeliveryRequestDialogState
    extends State<IntermunicipalDeliveryRequestDialog> {
  Timer? _timer;
  Duration _timeLeft = const Duration(seconds: 60); // 60 segundos por padrão
  bool _isProcessing = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    debugPrint('🛣️ ===== MODAL DE ENTREGA INTERMUNICIPAL ABERTO =====');
    debugPrint('📦 Dados recebidos: ${widget.data}');

    _startCountdown();
    _startNotificationSound();
  }

  Future<void> _startNotificationSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('audio/request_sound.mp3'));
      debugPrint('🔊 Som de notificação iniciado');
    } catch (e) {
      debugPrint('❌ Erro ao iniciar som: $e');
    }
  }

  void _startCountdown() {
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
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _acceptDelivery() async {
    if (_isProcessing) return;

    final entregaId = widget.data['entregaId'] as String?;
    if (entregaId == null) {
      debugPrint('❌ EntregaId não encontrado');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: ID da entrega não encontrado'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint('✅ Aceitando entrega intermunicipal: $entregaId');
      final viagemId = await EntregasRotaService.aceitarEntrega(entregaId);

      debugPrint('📦 ViagemId recebido do backend: $viagemId');
      debugPrint('🔍 ViagemId é nulo? ${viagemId == null}');

      if (!mounted) {
        debugPrint('⚠️ Widget não está mais montado - abortando navegação');
        return;
      }

      if (viagemId != null) {
        debugPrint('🚪 Fechando modal...');
        Navigator.pop(context); // Fechar modal

        debugPrint('🧭 Navegando para ViagemAtivaScreen com viagemId: $viagemId');
        // Navegar para tela de viagem ativa
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViagemAtivaScreen(viagemId: viagemId),
          ),
        );

        debugPrint('✅ Navegação para ViagemAtivaScreen concluída');

        if (!mounted) {
          debugPrint('⚠️ Widget não está montado após navegação - pulando SnackBar');
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Entrega aceita! Inicie as coletas.'),
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
            content: Text('Erro ao aceitar entrega. Pode já ter sido aceita por outro motorista.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Erro ao aceitar entrega: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao aceitar entrega'),
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

    final entregaId = widget.data['entregaId'] as String?;
    if (entregaId == null) {
      debugPrint('❌ EntregaId não encontrado');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint('❌ Rejeitando entrega intermunicipal: $entregaId');
      await EntregasRotaService.rejeitarEntrega(entregaId);

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrega rejeitada'),
          backgroundColor: Colors.grey,
        ),
      );
    } catch (e) {
      debugPrint('❌ Erro ao rejeitar entrega: $e');
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rotaNome = widget.data['rotaNome'] ?? 'Rota Intermunicipal';
    final dataAgendada = widget.data['dataAgendada'] ?? '';
    final numeroParadas = widget.data['numeroParadas']?.toString();
    final empresaNome = widget.data['empresaNome'] ?? 'Empresa';
    final enderecoColeta = widget.data['enderecoColeta'] ?? '';
    final enderecoEntrega = widget.data['enderecoEntrega'] ?? '';

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.route,
              color: Colors.blue,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Nova Rota Disponível!',
              style: TextStyle(
                fontSize: 20,
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
              // Rota
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rota',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            rotaNome,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Empresa
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        empresaNome,
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

              // Data Agendada
              _buildInfoRow(
                Icons.calendar_today,
                Colors.orange,
                'Data Agendada',
                dataAgendada,
              ),
              const SizedBox(height: 12),

              // Número de Paradas (se tiver múltiplas)
              if (numeroParadas != null && int.tryParse(numeroParadas) != null && int.parse(numeroParadas) > 1)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                                children: [
                                  const TextSpan(text: 'Esta entrega possui '),
                                  TextSpan(
                                    text: '$numeroParadas endereços de entrega',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const TextSpan(text: ' diferentes'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              const SizedBox(height: 4),

              // Endereços
              _buildAddressRow(
                Icons.place,
                Colors.green,
                'Coleta',
                enderecoColeta,
              ),
              const SizedBox(height: 8),
              _buildAddressRow(
                Icons.flag,
                Colors.red,
                'Entrega',
                enderecoEntrega,
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
              'Recusar',
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

  Widget _buildInfoRow(IconData icon, Color color, String label, String value) {
    return Row(
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
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
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

  Widget _buildAddressRow(
      IconData icon, Color color, String label, String address) {
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
                address.isEmpty ? 'Não informado' : address,
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
}

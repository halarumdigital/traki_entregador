import 'dart:async';
import 'dart:math' as math;
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

  /// Mostrar o modal como bottom sheet
  static Future<void> show(BuildContext context, Map<String, dynamic> data) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => IntermunicipalDeliveryRequestDialog(data: data),
    );
  }
}

class _IntermunicipalDeliveryRequestDialogState
    extends State<IntermunicipalDeliveryRequestDialog> {
  Timer? _timer;
  int _secondsLeft = 60;
  bool _isProcessing = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Cor principal
  static const Color _primaryColor = Colors.purple;

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
        _secondsLeft -= 1;

        if (_secondsLeft <= 0) {
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

      if (!mounted) return;

      if (viagemId != null) {
        Navigator.pop(context);

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViagemAtivaScreen(viagemId: viagemId),
          ),
        );

        if (!mounted) return;

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
      Navigator.pop(context);
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
    final media = MediaQuery.of(context).size;

    final rotaNome = widget.data['rotaNome'] ?? 'Rota Intermunicipal';
    final dataAgendada = widget.data['dataAgendada'] ?? '';
    final numeroParadas = widget.data['numeroParadas']?.toString() ?? '1';
    final empresaNome = widget.data['empresaNome'] ?? 'Empresa';
    final enderecoColeta = widget.data['enderecoColeta'] ?? '';
    final empresaLogo = widget.data['empresaLogo'] ?? '';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: media.width * 0.03),
            width: media.width * 0.1,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(media.width * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Timer circular + Logo + Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo da empresa
                    Container(
                      width: media.width * 0.15,
                      height: media.width * 0.15,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: empresaLogo.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                empresaLogo,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.business,
                                  color: _primaryColor,
                                  size: media.width * 0.08,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.business,
                              color: _primaryColor,
                              size: media.width * 0.08,
                            ),
                    ),
                    SizedBox(width: media.width * 0.03),

                    // Info da empresa
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // NOVA ROTA DISPONÍVEL
                          Text(
                            'NOVA ROTA DISPONÍVEL',
                            style: TextStyle(
                              fontSize: media.width * 0.028,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: media.width * 0.01),
                          Text(
                            empresaNome,
                            style: TextStyle(
                              fontSize: media.width * 0.045,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Timer circular
                    _buildCircularTimer(media),
                  ],
                ),

                SizedBox(height: media.width * 0.04),

                // Rota
                Container(
                  padding: EdgeInsets.all(media.width * 0.03),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.route, color: _primaryColor, size: media.width * 0.05),
                      SizedBox(width: media.width * 0.025),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rota',
                              style: TextStyle(
                                fontSize: media.width * 0.03,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              rotaNome,
                              style: TextStyle(
                                fontSize: media.width * 0.038,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Número de paradas
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: media.width * 0.025,
                          vertical: media.width * 0.015,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$numeroParadas ${int.parse(numeroParadas) > 1 ? 'paradas' : 'parada'}',
                          style: TextStyle(
                            fontSize: media.width * 0.03,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: media.width * 0.03),

                // Data Agendada
                if (dataAgendada.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: media.width * 0.03),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(media.width * 0.02),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.calendar_today, color: Colors.orange, size: media.width * 0.045),
                        ),
                        SizedBox(width: media.width * 0.025),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data Agendada',
                              style: TextStyle(
                                fontSize: media.width * 0.03,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              dataAgendada,
                              style: TextStyle(
                                fontSize: media.width * 0.038,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Endereço de Retirada (Coleta)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(media.width * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.place, color: Colors.green, size: media.width * 0.045),
                    ),
                    SizedBox(width: media.width * 0.025),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Retirada',
                            style: TextStyle(
                              fontSize: media.width * 0.03,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            enderecoColeta.isEmpty ? 'Não informado' : enderecoColeta,
                            style: TextStyle(
                              fontSize: media.width * 0.035,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: media.width * 0.05),

                // Botões
                Row(
                  children: [
                    // Botão Aceitar
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _acceptDelivery,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          padding: EdgeInsets.symmetric(vertical: media.width * 0.04),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isProcessing
                            ? SizedBox(
                                height: media.width * 0.05,
                                width: media.width * 0.05,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chevron_right, color: Colors.white, size: media.width * 0.05),
                                  SizedBox(width: media.width * 0.01),
                                  Text(
                                    'ACEITAR',
                                    style: TextStyle(
                                      fontSize: media.width * 0.04,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(width: media.width * 0.03),
                    // Botão Rejeitar
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isProcessing ? null : _rejectDelivery,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: media.width * 0.04),
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Rejeitar',
                          style: TextStyle(
                            fontSize: media.width * 0.038,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: media.width * 0.03),

                // Texto do tempo restante
                Center(
                  child: Text(
                    'Tempo restante: ${_secondsLeft}s',
                    style: TextStyle(
                      fontSize: media.width * 0.032,
                      fontWeight: FontWeight.w500,
                      color: _secondsLeft <= 10 ? Colors.red : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularTimer(Size media) {
    final double progress = _secondsLeft / 60;
    final bool isLow = _secondsLeft <= 10;

    return SizedBox(
      width: media.width * 0.12,
      height: media.width * 0.12,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: media.width * 0.12,
            height: media.width * 0.12,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[300]!),
            ),
          ),
          // Progress circle
          SizedBox(
            width: media.width * 0.12,
            height: media.width * 0.12,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(
                isLow ? Colors.red : _primaryColor,
              ),
            ),
          ),
          // Timer text
          Text(
            '$_secondsLeft',
            style: TextStyle(
              fontSize: media.width * 0.04,
              fontWeight: FontWeight.bold,
              color: isLow ? Colors.red : _primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_driver/pages/login/approval_status_screen.dart';
import 'package:flutter_driver/pages/login/login.dart';
import 'package:flutter_driver/styles/styles.dart';
import 'package:flutter_driver/widgets/delivery_request_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/notification_service.dart';
import '../services/delivery_service.dart';

class NotificationHandler {
  // Flag para garantir que apenas um modal de entrega esteja aberto por vez
  static bool _isDeliveryDialogOpen = false;

  // Set para rastrear IDs de entregas que estão sendo processadas
  static final Set<String> _processingDeliveries = {};

  static void handleNotification(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final type = data['type'] as String?;

    debugPrint('🎯 Processando notificação do tipo: $type');
    debugPrint('📦 Dados: $data');

    switch (type) {
      case 'driver_approved':
        _handleDriverApproved(context, data);
        break;

      case 'driver_rejected':
        _handleDriverRejected(context, data);
        break;

      case 'document_approved':
        _handleDocumentApproved(context, data);
        break;

      case 'document_rejected':
        _handleDocumentRejected(context, data);
        break;

      case 'new_delivery':
      case 'new_delivery_request':
        _handleNewDeliveryRequest(context, data);
        break;

      case 'DELIVERY_CANCELLED':
      case 'delivery_cancelled':
        _handleDeliveryCancelled(context, data);
        break;

      default:
        debugPrint('⚠️ Tipo de notificação desconhecido: $type');
        _showGenericNotification(context, data);
    }
  }

  // Cadastro aprovado → Ir para login
  static void _handleDriverApproved(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.green, size: 32),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cadastro Aprovado!',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Text(
          'Parabéns! Seu cadastro foi aprovado pelo administrador.\n\n'
          'Agora você pode fazer login e começar a trabalhar como motorista.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => Login()),
                  (route) => false,
                );
              },
              child: Text(
                'Fazer Login',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Cadastro rejeitado → Mostrar mensagem
  static void _handleDriverRejected(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final rejectionReason = data['rejectionReason'] as String? ??
        'Entre em contato com o suporte para mais informações.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cadastro Rejeitado',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Text(
          'Infelizmente seu cadastro foi rejeitado.\n\n'
          'Motivo: $rejectionReason\n\n'
          'Entre em contato com o suporte para mais informações.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fechar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              // Tentar abrir WhatsApp do suporte
              final whatsappUrl = Uri.parse('https://wa.me/5549999999999'); // Substituir pelo número real
              if (await canLaunchUrl(whatsappUrl)) {
                await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
                  );
                }
              }
            },
            child: Text('Falar com Suporte', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Documento aprovado → Atualizar timeline
  static void _handleDocumentApproved(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final documentType = data['documentType'] as String? ?? 'Documento';
    final approvedCount = data['approvedCount']?.toString() ?? '0';
    final totalCount = data['totalCount']?.toString() ?? '0';
    final driverId = data['driverId'] as String?;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '$documentType aprovado! ($approvedCount/$totalCount)',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
        action: driverId != null
            ? SnackBarAction(
                label: 'Ver Status',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ApprovalStatusScreen(
                        driverId: driverId,
                      ),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }

  // Documento rejeitado → Ir para reenvio
  static void _handleDocumentRejected(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final documentType = data['documentType'] as String? ?? 'Documento';
    final rejectionReason = data['rejectionReason'] as String? ?? 'Não especificado';
    final driverId = data['driverId'] as String?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.orange, size: 32),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '$documentType Rejeitado',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Motivo da rejeição:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Text(
                rejectionReason,
                style: TextStyle(fontSize: 14),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Por favor, envie o documento novamente com as correções necessárias.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Depois', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              if (driverId != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ApprovalStatusScreen(
                      driverId: driverId,
                    ),
                  ),
                );
              }
            },
            child: Text(
              'Ver Status',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Extrair requestId dos dados
  static String? _extractRequestId(Map<String, dynamic> data) {
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

  // Nova solicitação de entrega → Mostrar modal
  static void _handleNewDeliveryRequest(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    debugPrint('🚚 ===== NOVA SOLICITAÇÃO DE ENTREGA =====');
    debugPrint('📦 Dados recebidos no notification_handler: $data');
    debugPrint('🔍 needs_return no handler: ${data['needs_return']}');
    debugPrint('🔍 needsReturn no handler: ${data['needsReturn']}');

    // Extrair requestId
    final requestId = _extractRequestId(data);
    if (requestId == null) {
      debugPrint('❌ RequestId não encontrado na notificação. Ignorando.');
      return;
    }

    // Verificar se já existe um modal aberto
    if (_isDeliveryDialogOpen) {
      debugPrint('⚠️ Modal de entrega já está aberto. Ignorando nova solicitação.');
      return;
    }

    // Verificar se esta entrega já está sendo processada
    if (_processingDeliveries.contains(requestId)) {
      debugPrint('⚠️ Entrega $requestId já está sendo processada. Ignorando duplicata.');
      return;
    }

    // Marcar como sendo processada
    _processingDeliveries.add(requestId);

    debugPrint('🚚 Mostrando modal de nova solicitação de entrega');
    _isDeliveryDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeliveryRequestDialog(data: data),
    ).then((_) {
      // Quando o modal fechar, marcar como disponível
      _isDeliveryDialogOpen = false;
      _processingDeliveries.remove(requestId);
      debugPrint('✅ Modal de entrega fechado');
    });
  }

  // Entrega cancelada pelo administrador → Voltar para home
  static void _handleDeliveryCancelled(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    debugPrint('🚫 Entrega cancelada pelo administrador');

    final requestId = data['requestId'] as String?;
    final message = data['message'] as String? ?? 'A entrega foi cancelada pelo administrador.';

    // Se houver um modal de nova entrega aberto, fechá-lo imediatamente
    if (_isDeliveryDialogOpen) {
      debugPrint('ℹ️ Fechando modal de solicitação antes de exibir alerta de cancelamento');
      Navigator.of(context, rootNavigator: true).maybePop();
      _isDeliveryDialogOpen = false;
      if (requestId != null) {
        NotificationService.consumePendingCancellation(requestId);
      }
    }

    // Mostrar alerta ao motorista
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Entrega Cancelada',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(fontSize: 16),
            ),
            if (requestId != null) ...[
              SizedBox(height: 12),
              Text(
                'ID da Entrega: $requestId',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Você está disponível para aceitar novas entregas.',
                      style: TextStyle(fontSize: 14, color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                Navigator.of(context).pop();

                // Voltar para a tela inicial (Home)
                // Remove todas as rotas até a home
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text(
                'Entendi',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Notificação genérica
  static void _showGenericNotification(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final title = data['title'] as String? ?? 'Notificação';
    final message = data['message'] as String? ?? 'Você recebeu uma nova notificação';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

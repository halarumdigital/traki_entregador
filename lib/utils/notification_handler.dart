import 'package:flutter/material.dart';
import 'package:flutter_driver/pages/login/approval_status_screen.dart';
import 'package:flutter_driver/pages/login/login.dart';
import 'package:flutter_driver/styles/styles.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationHandler {
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

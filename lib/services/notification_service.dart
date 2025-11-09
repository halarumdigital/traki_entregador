import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

// Handler para notificações em background
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Notificação em background: ${message.messageId}');
  debugPrint('Dados: ${message.data}');
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static String? _fcmToken;
  static Function(Map<String, dynamic>)? _onNotificationTap;
  static Function(Map<String, dynamic>)? _onMessageReceived;

  // Inicializar notificações
  static Future<void> initialize({
    Function(Map<String, dynamic>)? onNotificationTap,
    Function(Map<String, dynamic>)? onMessageReceived,
  }) async {
    _onNotificationTap = onNotificationTap;
    _onMessageReceived = onMessageReceived;

    debugPrint('🔔 Inicializando serviço de notificações...');

    // 1. Configurar handler de background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Solicitar permissões
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Permissão de notificações concedida');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('⚠️ Permissão provisória de notificações concedida');
    } else {
      debugPrint('❌ Permissão de notificações negada');
      return;
    }

    // 3. Configurar notificações locais
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && _onNotificationTap != null) {
          debugPrint('👆 Notificação local tocada com payload: ${response.payload}');
          try {
            final data = jsonDecode(response.payload!);
            _onNotificationTap!(data);
          } catch (e) {
            debugPrint('❌ Erro ao decodificar payload: $e');
          }
        }
      },
    );

    // 4. Criar canal de notificação (Android)
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificações Importantes',
      description: 'Canal para notificações importantes do app',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    debugPrint('📢 Canal de notificação Android criado');

    // 5. Obter FCM Token
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM Token obtido: $_fcmToken');
    } catch (e) {
      debugPrint('❌ Erro ao obter FCM Token: $e');
    }

    // 6. Listener para quando o token muda
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 Token FCM atualizado: $newToken');
      _fcmToken = newToken;
      // TODO: Enviar novo token para o servidor se usuário estiver logado
    });

    // 7. Handler quando app está em foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 8. Handler quando usuário toca na notificação (app em background/fechado)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 9. Verificar se o app foi aberto por uma notificação
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🚀 App aberto por notificação');
      _handleNotificationTap(initialMessage);
    }

    debugPrint('✅ Serviço de notificações inicializado com sucesso');
  }

  // Obter token FCM
  static String? get fcmToken => _fcmToken;

  // Handler: App em foreground
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📨 ===== NOTIFICAÇÃO RECEBIDA (FOREGROUND) =====');
    debugPrint('ID: ${message.messageId}');
    debugPrint('Título: ${message.notification?.title}');
    debugPrint('Corpo: ${message.notification?.body}');
    debugPrint('Dados: ${message.data}');

    // Sempre mostrar notificação local (para aparecer na barra de notificações)
    await _showLocalNotification(message);

    // Se for notificação de entrega, processar imediatamente
    if (message.data['type'] == 'new_delivery' || message.data['type'] == 'new_delivery_request') {
      debugPrint('🚚 Notificação de entrega detectada - processando imediatamente');
      if (_onMessageReceived != null) {
        _onMessageReceived!(message.data);
      }
    }
  }

  // Handler: Usuário toca na notificação
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 ===== NOTIFICAÇÃO TOCADA =====');
    debugPrint('ID: ${message.messageId}');
    debugPrint('Dados: ${message.data}');

    if (_onNotificationTap != null) {
      _onNotificationTap!(message.data);
    }
  }

  // Mostrar notificação local
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    // Para mensagens data-only, pegar título e corpo do campo data
    String? title;
    String? body;

    if (notification != null) {
      title = notification.title;
      body = notification.body;
    } else if (message.data.isNotEmpty) {
      // Usar dados do campo data
      title = message.data['title'] as String?;
      body = message.data['body'] as String?;
    }

    if (title == null || body == null) {
      debugPrint('⚠️ Notificação sem título ou corpo');
      return;
    }

    // Para notificações de entrega, usar som insistente e vibração contínua
    final isDeliveryNotification = message.data['type'] == 'new_delivery' ||
                                     message.data['type'] == 'new_delivery_request';

    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Notificações Importantes',
      channelDescription: 'Canal para notificações importantes',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      // Using default notification sound instead of custom sound
      enableVibration: true,
      vibrationPattern: isDeliveryNotification
          ? Int64List.fromList([0, 1000, 500, 1000, 500, 1000, 500, 1000]) // Vibra repetidamente
          : null,
      category: AndroidNotificationCategory.call, // Categoria de chamada para mais atenção
      fullScreenIntent: isDeliveryNotification, // Mostrar em tela cheia
      ongoing: isDeliveryNotification, // Não pode ser descartada facilmente
      autoCancel: !isDeliveryNotification, // Não auto-cancelar entregas
      timeoutAfter: isDeliveryNotification
          ? (message.data['acceptanceTimeout'] != null
              ? int.tryParse(message.data['acceptanceTimeout'].toString())! * 1000
              : 60000)
          : null,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(2147483647), // ID dentro do range de 32-bit
      title,
      body,
      notificationDetails,
      payload: jsonEncode(message.data),
    );

    debugPrint('🔔 Notificação local exibida: $title');
  }

  // Cancelar todas as notificações
  static Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
    debugPrint('🗑️ Todas as notificações canceladas');
  }

  // Obter contagem de notificações pendentes
  static Future<int> getPendingNotificationCount() async {
    final pendingNotifications =
        await _localNotifications.pendingNotificationRequests();
    return pendingNotifications.length;
  }
}

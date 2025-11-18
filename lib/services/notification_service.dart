import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// Handler para notificações em background
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 ===== NOTIFICAÇÃO EM BACKGROUND/LOCKED =====');
  debugPrint('ID: ${message.messageId}');
  debugPrint('Notification payload: ${message.notification != null ? "Sim (title: ${message.notification!.title})" : "Não - apenas data"}');
  debugPrint('Dados: ${message.data}');

  // Para mensagens data-only (sem payload notification), Firebase NÃO cria notificação automaticamente
  // Precisamos criar uma notificação local explicitamente

  // Obter título e corpo dos dados
  final title = message.data['title'] as String?;
  final body = message.data['body'] as String?;

  if (title != null && body != null) {
    // Criar instância do plugin de notificações locais
    final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

    // Verificar se é notificação de entrega
    final isDeliveryNotification = message.data['type'] == 'new_delivery' ||
                                     message.data['type'] == 'new_delivery_request';

    // 🔥 ARMAZENAR DADOS DA NOTIFICAÇÃO EM ARQUIVO PARA PROCESSAR AO DESBLOQUEAR
    // Usando arquivo ao invés de SharedPreferences porque o handler roda em isolado separado
    if (isDeliveryNotification) {
      try {
        // Usar path direto para evitar overhead - background handler precisa ser rápido
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/pending_delivery_notification.json');
        await file.writeAsString(jsonEncode(message.data));
        debugPrint('💾 Notificação de entrega armazenada em arquivo para processar ao desbloquear');
      } catch (e) {
        debugPrint('❌ Erro ao armazenar notificação em arquivo: $e');
      }
    }

    final androidDetails = isDeliveryNotification
        ? AndroidNotificationDetails(
            'delivery_requests_channel',
            'Solicitações de Entrega',
            channelDescription: 'Notificações de novas solicitações de entrega',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            sound: RawResourceAndroidNotificationSound('request_sound'),
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
            category: AndroidNotificationCategory.call,
            fullScreenIntent: true,
            ongoing: true,
            autoCancel: false,
            visibility: NotificationVisibility.public,
            channelShowBadge: true,
            enableLights: true,
            ledColor: Color.fromARGB(255, 255, 0, 0),
            ledOnMs: 1000,
            ledOffMs: 500,
            timeoutAfter: message.data['acceptanceTimeout'] != null
                ? int.tryParse(message.data['acceptanceTimeout'].toString())! * 1000
                : 120000,
          )
        : AndroidNotificationDetails(
            'high_importance_channel',
            'Notificações Importantes',
            channelDescription: 'Canal para notificações importantes',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
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

    // Criar notificação com payload contendo os dados da mensagem
    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title,
      body,
      notificationDetails,
      payload: jsonEncode(message.data),
    );

    debugPrint('🔔 Notificação local criada em background: $title');
  } else {
    debugPrint('⚠️ Mensagem sem título/corpo - notificação não criada');
  }
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static String? _fcmToken;
  static Function(Map<String, dynamic>)? _onNotificationTap;
  static Function(Map<String, dynamic>)? _onMessageReceived;

  // Cache do path do arquivo de notificações para evitar chamadas lentas a getApplicationDocumentsDirectory()
  static String? _cachedNotificationFilePath;

  // StreamController para eventos de cancelamento de entregas
  static final _deliveryCancelledController = StreamController<String>.broadcast();

  // Stream pública para ouvir eventos de cancelamento
  static Stream<String> get onDeliveryCancelled => _deliveryCancelledController.stream;

  // StreamController para eventos de entrega aceita por outro motorista
  static final _deliveryTakenController = StreamController<Map<String, String>>.broadcast();

  // Stream pública para ouvir eventos de entrega aceita
  static Stream<Map<String, String>> get onDeliveryTaken => _deliveryTakenController.stream;

  // Guarda IDs de notificações locais associadas às entregas
  static final Map<String, int> _deliveryNotificationIds = {};
  static final Set<String> _pendingCancelledRequests = <String>{};

  static String? _extractRequestId(Map<String, dynamic> data) {
    const candidateKeys = [
      'requestId',
      'request_id',
      'deliveryId',
      'delivery_id',
      'id',
    ];

    for (final key in candidateKeys) {
      final value = data[key];
      if (value == null) continue;
      final parsed = value.toString();
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }
    return null;
  }

  static Future<void> _cancelDeliveryNotification(String requestId) async {
    try {
      final cachedId = _deliveryNotificationIds.remove(requestId);
      if (cachedId != null) {
        await _localNotifications.cancel(cachedId);
        debugPrint('�Y"" Notifica��o local vinculada ao requestId $requestId cancelada (cache)');
        return;
      }

      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final activeNotifications = await androidImplementation.getActiveNotifications();
        for (final activeNotification in activeNotifications) {
          final payload = activeNotification.payload;
          if (payload == null) continue;
          try {
            final payloadData = Map<String, dynamic>.from(jsonDecode(payload));
            final payloadRequestId = _extractRequestId(payloadData);
            if (payloadRequestId == requestId) {
              await androidImplementation.cancel(activeNotification.id ?? 0);
              debugPrint('�Y"" Notifica��o ativa removida do sistema para requestId $requestId');
              return;
            }
          } catch (e) {
            debugPrint('�?O Erro ao analisar payload da notifica��o ativa: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('�?O Nǜo foi poss��vel cancelar a notifica��o da entrega $requestId: $e');
    }
  }

  static Future<void> _clearPendingDeliveryNotification({String? requestId}) async {
    try {
      final filePath = await _getNotificationFilePath();
      final file = File(filePath);
      if (!await file.exists()) {
        return;
      }

      if (requestId == null) {
        await file.delete();
        debugPrint('�Y"� Notifica��o pendente removida (requestId desconhecido).');
        return;
      }

      final rawContent = await file.readAsString();
      final data = jsonDecode(rawContent);
      if (data is Map<String, dynamic>) {
        final storedRequestId = _extractRequestId(Map<String, dynamic>.from(data));
        if (storedRequestId == null || storedRequestId == requestId) {
          await file.delete();
          debugPrint('�Y"� Notifica��o pendente removida para requestId $requestId');
        } else {
          debugPrint(
              '�s���? Arquivo pendente encontrado mas pertencente a outro requestId ($storedRequestId)');
        }
      } else {
        await file.delete();
        debugPrint('�YZ� Conte��do inesperado no arquivo pendente. Arquivo removido.');
      }
    } catch (e) {
      debugPrint('�?O Erro ao limpar arquivo de notifica��o pendente: $e');
    }
  }

  static bool consumePendingCancellation(String requestId) {
    return _pendingCancelledRequests.remove(requestId);
  }

  // Método helper para obter o path do arquivo de notificações (com cache)
  static Future<String> _getNotificationFilePath() async {
    if (_cachedNotificationFilePath != null) {
      return _cachedNotificationFilePath!;
    }

    final directory = await getApplicationDocumentsDirectory();
    _cachedNotificationFilePath = '${directory.path}/pending_delivery_notification.json';
    return _cachedNotificationFilePath!;
  }

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
        if (response.payload != null) {
          debugPrint('👆 Notificação local tocada com payload: ${response.payload}');
          try {
            final data = jsonDecode(response.payload!);

            // Chamar onNotificationTap
            if (_onNotificationTap != null) {
              _onNotificationTap!(data);
            }

            // Se for notificação de entrega, processar também pelo onMessageReceived
            final notificationType = data['type'] as String?;
            if ((notificationType == 'new_delivery' || notificationType == 'new_delivery_request')
                && _onMessageReceived != null) {
              debugPrint('🚚 Processando entrega tocada via onMessageReceived');
              _onMessageReceived!(data);
            }
          } catch (e) {
            debugPrint('❌ Erro ao decodificar payload: $e');
          }
        }
      },
    );

    // 4. Criar canais de notificação (Android)

    // Canal principal para notificações gerais
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificações Importantes',
      description: 'Canal para notificações importantes do app',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Canal específico para entregas - com som customizado e prioridade máxima
    const deliveryChannel = AndroidNotificationChannel(
      'delivery_requests_channel',
      'Solicitações de Entrega',
      description: 'Notificações de novas solicitações de entrega',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('request_sound'),
      enableVibration: true,
      enableLights: true,
      ledColor: Color.fromARGB(255, 255, 0, 0),
    );

    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(androidChannel);
    await androidImplementation?.createNotificationChannel(deliveryChannel);

    debugPrint('📢 Canais de notificação Android criados');

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

    // 9. Verificar se o app foi aberto por uma notificação Firebase
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🚀 App aberto por notificação Firebase');
      _handleNotificationTap(initialMessage);
    }

    // 10. Verificar se o app foi aberto por uma notificação LOCAL
    final notificationAppLaunchDetails =
        await _localNotifications.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp == true) {
      debugPrint('🚀 App aberto por notificação LOCAL');
      final payload = notificationAppLaunchDetails!.notificationResponse?.payload;
      if (payload != null && _onNotificationTap != null) {
        debugPrint('📲 Processando payload da notificação local: $payload');
        try {
          final data = jsonDecode(payload);
          _onNotificationTap!(data);

          // Se for notificação de entrega, processar também pelo onMessageReceived
          final notificationType = data['type'] as String?;
          if ((notificationType == 'new_delivery' || notificationType == 'new_delivery_request')
              && _onMessageReceived != null) {
            debugPrint('🚚 Processando entrega via onMessageReceived');
            _onMessageReceived!(data);
          }
        } catch (e) {
          debugPrint('❌ Erro ao decodificar payload da notificação local: $e');
        }
      }
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

    final notificationData = Map<String, dynamic>.from(message.data);
    final notificationType = notificationData['type'] as String?;

    // Se for notificação de entrega, processar imediatamente
    if (notificationType == 'new_delivery' || notificationType == 'new_delivery_request') {
      debugPrint('🚚 Notificação de entrega detectada - processando imediatamente');

      // Sempre mostrar notificação local (para aparecer na barra de notificações)
      await _showLocalNotification(message);

      if (_onMessageReceived != null) {
        _onMessageReceived!(message.data);
      }
    }
    // Se for notificação de cancelamento de entrega
    else if (notificationType == 'DELIVERY_CANCELLED' || notificationType == 'delivery_cancelled') {
      debugPrint('🚫 ===== ENTREGA CANCELADA =====');
      debugPrint('RequestId: ${notificationData['requestId'] ?? notificationData['request_id']}');
      debugPrint('Mensagem: ${notificationData['message']}');

      // Emitir evento para fechar modal
      final requestId = _extractRequestId(notificationData);
      if (requestId != null) {
        _deliveryCancelledController.add(requestId);
        debugPrint('✅ Evento de cancelamento emitido para requestId: $requestId');
        _pendingCancelledRequests.add(requestId);
        await _cancelDeliveryNotification(requestId);
        await _clearPendingDeliveryNotification(requestId: requestId);
      } else {
        debugPrint('⚠️ RequestId não encontrado na notificação de cancelamento.');
      }

      // Mostrar notificação local informando o cancelamento
      await _showLocalNotification(message);
      if (_onMessageReceived != null) {
        debugPrint('📢 Encaminhando cancelamento para NotificationHandler');
        _onMessageReceived!(notificationData);
      }
    }
    // Se for notificação de entrega aceita por outro motorista
    else if (notificationType == 'delivery_taken' || notificationType == 'DELIVERY_TAKEN') {
      debugPrint('✅ ===== ENTREGA ACEITA POR OUTRO MOTORISTA =====');
      debugPrint('RequestId: ${notificationData['requestId'] ?? notificationData['request_id']}');
      debugPrint('RequestNumber: ${notificationData['requestNumber']}');
      debugPrint('Mensagem: ${notificationData['message']}');

      final requestId = _extractRequestId(notificationData);
      final requestNumber = notificationData['requestNumber']?.toString() ??
                           notificationData['request_number']?.toString() ??
                           'N/A';

      if (requestId != null) {
        // Emitir evento para fechar modal
        _deliveryTakenController.add({
          'requestId': requestId,
          'requestNumber': requestNumber,
        });
        debugPrint('✅ Evento de entrega aceita emitido para requestId: $requestId');

        // Cancelar notificação local se existir
        await _cancelDeliveryNotification(requestId);
        await _clearPendingDeliveryNotification(requestId: requestId);
      } else {
        debugPrint('⚠️ RequestId não encontrado na notificação de entrega aceita.');
      }

      // Não precisa mostrar notificação local nem encaminhar para handler
      // O modal fecha automaticamente e mostra um snackbar
    }
    // Para outros tipos de notificação
    else {
      await _showLocalNotification(message);
    }
  }

  // Handler: Usuário toca na notificação
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 ===== NOTIFICAÇÃO TOCADA =====');
    debugPrint('ID: ${message.messageId}');
    debugPrint('Dados: ${message.data}');

    if (_onNotificationTap != null) {
      debugPrint('📲 Chamando callback onNotificationTap com dados: ${message.data}');
      _onNotificationTap!(message.data);
    } else {
      debugPrint('⚠️ Callback onNotificationTap é null!');
    }

    // Se for notificação de entrega e temos onMessageReceived, processar também
    final notificationType = message.data['type'] as String?;
    if ((notificationType == 'new_delivery' || notificationType == 'new_delivery_request')
        && _onMessageReceived != null) {
      debugPrint('🚚 Processando entrega via onMessageReceived também');
      _onMessageReceived!(message.data);
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

    final androidDetails = isDeliveryNotification
        ? AndroidNotificationDetails(
            'delivery_requests_channel',
            'Solicitações de Entrega',
            channelDescription: 'Notificações de novas solicitações de entrega',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            sound: RawResourceAndroidNotificationSound('request_sound'),
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]), // Vibra repetidamente
            category: AndroidNotificationCategory.call, // Categoria de chamada para mais atenção
            fullScreenIntent: true, // Mostrar em tela cheia mesmo com celular bloqueado
            ongoing: true, // Não pode ser descartada facilmente
            autoCancel: false, // Não auto-cancelar
            visibility: NotificationVisibility.public, // Mostrar na tela de bloqueio
            channelShowBadge: true,
            enableLights: true,
            ledColor: Color.fromARGB(255, 255, 0, 0),
            ledOnMs: 1000,
            ledOffMs: 500,
            timeoutAfter: message.data['acceptanceTimeout'] != null
                ? int.tryParse(message.data['acceptanceTimeout'].toString())! * 1000
                : 120000, // 2 minutos padrão
          )
        : AndroidNotificationDetails(
            'high_importance_channel',
            'Notificações Importantes',
            channelDescription: 'Canal para notificações importantes',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
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

    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

    await _localNotifications.show(
      notificationId, // ID dentro do range de 32-bit
      title,
      body,
      notificationDetails,
      payload: jsonEncode(message.data),
    );

    final notificationType = message.data['type'] as String?;
    if (notificationType == 'new_delivery' || notificationType == 'new_delivery_request') {
      final requestId = _extractRequestId(Map<String, dynamic>.from(message.data));
      if (requestId != null) {
        _deliveryNotificationIds[requestId] = notificationId;
        debugPrint('?Y"? Vinculando notifica??o local $notificationId ao requestId $requestId');
      }
    }

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

  // Obter notificação de entrega pendente armazenada quando telefone estava bloqueado
  static Future<Map<String, dynamic>?> getPendingDeliveryNotification() async {
    try {
      // Usar método com cache para evitar chamadas lentas a getApplicationDocumentsDirectory()
      final filePath = await _getNotificationFilePath();
      final file = File(filePath);

      if (await file.exists()) {
        debugPrint('📦 Notificação de entrega pendente encontrada em arquivo');
        final notificationJson = await file.readAsString();
        final data = jsonDecode(notificationJson);

        // Limpar após recuperar
        await file.delete();
        debugPrint('🗑️ Notificação pendente removida do arquivo');

        return data;
      } else {
        debugPrint('📭 Nenhuma notificação de entrega pendente em arquivo');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erro ao recuperar notificação pendente de arquivo: $e');
      return null;
    }
  }

  // Obter notificações ativas (exibidas na barra de notificação)
  static Future<List<Map<String, dynamic>>> getActiveNotifications() async {
    try {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final activeNotifications = await androidImplementation.getActiveNotifications();

        debugPrint('🔎 Total de notificações ativas no sistema: ${activeNotifications.length}');

        List<Map<String, dynamic>> result = [];

        for (var notification in activeNotifications) {
          debugPrint('📋 Notificação ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}, Payload: ${notification.payload != null ? "Sim" : "Não"}');

          try {
            // O payload contém os dados JSON da notificação
            if (notification.payload != null && notification.payload!.isNotEmpty) {
              final data = jsonDecode(notification.payload!);
              result.add(data);
              debugPrint('✅ Notificação ativa decodificada com sucesso: ${data['type']}');
            } else {
              debugPrint('⚠️ Notificação sem payload ou payload vazio');
            }
          } catch (e) {
            debugPrint('❌ Erro ao decodificar payload da notificação ativa: $e');
          }
        }

        debugPrint('📊 Total de notificações ativas com payload válido: ${result.length}');
        return result;
      }

      debugPrint('⚠️ AndroidFlutterLocalNotificationsPlugin não disponível');
      return [];
    } catch (e) {
      debugPrint('❌ Erro ao obter notificações ativas: $e');
      return [];
    }
  }

  // Limpar recursos (chamar ao fechar o app)
  static void dispose() {
    _deliveryCancelledController.close();
    debugPrint('🗑️ NotificationService disposed');
  }
}

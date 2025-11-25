// import 'package:device_apps/device_apps.dart';
// import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:installed_apps/installed_apps.dart';
import 'package:quick_nav/quick_nav.dart';
import 'package:workmanager/workmanager.dart';
import 'functions/functions.dart';
import 'functions/notifications.dart';
import 'pages/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:bubble_head/bubble.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'utils/notification_handler.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'providers/delivery_stop_provider.dart';

// Variável global para armazenar notificação pendente
Map<String, dynamic>? pendingNotificationData;

// GlobalKey para acessar navigator de qualquer lugar
final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

// REMOVIDO: Handler de background agora está em notification_service.dart
// O Firebase usa o handler importado na linha 97

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Firebase.initializeApp();
      var position = await Geolocator.getCurrentPosition();

      // Enviar localização para o backend usando Bearer token
      await updateDriverLocation(position.latitude, position.longitude);

    } catch (e) {
      debugPrint('❌ Erro ao atualizar localização em background: $e');
    }

    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  await Firebase.initializeApp();

  // Inicializar serviço de notificações
  await NotificationService.initialize(
    onNotificationTap: (data) {
      // Armazenar notificação para processar depois que o app estiver pronto
      pendingNotificationData = data;
      debugPrint('🔔 Notificação pendente armazenada: $data');
    },
    onMessageReceived: (data) {
      // Processar notificação recebida em foreground IMEDIATAMENTE
      debugPrint('📨 Mensagem recebida em foreground: $data');

      final context = globalNavigatorKey.currentContext;
      if (context != null) {
        debugPrint('🎯 Processando notificação imediatamente com context disponível');
        NotificationHandler.handleNotification(context, data);
      } else {
        debugPrint('⚠️ Context não disponível, armazenando para processar depois');
        pendingNotificationData = data;
      }
    },
  );

  initMessaging();
  checkInternetConnection();

  currentPositionUpdate();

  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // final platforms = const MethodChannel('flutter.app/awake');
  // This widget is the root of your application.

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    Workmanager().cancelAll();
    if (Platform.isAndroid) {
      test();
    }

    // Processar notificação pendente após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pendingNotificationData != null) {
        final context = globalNavigatorKey.currentContext;
        if (context != null) {
          debugPrint('🔔 Processando notificação pendente');
          NotificationHandler.handleNotification(context, pendingNotificationData!);
          pendingNotificationData = null;
        }
      }
    });

    // Verificar notificações ativas ao retomar app
    _checkActiveNotificationsOnResume();

    super.initState();
  }

  // final Bubble _bubble =
  //     Bubble(showCloseButton: false, allowDragToClose: false);
  Future<void> startBubbleHead() async {
    try {
      // await _bubble.startBubbleHead(sendAppToBackground: false);
      bool? hasPermission = await QuickNav.I.checkPermission();
      if (hasPermission == false) {
        hasPermission = await QuickNav.I.askPermission();
      }
      if (hasPermission == true) {
        await QuickNav.I.startService();
      } else {
        debugPrint("Overlay permission not granted");
      }
    } on PlatformException {
      debugPrint('Failed to call startBubbleHead');
    }
  }

  Future<void> stopBubbleHead() async {
    try {
      // await _bubble.stopBubbleHead();
      await QuickNav.I.stopService();
    } on PlatformException {
      debugPrint('Failed to call stopBubbleHead');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      if (Platform.isAndroid &&
          userDetails.isNotEmpty &&
          userDetails['role'] == 'driver' &&
          userDetails['active'] == true) {
        updateLocation(10);
        test();
        if (await QuickNav.I.checkPermission() == true) {
          startBubbleHead();
        }
      } else {}
    }
    if (Platform.isAndroid && state == AppLifecycleState.resumed) {
      stopBubbleHead();
      Workmanager().cancelAll();

      // Verificar notificações ativas ao desbloquear
      _checkActiveNotificationsOnResume();
    }
  }

  Future<void> _checkActiveNotificationsOnResume() async {
    try {
      final startTime = DateTime.now();
      debugPrint('🔍 Verificando notificação de entrega pendente ao retomar app...');

      // Obter notificação de entrega pendente do arquivo
      final pendingNotification = await NotificationService.getPendingDeliveryNotification();

      final afterReadTime = DateTime.now();
      final readDuration = afterReadTime.difference(startTime).inMilliseconds;
      debugPrint('⏱️ Tempo de leitura do arquivo: ${readDuration}ms');

      if (pendingNotification != null) {
        debugPrint('🚚 Notificação de entrega pendente encontrada - abrindo modal');

        final context = globalNavigatorKey.currentContext;
        if (context != null && mounted) {
          // Abrir modal imediatamente - sem delay!
          final beforeHandleTime = DateTime.now();
          NotificationHandler.handleNotification(context, pendingNotification);
          final afterHandleTime = DateTime.now();
          final handleDuration = afterHandleTime.difference(beforeHandleTime).inMilliseconds;
          final totalDuration = afterHandleTime.difference(startTime).inMilliseconds;
          debugPrint('⏱️ Tempo de abertura do modal: ${handleDuration}ms');
          debugPrint('⏱️ Tempo total desde verificação: ${totalDuration}ms');
        }
      } else {
        debugPrint('📭 Nenhuma notificação de entrega pendente');
      }
    } catch (e) {
      debugPrint('❌ Erro ao verificar notificação pendente: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    platform = Theme.of(context).platform;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeliveryStopProvider()),
      ],
      child: GestureDetector(
          onTap: () {
            //remove keyboard on touching anywhere on the screen.
            FocusScopeNode currentFocus = FocusScope.of(context);

            if (!currentFocus.hasPrimaryFocus) {
              currentFocus.unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          child: MaterialApp(
            navigatorKey: globalNavigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'product name',
            theme: ThemeData(),
            home: const SplashScreen(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.0)),
                child: child!,
              );
            },
          )),
    );
  }
}

void updateLocation(duration) {
  for (var i = 0; i < 15; i++) {
    Workmanager().registerPeriodicTask('locs_$i', 'update_locs_$i',
        initialDelay: Duration(minutes: i),
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresDeviceIdle: false,
            requiresStorageNotLow: false),
        inputData: {'id': userDetails['id'].toString()});
  }
}

test() {
  QuickNav.I.initService(
      chatHeadIcon: '@drawable/logo',
      notificationIcon: "@drawable/logo",
      notificationCircleHexColor: 0xFFA432A7,
      screenHeight: 100);
}

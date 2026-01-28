import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/online_offline_toggle.dart';
import '../styles/styles.dart';
import '../styles/app_colors.dart';
import '../functions/functions.dart';
import '../services/local_storage_service.dart';
import '../services/delivery_service.dart';
import '../services/driver_block_service.dart';
import '../services/location_permission_service.dart';
import 'profile_details_screen.dart';
import 'active_delivery_screen.dart';
import 'delivery_with_stops_screen.dart';
import '../models/delivery.dart';
import 'NavigatorPages/promotions.dart';
import 'NavigatorPages/faq.dart';
import 'NavigatorPages/my_deliveries.dart';
import 'NavigatorPages/referral.dart';
import 'NavigatorPages/referral_companies.dart';
import 'NavigatorPages/support_tickets.dart';
import 'NavigatorPages/entregas_ativas.dart';
import 'NavigatorPages/minhas_rotas.dart';
import 'NavigatorPages/minhas_viagens.dart';
import 'NavigatorPages/carteira_page.dart';
import 'NavigatorPages/notification.dart';
import 'auth/login_screen_new.dart';
import '../services/driver_notification_service.dart';

class HomeSimple extends StatefulWidget {
  const HomeSimple({super.key});

  @override
  State<HomeSimple> createState() => _HomeSimpleState();
}

class _HomeSimpleState extends State<HomeSimple> with WidgetsBindingObserver {
  Map<String, dynamic>? _driverProfile;
  bool _isLoadingProfile = false;
  Timer? _locationTimer;
  Timer? _blockCheckTimer; // Timer para verificar bloqueio periodicamente
  Map<String, dynamic>? _currentDelivery;
  bool _isLoadingDelivery = false;
  Map<String, dynamic>? _commissionStats;
  bool _isLoadingStats = false;
  List<Map<String, dynamic>> _availableDeliveries = [];
  bool _isLoadingAvailableDeliveries = false;
  List<Map<String, dynamic>> _activeDeliveries = []; // NOVO: lista de entregas ativas
  Map<String, dynamic>? _balanceData; // NOVO: dados da carteira
  bool _isLoadingBalance = false; // NOVO: loading da carteira
  int _notificationCount = 0; // Contador de notificações novas
  DateTime? _lastNotificationCheck; // Última vez que viu notificações
  int _todayDeliveries = 0; // Entregas de hoje (zera à meia noite)
  List<Map<String, dynamic>> _promotions = []; // Promoções ativas

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDriverProfile();
    _loadCurrentDelivery();
    _loadCommissionStats();
    _loadAvailableDeliveries();
    _loadWalletBalance(); // NOVO: carregar saldo da carteira
    _loadNotificationCount(); // Carregar contador de notificações
    _loadTodayDeliveries(); // Carregar entregas de hoje
    _loadPromotions(); // Carregar promoções ativas
    _startLocationUpdates();
    _startBlockStatusCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationTimer?.cancel();
    _blockCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 App voltou para foreground - verificando permissões de localização');
      // Verificar permissões de localização quando o app volta para foreground
      _checkLocationPermissionOnResume();
    }
  }

  Future<void> _checkLocationPermissionOnResume() async {
    if (!mounted) return;

    // Verificar e solicitar permissões se necessário
    await LocationPermissionService.checkAndRequestLocationPermission(context);
  }

  void _startLocationUpdates() {
    // Atualizar localização a cada 30 segundos
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        // Obter posição atual
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Enviar para o backend
        await updateDriverLocation(position.latitude, position.longitude);
      } catch (e) {
        debugPrint('❌ Erro ao obter/enviar localização: $e');
      }
    });

    // Enviar localização imediatamente ao iniciar
    Future.delayed(Duration.zero, () async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await updateDriverLocation(position.latitude, position.longitude);
      } catch (e) {
        debugPrint('❌ Erro ao obter/enviar localização inicial: $e');
      }
    });
  }

  /// Inicia verificação periódica de status de bloqueio
  void _startBlockStatusCheck() {
    // Verificar imediatamente ao iniciar
    _checkBlockStatus();

    // Verificar a cada 5 minutos (300 segundos)
    _blockCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkBlockStatus();
    });
  }

  /// Verifica se o entregador está bloqueado
  Future<void> _checkBlockStatus() async {
    if (!mounted) return;

    debugPrint('🔍 [HomeSimple] Verificando status de bloqueio...');

    final isBlocked = await DriverBlockService.checkAndHandleBlock(context);

    if (isBlocked) {
      debugPrint('🚫 [HomeSimple] Entregador bloqueado - logout realizado');
      // O DriverBlockService já faz o logout e mostra o diálogo
    }
  }

  Future<void> _loadDriverProfile() async {
    debugPrint('🚀 INICIANDO _loadDriverProfile()');

    setState(() {
      _isLoadingProfile = true;
    });

    try {
      debugPrint('👤 Buscando perfil do motorista...');

      // Primeiro tentar carregar do LocalStorageService
      debugPrint('📂 Tentando carregar do LocalStorageService...');
      final cachedData = await LocalStorageService.getDriverData();
      debugPrint('📂 CachedData resultado: ${cachedData != null ? "ENCONTRADO" : "NULL"}');

      if (cachedData != null) {
        debugPrint('✅ Perfil carregado do cache local');
        debugPrint('📋 Dados completos do cache: $cachedData');
        setState(() {
          _driverProfile = cachedData;
        });
        debugPrint('👤 personalData do cache: ${_driverProfile?['personalData']}');
        debugPrint('👤 fullName do cache: ${_driverProfile?['personalData']?['fullName']}');
      } else {
        debugPrint('⚠️ Nenhum dado encontrado no cache local');
      }

      // Tentar atualizar da API
      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        setState(() {
          _isLoadingProfile = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${url}api/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📥 Status Code da API: ${response.statusCode}');
      debugPrint('📥 Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('📦 JSON parseado: $jsonResponse');
        debugPrint('📦 success: ${jsonResponse['success']}');
        debugPrint('📦 data: ${jsonResponse['data']}');

        if (jsonResponse['success'] == true) {
          setState(() {
            _driverProfile = jsonResponse['data'];
          });
          debugPrint('✅ Perfil atualizado da API');
          debugPrint('📋 Dados do perfil: ${jsonEncode(_driverProfile)}');
          debugPrint('👤 personalData: ${_driverProfile?['personalData']}');
          debugPrint('👤 fullName: ${_driverProfile?['personalData']?['fullName']}');

          // Salvar no cache local
          if (_driverProfile != null) {
            final token = await LocalStorageService.getAccessToken();
            final driverId = await LocalStorageService.getDriverId();
            if (token != null && driverId != null) {
              await LocalStorageService.saveDriverSession(
                driverId: driverId,
                accessToken: token,
                driverData: _driverProfile!,
              );
              debugPrint('💾 Perfil atualizado no cache local');
            }
          }
        } else {
          debugPrint('⚠️ API retornou success = false');
        }
      } else {
        debugPrint('❌ Erro ao carregar perfil da API: ${response.statusCode}');
        debugPrint('❌ Corpo do erro: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar perfil: $e');
    } finally {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _loadCurrentDelivery() async {
    setState(() {
      _isLoadingDelivery = true;
    });

    try {
      debugPrint('📦 ===== BUSCANDO ENTREGAS EM ANDAMENTO =====');

      // Buscar TODAS as entregas ativas
      final deliveries = await DeliveryService.getCurrentDeliveries();

      if (mounted) {
        setState(() {
          _activeDeliveries = deliveries;
          // Manter _currentDelivery para compatibilidade (primeira entrega)
          _currentDelivery = deliveries.isNotEmpty ? deliveries.first : null;
        });

        if (deliveries.isEmpty) {
          debugPrint('ℹ️ Nenhuma entrega em andamento');
        } else {
          debugPrint('✅ ${deliveries.length} entrega(s) ativa(s) carregada(s)');
          for (var i = 0; i < deliveries.length; i++) {
            debugPrint('   [$i] ${deliveries[i]['requestNumber']} - ${deliveries[i]['customerName']}');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar entregas em andamento: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDelivery = false;
        });
      }
    }
  }

  // NOVO: Carregar saldo da carteira
  Future<void> _loadWalletBalance() async {
    setState(() {
      _isLoadingBalance = true;
    });

    try {
      debugPrint('💰 Buscando saldo da carteira...');
      final balanceResponse = await getDriverBalance();

      if (mounted) {
        setState(() {
          // A API retorna { success: true, data: { ... } }
          if (balanceResponse != null && balanceResponse['success'] == true) {
            _balanceData = balanceResponse['data'] as Map<String, dynamic>?;
          } else {
            _balanceData = balanceResponse;
          }
          _isLoadingBalance = false;
        });

        if (_balanceData != null) {
          debugPrint('✅ Saldo carregado: ${_balanceData!['saldoDisponivel']}');
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar saldo: $e');
      if (mounted) {
        setState(() {
          _isLoadingBalance = false;
        });
      }
    }
  }

  Future<void> _loadNotificationCount() async {
    try {
      // Carregar última vez que viu notificações
      final prefs = await SharedPreferences.getInstance();
      final lastCheckMillis = prefs.getInt('lastNotificationCheck');
      if (lastCheckMillis != null) {
        _lastNotificationCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckMillis);
      }

      final response = await DriverNotificationService.getNotifications();
      if (mounted && response != null) {
        // Contar apenas notificações mais recentes que a última visualização
        int newCount = 0;
        if (_lastNotificationCheck != null) {
          for (var notification in response.notifications) {
            if (notification.createdAt.isAfter(_lastNotificationCheck!)) {
              newCount++;
            }
          }
        } else {
          // Se nunca viu, todas são novas
          newCount = response.count;
        }

        setState(() {
          _notificationCount = newCount;
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar contagem de notificações: $e');
    }
  }

  Future<void> _loadTodayDeliveries() async {
    try {
      debugPrint('📅 Buscando entregas de hoje via API...');

      // Obter data de hoje no formato YYYY-MM-DD (usando horário local)
      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      debugPrint('📅 Data de hoje (local): $today');
      debugPrint('📅 DateTime.now(): $now');

      // Buscar histórico - pegar um range maior para compensar timezone
      // (ontem até amanhã no UTC pode conter entregas de hoje no horário local)
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowStr = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

      final response = await DeliveryService.getDeliveryHistory(
        startDate: yesterdayStr,
        endDate: tomorrowStr,
      );

      debugPrint('📦 Resposta do getDeliveryHistory ($yesterdayStr a $tomorrowStr): ${response?.keys}');

      int todayCount = 0;

      if (response != null && response['grouped'] != null) {
        final grouped = response['grouped'] as List;

        // Verificar cada entrega individualmente pelo completedAt convertido para horário local
        for (var group in grouped) {
          final deliveries = group['deliveries'] as List?;
          if (deliveries == null) continue;

          for (var delivery in deliveries) {
            final completedAtStr = delivery['completedAt'] as String?;
            if (completedAtStr == null) continue;

            try {
              // Converter UTC para horário local
              final completedAtUtc = DateTime.parse(completedAtStr);
              final completedAtLocal = completedAtUtc.toLocal();
              final completedDateLocal = '${completedAtLocal.year}-${completedAtLocal.month.toString().padLeft(2, '0')}-${completedAtLocal.day.toString().padLeft(2, '0')}';

              debugPrint('📅 Entrega ${delivery['requestNumber']}: completedAt UTC=$completedAtStr -> Local=$completedDateLocal (esperado: $today)');

              if (completedDateLocal == today) {
                todayCount++;
                debugPrint('✅ Contando entrega ${delivery['requestNumber']} para hoje');
              }
            } catch (e) {
              debugPrint('⚠️ Erro ao parsear completedAt: $completedAtStr - $e');
            }
          }
        }
      }

      // Log se não encontrou entregas hoje
      if (todayCount == 0) {
        debugPrint('ℹ️ Nenhuma entrega concluída hoje ($today)');
      }

      debugPrint('✅ Entregas de hoje (final): $todayCount');

      if (mounted) {
        setState(() {
          _todayDeliveries = todayCount;
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar entregas de hoje: $e');
    }
  }

  Future<void> _loadPromotions() async {
    try {
      debugPrint('🎁 Carregando promoções ativas...');
      final promotions = await DeliveryService.getPromotions();

      if (mounted) {
        setState(() {
          _promotions = promotions;
        });
        debugPrint('✅ ${promotions.length} promoções carregadas');
        for (var promo in promotions) {
          debugPrint('🎁 Promoção completa: $promo');
          debugPrint('🎁 Progress object: ${promo['progress']}');
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar promoções: $e');
    }
  }

  Future<void> _markNotificationsAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastNotificationCheck', DateTime.now().millisecondsSinceEpoch);
    _lastNotificationCheck = DateTime.now();
    setState(() {
      _notificationCount = 0;
    });
  }

  Future<void> _loadCommissionStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      debugPrint('📊 Buscando estatísticas de comissão...');
      final stats = await DeliveryService.getCommissionStats();

      debugPrint('🔍 Stats recebidas: $stats');
      debugPrint('🔍 Stats tipo: ${stats.runtimeType}');
      debugPrint('🔍 Stats keys: ${stats?.keys}');
      if (stats != null) {
        debugPrint('🔍 commissionRate: ${stats['commissionRate']}');
        debugPrint('🔍 deliveriesNeededForNextTier: ${stats['deliveriesNeededForNextTier']}');
        debugPrint('🔍 nextTierRate: ${stats['nextTierRate']}');
      }

      if (mounted) {
        setState(() {
          _commissionStats = stats;
        });

        if (stats != null) {
          debugPrint('✅ Estatísticas carregadas: ${stats['currentMonthDeliveries']} entregas este mês');
          debugPrint('✅ _commissionStats setado: $_commissionStats');
        } else {
          debugPrint('ℹ️ Não foi possível carregar estatísticas');
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar estatísticas: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _loadAvailableDeliveries() async {
    setState(() {
      _isLoadingAvailableDeliveries = true;
    });

    try {
      debugPrint('📦 ===== BUSCANDO ENTREGAS DISPONÍVEIS =====');
      final deliveries = await DeliveryService.getAvailableDeliveries();

      debugPrint('📊 RESPOSTA RECEBIDA:');
      debugPrint('   - Número de entregas: ${deliveries.length}');
      debugPrint('   - Dados completos: $deliveries');

      if (mounted) {
        setState(() {
          _availableDeliveries = deliveries;
        });

        debugPrint('✅ ${deliveries.length} entregas disponíveis carregadas no estado');

        if (deliveries.isEmpty) {
          debugPrint('⚠️ ATENÇÃO: Backend retornou lista vazia de entregas disponíveis');
        } else {
          debugPrint('📦 IDs das entregas recebidas:');
          for (var i = 0; i < deliveries.length; i++) {
            debugPrint('   [$i] ID: ${deliveries[i]['id'] ?? deliveries[i]['request_id']} - Empresa: ${deliveries[i]['company_name']}');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ ERRO ao buscar entregas disponíveis: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAvailableDeliveries = false;
        });
      }
    }
  }

  // Função para atualizar todos os dados (pull-to-refresh)
  Future<void> _refreshData() async {
    debugPrint('🔄 Atualizando dados...');

    // Executar todas as atualizações em paralelo
    await Future.wait([
      _loadDriverProfile(),
      _loadCurrentDelivery(),
      _loadCommissionStats(),
      _loadAvailableDeliveries(),
      _loadNotificationCount(),
      _loadWalletBalance(),
      _loadTodayDeliveries(),
      _loadPromotions(),
    ]);

    debugPrint('✅ Dados atualizados com sucesso!');
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    // Debug: Verificar estado das variáveis
    debugPrint('🔧 BUILD - _commissionStats: $_commissionStats');
    debugPrint('🔧 BUILD - _currentDelivery: $_currentDelivery');

    // Extrair primeiro nome do perfil
    String firstName = 'Motorista';
    if (_driverProfile != null) {
      // Tentar diferentes estruturas de dados
      String? fullName;

      // Estrutura nova: personalData.fullName
      if (_driverProfile!['personalData']?['fullName'] != null) {
        fullName = _driverProfile!['personalData']['fullName'].toString();
      }
      // Estrutura antiga: name diretamente
      else if (_driverProfile!['name'] != null) {
        fullName = _driverProfile!['name'].toString();
      }

      if (fullName != null && fullName.isNotEmpty) {
        firstName = fullName.trim().split(' ').first;
        debugPrint('👤 Nome completo: $fullName');
        debugPrint('👤 Primeiro nome extraído: $firstName');
      } else {
        debugPrint('⚠️ Nome não encontrado no perfil');
      }
    } else {
      debugPrint('⚠️ Perfil do motorista não carregado');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(180),
        child: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Container(
              height: 180,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coluna esquerda: Menu + Nome
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white, size: 30),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Oi, $firstName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Bem-vindo de volta',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Coluna direita: Sino + Toggle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ícone de notificação com badge
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationPage()),
                          );
                          // Marcar como lidas e recarregar contador ao voltar
                          await _markNotificationsAsRead();
                        },
                        child: Stack(
                          children: [
                            const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                            if (_notificationCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Toggle Ativo/Inativo (label já está dentro do widget)
                      const OnlineOfflineToggle(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Header do drawer com perfil
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF6A0DAD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: _isLoadingProfile
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : _driverProfile != null
                        ? Builder(
                            builder: (context) {
                              // Buscar foto do perfil - verificar várias estruturas possíveis
                              String? profilePicture = _driverProfile!['personalData']?['profilePicture']?.toString();
                              if (profilePicture == null || profilePicture.isEmpty) {
                                profilePicture = _driverProfile!['profilePicture']?.toString();
                              }
                              if (profilePicture == null || profilePicture.isEmpty) {
                                profilePicture = userDetails['profilePicture']?.toString();
                              }

                              // Buscar nome - verificar várias estruturas possíveis
                              String driverName = _driverProfile!['personalData']?['fullName']?.toString() ?? '';
                              if (driverName.isEmpty) {
                                driverName = _driverProfile!['name']?.toString() ?? '';
                              }
                              if (driverName.isEmpty) {
                                driverName = userDetails['name']?.toString() ?? '';
                              }
                              if (driverName.isEmpty) {
                                driverName = 'Motorista';
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Foto do perfil
                                  Center(
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: profilePicture != null && profilePicture.isNotEmpty
                                          ? ClipOval(
                                              child: Image.network(
                                                '$url$profilePicture',
                                                fit: BoxFit.cover,
                                                width: 80,
                                                height: 80,
                                                errorBuilder:
                                                    (context, error, stackTrace) {
                                                  return Icon(
                                                    Icons.person,
                                                    size: 50,
                                                    color: Colors.grey[600],
                                                  );
                                                },
                                              ),
                                            )
                                          : Icon(
                                              Icons.person,
                                              size: 50,
                                              color: Colors.grey[600],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  // Nome
                                  Center(
                                    child: Text(
                                      driverName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                        : const Column(
                            children: [
                              Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Erro ao carregar perfil',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
              ),
              // Conteúdo scrollável
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Dados do veículo
                      if (_driverProfile != null &&
                          _driverProfile!['vehicleData'] != null)
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.directions_car,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Meu Veículo',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildVehicleInfo(
                                'Categoria',
                                _driverProfile!['vehicleData']?['category'] ?? '-',
                              ),
                              _buildVehicleInfo(
                                'Marca',
                                _driverProfile!['vehicleData']?['brand'] ?? '-',
                              ),
                              _buildVehicleInfo(
                                'Modelo',
                                _driverProfile!['vehicleData']?['model'] ?? '-',
                              ),
                              _buildVehicleInfo(
                                'Placa',
                                _driverProfile!['vehicleData']?['plate'] ?? '-',
                              ),
                              _buildVehicleInfo(
                                'Cor',
                                _driverProfile!['vehicleData']?['color'] ?? '-',
                              ),
                              _buildVehicleInfo(
                                'Ano',
                                _driverProfile!['vehicleData']?['year'] ?? '-',
                              ),
                            ],
                          ),
                        ),
                      // Rating
                      if (_driverProfile != null &&
                          _driverProfile!['rating'] != null)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _driverProfile!['rating']?.toString() ?? '0.0',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    'Média',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textColor.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Icon(
                                    Icons.rate_review,
                                    color: buttonColor,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _driverProfile!['noOfRatings']?.toString() ?? '0',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    'Avaliações',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textColor.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      // Itens do menu
                      ListTile(
                        leading: const Icon(Icons.local_shipping_outlined, color: AppColors.primary),
                        title: const Text(
                          'Minhas Entregas',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EntregasAtivasScreen(),
                            ),
                          );
                        },
                      ),
                      Divider(height: 1, color: borderLines),
                      ExpansionTile(
                        leading: const Icon(Icons.route, color: AppColors.primary),
                        title: const Text(
                          'Rotas',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                        ),
                        iconColor: AppColors.primary,
                        collapsedIconColor: AppColors.primary,
                        children: [
                          ListTile(
                            leading: const SizedBox(width: 40),
                            title: const Text(
                              'Minhas Rotas',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MinhasRotasScreen(),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: SizedBox(width: 40),
                            title: const Text(
                              'Minhas Viagens',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MinhasViagensScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Divider(height: 1, color: borderLines),
                      ListTile(
                        leading: const Icon(Icons.history, color: AppColors.primary),
                        title: const Text(
                          'Histórico',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyDeliveries(),
                            ),
                          );
                        },
                      ),
                      Divider(height: 1, color: borderLines),
                      ExpansionTile(
                        leading: const Icon(Icons.people_alt_outlined, color: AppColors.primary),
                        title: const Text(
                          'Indicação',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                        ),
                        iconColor: AppColors.primary,
                        collapsedIconColor: AppColors.primary,
                        children: [
                          ListTile(
                            leading: SizedBox(width: 40),
                            title: const Text(
                              'Entregadores',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ReferralPage(),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: SizedBox(width: 40),
                            title: const Text(
                              'Empresas',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ReferralCompaniesPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Divider(height: 1, color: borderLines),
                      ListTile(
                        leading: const Icon(Icons.card_giftcard, color: AppColors.primary),
                        title: const Text(
                          'Promoções',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PromotionsPage(),
                            ),
                          );
                        },
                      ),
                      Divider(height: 1, color: borderLines),
                      ListTile(
                        leading: const Icon(Icons.help_outline, color: AppColors.primary),
                        title: const Text(
                          'FAQ',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Faq()),
                          );
                        },
                      ),
                      Divider(height: 1, color: borderLines),
                      ListTile(
                        leading: const Icon(Icons.confirmation_number_outlined, color: AppColors.primary),
                        title: const Text(
                          'Meus Tickets',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SupportTicketsPage(),
                            ),
                          );
                        },
                      ),
                      Divider(height: 1, color: borderLines),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: const Icon(Icons.exit_to_app, color: Colors.red),
                        title: const Text(
                          'Sair',
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                        onTap: () async {
                          debugPrint('🚪 Botão de sair clicado');

                          try {
                            // Limpar sessão do LocalStorageService
                            debugPrint('🧹 Limpando LocalStorageService...');
                            await LocalStorageService.clearSession();

                            // Limpar userDetails
                            debugPrint('🧹 Limpando userDetails...');
                            userDetails.clear();

                            // Limpar SharedPreferences
                            debugPrint('🧹 Limpando SharedPreferences...');
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('Bearer');
                            await prefs.clear();

                            debugPrint('✅ Dados limpos com sucesso');

                            if (context.mounted) {
                              debugPrint('🔄 Navegando para tela de login...');
                              // Navegar para tela de login removendo todas as rotas anteriores
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreenNew()),
                                (route) => false,
                              );
                              debugPrint('✅ Navegação concluída');
                            }
                          } catch (e) {
                            debugPrint('❌ Erro ao fazer logout: $e');
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.primary,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Card de Saldo (Balance Card) - Novo design do Figma
                    _buildBalanceCard(),
                    const SizedBox(height: 16),

                    // Cards informativos de estatísticas (Novo design do Figma)
                    if (_commissionStats != null)
                      _buildStatisticsCards(),

                    if (_commissionStats != null)
                      const SizedBox(height: 20),

                    // Seção de Promoções Ativas
                    _buildPromotionsSection(),
                    if (_promotions.isNotEmpty)
                      const SizedBox(height: 20),

                    // Seção "Entrega em andamento agora"
                    if (_activeDeliveries.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Entrega em andamento agora',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Listar todos os cards de entregas ativas
                      ..._activeDeliveries.asMap().entries.map((entry) {
                        final delivery = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildActiveDeliveryCardFigma(delivery),
                        );
                      }),
                      const SizedBox(height: 20),
                    ],

                    const SizedBox(height: 100), // Espaço para o bottom navigation
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Banner informativo quando há múltiplas entregas
  Widget _buildMultipleDeliveriesBanner(int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.layers,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Múltiplas Entregas Ativas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Você tem $count entregas em andamento',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card individual para cada entrega ativa
  Widget _buildActiveDeliveryCard(Map<String, dynamic> delivery, int position) {
    final String companyName = delivery['companyName'] ?? 'Empresa';
    final String requestNumber = delivery['requestNumber'] ?? 'N/A';
    final String customerName = delivery['customerName'] ?? 'Cliente';
    final String distance = delivery['distance'] ?? '0';
    final String driverAmount = delivery['driverAmount'] ?? '0.00';
    final bool isTripStart = delivery['isTripStart'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF6A0DAD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            // Verificar se é uma entrega com múltiplas paradas já retirada
            final deliveryAddress = delivery['deliveryAddress'] ?? '';
            final hasMultipleStops = deliveryAddress.toString().contains(' | ');
            final isTripStart = delivery['isTripStart'] ?? false;

            // Se já foi retirada e tem múltiplas paradas, ir direto para a tela de stops
            if (isTripStart && hasMultipleStops) {
              debugPrint('📍 Entrega com múltiplas paradas já retirada, indo direto para tela de stops');

              // Criar objeto Delivery
              final stopsCount = deliveryAddress.toString().split(' | ').length;
              final deliveryObj = Delivery(
                requestId: delivery['requestId']?.toString() ?? '',
                requestNumber: delivery['requestNumber']?.toString() ?? '',
                companyName: delivery['companyName'],
                companyPhone: delivery['companyPhone'],
                customerName: delivery['customerName'],
                customerWhatsapp: delivery['customerWhatsapp'],
                deliveryReference: delivery['deliveryReference'],
                pickupAddress: delivery['pickupAddress'],
                pickupLat: delivery['pickupLat'] != null ? double.tryParse(delivery['pickupLat'].toString()) : null,
                pickupLng: delivery['pickupLng'] != null ? double.tryParse(delivery['pickupLng'].toString()) : null,
                deliveryAddress: deliveryAddress.toString(),
                deliveryLat: delivery['deliveryLat'] != null ? double.tryParse(delivery['deliveryLat'].toString()) : null,
                deliveryLng: delivery['deliveryLng'] != null ? double.tryParse(delivery['deliveryLng'].toString()) : null,
                distance: delivery['distance']?.toString(),
                estimatedTime: delivery['estimatedTime']?.toString(),
                driverAmount: delivery['driverAmount']?.toString(),
                isTripStart: true,
                needsReturn: delivery['needsReturn'] ?? false,
                hasMultipleStops: true,
                stopsCount: stopsCount,
              );

              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeliveryWithStopsScreen(delivery: deliveryObj),
                ),
              );

              // Recarregar entregas após voltar
              if (result != null || mounted) {
                _loadCurrentDelivery();
              }
            } else {
              // Ir para tela normal de entrega ativa
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActiveDeliveryScreen(
                    delivery: delivery,
                  ),
                ),
              );
              // Recarregar entregas após voltar
              if (result != null || mounted) {
                _loadCurrentDelivery();
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com número da posição e status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_shipping,
                                color: Colors.white,
                                size: 24,
                              ),
                              if (_activeDeliveries.length > 1) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '#$position',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Badge de status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isTripStart ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isTripStart ? Icons.check_circle : Icons.pending,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isTripStart ? 'Retirada' : 'Pendente',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Informações principais
                Text(
                  'Entrega #$requestNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  companyName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cliente: $customerName',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),

                // Informações de distância e valor
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.straighten,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$distance km',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            color: Colors.white,
                            size: 14,
                          ),
                          Text(
                            'R\$ $driverAmount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Botão de ação
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Ver detalhes',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white.withOpacity(0.9),
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveDeliveryBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF6A0DAD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActiveDeliveryScreen(
                  delivery: _currentDelivery!,
                ),
              ),
            );
            // Recarregar entrega após voltar
            if (result != null || mounted) {
              _loadCurrentDelivery();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Entrega em Andamento',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentDelivery!['companyName'] ?? 'Empresa',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.straighten,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_currentDelivery!['distance'] ?? '0'} km',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.attach_money,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                Text(
                                  'R\$ ${_currentDelivery!['driverAmount'] ?? '0.00'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
    final String companyName = delivery['company_name'] ?? 'Empresa';
    final String pickupAddress = delivery['pick_address'] ?? 'Endereço de coleta';
    final String dropAddress = delivery['drop_address'] ?? 'Endereço de entrega';
    final String distance = delivery['total_distance']?.toString() ?? '0';
    final String driverAmount = delivery['driver_amount']?.toString() ??
                                 delivery['request_eta_amount']?.toString() ?? '0.00';
    final String requestNumber = delivery['request_number'] ?? 'N/A';
    final bool needsReturn = delivery['needs_return'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com nome da empresa e número da solicitação
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    companyName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#$requestNumber',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Endereço de coleta
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.store, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pickupAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Ícone de seta
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.arrow_downward, color: Colors.grey, size: 16),
            ),
            const SizedBox(height: 8),

            // Endereço de entrega
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dropAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Informações de distância e valor
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Distância
                Row(
                  children: [
                    Icon(Icons.straighten, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$distance km',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // Valor
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_money, color: Colors.green, size: 18),
                      Text(
                        'R\$ $driverAmount',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Badge de retorno se necessário
            if (needsReturn) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.sync, color: Colors.orange, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Necessita retorno',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Card de Entrega Ativa - Estilo Figma
  Widget _buildActiveDeliveryCardFigma(Map<String, dynamic> delivery) {
    final String companyName = delivery['companyName'] ?? 'Empresa';
    final String requestNumber = delivery['requestNumber'] ?? 'N/A';
    final String pickupAddress = delivery['pickupAddress'] ?? 'Endereço de coleta';
    final String deliveryAddress = delivery['deliveryAddress'] ?? 'Endereço de entrega';
    final bool isTripStart = delivery['isTripStart'] == true;

    // Determinar status e cor
    String statusText = isTripStart ? 'Entrega' : 'Coleta';
    Color statusColor = isTripStart ? Colors.green : Colors.orange;

    return GestureDetector(
      onTap: () async {
        // Verificar se é uma entrega com múltiplas paradas já retirada
        final deliveryAddressStr = delivery['deliveryAddress'] ?? '';
        final hasMultipleStops = deliveryAddressStr.toString().contains(' | ');

        // Se já foi retirada e tem múltiplas paradas, ir direto para a tela de stops
        if (isTripStart && hasMultipleStops) {
          final stopsCount = deliveryAddressStr.toString().split(' | ').length;
          final deliveryObj = Delivery(
            requestId: delivery['requestId']?.toString() ?? '',
            requestNumber: delivery['requestNumber']?.toString() ?? '',
            companyName: delivery['companyName'],
            companyPhone: delivery['companyPhone'],
            customerName: delivery['customerName'],
            customerWhatsapp: delivery['customerWhatsapp'],
            deliveryReference: delivery['deliveryReference'],
            pickupAddress: delivery['pickupAddress'],
            pickupLat: delivery['pickupLat'] != null ? double.tryParse(delivery['pickupLat'].toString()) : null,
            pickupLng: delivery['pickupLng'] != null ? double.tryParse(delivery['pickupLng'].toString()) : null,
            deliveryAddress: deliveryAddressStr.toString(),
            deliveryLat: delivery['deliveryLat'] != null ? double.tryParse(delivery['deliveryLat'].toString()) : null,
            deliveryLng: delivery['deliveryLng'] != null ? double.tryParse(delivery['deliveryLng'].toString()) : null,
            distance: delivery['distance']?.toString(),
            estimatedTime: delivery['estimatedTime']?.toString(),
            driverAmount: delivery['driverAmount']?.toString(),
            isTripStart: true,
            needsReturn: delivery['needsReturn'] ?? false,
            hasMultipleStops: true,
            stopsCount: stopsCount,
          );

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryWithStopsScreen(delivery: deliveryObj),
            ),
          );

          if (result != null || mounted) {
            _loadCurrentDelivery();
          }
        } else {
          // Ir para tela normal de entrega ativa
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActiveDeliveryScreen(
                delivery: delivery,
              ),
            ),
          );
          if (result != null || mounted) {
            _loadCurrentDelivery();
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Nome da empresa + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    companyName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Pedido #$requestNumber',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Endereço de retirada
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isTripStart ? deliveryAddress : pickupAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.primary,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Card de Saldo - Novo design do Figma
  Widget _buildBalanceCard() {
    // Obter saldo disponível para saque
    final saque = _balanceData?['saque'];
    final double valorDisponivelParaSaque = (saque?['valorDisponivelParaSaque'] ?? 0).toDouble();

    // Obter dados de comissão (corrigir nomes das chaves da API)
    final double commissionRate = (_commissionStats?['currentCommissionPercentage'] ?? 18).toDouble();
    final nextTier = _commissionStats?['nextTier'] as Map<String, dynamic>?;
    final int deliveriesNeeded = nextTier?['deliveriesNeeded'] ?? 0;
    final double nextTierRate = (nextTier?['commissionPercentage'] ?? 0).toDouble();

    // Debug: Verificar dados de comissão
    debugPrint('💰 Dados de comissão:');
    debugPrint('   - currentCommissionPercentage: $commissionRate');
    debugPrint('   - nextTier.deliveriesNeeded: $deliveriesNeeded');
    debugPrint('   - nextTier.commissionPercentage: $nextTierRate');
    debugPrint('   - _commissionStats completo: $_commissionStats');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD4F1E8), Color(0xFFB8E6D5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Ícone da carteira
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Color(0xFF2E7D32),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Disponível',
                          style: TextStyle(
                            color: Color(0xFF424242),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _isLoadingBalance
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF2E7D32),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'R\$ ${valorDisponivelParaSaque.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                      ],
                    ),
                  ),
                  // Tag de comissão
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Comissão',
                        style: TextStyle(
                          color: Color(0xFF424242),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${commissionRate.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Color(0xFF1B5E20),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Texto sobre entregas necessárias para próximo nível
              if (_commissionStats != null && deliveriesNeeded > 0 && nextTierRate > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.star_border,
                      size: 14,
                      color: Color(0xFF4CAF50),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Faltam $deliveriesNeeded ${deliveriesNeeded == 1 ? 'entrega' : 'entregas'} para ${nextTierRate.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCards() {
    final int currentMonthDeliveries = _commissionStats?['currentMonthDeliveries'] ?? 0;
    final int currentWeekDeliveries = _commissionStats?['currentWeekDeliveries'] ?? 0;

    debugPrint('📊 Estatísticas - Hoje: $_todayDeliveries, Semana: $currentWeekDeliveries, Mês: $currentMonthDeliveries');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Card de entregas de hoje
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.today,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Entregas\nhoje',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_todayDeliveries',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Card de entregas da semana
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Entregas\nsemana',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$currentWeekDeliveries',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Card de entregas do mês
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    color: Colors.indigo,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Entregas\nmês',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$currentMonthDeliveries',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Seção de Promoções Ativas
  Widget _buildPromotionsSection() {
    if (_promotions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Promoções Ativas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PromotionsPage()),
                  );
                },
                child: const Text(
                  'Ver todas',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._promotions.map((promotion) => _buildPromotionCard(promotion)),
        ],
      ),
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promotion) {
    final String type = promotion['type'] ?? '';
    final String name = promotion['name'] ?? 'Promoção';
    final String prize = promotion['prize'] ?? '';

    // Determinar cor baseada no tipo
    final Color cardColor;
    final Color progressColor;
    final IconData icon;

    if (type == 'top_performer') {
      cardColor = const Color(0xFFFFF3E0); // Laranja claro
      progressColor = Colors.orange;
      icon = Icons.emoji_events;
    } else {
      cardColor = const Color(0xFFF3E5F5); // Roxo claro
      progressColor = AppColors.primary;
      icon = Icons.local_shipping;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: progressColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: progressColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Badge de prêmio
              if (prize.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.card_giftcard, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        prize,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (type == 'complete_and_win') ...[
            // Barra de progresso para complete_and_win
            _buildCompleteAndWinProgress(promotion, progressColor),
          ] else if (type == 'top_performer') ...[
            // Exibição de ranking para top_performer
            _buildTopPerformerProgress(promotion, progressColor),
          ],
        ],
      ),
    );
  }

  Widget _buildCompleteAndWinProgress(Map<String, dynamic> promotion, Color color) {
    // Pegar dados do progress se existir, senão usar valores da raiz
    final Map<String, dynamic>? progressData = promotion['progress'];
    final int goal = progressData?['goal'] ?? promotion['goal'] ?? 1;
    final int current = progressData?['current'] ?? 0;
    final int remaining = progressData?['remaining'] ?? (goal - current);
    final double percentage = progressData?['percentage']?.toDouble() ??
        (goal > 0 ? (current / goal * 100) : 0.0);
    final bool goalReached = progressData?['goalReached'] ?? (current >= goal);

    // Formatar datas válidas
    final String validDates = promotion['validDates'] ?? '';
    String formattedDates = '';
    if (validDates.isNotEmpty) {
      final dates = validDates.split(',');
      final formattedList = dates.map((date) {
        try {
          final parts = date.split('-');
          if (parts.length == 3) {
            return '${parts[2]}/${parts[1]}';
          }
        } catch (_) {}
        return date;
      }).toList();
      formattedDates = formattedList.join(', ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Datas válidas
        if (formattedDates.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Válido: $formattedDates',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        // Linha com meta e progresso
        Row(
          children: [
            // Coluna: Entregas feitas
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Suas entregas',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$current',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            // Coluna: Meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Meta',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$goal',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            // Coluna: Faltam
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    goalReached ? 'Concluído!' : 'Faltam',
                    style: TextStyle(
                      fontSize: 12,
                      color: goalReached ? Colors.green : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goalReached ? '0' : '$remaining',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: goalReached ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Barra de progresso
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${percentage.toStringAsFixed(1)}% concluído',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTopPerformerProgress(Map<String, dynamic> promotion, Color color) {
    // Pegar dados do progress se existir, senão usar valores da raiz
    final Map<String, dynamic>? progressData = promotion['progress'];
    final int current = progressData?['current'] ?? 0;
    final int rank = progressData?['rank'] ?? 0;
    final int leaderCount = progressData?['leaderCount'] ?? 0;

    // Formatar datas válidas
    final String validDates = promotion['validDates'] ?? '';
    String formattedDates = '';
    if (validDates.isNotEmpty) {
      final dates = validDates.split(',');
      final formattedList = dates.map((date) {
        try {
          final parts = date.split('-');
          if (parts.length == 3) {
            return '${parts[2]}/${parts[1]}';
          }
        } catch (_) {}
        return date;
      }).toList();
      formattedDates = formattedList.join(', ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Datas válidas
        if (formattedDates.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Válido: $formattedDates',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        // Linha com estatísticas
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Suas entregas',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$current',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Sua posição',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (rank > 0 && rank <= 3)
                        Icon(
                          Icons.emoji_events,
                          color: rank == 1
                              ? Colors.amber
                              : rank == 2
                                  ? Colors.grey.shade400
                                  : Colors.brown.shade300,
                          size: 20,
                        ),
                      Text(
                        rank > 0 ? '$rank°' : '-',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Participantes',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    leaderCount > 0 ? '$leaderCount' : '-',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Seção de Entregas - Novo design do Figma
  Widget _buildDeliverySections() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Entregas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Card de Coleta
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.orange,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Coleta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_activeDeliveries.where((d) => d['isTripStart'] == false).length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Card de Entregas
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_shipping_outlined,
                          color: Colors.green,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Entregas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_activeDeliveries.where((d) => d['isTripStart'] == true).length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Bottom Navigation Bar - Novo design do Figma
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem(Icons.home_outlined, 'Início', true),
              _buildNavBarItem(Icons.account_balance_wallet_outlined, 'Carteira', false),
              // Centro - Botão de entregas destacado
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF6A0DAD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EntregasAtivasScreen(),
                      ),
                    );
                  },
                ),
              ),
              _buildNavBarItem(Icons.person_outline, 'Perfil', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(IconData icon, String label, bool isActive) {
    return InkWell(
      onTap: () {
        if (label == 'Carteira') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CarteiraPage(),
            ),
          );
        } else if (label == 'Perfil') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileDetailsScreen(),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

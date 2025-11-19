import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/online_offline_toggle.dart';
import '../styles/styles.dart';
import '../functions/functions.dart';
import '../services/local_storage_service.dart';
import '../services/delivery_service.dart';
import '../services/location_permission_service.dart';
import 'driver_profile_screen.dart';
import 'active_delivery_screen.dart';
import 'delivery_with_stops_screen.dart';
import '../models/delivery.dart';
import 'NavigatorPages/promotions.dart';
import 'NavigatorPages/faq.dart';
import 'NavigatorPages/my_deliveries.dart';
import 'NavigatorPages/notification.dart';
import 'NavigatorPages/referral.dart';
import 'NavigatorPages/referral_companies.dart';
import 'NavigatorPages/support_tickets.dart';
import 'NavigatorPages/entregas_ativas.dart';
import 'NavigatorPages/minhas_rotas.dart';
import 'NavigatorPages/minhas_viagens.dart';
import 'login/login.dart';

class HomeSimple extends StatefulWidget {
  const HomeSimple({Key? key}) : super(key: key);

  @override
  State<HomeSimple> createState() => _HomeSimpleState();
}

class _HomeSimpleState extends State<HomeSimple> with WidgetsBindingObserver {
  Map<String, dynamic>? _driverProfile;
  bool _isLoadingProfile = false;
  Timer? _locationTimer;
  Map<String, dynamic>? _currentDelivery;
  bool _isLoadingDelivery = false;
  Map<String, dynamic>? _commissionStats;
  bool _isLoadingStats = false;
  List<Map<String, dynamic>> _availableDeliveries = [];
  bool _isLoadingAvailableDeliveries = false;
  List<Map<String, dynamic>> _activeDeliveries = []; // NOVO: lista de entregas ativas

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDriverProfile();
    _loadCurrentDelivery();
    _loadCommissionStats();
    _loadAvailableDeliveries();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationTimer?.cancel();
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

  Future<void> _loadDriverProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      debugPrint('👤 Buscando perfil do motorista...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return;
      }

      final response = await http.get(
        Uri.parse('${url}api/v1/driver/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          setState(() {
            _driverProfile = jsonResponse['data'];
          });
          debugPrint('✅ Perfil carregado com sucesso');
        }
      } else {
        debugPrint('❌ Erro ao carregar perfil: ${response.statusCode}');
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
    ]);

    debugPrint('✅ Dados atualizados com sucesso!');
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    // Debug: Verificar estado das variáveis
    debugPrint('🔧 BUILD - _commissionStats: $_commissionStats');
    debugPrint('🔧 BUILD - _currentDelivery: $_currentDelivery');

    return Scaffold(
      backgroundColor: page,
      appBar: AppBar(
        backgroundColor: buttonColor,
        title: const Text('Home', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      drawer: Drawer(
        child: Container(
          color: page,
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [buttonColor, buttonColor.withOpacity(0.7)],
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
                        ? Column(
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
                                  child: _driverProfile!['personalData']
                                                  ?['profilePicture'] !=
                                              null &&
                                          _driverProfile!['personalData']
                                                  ['profilePicture']
                                              .toString()
                                              .isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            '$url${_driverProfile!['personalData']['profilePicture']}',
                                            fit: BoxFit.cover,
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
                                  _driverProfile!['personalData']?['fullName'] ??
                                      'Motorista',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 5),
                              // Email
                              Center(
                                child: Text(
                                  _driverProfile!['personalData']?['email'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 5),
                              // WhatsApp
                              if (_driverProfile!['personalData']?['whatsapp'] !=
                                  null)
                                Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        size: 16,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _driverProfile!['personalData']
                                                ['whatsapp'] ??
                                            '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 5),
                              // Cidade
                              if (_driverProfile!['personalData']?['city'] !=
                                  null)
                                Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _driverProfile!['personalData']
                                                ['city'] ??
                                            '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
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
                              Row(
                                children: [
                                  Icon(
                                    Icons.directions_car,
                                    color: buttonColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Meu Veículo',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
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
                        leading: Icon(Icons.person, color: buttonColor),
                        title: Text(
                          'Meu Perfil',
                          style: TextStyle(color: textColor, fontSize: 16),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DriverProfileScreen(),
                            ),
                          );
                        },
                      ),
                      Divider(height: 1, color: borderLines),
                      ListTile(
                        leading: Icon(Icons.local_shipping_outlined, color: buttonColor),
                        title: Text(
                          'Minhas Entregas',
                          style: TextStyle(color: textColor, fontSize: 16),
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
                        leading: Icon(Icons.route, color: buttonColor),
                        title: Text(
                          'Rotas',
                          style: TextStyle(color: textColor, fontSize: 16),
                        ),
                        iconColor: buttonColor,
                        collapsedIconColor: buttonColor,
                        children: [
                          ListTile(
                            leading: SizedBox(width: 40),
                            title: Text(
                              'Minhas Rotas',
                              style: TextStyle(color: textColor, fontSize: 15),
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
                            title: Text(
                              'Minhas Viagens',
                              style: TextStyle(color: textColor, fontSize: 15),
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
                        leading: Icon(Icons.history, color: buttonColor),
                        title: Text(
                          'Histórico',
                          style: TextStyle(color: textColor, fontSize: 16),
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
                      ListTile(
                        leading: Icon(Icons.notifications_outlined, color: buttonColor),
                        title: Text(
                          'Notificações',
                          style: TextStyle(color: textColor, fontSize: 16),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationPage(),
                            ),
                          );
                        },
                      ),
                      Divider(height: 1, color: borderLines),
                      ExpansionTile(
                        leading: Icon(Icons.people_alt_outlined, color: buttonColor),
                        title: Text(
                          'Indicação',
                          style: TextStyle(color: textColor, fontSize: 16),
                        ),
                        iconColor: buttonColor,
                        collapsedIconColor: buttonColor,
                        children: [
                          ListTile(
                            leading: SizedBox(width: 40),
                            title: Text(
                              'Entregadores',
                              style: TextStyle(color: textColor, fontSize: 15),
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
                            title: Text(
                              'Empresas',
                              style: TextStyle(color: textColor, fontSize: 15),
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
                        leading: Icon(Icons.card_giftcard, color: buttonColor),
                        title: Text(
                          'Promoções',
                          style: TextStyle(color: textColor, fontSize: 16),
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
                        leading: Icon(Icons.settings, color: buttonColor),
                        title: Text(
                          'Configurações',
                          style: TextStyle(color: textColor, fontSize: 16),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: Navegar para tela de configurações
                        },
                      ),
                      Divider(height: 1, color: borderLines),
                      ListTile(
                        leading: Icon(Icons.help_outline, color: buttonColor),
                        title: Text(
                          'FAQ',
                          style: TextStyle(color: textColor, fontSize: 16),
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
                        leading: Icon(Icons.confirmation_number_outlined, color: buttonColor),
                        title: Text(
                          'Meus Tickets',
                          style: TextStyle(color: textColor, fontSize: 16),
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
                                MaterialPageRoute(builder: (context) => const Login()),
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
        color: buttonColor,
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

                    // Indicador de entregas ativas (suporta múltiplas entregas)
                    if (_activeDeliveries.isNotEmpty) ...[
                      // Banner informativo quando há múltiplas entregas
                      if (_activeDeliveries.length > 1) ...[
                        _buildMultipleDeliveriesBanner(_activeDeliveries.length),
                        const SizedBox(height: 16),
                      ],

                      // Listar todos os cards de entregas ativas
                      ..._activeDeliveries.asMap().entries.map((entry) {
                        final index = entry.key;
                        final delivery = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildActiveDeliveryCard(delivery, index + 1),
                        );
                      }),
                      const SizedBox(height: 4),
                    ],

                    // Cards informativos de estatísticas
                    if (_commissionStats != null)
                      _buildStatisticsCards(),

                    if (_commissionStats != null)
                      const SizedBox(height: 20),

                    // Toggle Online/Offline
                    const Center(
                      child: OnlineOfflineToggle(),
                    ),
                    const SizedBox(height: 30),

                    // Lista de entregas disponíveis
                    if (_availableDeliveries.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.local_shipping, color: buttonColor, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Entregas Disponíveis (${_availableDeliveries.length})',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._availableDeliveries.map((delivery) => _buildDeliveryCard(delivery)),
                      const SizedBox(height: 20),
                    ],

                    // Loading de entregas disponíveis
                    if (_isLoadingAvailableDeliveries)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(),
                      ),

                    // Texto informativo
                    if (_availableDeliveries.isEmpty && !_isLoadingAvailableDeliveries)
                      Center(
                        child: Text(
                          'Arraste para baixo para atualizar\n\nUse o toggle acima para ficar\nOnline ou Offline\n\nNenhuma entrega disponível no momento',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
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
        gradient: LinearGradient(
          colors: [buttonColor, buttonColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withOpacity(0.3),
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
        gradient: LinearGradient(
          colors: [buttonColor, buttonColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withOpacity(0.3),
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
            style: TextStyle(
              fontSize: 14,
              color: textColor.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: buttonColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#$requestNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: buttonColor,
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
                Icon(Icons.store, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pickupAddress,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Ícone de seta
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(Icons.arrow_downward, color: Colors.grey, size: 16),
            ),
            const SizedBox(height: 8),

            // Endereço de entrega
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dropAddress,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
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
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
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

  Widget _buildStatisticsCards() {
    final int currentMonthDeliveries = _commissionStats?['currentMonthDeliveries'] ?? 0;
    final int currentWeekDeliveries = _commissionStats?['currentWeekDeliveries'] ?? 0;
    final double currentCommission = (_commissionStats?['currentCommissionPercentage'] ?? 0.0).toDouble();
    final Map<String, dynamic>? nextTier = _commissionStats?['nextTier'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Primeira linha - Entregas da semana e do mês
          Row(
            children: [
              // Card de entregas da semana
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.purple.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$currentWeekDeliveries',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Entregas\nesta semana',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Card de entregas do mês
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.local_shipping,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$currentMonthDeliveries',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Entregas\neste mês',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Segunda linha - Card de comissão
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.attach_money,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${currentCommission.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nextTier != null
                            ? 'Comissão atual'
                            : 'Comissão máxima!',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (nextTier != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Faltam ${nextTier['deliveriesNeeded']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'para ${nextTier['commissionPercentage'].toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

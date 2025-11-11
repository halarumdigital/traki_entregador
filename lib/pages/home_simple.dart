import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../widgets/online_offline_toggle.dart';
import '../styles/styles.dart';
import '../functions/functions.dart';
import '../services/local_storage_service.dart';
import '../services/delivery_service.dart';
import '../services/location_permission_service.dart';
import 'driver_profile_screen.dart';
import 'active_delivery_screen.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDriverProfile();
    _loadCurrentDelivery();
    _loadCommissionStats();
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
      debugPrint('📦 Buscando entrega em andamento...');
      final delivery = await DeliveryService.getCurrentDelivery();

      if (mounted) {
        setState(() {
          _currentDelivery = delivery;
        });

        // Apenas mostrar log, não navegar automaticamente
        if (delivery != null) {
          debugPrint('✅ Entrega em andamento encontrada');
        } else {
          debugPrint('ℹ️ Nenhuma entrega em andamento');
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar entrega em andamento: $e');
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

      if (mounted) {
        setState(() {
          _commissionStats = stats;
        });

        if (stats != null) {
          debugPrint('✅ Estatísticas carregadas: ${stats['currentMonthDeliveries']} entregas este mês');
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

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

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
                leading: Icon(Icons.local_shipping, color: buttonColor),
                title: Text(
                  'Minhas Viagens',
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navegar para tela de viagens
                },
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
                  // TODO: Navegar para tela de histórico
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
                  'Ajuda',
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navegar para tela de ajuda
                },
              ),
              const Spacer(),
              Divider(height: 1, color: borderLines),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text(
                  'Sair',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
                onTap: () async {
                  await LocalStorageService.clearSession();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Indicador de entrega ativa
          if (_currentDelivery != null)
            _buildActiveDeliveryBanner(),

          if (_currentDelivery != null)
            const SizedBox(height: 20),

          // Cards informativos de estatísticas
          if (_commissionStats != null)
            _buildStatisticsCards(),

          if (_commissionStats != null)
            const SizedBox(height: 20),

          // Toggle Online/Offline
          const Center(
            child: OnlineOfflineToggle(),
          ),
          const SizedBox(height: 40),
          // Texto informativo
          Center(
            child: Text(
              'Use o toggle acima para ficar\nOnline ou Offline',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
              ),
            ),
          ),
        ],
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

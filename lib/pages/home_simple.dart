import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../widgets/online_offline_toggle.dart';
import '../styles/styles.dart';
import '../functions/functions.dart';
import '../services/local_storage_service.dart';

class HomeSimple extends StatefulWidget {
  const HomeSimple({Key? key}) : super(key: key);

  @override
  State<HomeSimple> createState() => _HomeSimpleState();
}

class _HomeSimpleState extends State<HomeSimple> {
  Map<String, dynamic>? _driverProfile;
  bool _isLoadingProfile = false;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: page,
      appBar: AppBar(
        backgroundColor: topBar,
        title: const Text('Home', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
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
                            _driverProfile!['rating']?['average']?.toString() ??
                                '0.0',
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
                            _driverProfile!['rating']?['count']?.toString() ??
                                '0',
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
              const Spacer(),
              // Botão de recarregar perfil
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: _loadDriverProfile,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar Perfil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
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
}

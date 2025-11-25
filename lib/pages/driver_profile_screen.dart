import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../styles/styles.dart';
import '../functions/functions.dart';
import '../services/local_storage_service.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  Map<String, dynamic>? _driverProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  Future<void> _loadDriverProfile() async {
    setState(() {
      _isLoading = true;
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
          debugPrint('📦 Dados: ${jsonResponse['data']}');
        }
      } else {
        debugPrint('❌ Erro ao carregar perfil: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar perfil: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: page,
      appBar: AppBar(
        backgroundColor: buttonColor,
        title: const Text('Meu Perfil', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _driverProfile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Erro ao carregar perfil',
                        style: TextStyle(
                          fontSize: 18,
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tente novamente mais tarde',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _loadDriverProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                        ),
                        child: const Text(
                          'Tentar Novamente',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDriverProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Foto e informações básicas
                        Center(
                          child: Column(
                            children: [
                              // Foto do perfil
                              Container(
                                width: 120,
                                height: 120,
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
                                child: _driverProfile!['profilePicture'] != null &&
                                        _driverProfile!['profilePicture']
                                            .toString()
                                            .isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          '$url${_driverProfile!['profilePicture']}',
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person,
                                              size: 70,
                                              color: Colors.grey[600],
                                            );
                                          },
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 70,
                                        color: Colors.grey[600],
                                      ),
                              ),
                              const SizedBox(height: 20),
                              // Nome
                              Text(
                                _driverProfile!['name'] ?? 'Motorista',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 5),
                              // Email
                              Text(
                                _driverProfile!['email'] ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Dados Pessoais
                        _buildSectionTitle('Dados Pessoais'),
                        _buildInfoCard([
                          if (_driverProfile!['mobile'] != null)
                            _buildInfoRow(
                              Icons.phone,
                              'Celular',
                              _driverProfile!['mobile'],
                            ),
                          if (_driverProfile!['cpf'] != null)
                            _buildInfoRow(
                              Icons.credit_card,
                              'CPF',
                              _driverProfile!['cpf'],
                            ),
                          if (_driverProfile!['email'] != null)
                            _buildInfoRow(
                              Icons.email,
                              'Email',
                              _driverProfile!['email'],
                            ),
                        ]),
                        const SizedBox(height: 20),

                        // Dados do Veículo
                        _buildSectionTitle('Dados do Veículo'),
                        _buildInfoCard([
                          if (_driverProfile!['carNumber'] != null)
                            _buildInfoRow(
                              Icons.pin,
                              'Placa',
                              _driverProfile!['carNumber'],
                            ),
                          if (_driverProfile!['carColor'] != null)
                            _buildInfoRow(
                              Icons.color_lens,
                              'Cor',
                              _driverProfile!['carColor'],
                            ),
                          if (_driverProfile!['carYear'] != null)
                            _buildInfoRow(
                              Icons.calendar_today,
                              'Ano',
                              _driverProfile!['carYear'].toString(),
                            ),
                          if (_driverProfile!['carMake'] != null)
                            _buildInfoRow(
                              Icons.directions_car,
                              'Marca',
                              _driverProfile!['carMake'],
                            ),
                          if (_driverProfile!['carModel'] != null)
                            _buildInfoRow(
                              Icons.car_rental,
                              'Modelo',
                              _driverProfile!['carModel'],
                            ),
                        ]),
                        const SizedBox(height: 20),

                        // Rating
                        _buildSectionTitle('Avaliações'),
                        Container(
                          padding: const EdgeInsets.all(20),
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
                                    size: 40,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _driverProfile!['rating']?.toString() ?? '0.0',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    'Média',
                                    style: TextStyle(
                                      fontSize: 14,
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
                                    size: 40,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _driverProfile!['noOfRatings']?.toString() ?? '0',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    'Avaliações',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Status
                        _buildSectionTitle('Status'),
                        _buildInfoCard([
                          _buildInfoRow(
                            Icons.check_circle,
                            'Conta Ativa',
                            _driverProfile!['active'] == true ? 'Sim' : 'Não',
                          ),
                          _buildInfoRow(
                            Icons.verified,
                            'Aprovado',
                            _driverProfile!['approve'] == true ? 'Sim' : 'Não',
                          ),
                          _buildInfoRow(
                            Icons.upload_file,
                            'Documentos Enviados',
                            _driverProfile!['uploadedDocuments'] == true
                                ? 'Sim'
                                : 'Não',
                          ),
                          _buildInfoRow(
                            Icons.online_prediction,
                            'Disponível',
                            _driverProfile!['available'] == true ? 'Sim' : 'Não',
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
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
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: buttonColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

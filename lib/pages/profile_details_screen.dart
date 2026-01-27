import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../styles/app_colors.dart';
import '../functions/functions.dart';
import '../services/local_storage_service.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  Map<String, dynamic>? _driverProfile;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<Map<String, String>> _pixKeyTypes = [
    {'value': 'CPF', 'label': 'CPF'},
    {'value': 'CNPJ', 'label': 'CNPJ'},
    {'value': 'EMAIL', 'label': 'E-mail'},
    {'value': 'PHONE', 'label': 'Telefone'},
    {'value': 'EVP', 'label': 'Chave Aleatória'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Buscar da API /api/v1/driver/profile
      final token = await LocalStorageService.getAccessToken();
      if (token != null) {
        debugPrint('🔍 Buscando perfil em: ${url}api/v1/driver/profile');
        final response = await http.get(
          Uri.parse('${url}api/v1/driver/profile'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        debugPrint('📥 Status: ${response.statusCode}');
        debugPrint('📥 Body: ${response.body}');

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          if (jsonResponse['success'] == true && mounted) {
            setState(() {
              _driverProfile = jsonResponse['data'];
            });
            debugPrint('✅ Perfil carregado da API');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar perfil: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showEditPixKeyDialog() {
    final currentPixKey = _driverProfile?['pixKey']?.toString() ?? '';
    final currentPixKeyType = _driverProfile?['pixKeyType']?.toString() ?? 'CPF';

    final pixKeyController = TextEditingController(text: currentPixKey);
    String selectedType = _pixKeyTypes.any((t) => t['value'] == currentPixKeyType)
        ? currentPixKeyType
        : 'CPF';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.pix, color: AppColors.primary, size: 28),
              const SizedBox(width: 10),
              const Text('Chave PIX'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tipo da chave',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedType,
                    isExpanded: true,
                    items: _pixKeyTypes.map((type) {
                      return DropdownMenuItem(
                        value: type['value'],
                        child: Text(type['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chave PIX',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pixKeyController,
                decoration: InputDecoration(
                  hintText: _getPixKeyHint(selectedType),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                keyboardType: _getKeyboardType(selectedType),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      await _savePixKey(pixKeyController.text.trim(), selectedType);
                      if (mounted) Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  String _getPixKeyHint(String type) {
    switch (type) {
      case 'CPF':
        return '000.000.000-00';
      case 'CNPJ':
        return '00.000.000/0000-00';
      case 'EMAIL':
        return 'email@exemplo.com';
      case 'PHONE':
        return '(00) 00000-0000';
      case 'EVP':
        return 'Chave aleatória';
      default:
        return '';
    }
  }

  TextInputType _getKeyboardType(String type) {
    switch (type) {
      case 'CPF':
      case 'CNPJ':
      case 'PHONE':
        return TextInputType.number;
      case 'EMAIL':
        return TextInputType.emailAddress;
      default:
        return TextInputType.text;
    }
  }

  Future<void> _savePixKey(String pixKey, String pixKeyType) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        _showErrorSnackBar('Sessão expirada. Faça login novamente.');
        return;
      }

      final response = await http.post(
        Uri.parse('${url}api/v1/driver/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pixKey': pixKey.isEmpty ? null : pixKey,
          'pixKeyType': pixKey.isEmpty ? null : pixKeyType,
        }),
      );

      debugPrint('📤 Salvando PIX: ${response.statusCode}');
      debugPrint('📤 Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          _showSuccessSnackBar('Chave PIX atualizada com sucesso!');
          await _loadProfile();
        } else {
          _showErrorSnackBar(jsonResponse['message'] ?? 'Erro ao atualizar chave PIX');
        }
      } else {
        _showErrorSnackBar('Erro ao atualizar chave PIX');
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar PIX: $e');
      _showErrorSnackBar('Erro ao atualizar chave PIX');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dados pessoais - estrutura do endpoint /api/v1/driver/profile
    final String fullName = _driverProfile?['name']?.toString() ??
                            _driverProfile?['nome']?.toString() ?? 'Não informado';
    final String email = _driverProfile?['email']?.toString() ?? 'Não informado';
    final String whatsapp = _driverProfile?['mobile']?.toString() ?? 'Não informado';
    final String cpf = _driverProfile?['cpf']?.toString() ?? 'Não informado';
    final String? profilePicture = _driverProfile?['profilePicture']?.toString();

    // Chave PIX
    final String pixKey = _driverProfile?['pixKey']?.toString() ?? '';
    final String pixDisplay = pixKey.isNotEmpty ? pixKey : 'Não cadastrada';

    // Cidade - nova estrutura com objeto cidade
    final cidadeObj = _driverProfile?['cidade'] as Map<String, dynamic>?;
    String city = 'Não informado';
    if (cidadeObj != null && cidadeObj['name'] != null) {
      city = cidadeObj['name'].toString();
      if (cidadeObj['state'] != null && cidadeObj['state'].toString().isNotEmpty) {
        city = '$city - ${cidadeObj['state']}';
      }
    }

    // Dados do veículo - nova estrutura com objetos categoria, marca, modelo
    final categoriaObj = _driverProfile?['categoria'] as Map<String, dynamic>?;
    final marcaObj = _driverProfile?['marca'] as Map<String, dynamic>?;
    final modeloObj = _driverProfile?['modelo'] as Map<String, dynamic>?;

    final String category = categoriaObj?['name']?.toString() ?? 'Não informado';
    final String brand = marcaObj?['name']?.toString() ?? 'Não informado';
    final String model = modeloObj?['name']?.toString() ?? 'Não informado';
    final String plate = _driverProfile?['carNumber']?.toString() ?? 'Não informado';
    final String color = _driverProfile?['carColor']?.toString() ?? 'Não informado';
    final String year = _driverProfile?['carYear']?.toString() ?? 'Não informado';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Meus Dados',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Header com foto
                    Container(
                      color: Colors.white,
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Foto do perfil
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                              border: Border.all(
                                color: AppColors.primary,
                                width: 3,
                              ),
                            ),
                            child: profilePicture != null && profilePicture.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      '$url$profilePicture',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey,
                                        );
                                      },
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Seção Dados Pessoais
                    _buildSectionHeader('Dados Pessoais'),
                    Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          _buildInfoItem(Icons.person_outline, 'Nome completo', fullName),
                          _buildDivider(),
                          _buildInfoItem(Icons.email_outlined, 'E-mail', email),
                          _buildDivider(),
                          _buildInfoItem(Icons.phone_outlined, 'WhatsApp', whatsapp),
                          _buildDivider(),
                          _buildInfoItem(Icons.badge_outlined, 'CPF', cpf),
                          _buildDivider(),
                          _buildInfoItem(Icons.location_city_outlined, 'Cidade', city),
                          _buildDivider(),
                          _buildEditablePixItem(pixDisplay),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Seção Veículo
                    _buildSectionHeader('Veículo Cadastrado'),
                    Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          _buildInfoItem(Icons.category_outlined, 'Categoria', category),
                          _buildDivider(),
                          _buildInfoItem(Icons.directions_car_outlined, 'Marca', brand),
                          _buildDivider(),
                          _buildInfoItem(Icons.drive_eta_outlined, 'Modelo', model),
                          _buildDivider(),
                          _buildInfoItem(Icons.pin_outlined, 'Placa', plate),
                          _buildDivider(),
                          _buildInfoItem(Icons.palette_outlined, 'Cor', color),
                          _buildDivider(),
                          _buildInfoItem(Icons.calendar_today_outlined, 'Ano', year),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      color: Color(0xFFEEEEEE),
    );
  }

  Widget _buildEditablePixItem(String value) {
    return InkWell(
      onTap: _showEditPixKeyDialog,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              Icons.pix_outlined,
              color: AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chave PIX',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: value == 'Não cadastrada' ? Colors.grey[400] : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

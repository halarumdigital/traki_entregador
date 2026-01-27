import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../styles/app_colors.dart';
import '../functions/functions.dart';
import '../services/local_storage_service.dart';
import '../services/delivery_service.dart';
import 'NavigatorPages/carteira_page.dart';
import 'NavigatorPages/entregas_ativas.dart';
import 'NavigatorPages/notification.dart';
import 'NavigatorPages/referral.dart';
import 'NavigatorPages/faq.dart';
import 'NavigatorPages/support_tickets.dart';
import 'auth/login_screen_new.dart';
import 'profile_details_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  Map<String, dynamic>? _driverProfile;
  Map<String, dynamic>? _commissionStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.wait([
      _loadDriverProfile(),
      _loadCommissionStats(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadDriverProfile() async {
    try {
      debugPrint('👤 Buscando perfil do motorista...');

      // Primeiro tentar do cache
      final cachedData = await LocalStorageService.getDriverData();
      if (cachedData != null) {
        setState(() {
          _driverProfile = cachedData;
        });
      }

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        return;
      }

      final response = await http.get(
        Uri.parse('${url}api/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          setState(() {
            _driverProfile = jsonResponse['data'];
          });
          debugPrint('✅ Perfil carregado com sucesso');
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar perfil: $e');
    }
  }

  Future<void> _loadCommissionStats() async {
    try {
      final stats = await DeliveryService.getCommissionStats();
      if (stats != null && mounted) {
        setState(() {
          _commissionStats = stats;
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar estatísticas: $e');
    }
  }

  Future<void> _logout() async {
    try {
      await LocalStorageService.clearSession();
      userDetails.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreenNew()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao fazer logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extrair dados do perfil
    final personalData = _driverProfile?['personalData'] as Map<String, dynamic>?;

    // Tentar diferentes estruturas de dados para o nome (igual ao home_simple)
    String fullName = 'Motorista';
    if (_driverProfile != null) {
      // Estrutura nova: personalData.fullName
      if (personalData?['fullName'] != null && personalData!['fullName'].toString().isNotEmpty) {
        fullName = personalData['fullName'].toString();
      }
      // Estrutura antiga: name diretamente
      else if (_driverProfile!['name'] != null && _driverProfile!['name'].toString().isNotEmpty) {
        fullName = _driverProfile!['name'].toString();
      }
    }

    final String email = personalData?['email'] ?? '';
    final String? profilePicture = personalData?['profilePicture'];
    final ratingValue = _driverProfile?['rating'];
    final double rating = ratingValue is num
        ? ratingValue.toDouble()
        : (double.tryParse(ratingValue?.toString() ?? '0') ?? 0.0);
    final noOfRatingsValue = _driverProfile?['noOfRatings'];
    final int noOfRatings = noOfRatingsValue is int
        ? noOfRatingsValue
        : (int.tryParse(noOfRatingsValue?.toString() ?? '0') ?? 0);
    final totalDeliveriesValue = _commissionStats?['currentMonthDeliveries'];
    final int totalDeliveries = totalDeliveriesValue is int
        ? totalDeliveriesValue
        : (int.tryParse(totalDeliveriesValue?.toString() ?? '0') ?? 0);

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
          'Perfil',
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
              onRefresh: _loadData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Header com foto e informações
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileDetailsScreen(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            // Foto do perfil
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[200],
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                  width: 2,
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
                                            size: 35,
                                            color: Colors.grey,
                                          );
                                        },
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 35,
                                      color: Colors.grey,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            // Nome e email
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Oi,',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    fullName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (email.isNotEmpty)
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
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Estatísticas
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Média
                          _buildStatItem(
                            icon: Icons.star,
                            iconColor: Colors.amber,
                            value: rating.toStringAsFixed(1),
                            label: 'Média',
                          ),
                          // Avaliações
                          _buildStatItem(
                            icon: Icons.chat_bubble,
                            iconColor: AppColors.primary,
                            value: noOfRatings.toString(),
                            label: 'Avaliações',
                          ),
                          // Entregas
                          _buildStatItem(
                            icon: Icons.inventory_2_outlined,
                            iconColor: AppColors.primary,
                            value: totalDeliveries.toString(),
                            label: 'Entregas',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Seção Conta
                    _buildSectionHeader('Conta'),
                    Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          _buildMenuItem(
                            icon: Icons.person_outline,
                            title: 'Meu Perfil',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfileDetailsScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.inventory_2_outlined,
                            title: 'Minhas Entregas',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EntregasAtivasScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.notifications_outlined,
                            title: 'Notificações',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NotificationPage(),
                                ),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.people_outline,
                            title: 'Indicações',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ReferralPage(),
                                ),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.attach_money,
                            title: 'Minha Carteira',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CarteiraPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Seção Adicionais
                    _buildSectionHeader('Adicionais'),
                    Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          _buildMenuItem(
                            icon: Icons.folder_outlined,
                            title: 'FAQ',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Faq(),
                                ),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.grid_view_outlined,
                            title: 'Meus tickets',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SupportTicketsPage(),
                                ),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.edit_outlined,
                            title: 'Alterar senha',
                            onTap: () {
                              // TODO: Navegar para alterar senha
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Botão Sair
                    Container(
                      color: Colors.white,
                      child: _buildMenuItem(
                        icon: Icons.logout,
                        title: 'Sair',
                        onTap: () {
                          _showLogoutDialog();
                        },
                        showArrow: true,
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (showArrow)
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
          ],
        ),
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text(
              'Sair',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

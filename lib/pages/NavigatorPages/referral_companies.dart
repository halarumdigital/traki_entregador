// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../functions/functions.dart';
import '../../services/local_storage_service.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../login/landingpage.dart';
import '../login/login.dart';
import '../noInternet/nointernet.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReferralCompaniesPage extends StatefulWidget {
  const ReferralCompaniesPage({super.key});

  @override
  State<ReferralCompaniesPage> createState() => _ReferralCompaniesPageState();
}

class _ReferralCompaniesPageState extends State<ReferralCompaniesPage> {
  bool _isLoading = true;
  String? _referralCode;
  int _totalReferrals = 0;
  int _pendingReferrals = 0;
  int _qualifiedReferrals = 0;
  int _paidReferrals = 0;
  double _totalEarned = 0.0;
  double _totalPaid = 0.0;
  double _totalPending = 0.0;
  int _requiredDeliveries = 20;
  double _commissionAmount = 100.0;
  List<Map<String, dynamic>> _referrals = [];

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🏢 Buscando dados de indicação de empresas...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        setState(() => _isLoading = false);
        return;
      }

      // Buscar dados de indicações de empresas
      debugPrint('📊 Buscando estatísticas de indicações de empresas...');
      debugPrint('📊 URL: ${url}api/v1/driver/my-company-referrals');

      final statsResponse = await http.get(
        Uri.parse('${url}api/v1/driver/my-company-referrals'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📊 Stats Status Code: ${statsResponse.statusCode}');
      debugPrint('📊 Stats Response Body: ${statsResponse.body}');

      if (statsResponse.statusCode == 200) {
        final statsJson = jsonDecode(statsResponse.body);
        debugPrint('📊 Response JSON: $statsJson');

        if (statsJson['success'] == true) {
          final data = statsJson['data'];
          debugPrint('📊 Data Keys: ${data.keys.toList()}');

          setState(() {
            // Stats
            final stats = data['stats'] ?? {};
            _totalReferrals = stats['totalReferrals'] ?? 0;
            _pendingReferrals = stats['pendingReferrals'] ?? 0;
            _qualifiedReferrals = stats['qualifiedReferrals'] ?? 0;
            _paidReferrals = stats['paidReferrals'] ?? 0;
            _totalEarned = double.tryParse(stats['totalCommissionEarned']?.toString() ?? '0') ?? 0.0;
            _totalPaid = double.tryParse(stats['totalCommissionPaid']?.toString() ?? '0') ?? 0.0;
            _totalPending = double.tryParse(stats['totalCommissionPending']?.toString() ?? '0') ?? 0.0;

            // Referrals list
            if (data['referrals'] != null && data['referrals'] is List) {
              _referrals = List<Map<String, dynamic>>.from(
                data['referrals'].map((referral) => referral as Map<String, dynamic>)
              );

              // Pegar requiredDeliveries e commissionAmount da primeira empresa
              if (_referrals.isNotEmpty) {
                _requiredDeliveries = _referrals.first['requiredDeliveries'] ?? 20;
                _commissionAmount = double.tryParse(_referrals.first['commissionAmount']?.toString() ?? '100') ?? 100.0;
              }

              debugPrint('📋 ${_referrals.length} empresas indicadas carregadas');
              if (_referrals.isNotEmpty) {
                debugPrint('📋 Primeira empresa: ${_referrals.first}');
              }
            }
          });

          debugPrint('✅ Dados carregados:');
          debugPrint('   - Total: $_totalReferrals empresas');
          debugPrint('   - Pendentes: $_pendingReferrals');
          debugPrint('   - Qualificados: $_qualifiedReferrals');
          debugPrint('   - Pagos: $_paidReferrals');
          debugPrint('   - Required Deliveries: $_requiredDeliveries');
          debugPrint('   - Commission Amount: $_commissionAmount');
        }

        // Buscar código de indicação do endpoint de motoristas
        debugPrint('🔑 Buscando código de indicação...');
        final codeResponse = await http.get(
          Uri.parse('${url}api/v1/driver/my-referrals'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (codeResponse.statusCode == 200) {
          final codeJson = jsonDecode(codeResponse.body);
          if (codeJson['success'] == true && codeJson['data']?['myReferralCode'] != null) {
            setState(() {
              _referralCode = codeJson['data']['myReferralCode'];
            });
            debugPrint('✅ Código de indicação: $_referralCode');
          }
        }
      } else {
        debugPrint('❌ Erro ao carregar dados:');
        debugPrint('   - Status Code: ${statsResponse.statusCode}');
        debugPrint('   - Response Body: ${statsResponse.body}');

        // Se falhar, tenta buscar apenas o código de indicação do endpoint de motoristas
        debugPrint('🔑 Tentando buscar código de indicação do endpoint de motoristas...');
        final codeResponse = await http.get(
          Uri.parse('${url}api/v1/driver/my-referrals'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (codeResponse.statusCode == 200) {
          final codeJson = jsonDecode(codeResponse.body);
          if (codeJson['success'] == true && codeJson['data']?['myReferralCode'] != null) {
            setState(() {
              _referralCode = codeJson['data']['myReferralCode'];
            });
            debugPrint('✅ Código de indicação obtido: $_referralCode');
          }
        }
      }

    } catch (e) {
      debugPrint('❌ Erro ao buscar dados de indicação de empresas: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_referralCode != null) {
      Clipboard.setData(ClipboardData(text: _referralCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Código copiado para a área de transferência!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareReferralCode() {
    if (_referralCode != null) {
      final message = '''
Olá! 👋

Estou usando o app Fretus Driver e quero indicar minha empresa favorita!

Use meu código de indicação: $_referralCode

Baixe o app Fretus e cadastre sua empresa para começar a fazer entregas rápidas e eficientes! 🚚💼
''';
      Share.share(message);
    }
  }

  navigateLogout() {
    if (ownermodule == '1') {
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
            (route) => false);
      });
    } else {
      ischeckownerordriver = 'driver';
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Login()),
            (route) => false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return SafeArea(
      child: Material(
        child: ValueListenableBuilder(
          valueListenable: valueNotifierHome.value,
          builder: (context, value, child) {
            return Directionality(
              textDirection: (languageDirection == 'rtl')
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Stack(
                children: [
                  Container(
                    height: media.height * 1,
                    width: media.width * 1,
                    color: page,
                    padding: EdgeInsets.fromLTRB(
                        media.width * 0.05, media.width * 0.05, media.width * 0.05, 0),
                    child: Column(
                      children: [
                        SizedBox(height: MediaQuery.of(context).padding.top),
                        Stack(
                          children: [
                            Container(
                              padding: EdgeInsets.only(bottom: media.width * 0.05),
                              width: media.width * 1,
                              alignment: Alignment.center,
                              child: MyText(
                                text: 'Indicações de Empresas',
                                size: media.width * twenty,
                                fontweight: FontWeight.w600,
                              ),
                            ),
                            Positioned(
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Icon(Icons.arrow_back_ios, color: textColor),
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: media.width * 0.05),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadReferralData,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                children: [
                                  // Card com código de indicação
                                  Container(
                                    width: media.width * 0.9,
                                    padding: EdgeInsets.all(media.width * 0.05),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.deepPurple, Colors.deepPurple.withValues(alpha: 0.7)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.deepPurple.withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.business,
                                          size: media.width * 0.15,
                                          color: Colors.white,
                                        ),
                                        SizedBox(height: media.width * 0.04),
                                        Text(
                                          'Seu Código de Indicação',
                                          style: GoogleFonts.notoSans(
                                            fontSize: media.width * sixteen,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: media.width * 0.03),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: media.width * 0.05,
                                            vertical: media.width * 0.03,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _referralCode ?? '------',
                                            style: GoogleFonts.notoSans(
                                              fontSize: media.width * 0.08,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 3,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: media.width * 0.05),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            // Botão Copiar
                                            Expanded(
                                              child: InkWell(
                                                onTap: _copyToClipboard,
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: media.width * 0.03,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.copy, color: Colors.deepPurple, size: 20),
                                                      SizedBox(width: media.width * 0.02),
                                                      Text(
                                                        'Copiar',
                                                        style: GoogleFonts.notoSans(
                                                          color: Colors.deepPurple,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: media.width * 0.03),
                                            // Botão Compartilhar
                                            Expanded(
                                              child: InkWell(
                                                onTap: _shareReferralCode,
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: media.width * 0.03,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.share, color: Colors.deepPurple, size: 20),
                                                      SizedBox(width: media.width * 0.02),
                                                      Text(
                                                        'Compartilhar',
                                                        style: GoogleFonts.notoSans(
                                                          color: Colors.deepPurple,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: media.width * 0.05),

                                  // Card com estatísticas
                                  Container(
                                    width: media.width * 0.9,
                                    padding: EdgeInsets.all(media.width * 0.05),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: borderLines, width: 1.2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.business_center,
                                          size: media.width * 0.12,
                                          color: Colors.deepPurple,
                                        ),
                                        SizedBox(height: media.width * 0.03),
                                        Text(
                                          '$_totalReferrals',
                                          style: GoogleFonts.notoSans(
                                            fontSize: media.width * 0.12,
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _totalReferrals == 1 ? 'Empresa Indicada' : 'Empresas Indicadas',
                                          style: GoogleFonts.notoSans(
                                            fontSize: media.width * sixteen,
                                            color: textColor.withValues(alpha: 0.7),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: media.width * 0.05),

                                  // Como funciona
                                  Container(
                                    width: media.width * 0.9,
                                    padding: EdgeInsets.all(media.width * 0.05),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.purple.shade200, width: 1.2),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: Colors.purple.shade700,
                                              size: media.width * 0.06,
                                            ),
                                            SizedBox(width: media.width * 0.02),
                                            Text(
                                              'Como funciona?',
                                              style: GoogleFonts.notoSans(
                                                fontSize: media.width * eighteen,
                                                color: Colors.purple.shade700,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: media.width * 0.04),
                                        _buildStep('1', 'Compartilhe seu código', 'Envie seu código de indicação para empresas'),
                                        SizedBox(height: media.width * 0.03),
                                        _buildStep('2', 'Elas se cadastram', 'As empresas devem usar seu código no cadastro'),
                                        SizedBox(height: media.width * 0.03),
                                        _buildStep('3', 'Ganhe recompensas', 'Você ganha benefícios quando elas fazem pedidos'),
                                      ],
                                    ),
                                  ),

                                  // Card de comissões
                                  if (_requiredDeliveries > 0) ...[
                                    SizedBox(height: media.width * 0.05),
                                    Container(
                                      width: media.width * 0.9,
                                      padding: EdgeInsets.all(media.width * 0.05),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.green.shade200, width: 1.2),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.attach_money,
                                            size: media.width * 0.12,
                                            color: Colors.green.shade700,
                                          ),
                                          SizedBox(height: media.width * 0.03),
                                          Text(
                                            'Ganhe R\$ ${_commissionAmount.toStringAsFixed(2)}',
                                            style: GoogleFonts.notoSans(
                                              fontSize: media.width * 0.06,
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: media.width * 0.02),
                                          Text(
                                            'Para cada empresa que completar $_requiredDeliveries pedidos',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.notoSans(
                                              fontSize: media.width * fourteen,
                                              color: textColor.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // Ganhos
                                  if (_totalEarned > 0 || _totalPaid > 0 || _totalPending > 0) ...[
                                    SizedBox(height: media.width * 0.05),
                                    Container(
                                      width: media.width * 0.9,
                                      padding: EdgeInsets.all(media.width * 0.05),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: borderLines, width: 1.2),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Seus Ganhos',
                                            style: GoogleFonts.notoSans(
                                              fontSize: media.width * eighteen,
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: media.width * 0.04),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  padding: EdgeInsets.all(media.width * 0.04),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade50,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        'R\$ ${_totalEarned.toStringAsFixed(2)}',
                                                        style: GoogleFonts.notoSans(
                                                          fontSize: media.width * 0.045,
                                                          color: Colors.green.shade700,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      SizedBox(height: media.width * 0.01),
                                                      Text(
                                                        'Total Ganho',
                                                        style: GoogleFonts.notoSans(
                                                          fontSize: media.width * twelve,
                                                          color: textColor.withValues(alpha: 0.6),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: media.width * 0.02),
                                              Expanded(
                                                child: Container(
                                                  padding: EdgeInsets.all(media.width * 0.04),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade50,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        'R\$ ${_totalPaid.toStringAsFixed(2)}',
                                                        style: GoogleFonts.notoSans(
                                                          fontSize: media.width * 0.045,
                                                          color: Colors.blue.shade700,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      SizedBox(height: media.width * 0.01),
                                                      Text(
                                                        'Já Recebido',
                                                        style: GoogleFonts.notoSans(
                                                          fontSize: media.width * twelve,
                                                          color: textColor.withValues(alpha: 0.6),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: media.width * 0.02),
                                              Expanded(
                                                child: Container(
                                                  padding: EdgeInsets.all(media.width * 0.04),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange.shade50,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        'R\$ ${_totalPending.toStringAsFixed(2)}',
                                                        style: GoogleFonts.notoSans(
                                                          fontSize: media.width * 0.045,
                                                          color: Colors.orange.shade700,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      SizedBox(height: media.width * 0.01),
                                                      Text(
                                                        'Pendente',
                                                        style: GoogleFonts.notoSans(
                                                          fontSize: media.width * twelve,
                                                          color: textColor.withValues(alpha: 0.6),
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
                                    ),
                                  ],

                                  // Lista de indicações
                                  if (_referrals.isNotEmpty) ...[
                                    SizedBox(height: media.width * 0.05),
                                    Container(
                                      width: media.width * 0.9,
                                      padding: EdgeInsets.all(media.width * 0.05),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: borderLines, width: 1.2),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Empresas Indicadas',
                                            style: GoogleFonts.notoSans(
                                              fontSize: media.width * eighteen,
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: media.width * 0.03),
                                          ..._referrals.map((referral) {
                                            final String status = referral['status'] ?? 'pending';
                                            final int ordersCompleted = referral['completedDeliveries'] ?? 0;
                                            final double commissionAmount = double.tryParse(referral['commissionAmount']?.toString() ?? '0') ?? 0.0;
                                            final bool commissionPaid = status == 'paid';
                                            final bool isQualified = status == 'qualified' || status == 'paid';

                                            final String companyName = referral['companyName'] ??
                                                                        referral['name'] ??
                                                                        referral['company_name'] ??
                                                                        'Empresa';

                                            // Calcular progresso
                                            final int remaining = _requiredDeliveries - ordersCompleted;
                                            final double progress = _requiredDeliveries > 0
                                                ? (ordersCompleted / _requiredDeliveries).clamp(0.0, 1.0)
                                                : 0.0;

                                            // Definir cor do status
                                            Color statusColor;
                                            String statusText;
                                            switch (status) {
                                              case 'paid':
                                                statusColor = Colors.blue;
                                                statusText = 'Pago';
                                                break;
                                              case 'qualified':
                                                statusColor = Colors.green;
                                                statusText = 'Qualificado';
                                                break;
                                              case 'pending':
                                              default:
                                                statusColor = Colors.orange;
                                                statusText = 'Pendente';
                                            }

                                            return Container(
                                              margin: EdgeInsets.only(bottom: media.width * 0.03),
                                              padding: EdgeInsets.all(media.width * 0.04),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isQualified ? Colors.green.shade200 : borderLines,
                                                  width: isQualified ? 2 : 1,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Header com nome e status
                                                  Row(
                                                    children: [
                                                      CircleAvatar(
                                                        backgroundColor: statusColor,
                                                        radius: media.width * 0.05,
                                                        child: Icon(
                                                          Icons.business,
                                                          color: Colors.white,
                                                          size: media.width * 0.05,
                                                        ),
                                                      ),
                                                      SizedBox(width: media.width * 0.03),
                                                      Expanded(
                                                        child: Text(
                                                          companyName,
                                                          style: GoogleFonts.notoSans(
                                                            fontSize: media.width * sixteen,
                                                            fontWeight: FontWeight.bold,
                                                            color: textColor,
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: EdgeInsets.symmetric(
                                                          horizontal: media.width * 0.025,
                                                          vertical: media.width * 0.015,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: statusColor.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          statusText,
                                                          style: GoogleFonts.notoSans(
                                                            fontSize: media.width * twelve,
                                                            color: statusColor,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: media.width * 0.03),

                                                  // Progresso de pedidos
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.shopping_cart,
                                                        size: media.width * 0.045,
                                                        color: textColor.withValues(alpha: 0.6),
                                                      ),
                                                      SizedBox(width: media.width * 0.02),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                Text(
                                                                  'Pedidos completados',
                                                                  style: GoogleFonts.notoSans(
                                                                    fontSize: media.width * twelve,
                                                                    color: textColor.withValues(alpha: 0.7),
                                                                  ),
                                                                ),
                                                                Text(
                                                                  '$ordersCompleted/$_requiredDeliveries',
                                                                  style: GoogleFonts.notoSans(
                                                                    fontSize: media.width * twelve,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: textColor,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            SizedBox(height: media.width * 0.01),
                                                            ClipRRect(
                                                              borderRadius: BorderRadius.circular(10),
                                                              child: LinearProgressIndicator(
                                                                value: progress,
                                                                backgroundColor: Colors.grey.shade200,
                                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                                  isQualified ? Colors.green : Colors.deepPurple,
                                                                ),
                                                                minHeight: media.width * 0.015,
                                                              ),
                                                            ),
                                                            if (remaining > 0) ...[
                                                              SizedBox(height: media.width * 0.01),
                                                              Text(
                                                                'Faltam $remaining pedidos',
                                                                style: GoogleFonts.notoSans(
                                                                  fontSize: media.width * twelve,
                                                                  color: textColor.withValues(alpha: 0.5),
                                                                  fontStyle: FontStyle.italic,
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  // Comissão
                                                  if (isQualified) ...[
                                                    SizedBox(height: media.width * 0.03),
                                                    Container(
                                                      padding: EdgeInsets.all(media.width * 0.03),
                                                      decoration: BoxDecoration(
                                                        color: commissionPaid
                                                            ? Colors.blue.shade50
                                                            : Colors.green.shade50,
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(
                                                          color: commissionPaid
                                                              ? Colors.blue.shade200
                                                              : Colors.green.shade200,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            commissionPaid
                                                                ? Icons.check_circle
                                                                : Icons.attach_money,
                                                            color: commissionPaid
                                                                ? Colors.blue.shade700
                                                                : Colors.green.shade700,
                                                            size: media.width * 0.05,
                                                          ),
                                                          SizedBox(width: media.width * 0.02),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  commissionPaid
                                                                      ? 'Comissão paga'
                                                                      : 'Comissão qualificada',
                                                                  style: GoogleFonts.notoSans(
                                                                    fontSize: media.width * twelve,
                                                                    color: commissionPaid
                                                                        ? Colors.blue.shade700
                                                                        : Colors.green.shade700,
                                                                    fontWeight: FontWeight.w600,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  'R\$ ${commissionAmount.toStringAsFixed(2)}',
                                                                  style: GoogleFonts.notoSans(
                                                                    fontSize: media.width * fourteen,
                                                                    color: commissionPaid
                                                                        ? Colors.blue.shade900
                                                                        : Colors.green.shade900,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          if (!commissionPaid)
                                                            Container(
                                                              padding: EdgeInsets.symmetric(
                                                                horizontal: media.width * 0.02,
                                                                vertical: media.width * 0.01,
                                                              ),
                                                              decoration: BoxDecoration(
                                                                color: Colors.orange,
                                                                borderRadius: BorderRadius.circular(6),
                                                              ),
                                                              child: Text(
                                                                'Aguardando',
                                                                style: GoogleFonts.notoSans(
                                                                  fontSize: media.width * twelve,
                                                                  color: Colors.white,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: media.width * 0.1),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // No internet
                  (internet == false)
                      ? Positioned(
                          top: 0,
                          child: NoInternet(
                            onTap: () {
                              setState(() {
                                internetTrue();
                                _loadReferralData();
                              });
                            },
                          ),
                        )
                      : Container(),

                  // Loader
                  (_isLoading == true)
                      ? const Positioned(top: 0, child: Loading())
                      : Container(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStep(String number, String title, String description) {
    var media = MediaQuery.of(context).size;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: media.width * 0.08,
          height: media.width * 0.08,
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.notoSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: media.width * fourteen,
              ),
            ),
          ),
        ),
        SizedBox(width: media.width * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.notoSans(
                  fontSize: media.width * fourteen,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              SizedBox(height: media.width * 0.01),
              Text(
                description,
                style: GoogleFonts.notoSans(
                  fontSize: media.width * twelve,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

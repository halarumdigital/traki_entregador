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

class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  bool _isLoading = true;
  String? _referralCode;
  int _totalReferrals = 0;
  int _activeReferrals = 0;
  double _totalEarned = 0.0;
  double _totalPaid = 0.0;
  int _minimumDeliveries = 0;
  double _commissionAmount = 0.0;
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
      debugPrint('👤 Buscando dados de indicação...');

      final token = await LocalStorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ Token não encontrado');
        setState(() => _isLoading = false);
        return;
      }

      // Buscar dados de indicações (inclui o código também)
      debugPrint('📥 Buscando dados de indicações...');
      final referralsResponse = await http.get(
        Uri.parse('${url}api/v1/driver/my-referrals'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📥 Referrals Status Code: ${referralsResponse.statusCode}');

      if (referralsResponse.statusCode == 200) {
        final referralsJson = jsonDecode(referralsResponse.body);
        if (referralsJson['success'] == true) {
          final data = referralsJson['data'];

          setState(() {
            // Código de indicação
            _referralCode = data['myReferralCode'];

            // Settings
            final settings = data['settings'] ?? {};
            _minimumDeliveries = settings['minimumDeliveries'] ?? 0;
            _commissionAmount = double.tryParse(settings['commissionAmount']?.toString() ?? '0') ?? 0.0;

            // Totals
            final totals = data['totals'] ?? {};
            _totalReferrals = totals['totalReferrals'] ?? 0;
            _activeReferrals = totals['activeReferrals'] ?? 0;
            _totalEarned = double.tryParse(totals['totalEarned']?.toString() ?? '0') ?? 0.0;
            _totalPaid = double.tryParse(totals['totalPaid']?.toString() ?? '0') ?? 0.0;

            // Referrals list
            if (data['referrals'] != null && data['referrals'] is List) {
              _referrals = List<Map<String, dynamic>>.from(
                data['referrals'].map((referral) => referral as Map<String, dynamic>)
              );
              debugPrint('📋 Indicações recebidas: ${_referrals.length}');
              if (_referrals.isNotEmpty) {
                debugPrint('📋 Primeira indicação - Dados completos: ${_referrals.first}');
              }
            }
          });
          debugPrint('✅ Código de indicação: $_referralCode');
          debugPrint('✅ Total de indicações: $_totalReferrals');
        }
      } else {
        debugPrint('❌ Erro ao carregar dados de indicação: ${referralsResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar dados de indicação: $e');
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

Estou usando o app Fretus Driver e quero te indicar para fazer parte também!

Use meu código de indicação: $_referralCode

Baixe o app e cadastre-se para começar a ganhar dinheiro fazendo entregas! 🚚💰
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
                                text: 'Indicações',
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
                                        colors: [buttonColor, buttonColor.withValues(alpha: 0.7)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: buttonColor.withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.card_giftcard,
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
                                                      Icon(Icons.copy, color: buttonColor, size: 20),
                                                      SizedBox(width: media.width * 0.02),
                                                      Text(
                                                        'Copiar',
                                                        style: GoogleFonts.notoSans(
                                                          color: buttonColor,
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
                                                      Icon(Icons.share, color: buttonColor, size: 20),
                                                      SizedBox(width: media.width * 0.02),
                                                      Text(
                                                        'Compartilhar',
                                                        style: GoogleFonts.notoSans(
                                                          color: buttonColor,
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
                                          Icons.people,
                                          size: media.width * 0.12,
                                          color: buttonColor,
                                        ),
                                        SizedBox(height: media.width * 0.03),
                                        Text(
                                          '$_totalReferrals',
                                          style: GoogleFonts.notoSans(
                                            fontSize: media.width * 0.12,
                                            color: buttonColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _totalReferrals == 1 ? 'Indicação' : 'Indicações',
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
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.blue.shade200, width: 1.2),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: Colors.blue.shade700,
                                              size: media.width * 0.06,
                                            ),
                                            SizedBox(width: media.width * 0.02),
                                            Text(
                                              'Como funciona?',
                                              style: GoogleFonts.notoSans(
                                                fontSize: media.width * eighteen,
                                                color: Colors.blue.shade700,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: media.width * 0.04),
                                        _buildStep('1', 'Compartilhe seu código', 'Envie seu código de indicação para amigos motoristas'),
                                        SizedBox(height: media.width * 0.03),
                                        _buildStep('2', 'Eles se cadastram', 'Seus amigos devem usar seu código no cadastro'),
                                        SizedBox(height: media.width * 0.03),
                                        _buildStep('3', 'Ganhe recompensas', 'Você e seu amigo ganham benefícios especiais'),
                                      ],
                                    ),
                                  ),

                                  // Card de comissões
                                  if (_minimumDeliveries > 0) ...[
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
                                            'Para cada amigo que completar $_minimumDeliveries entregas',
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
                                  if (_totalEarned > 0 || _totalPaid > 0) ...[
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
                                                          fontSize: media.width * 0.05,
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
                                              SizedBox(width: media.width * 0.03),
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
                                                          fontSize: media.width * 0.05,
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
                                            'Suas Indicações',
                                            style: GoogleFonts.notoSans(
                                              fontSize: media.width * eighteen,
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: media.width * 0.03),
                                          ..._referrals.map((referral) {
                                            final String status = referral['status'] ?? 'pending';
                                            final int deliveriesCompleted = referral['deliveriesCompleted'] ?? 0;
                                            final double commissionEarned = double.tryParse(referral['commissionEarned']?.toString() ?? '0') ?? 0.0;
                                            final bool commissionPaid = referral['commissionPaid'] == true;
                                            final bool isQualified = commissionEarned > 0;

                                            // Tenta obter o nome de diferentes campos possíveis
                                            final String referredName = referral['referredName'] ??
                                                                        referral['name'] ??
                                                                        referral['driverName'] ??
                                                                        referral['referred_name'] ??
                                                                        referral['driver_name'] ??
                                                                        'Motorista';

                                            debugPrint('👤 Indicado: $referredName (campos disponíveis: ${referral.keys.toList()})');

                                            // Calcular progresso
                                            final int remaining = _minimumDeliveries - deliveriesCompleted;
                                            final double progress = _minimumDeliveries > 0
                                                ? (deliveriesCompleted / _minimumDeliveries).clamp(0.0, 1.0)
                                                : 0.0;

                                            // Definir cor do status
                                            Color statusColor;
                                            String statusText;
                                            switch (status) {
                                              case 'active':
                                                statusColor = Colors.green;
                                                statusText = 'Ativo';
                                                break;
                                              case 'registered':
                                                statusColor = Colors.orange;
                                                statusText = 'Cadastrado';
                                                break;
                                              default:
                                                statusColor = Colors.grey;
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
                                                          Icons.person,
                                                          color: Colors.white,
                                                          size: media.width * 0.05,
                                                        ),
                                                      ),
                                                      SizedBox(width: media.width * 0.03),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              referredName,
                                                              style: GoogleFonts.notoSans(
                                                                fontSize: media.width * sixteen,
                                                                fontWeight: FontWeight.bold,
                                                                color: textColor,
                                                              ),
                                                            ),
                                                            if (referral['referredPhone'] != null)
                                                              Text(
                                                                referral['referredPhone'],
                                                                style: GoogleFonts.notoSans(
                                                                  fontSize: media.width * twelve,
                                                                  color: textColor.withValues(alpha: 0.6),
                                                                ),
                                                              ),
                                                          ],
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

                                                  // Progresso de entregas
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.local_shipping,
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
                                                                  'Entregas completadas',
                                                                  style: GoogleFonts.notoSans(
                                                                    fontSize: media.width * twelve,
                                                                    color: textColor.withValues(alpha: 0.7),
                                                                  ),
                                                                ),
                                                                Text(
                                                                  '$deliveriesCompleted/$_minimumDeliveries',
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
                                                                  isQualified ? Colors.green : buttonColor,
                                                                ),
                                                                minHeight: media.width * 0.015,
                                                              ),
                                                            ),
                                                            if (remaining > 0) ...[
                                                              SizedBox(height: media.width * 0.01),
                                                              Text(
                                                                'Faltam $remaining entregas',
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
                                                                  'R\$ ${commissionEarned.toStringAsFixed(2)}',
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
            color: buttonColor,
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

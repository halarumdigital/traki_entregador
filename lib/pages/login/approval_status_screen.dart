import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_driver/models/approval_status_model.dart';
import 'package:flutter_driver/functions/functions.dart';
import 'package:flutter_driver/styles/styles.dart';
import 'package:intl/intl.dart';
import 'package:flutter_driver/services/local_storage_service.dart';
import 'package:flutter_driver/pages/login/login.dart';
import 'package:flutter_driver/pages/login/document_upload_screen.dart';

class ApprovalStatusScreen extends StatefulWidget {
  final String driverId;

  const ApprovalStatusScreen({
    super.key,
    required this.driverId,
  });

  @override
  State<ApprovalStatusScreen> createState() => _ApprovalStatusScreenState();
}

class _ApprovalStatusScreenState extends State<ApprovalStatusScreen> {
  ApprovalStatusData? statusData;
  bool isLoading = true;
  String? errorMessage;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    // Atualizar a cada 30 segundos
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _loadStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      debugPrint('📊 Carregando status para driver: ${widget.driverId}');
      final data = await getDriverApprovalStatus(widget.driverId);

      if (mounted) {
        setState(() {
          statusData = data;
          isLoading = false;
          errorMessage = null;
        });

        debugPrint('✅ Status carregado: ${data.status}');
        debugPrint('🔐 Pode fazer login: ${data.canLogin}');

        // Se aprovado, redirecionar para login
        if (data.canLogin) {
          _showApprovedDialog();
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar status: $e');
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  void _showApprovedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.green, size: 32),
            SizedBox(width: 8),
            Text('Cadastro Aprovado!'),
          ],
        ),
        content: Text(
          'Seu cadastro foi aprovado pelo administrador. '
          'Você já pode fazer login e começar a trabalhar!',
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
              child: Text('Ir para Login', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: page,
        appBar: AppBar(
          backgroundColor: topBar,
          title: Text('Status do Cadastro', style: TextStyle(color: textColor)),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: buttonColor),
              SizedBox(height: 16),
              Text('Carregando seu status...', style: TextStyle(color: textColor)),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: page,
        appBar: AppBar(
          backgroundColor: topBar,
          title: Text('Status do Cadastro', style: TextStyle(color: textColor)),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Erro ao carregar status',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                      errorMessage = null;
                    });
                    _loadStatus();
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: page,
      appBar: AppBar(
        backgroundColor: topBar,
        title: Text('Status do Cadastro', style: TextStyle(color: textColor)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textColor),
            onPressed: _loadStatus,
            tooltip: 'Atualizar',
          ),
          IconButton(
            icon: Icon(Icons.logout, color: textColor),
            onPressed: () async {
              // Confirmar logout
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Sair'),
                  content: Text('Deseja realmente sair?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Sair', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                // Limpar sessão
                await LocalStorageService.clearSession();

                // Ir para login
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                    (route) => false,
                  );
                }
              }
            },
            tooltip: 'Sair',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatus,
        color: buttonColor,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              _buildTimeline(),
              _buildActionButton(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getStatusGradient(statusData!.status),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              statusData!.driverName.isNotEmpty
                  ? statusData!.driverName[0].toUpperCase()
                  : 'M',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: buttonColor),
            ),
          ),
          SizedBox(height: 16),
          Text(
            statusData!.driverName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusMessage(statusData!.status),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progresso do Cadastro',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 24),
          ...statusData!.timeline.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == statusData!.timeline.length - 1;
            return _buildTimelineItem(step, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(TimelineStep step, bool isLast) {
    final color = _getStepColor(step.status);
    final icon = _getStatusIcon(step.status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 70,
                margin: EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color,
                      Colors.grey[300]!,
                    ],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _adjustDescription(step.description),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (step.date != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                        SizedBox(width: 4),
                        Text(
                          _formatDate(step.date!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildActionButton() {
    // Se ainda não enviou documentos, mostrar botão de enviar
    if (statusData!.statistics.uploadedDocuments < statusData!.statistics.totalDocuments) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentUploadScreen(
                    driverId: widget.driverId,
                  ),
                ),
              );

              // Recarregar status após voltar da tela de upload
              if (result != null || mounted) {
                _loadStatus();
              }
            },
            icon: Icon(Icons.upload_file, color: Colors.white),
            label: Text('Enviar Documentos', style: TextStyle(fontSize: 16, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      );
    }

    if (statusData!.status == 'rejected') {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentUploadScreen(
                    driverId: widget.driverId,
                  ),
                ),
              );

              // Recarregar status após voltar da tela de upload
              if (result != null || mounted) {
                _loadStatus();
              }
            },
            icon: Icon(Icons.upload_file, color: Colors.white),
            label: Text('Reenviar Documentos', style: TextStyle(fontSize: 16, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      );
    }

    // Sem botão de ação quando documentos já foram enviados e está aguardando aprovação
    return SizedBox.shrink();
  }

  List<Color> _getStatusGradient(String status) {
    switch (status) {
      case 'approved':
        return [Colors.green[400]!, Colors.green[700]!];
      case 'under_review':
        return [Colors.blue[400]!, Colors.blue[700]!];
      case 'rejected':
        return [Colors.red[400]!, Colors.red[700]!];
      default:
        return [Colors.orange[400]!, Colors.orange[700]!];
    }
  }

  Color _getStepColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey[400]!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.hourglass_bottom;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'approved':
        return '🎉 Cadastro Aprovado!';
      case 'under_review':
        return '⏳ Em Análise';
      case 'rejected':
        return '⚠️ Documentos Rejeitados';
      default:
        return '📝 Aguardando Análise';
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _adjustDescription(String description) {
    // Substituir a frase longa pela versão curta
    return description
        .replaceAll('Aguardando aprovação final do administrador', 'Aguardando aprovação final')
        .replaceAll('aguardando aprovação final do administrador', 'Aguardando aprovação final');
  }
}

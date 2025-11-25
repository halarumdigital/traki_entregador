import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';

class CarteiraPage extends StatefulWidget {
  const CarteiraPage({super.key});

  @override
  State<CarteiraPage> createState() => _CarteiraPageState();
}

class _CarteiraPageState extends State<CarteiraPage> {
  bool _isLoading = true;
  bool _isWithdrawing = false;
  Map<String, dynamic>? _balanceData;
  List<dynamic> _withdrawHistory = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final results = await Future.wait([
        getDriverBalance(),
        getWithdrawHistory(),
      ]);

      if (mounted) {
        final balanceResponse = results[0] as Map<String, dynamic>?;

        setState(() {
          // A API retorna { success: true, data: { ... } }
          // Precisamos extrair o 'data' interno
          if (balanceResponse != null && balanceResponse['success'] == true) {
            _balanceData = balanceResponse['data'] as Map<String, dynamic>?;
          } else {
            _balanceData = balanceResponse;
          }
          _withdrawHistory = results[1] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar dados';
          _isLoading = false;
        });
      }
    }
  }

  void _showWithdrawConfirmation() {
    if (_balanceData == null) return;

    final saque = _balanceData!['saque'];
    if (saque == null) return;

    final bool podeSacar = saque['podeSacarHoje'] ?? false;
    final double valorDisponivel = (saque['valorDisponivelParaSaque'] ?? 0).toDouble();
    final double taxaSaque = (saque['taxaSaque'] ?? 1.50).toDouble();
    final String mensagem = saque['mensagem'] ?? '';

    if (!podeSacar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem.isNotEmpty ? mensagem : 'Você já realizou um saque hoje. Limite: 1 saque por dia.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (valorDisponivel <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saldo insuficiente para saque.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 10),
            const Text('Confirmar Saque'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Taxa de saque: R\$ ${taxaSaque.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Valor disponível:', 'R\$ ${valorDisponivel.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildInfoRow('Taxa:', '- R\$ ${taxaSaque.toStringAsFixed(2)}'),
            const Divider(height: 24),
            _buildInfoRow(
              'Você receberá:',
              'R\$ ${valorDisponivel.toStringAsFixed(2)}',
              isTotal: true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Limite: 1 saque por dia',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
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
            onPressed: () {
              Navigator.pop(context);
              _performWithdraw();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Saque'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: textColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? Colors.green : textColor,
          ),
        ),
      ],
    );
  }

  Future<void> _performWithdraw() async {
    setState(() {
      _isWithdrawing = true;
    });

    final result = await requestDriverWithdraw();

    if (mounted) {
      setState(() {
        _isWithdrawing = false;
      });

      if (result['success'] == true) {
        final data = result['data'];
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 10),
                const Text('Saque Realizado!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'R\$ ${(data['valorRecebido'] ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Transferido para sua chave PIX',
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Taxa cobrada: R\$ ${(data['taxaSaque'] ?? 1.50).toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadData(); // Recarregar dados
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erro ao realizar saque'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: page,
      appBar: AppBar(
        backgroundColor: buttonColor,
        title: const Text('Carteira', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(_error, style: TextStyle(color: textColor)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: buttonColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card de Saldo
                        _buildBalanceCard(),
                        const SizedBox(height: 20),

                        // Botão de Saque
                        _buildWithdrawButton(),
                        const SizedBox(height: 30),

                        // Histórico de Saques
                        _buildWithdrawHistorySection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildBalanceCard() {
    final double saldoDisponivel = (_balanceData?['saldoDisponivel'] ?? 0).toDouble();
    final saque = _balanceData?['saque'];
    final bool podeSacar = saque?['podeSacarHoje'] ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [buttonColor, buttonColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo Disponível',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: podeSacar ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  podeSacar ? 'Saque disponível' : 'Saque indisponível',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'R\$ ${saldoDisponivel.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (saque != null && saque['mensagem'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      saque['mensagem'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
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
  }

  Widget _buildWithdrawButton() {
    final saque = _balanceData?['saque'];
    final bool podeSacar = saque?['podeSacarHoje'] ?? false;
    final double valorDisponivel = (saque?['valorDisponivelParaSaque'] ?? 0).toDouble();

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isWithdrawing || !podeSacar || valorDisponivel <= 0
            ? null
            : _showWithdrawConfirmation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isWithdrawing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    podeSacar && valorDisponivel > 0
                        ? 'Sacar R\$ ${valorDisponivel.toStringAsFixed(2)}'
                        : 'Saque Indisponível',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildWithdrawHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: buttonColor, size: 24),
            const SizedBox(width: 8),
            Text(
              'Histórico de Saques',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_withdrawHistory.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'Nenhum saque realizado',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        else
          ...(_withdrawHistory.map((withdraw) => _buildWithdrawHistoryItem(withdraw))),
      ],
    );
  }

  Widget _buildWithdrawHistoryItem(dynamic withdraw) {
    final double valor = (withdraw['valor'] ?? withdraw['valorRecebido'] ?? 0).toDouble();
    final double taxa = (withdraw['taxa'] ?? withdraw['taxaSaque'] ?? 0).toDouble();
    final String status = withdraw['status'] ?? 'completed';
    final String data = withdraw['createdAt'] ?? withdraw['data'] ?? '';

    String formattedDate = data;
    try {
      if (data.isNotEmpty) {
        final dateTime = DateTime.parse(data);
        formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
      }
    } catch (e) {
      // Mantém a data original se não conseguir parsear
    }

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'concluido':
        statusColor = Colors.green;
        statusText = 'Concluído';
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
      case 'pendente':
        statusColor = Colors.orange;
        statusText = 'Pendente';
        statusIcon = Icons.schedule;
        break;
      case 'failed':
      case 'falhou':
        statusColor = Colors.red;
        statusText = 'Falhou';
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'R\$ ${valor.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Taxa: R\$ ${taxa.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

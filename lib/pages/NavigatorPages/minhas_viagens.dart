// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/viagem.dart';
import '../../services/viagens_service.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';
import 'viagem_ativa_screen.dart';

class MinhasViagensScreen extends StatefulWidget {
  const MinhasViagensScreen({super.key});

  @override
  State<MinhasViagensScreen> createState() => _MinhasViagensScreenState();
}

class _MinhasViagensScreenState extends State<MinhasViagensScreen> {
  bool _isLoading = true;
  List<Viagem> _viagens = [];
  String _filtroStatus = 'todos'; // todos, agendada, em_andamento, concluida

  @override
  void initState() {
    super.initState();
    _loadViagens();
  }

  Future<void> _loadViagens() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final viagens = await ViagensService.getMinhasViagens();
      setState(() {
        _viagens = viagens;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar viagens: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Viagem> get _viagensFiltradas {
    if (_filtroStatus == 'todos') return _viagens;

    if (_filtroStatus == 'em_andamento') {
      return _viagens.where((v) => v.emAndamento).toList();
    }

    return _viagens.where((v) => v.status == _filtroStatus).toList();
  }

  Future<void> _abrirViagem(Viagem viagem) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViagemAtivaScreen(viagemId: viagem.id),
      ),
    );

    if (resultado == true) {
      _loadViagens();
    }
  }

  Future<void> _iniciarViagem(Viagem viagem) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar Viagem'),
        content: Text(
          'Deseja iniciar a viagem?\n\n'
          'Rota: ${viagem.rotaNome}\n'
          'Coletas: ${viagem.totalColetas}\n'
          'Entregas: ${viagem.totalEntregas}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Iniciar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final sucesso = await ViagensService.iniciarViagem(viagem.id);
      Navigator.pop(context); // Fechar loading

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Viagem iniciada!'),
            backgroundColor: Colors.green,
          ),
        );
        _abrirViagem(viagem);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao iniciar viagem'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Material(
      child: Scaffold(
        backgroundColor: page,
        body: Column(
          children: [
            // AppBar
            Container(
              padding: EdgeInsets.only(
                left: media.width * 0.05,
                right: media.width * 0.05,
                top: MediaQuery.of(context).padding.top + media.width * 0.05,
                bottom: media.width * 0.05,
              ),
              decoration: BoxDecoration(
                color: theme,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: media.width * 0.1,
                      width: media.width * 0.1,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: media.width * 0.05,
                      ),
                    ),
                  ),
                  SizedBox(width: media.width * 0.03),
                  Expanded(
                    child: MyText(
                      text: 'Minhas Viagens',
                      size: media.width * twenty,
                      fontweight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Filtros
            _buildFiltros(media),

            // Conteúdo
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(theme)))
                  : _viagensFiltradas.isEmpty
                      ? _buildEmptyState(media)
                      : RefreshIndicator(
                          onRefresh: _loadViagens,
                          child: ListView.builder(
                            padding: EdgeInsets.all(media.width * 0.05),
                            itemCount: _viagensFiltradas.length,
                            itemBuilder: (context, index) {
                              return _buildViagemCard(_viagensFiltradas[index], media);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros(Size media) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: media.width * 0.05,
        vertical: media.width * 0.03,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFiltroChip('Todas', 'todos', media),
            SizedBox(width: media.width * 0.02),
            _buildFiltroChip('Agendadas', 'agendada', media),
            SizedBox(width: media.width * 0.02),
            _buildFiltroChip('Em Andamento', 'em_andamento', media),
            SizedBox(width: media.width * 0.02),
            _buildFiltroChip('Concluídas', 'concluida', media),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroChip(String label, String valor, Size media) {
    final isSelected = _filtroStatus == valor;
    return InkWell(
      onTap: () {
        setState(() {
          _filtroStatus = valor;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: media.width * 0.04,
          vertical: media.width * 0.02,
        ),
        decoration: BoxDecoration(
          color: isSelected ? theme : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: MyText(
          text: label,
          size: media.width * fourteen,
          fontweight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : textColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState(Size media) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tour_outlined,
            size: media.width * 0.2,
            color: Colors.grey[400],
          ),
          SizedBox(height: media.width * 0.05),
          MyText(
            text: 'Nenhuma viagem encontrada',
            size: media.width * sixteen,
            color: textColor.withOpacity(0.7),
          ),
        ],
      ),
    );
  }

  Widget _buildViagemCard(Viagem viagem, Size media) {
    Color statusColor;
    IconData statusIcon;

    switch (viagem.status) {
      case 'agendada':
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        break;
      case 'em_transito':
      case 'em_entrega':
        statusColor = Colors.orange;
        statusIcon = Icons.local_shipping;
        break;
      case 'concluida':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      margin: EdgeInsets.only(bottom: media.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Container(
            padding: EdgeInsets.all(media.width * 0.04),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(media.width * 0.03),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    statusIcon,
                    color: Colors.white,
                    size: media.width * 0.06,
                  ),
                ),
                SizedBox(width: media.width * 0.03),
                Expanded(
                  child: Row(
                    children: [
                      // Badge status
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: media.width * 0.03,
                          vertical: media.width * 0.015,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: MyText(
                          text: viagem.statusFormatado,
                          size: media.width * twelve,
                          fontweight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                      SizedBox(width: media.width * 0.02),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: media.width * 0.035, color: textColor.withOpacity(0.6)),
                            SizedBox(width: media.width * 0.01),
                            Expanded(
                              child: MyText(
                                text: viagem.rotaNome,
                                size: media.width * twelve,
                                fontweight: FontWeight.w500,
                                color: textColor.withOpacity(0.8),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Informações
          Padding(
            padding: EdgeInsets.all(media.width * 0.04),
            child: Column(
              children: [
                // Data e horário
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.blue, size: media.width * 0.045),
                    SizedBox(width: media.width * 0.02),
                    MyText(
                      text: DateFormat('dd/MM/yyyy').format(viagem.dataViagemDate!),
                      size: media.width * fourteen,
                      fontweight: FontWeight.w600,
                      color: textColor,
                    ),
                    SizedBox(width: media.width * 0.04),
                    Icon(Icons.access_time, color: Colors.orange, size: media.width * 0.045),
                    SizedBox(width: media.width * 0.02),
                    MyText(
                      text: viagem.horarioSaidaPlanejado,
                      size: media.width * fourteen,
                      fontweight: FontWeight.w600,
                      color: textColor,
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.03),

                // Grid info
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Coletas',
                        '${viagem.coletasConcluidas}/${viagem.totalColetas}',
                        Icons.shopping_bag,
                        Colors.blue,
                        media,
                      ),
                    ),
                    SizedBox(width: media.width * 0.03),
                    Expanded(
                      child: _buildInfoItem(
                        'Entregas',
                        '${viagem.entregasConcluidas}/${viagem.totalEntregas}',
                        Icons.local_shipping,
                        Colors.orange,
                        media,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.04),

                // Botão ação
                if (viagem.podeIniciar)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _iniciarViagem(viagem),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: media.width * 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, color: Colors.white),
                          SizedBox(width: media.width * 0.02),
                          MyText(
                            text: 'Iniciar Viagem',
                            size: media.width * sixteen,
                            fontweight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (viagem.emAndamento)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _abrirViagem(viagem),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme,
                        padding: EdgeInsets.symmetric(vertical: media.width * 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map, color: Colors.white),
                          SizedBox(width: media.width * 0.02),
                          MyText(
                            text: 'Continuar Viagem',
                            size: media.width * sixteen,
                            fontweight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color, Size media) {
    return Container(
      padding: EdgeInsets.all(media.width * 0.03),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: media.width * 0.05, color: color),
          SizedBox(height: media.width * 0.01),
          MyText(
            text: value,
            size: media.width * sixteen,
            fontweight: FontWeight.bold,
            color: textColor,
          ),
          MyText(
            text: label,
            size: media.width * twelve,
            color: textColor.withOpacity(0.7),
          ),
        ],
      ),
    );
  }
}

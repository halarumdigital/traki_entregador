// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../models/minha_rota.dart';
import '../../services/rotas_service.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';
import 'rotas_disponiveis.dart';
import 'editar_rota_dialog.dart';

class MinhasRotasScreen extends StatefulWidget {
  const MinhasRotasScreen({super.key});

  @override
  State<MinhasRotasScreen> createState() => _MinhasRotasScreenState();
}

class _MinhasRotasScreenState extends State<MinhasRotasScreen> {
  bool _isLoading = true;
  List<MinhaRota> _rotas = [];

  @override
  void initState() {
    super.initState();
    _loadRotas();
  }

  Future<void> _loadRotas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rotas = await RotasService.getMinhasRotas();
      setState(() {
        _rotas = rotas;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar rotas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _adicionarNovaRota() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RotasDisponiveisScreen(),
      ),
    );

    if (resultado == true) {
      _loadRotas();
    }
  }

  Future<void> _editarRota(MinhaRota rota) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => EditarRotaDialog(rota: rota),
    );

    if (resultado == true) {
      _loadRotas();
    }
  }

  Future<void> _confirmarRemover(MinhaRota rota) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Rota'),
        content: Text(
          'Tem certeza que deseja remover a rota ${rota.rotaNome}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _removerRota(rota);
    }
  }

  Future<void> _removerRota(MinhaRota rota) async {
    final sucesso = await RotasService.removerRota(rota.id);

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rota removida com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
      _loadRotas();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao remover rota'),
          backgroundColor: Colors.red,
        ),
      );
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
            // AppBar customizado
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
                      text: 'Minhas Rotas',
                      size: media.width * twenty,
                      fontweight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.white),
                    iconSize: media.width * 0.07,
                    onPressed: _adicionarNovaRota,
                  ),
                ],
              ),
            ),

            // Conteúdo
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(theme),
                      ),
                    )
                  : _rotas.isEmpty
                      ? _buildEmptyState(media)
                      : RefreshIndicator(
                          onRefresh: _loadRotas,
                          child: ListView.builder(
                            padding: EdgeInsets.all(media.width * 0.05),
                            itemCount: _rotas.length,
                            itemBuilder: (context, index) {
                              return _buildRotaCard(_rotas[index], media);
                            },
                          ),
                        ),
            ),
          ],
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
            Icons.route_outlined,
            size: media.width * 0.2,
            color: Colors.grey[400],
          ),
          SizedBox(height: media.width * 0.05),
          MyText(
            text: 'Nenhuma rota configurada',
            size: media.width * sixteen,
            color: textColor.withOpacity(0.7),
          ),
          SizedBox(height: media.width * 0.03),
          MyText(
            text: 'Adicione rotas para começar a receber entregas',
            size: media.width * fourteen,
            color: textColor.withOpacity(0.5),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: media.width * 0.06),
          ElevatedButton.icon(
            onPressed: _adicionarNovaRota,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Adicionar Rota'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: media.width * 0.08,
                vertical: media.width * 0.04,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRotaCard(MinhaRota rota, Size media) {
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
              color: rota.ativo ? theme.withOpacity(0.1) : Colors.grey[200],
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
                    color: rota.ativo ? theme : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.route,
                    color: Colors.white,
                    size: media.width * 0.06,
                  ),
                ),
                SizedBox(width: media.width * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        text: rota.cidadeOrigemNome,
                        size: media.width * sixteen,
                        fontweight: FontWeight.bold,
                        color: textColor,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            size: media.width * 0.04,
                            color: rota.ativo ? theme : Colors.grey,
                          ),
                          SizedBox(width: media.width * 0.01),
                          MyText(
                            text: rota.cidadeDestinoNome,
                            size: media.width * fourteen,
                            fontweight: FontWeight.w600,
                            color: rota.ativo ? theme : Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Badge de status
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: media.width * 0.03,
                    vertical: media.width * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: rota.ativo ? Colors.green.withOpacity(0.2) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: MyText(
                    text: rota.ativo ? 'Ativa' : 'Inativa',
                    size: media.width * twelve,
                    fontweight: FontWeight.w600,
                    color: rota.ativo ? Colors.green : Colors.grey[700]!,
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
                // Grid de info
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Capacidade',
                        '${rota.capacidadePacotes} pacotes',
                        Icons.inventory_2,
                        Colors.blue,
                        media,
                      ),
                    ),
                    SizedBox(width: media.width * 0.03),
                    Expanded(
                      child: _buildInfoItem(
                        'Peso Máx.',
                        '${rota.capacidadePesoKg} kg',
                        Icons.scale,
                        Colors.orange,
                        media,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.03),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Horário Saída',
                        rota.horarioSaidaPadrao,
                        Icons.access_time,
                        Colors.purple,
                        media,
                      ),
                    ),
                    SizedBox(width: media.width * 0.03),
                    Expanded(
                      child: _buildInfoItem(
                        'Distância',
                        '${rota.distanciaKm} km',
                        Icons.straighten,
                        Colors.green,
                        media,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.03),

                // Dias da Semana
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(media.width * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: media.width * 0.04, color: Colors.indigo),
                          SizedBox(width: media.width * 0.02),
                          MyText(
                            text: 'Dias de Operação',
                            size: media.width * twelve,
                            color: textColor.withOpacity(0.7),
                          ),
                        ],
                      ),
                      SizedBox(height: media.width * 0.01),
                      MyText(
                        text: rota.diasSemanaFormatado,
                        size: media.width * fourteen,
                        fontweight: FontWeight.bold,
                        color: textColor,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: media.width * 0.04),

                // Botões de ação
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editarRota(rota),
                        icon: Icon(Icons.edit, size: media.width * 0.045),
                        label: const Text('Editar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme,
                          side: BorderSide(color: theme),
                          padding: EdgeInsets.symmetric(vertical: media.width * 0.03),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: media.width * 0.03),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmarRemover(rota),
                        icon: Icon(Icons.delete, size: media.width * 0.045),
                        label: const Text('Remover'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: EdgeInsets.symmetric(vertical: media.width * 0.03),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon,
    Color color,
    Size media,
  ) {
    return Container(
      padding: EdgeInsets.all(media.width * 0.03),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: media.width * 0.04, color: color),
              SizedBox(width: media.width * 0.02),
              Expanded(
                child: MyText(
                  text: label,
                  size: media.width * twelve,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
          SizedBox(height: media.width * 0.01),
          MyText(
            text: value,
            size: media.width * fourteen,
            fontweight: FontWeight.bold,
            color: textColor,
          ),
        ],
      ),
    );
  }
}

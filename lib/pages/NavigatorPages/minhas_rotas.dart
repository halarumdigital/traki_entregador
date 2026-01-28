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

  // Cor principal da tela
  static const Color _primaryColor = Colors.purple;

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

  void _mostrarDetalhes(MinhaRota rota) {
    final media = MediaQuery.of(context).size;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: EdgeInsets.all(media.width * 0.05),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: media.width * 0.1,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: media.width * 0.04),

            // Título + Status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        text: rota.cidadeOrigemNome,
                        size: media.width * eighteen,
                        fontweight: FontWeight.bold,
                        color: textColor,
                      ),
                      Row(
                        children: [
                          Icon(Icons.arrow_forward, size: media.width * 0.04, color: _primaryColor),
                          SizedBox(width: media.width * 0.01),
                          MyText(
                            text: rota.cidadeDestinoNome,
                            size: media.width * fourteen,
                            fontweight: FontWeight.w600,
                            color: _primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: media.width * 0.03,
                    vertical: media.width * 0.015,
                  ),
                  decoration: BoxDecoration(
                    color: rota.ativo ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: MyText(
                    text: rota.ativo ? 'Ativa' : 'Inativa',
                    size: media.width * twelve,
                    fontweight: FontWeight.w600,
                    color: rota.ativo ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: media.width * 0.05),

            // Grid de informações
            _buildDetalheItem(Icons.inventory_2, 'Capacidade', '${rota.capacidadePacotes} pacotes', Colors.blue, media),
            _buildDetalheItem(Icons.scale, 'Peso Máximo', '${rota.capacidadePesoKg} kg', Colors.orange, media),
            _buildDetalheItem(Icons.access_time, 'Horário de Saída', rota.horarioSaidaPadrao, Colors.purple, media),
            _buildDetalheItem(Icons.straighten, 'Distância', '${rota.distanciaKm} km', Colors.teal, media),
            _buildDetalheItem(Icons.calendar_today, 'Dias de Operação', rota.diasSemanaFormatado, Colors.indigo, media),

            SizedBox(height: media.width * 0.05),

            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: media.width * 0.12,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _editarRota(rota);
                      },
                      icon: Icon(Icons.edit, color: _primaryColor),
                      label: MyText(
                        text: 'Editar',
                        size: media.width * fourteen,
                        fontweight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: media.width * 0.03),
                Expanded(
                  child: SizedBox(
                    height: media.width * 0.12,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmarRemover(rota);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: MyText(
                        text: 'Remover',
                        size: media.width * fourteen,
                        fontweight: FontWeight.bold,
                        color: Colors.red,
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: media.width * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalheItem(IconData icon, String label, String value, Color color, Size media) {
    return Container(
      margin: EdgeInsets.only(bottom: media.width * 0.025),
      padding: EdgeInsets.symmetric(
        horizontal: media.width * 0.04,
        vertical: media.width * 0.03,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(media.width * 0.025),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: media.width * 0.05, color: color),
          ),
          SizedBox(width: media.width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: label,
                  size: media.width * twelve,
                  color: textColor.withOpacity(0.6),
                ),
                MyText(
                  text: value,
                  size: media.width * fourteen,
                  fontweight: FontWeight.bold,
                  color: textColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                color: _primaryColor,
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
                  InkWell(
                    onTap: _adicionarNovaRota,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: media.width * 0.03,
                        vertical: media.width * 0.02,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: media.width * 0.045),
                          SizedBox(width: media.width * 0.01),
                          MyText(
                            text: 'Nova',
                            size: media.width * twelve,
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

            // Conteúdo
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)))
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
            text: 'Adicione rotas para começar',
            size: media.width * fourteen,
            color: textColor.withOpacity(0.5),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: media.width * 0.06),
          ElevatedButton.icon(
            onPressed: _adicionarNovaRota,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Adicionar Rota', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
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
    return InkWell(
      onTap: () => _mostrarDetalhes(rota),
      child: Container(
        margin: EdgeInsets.only(bottom: media.width * 0.03),
        padding: EdgeInsets.all(media.width * 0.035),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: rota.ativo ? _primaryColor.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha 1: Rota + Status
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      MyText(
                        text: rota.cidadeOrigemNome,
                        size: media.width * fourteen,
                        fontweight: FontWeight.bold,
                        color: textColor,
                        maxLines: 1,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: media.width * 0.02),
                        child: Icon(Icons.arrow_forward, size: media.width * 0.035, color: _primaryColor),
                      ),
                      Expanded(
                        child: MyText(
                          text: rota.cidadeDestinoNome,
                          size: media.width * fourteen,
                          fontweight: FontWeight.bold,
                          color: _primaryColor,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: media.width * 0.02,
                    vertical: media.width * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: rota.ativo ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: MyText(
                    text: rota.ativo ? 'Ativa' : 'Inativa',
                    size: media.width * ten,
                    fontweight: FontWeight.w600,
                    color: rota.ativo ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: media.width * 0.02),

            // Linha 2: Informações compactas
            Row(
              children: [
                _buildCompactInfo(Icons.access_time, rota.horarioSaidaPadrao, media),
                _buildCompactInfo(Icons.inventory_2, '${rota.capacidadePacotes}', media),
                _buildCompactInfo(Icons.scale, '${rota.capacidadePesoKg}kg', media),
                _buildCompactInfo(Icons.straighten, '${rota.distanciaKm}km', media),
                Expanded(
                  child: MyText(
                    text: rota.diasSemanaFormatado,
                    size: media.width * ten,
                    color: textColor.withOpacity(0.6),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfo(IconData icon, String value, Size media) {
    return Padding(
      padding: EdgeInsets.only(right: media.width * 0.025),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: media.width * 0.035, color: textColor.withOpacity(0.5)),
          SizedBox(width: media.width * 0.01),
          MyText(
            text: value,
            size: media.width * ten,
            color: textColor.withOpacity(0.8),
          ),
        ],
      ),
    );
  }
}

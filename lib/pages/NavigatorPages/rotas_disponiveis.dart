// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../models/rota.dart';
import '../../services/rotas_service.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';
import 'configurar_rota_dialog.dart';

class RotasDisponiveisScreen extends StatefulWidget {
  const RotasDisponiveisScreen({super.key});

  @override
  State<RotasDisponiveisScreen> createState() => _RotasDisponiveisScreenState();
}

class _RotasDisponiveisScreenState extends State<RotasDisponiveisScreen> {
  bool _isLoading = true;
  List<Rota> _rotas = [];

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
      final rotas = await RotasService.getRotasDisponiveis();
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

  void _mostrarDetalhesRota(Rota rota) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header roxo
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(media.width * 0.05),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(media.width * 0.03),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.route,
                      color: Colors.white,
                      size: media.width * 0.07,
                    ),
                  ),
                  SizedBox(width: media.width * 0.04),
                  Expanded(
                    child: MyText(
                      text: 'Nova Rota Disponível!',
                      size: media.width * eighteen,
                      fontweight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),

            // Conteúdo
            Padding(
              padding: EdgeInsets.all(media.width * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rota (Origem → Destino)
                  _buildInfoSection(
                    icon: Icons.route,
                    label: 'Rota',
                    value: '${rota.cidadeOrigemNome} → ${rota.cidadeDestinoNome}',
                    color: _primaryColor,
                    media: media,
                  ),

                  // Nome da Rota
                  if (rota.nomeRota.isNotEmpty)
                    _buildInfoSection(
                      icon: Icons.label,
                      label: 'Nome',
                      value: rota.nomeRota,
                      color: Colors.indigo,
                      media: media,
                    ),

                  // Distância
                  _buildInfoSection(
                    icon: Icons.straighten,
                    label: 'Distância',
                    value: '${rota.distanciaKm} km',
                    color: Colors.blue,
                    media: media,
                  ),

                  // Tempo Estimado
                  _buildInfoSection(
                    icon: Icons.timer,
                    label: 'Tempo Estimado',
                    value: rota.tempoEstimadoFormatado,
                    color: Colors.orange,
                    media: media,
                  ),

                  SizedBox(height: media.width * 0.05),

                  // Botões
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: media.width * 0.04),
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: MyText(
                            text: 'Recusar',
                            size: media.width * sixteen,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      ),
                      SizedBox(width: media.width * 0.03),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _mostrarDialogConfigurar(rota);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            padding: EdgeInsets.symmetric(vertical: media.width * 0.04),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: MyText(
                            text: 'Aceitar',
                            size: media.width * sixteen,
                            fontweight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: media.width * 0.02),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Size media,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: media.width * 0.03),
      padding: EdgeInsets.all(media.width * 0.035),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: media.width * 0.055),
          SizedBox(width: media.width * 0.03),
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
                  fontweight: FontWeight.w600,
                  color: textColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogConfigurar(Rota rota) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => ConfigurarRotaDialog(rota: rota),
    );

    if (resultado == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Rota configurada com sucesso!'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context, true);
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
                  MyText(
                    text: 'Rotas Disponíveis',
                    size: media.width * twenty,
                    fontweight: FontWeight.bold,
                    color: Colors.white,
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
            text: 'Nenhuma rota disponível',
            size: media.width * sixteen,
            color: textColor.withOpacity(0.7),
          ),
          SizedBox(height: media.width * 0.03),
          MyText(
            text: 'Aguarde novas rotas serem cadastradas',
            size: media.width * fourteen,
            color: textColor.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRotaCard(Rota rota, Size media) {
    return InkWell(
      onTap: () => _mostrarDetalhesRota(rota),
      child: Container(
        margin: EdgeInsets.only(bottom: media.width * 0.03),
        padding: EdgeInsets.all(media.width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _primaryColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ícone
            Container(
              padding: EdgeInsets.all(media.width * 0.03),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.route,
                color: _primaryColor,
                size: media.width * 0.06,
              ),
            ),
            SizedBox(width: media.width * 0.035),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: '${rota.cidadeOrigemNome} → ${rota.cidadeDestinoNome}',
                    size: media.width * fourteen,
                    fontweight: FontWeight.bold,
                    color: textColor,
                  ),
                  SizedBox(height: media.width * 0.01),
                  Row(
                    children: [
                      Icon(Icons.straighten, size: media.width * 0.035, color: Colors.grey[600]),
                      SizedBox(width: media.width * 0.01),
                      MyText(
                        text: '${rota.distanciaKm} km',
                        size: media.width * twelve,
                        color: textColor.withOpacity(0.7),
                      ),
                      SizedBox(width: media.width * 0.03),
                      Icon(Icons.timer, size: media.width * 0.035, color: Colors.grey[600]),
                      SizedBox(width: media.width * 0.01),
                      MyText(
                        text: rota.tempoEstimadoFormatado,
                        size: media.width * twelve,
                        color: textColor.withOpacity(0.7),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Seta
            Icon(
              Icons.chevron_right,
              color: _primaryColor,
              size: media.width * 0.06,
            ),
          ],
        ),
      ),
    );
  }
}

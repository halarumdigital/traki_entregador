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

  Future<void> _mostrarDialogConfigurar(Rota rota) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => ConfigurarRotaDialog(rota: rota),
    );

    if (resultado == true) {
      // Rota configurada com sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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

      // Voltar para tela anterior
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
          // Cabeçalho com ícone de rota
          Container(
            padding: EdgeInsets.all(media.width * 0.04),
            decoration: BoxDecoration(
              color: theme.withOpacity(0.1),
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
                    color: theme,
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
                          Icon(Icons.arrow_downward, size: media.width * 0.04, color: theme),
                          SizedBox(width: media.width * 0.01),
                          MyText(
                            text: rota.cidadeDestinoNome,
                            size: media.width * fourteen,
                            fontweight: FontWeight.w600,
                            color: theme,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Informações da rota
          Padding(
            padding: EdgeInsets.all(media.width * 0.04),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Distância',
                        '${rota.distanciaKm} km',
                        Icons.straighten,
                        Colors.blue,
                        media,
                      ),
                    ),
                    SizedBox(width: media.width * 0.03),
                    Expanded(
                      child: _buildInfoItem(
                        'Tempo Estimado',
                        rota.tempoEstimadoFormatado,
                        Icons.schedule,
                        Colors.orange,
                        media,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.04),

                // Botão configurar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _mostrarDialogConfigurar(rota),
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
                        Icon(Icons.add_circle, color: Colors.white, size: media.width * 0.05),
                        SizedBox(width: media.width * 0.02),
                        MyText(
                          text: 'Configurar Rota',
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

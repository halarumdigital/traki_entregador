// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/entrega_rota.dart';
import '../../services/entregas_rota_service.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';

class EntregasDisponiveisRotasScreen extends StatefulWidget {
  const EntregasDisponiveisRotasScreen({super.key});

  @override
  State<EntregasDisponiveisRotasScreen> createState() =>
      _EntregasDisponiveisRotasScreenState();
}

class _EntregasDisponiveisRotasScreenState
    extends State<EntregasDisponiveisRotasScreen> {
  bool _isLoading = true;
  List<EntregaRota> _entregas = [];
  DateTime _dataSelecionada = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadEntregas();
  }

  Future<void> _loadEntregas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dataFormatada = DateFormat('yyyy-MM-dd').format(_dataSelecionada);
      final entregas = await EntregasRotaService.getEntregasDisponiveis(
        dataViagem: dataFormatada,
      );

      setState(() {
        _entregas = entregas;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar entregas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selecionarData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: theme,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dataSelecionada) {
      setState(() {
        _dataSelecionada = picked;
      });
      _loadEntregas();
    }
  }

  Future<void> _mostrarDialogAceitar(EntregaRota entrega) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceitar Entrega'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Empresa: ${entrega.empresaNome}'),
            const SizedBox(height: 8),
            Text('Pedido: ${entrega.numeroPedido}'),
            const SizedBox(height: 8),
            Text('Rota: ${entrega.rotaNome}'),
            const SizedBox(height: 8),
            Text('Peso: ${entrega.pesoTotalKg} kg'),
            const SizedBox(height: 16),
            const Text(
              'Deseja aceitar esta entrega?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
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
            child: const Text('Aceitar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _aceitarEntrega(entrega);
    }
  }

  Future<void> _aceitarEntrega(EntregaRota entrega) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final viagemId = await EntregasRotaService.aceitarEntrega(entrega.id);

    Navigator.pop(context); // Fechar loading

    if (viagemId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Entrega aceita! Você pode fazer a coleta agora.'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      _loadEntregas(); // Recarregar lista
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao aceitar entrega. Verifique sua capacidade disponível.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
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
                      text: 'Entregas Disponíveis',
                      size: media.width * twenty,
                      fontweight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Filtro de data
            Container(
              padding: EdgeInsets.all(media.width * 0.04),
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
              child: InkWell(
                onTap: _selecionarData,
                child: Container(
                  padding: EdgeInsets.all(media.width * 0.03),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: theme, size: media.width * 0.05),
                      SizedBox(width: media.width * 0.03),
                      Expanded(
                        child: MyText(
                          text: DateFormat('dd/MM/yyyy').format(_dataSelecionada),
                          size: media.width * sixteen,
                          fontweight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
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
                  : _entregas.isEmpty
                      ? _buildEmptyState(media)
                      : RefreshIndicator(
                          onRefresh: _loadEntregas,
                          child: ListView.builder(
                            padding: EdgeInsets.all(media.width * 0.05),
                            itemCount: _entregas.length,
                            itemBuilder: (context, index) {
                              return _buildEntregaCard(_entregas[index], media);
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
            Icons.local_shipping_outlined,
            size: media.width * 0.2,
            color: Colors.grey[400],
          ),
          SizedBox(height: media.width * 0.05),
          MyText(
            text: 'Nenhuma entrega disponível',
            size: media.width * sixteen,
            color: textColor.withOpacity(0.7),
          ),
          SizedBox(height: media.width * 0.03),
          MyText(
            text: 'Tente selecionar outra data',
            size: media.width * fourteen,
            color: textColor.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildEntregaCard(EntregaRota entrega, Size media) {
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
              color: Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(media.width * 0.02),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.business,
                    color: Colors.white,
                    size: media.width * 0.05,
                  ),
                ),
                SizedBox(width: media.width * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        text: entrega.empresaNome,
                        size: media.width * sixteen,
                        fontweight: FontWeight.bold,
                        color: textColor,
                      ),
                      MyText(
                        text: 'Pedido: ${entrega.numeroPedido}',
                        size: media.width * twelve,
                        color: textColor.withOpacity(0.7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Rota
          Container(
            padding: EdgeInsets.all(media.width * 0.04),
            decoration: BoxDecoration(
              color: theme.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.route, color: theme, size: media.width * 0.05),
                SizedBox(width: media.width * 0.02),
                Expanded(
                  child: MyText(
                    text: entrega.rotaNome,
                    size: media.width * fourteen,
                    fontweight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),

          // Informações
          Padding(
            padding: EdgeInsets.all(media.width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coleta
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue, size: media.width * 0.045),
                    SizedBox(width: media.width * 0.02),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText(
                            text: 'Coleta',
                            size: media.width * twelve,
                            color: textColor.withOpacity(0.6),
                          ),
                          MyText(
                            text: entrega.enderecoColetaCompleto,
                            size: media.width * fourteen,
                            color: textColor,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.03),

                // Entrega
                Row(
                  children: [
                    Icon(Icons.flag, color: Colors.green, size: media.width * 0.045),
                    SizedBox(width: media.width * 0.02),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText(
                            text: 'Entrega',
                            size: media.width * twelve,
                            color: textColor.withOpacity(0.6),
                          ),
                          MyText(
                            text: entrega.enderecoEntregaCompleto,
                            size: media.width * fourteen,
                            color: textColor,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.04),

                // Grid de informações
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        '${entrega.pesoTotalKg} kg',
                        Icons.scale,
                        Colors.orange,
                        media,
                      ),
                    ),
                    SizedBox(width: media.width * 0.02),
                    Expanded(
                      child: _buildInfoChip(
                        'R\$ ${entrega.valorTotal}',
                        Icons.attach_money,
                        Colors.green,
                        media,
                      ),
                    ),
                    SizedBox(width: media.width * 0.02),
                    Expanded(
                      child: _buildInfoChip(
                        DateFormat('dd/MM').format(entrega.dataAgendadaDate!),
                        Icons.calendar_today,
                        Colors.purple,
                        media,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.04),

                // Botão aceitar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _mostrarDialogAceitar(entrega),
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
                        Icon(Icons.check_circle, color: Colors.white, size: media.width * 0.05),
                        SizedBox(width: media.width * 0.02),
                        MyText(
                          text: 'Aceitar Entrega',
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

  Widget _buildInfoChip(String text, IconData icon, Color color, Size media) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: media.width * 0.03,
        vertical: media.width * 0.02,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: media.width * 0.04, color: color),
          SizedBox(width: media.width * 0.02),
          Expanded(
            child: MyText(
              text: text,
              size: media.width * twelve,
              fontweight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

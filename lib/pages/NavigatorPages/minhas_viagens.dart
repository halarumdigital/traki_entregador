// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/viagem.dart';
import '../../models/viagem_coleta.dart';
import '../../models/entrega_viagem.dart';
import '../../services/viagens_service.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';

class MinhasViagensScreen extends StatefulWidget {
  const MinhasViagensScreen({super.key});

  @override
  State<MinhasViagensScreen> createState() => _MinhasViagensScreenState();
}

class _MinhasViagensScreenState extends State<MinhasViagensScreen> {
  bool _isLoading = true;
  List<Viagem> _viagens = [];
  String _filtroStatus = 'todos'; // todos, agendada, em_andamento, concluida

  // Cor principal da tela
  static const Color _primaryColor = Colors.purple;

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
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Carregar coletas e entregas da viagem
      final coletas = await ViagensService.getColetasViagem(viagem.id);
      final entregas = await ViagensService.getEntregasViagem(viagem.id);

      Navigator.pop(context); // Fechar loading

      // Verificar se todas as coletas estão finalizadas
      final todasColetasFinalizadas = coletas.isEmpty ||
          coletas.every((c) => c.isColetado || c.isFalhou);

      if (!todasColetasFinalizadas) {
        // Mostrar modal de coleta pendente
        final coletaPendente = coletas.firstWhere(
          (c) => !c.isColetado && !c.isFalhou,
          orElse: () => coletas.first,
        );
        _mostrarModalColeta(viagem, coletaPendente, coletas);
      } else {
        // Mostrar modal de entrega pendente
        final entregaPendente = entregas.firstWhere(
          (e) => !e.isEntregue && !e.isFalha,
          orElse: () => entregas.first,
        );
        _mostrarModalEntrega(viagem, entregaPendente, entregas);
      }
    } catch (e) {
      Navigator.pop(context); // Fechar loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar viagem: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarModalColeta(Viagem viagem, ViagemColeta coleta, List<ViagemColeta> todasColetas) {
    final media = MediaQuery.of(context).size;
    final coletasConcluidas = todasColetas.where((c) => c.isColetado).length;
    final totalColetas = todasColetas.length;

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
            // Botão Abrir Mapa - centralizado no topo
            Padding(
              padding: EdgeInsets.only(top: media.width * 0.05),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _abrirNavegacaoColeta(coleta);
                  },
                  icon: Icon(Icons.map_outlined, color: Colors.white, size: media.width * 0.05),
                  label: MyText(
                    text: 'Abrir Mapa',
                    size: media.width * fourteen,
                    fontweight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: media.width * 0.08,
                      vertical: media.width * 0.035,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ),

            SizedBox(height: media.width * 0.05),

            // Linha com: Logo | Nome | WhatsApp | Cancelar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: media.width * 0.05),
              child: Row(
                children: [
                  // Logo empresa (círculo com ícone)
                  Container(
                    width: media.width * 0.14,
                    height: media.width * 0.14,
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
                    ),
                    child: Icon(
                      Icons.store,
                      color: Colors.amber[700],
                      size: media.width * 0.07,
                    ),
                  ),
                  SizedBox(width: media.width * 0.03),

                  // Nome da empresa
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          text: coleta.empresaNome,
                          size: media.width * sixteen,
                          fontweight: FontWeight.bold,
                          color: textColor,
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: media.width * 0.035),
                            SizedBox(width: media.width * 0.01),
                            MyText(
                              text: '5.00',
                              size: media.width * twelve,
                              color: textColor.withOpacity(0.7),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Botão WhatsApp
                  if (coleta.empresaTelefone != null)
                    InkWell(
                      onTap: () => _abrirWhatsApp(coleta.empresaTelefone!),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: media.width * 0.025,
                          vertical: media.width * 0.015,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone, color: Colors.white, size: media.width * 0.035),
                            SizedBox(width: media.width * 0.01),
                            MyText(
                              text: 'WhatsApp',
                              size: media.width * ten,
                              fontweight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (coleta.empresaTelefone != null)
                    SizedBox(width: media.width * 0.03),

                  // Cancelar
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: MyText(
                      text: 'Cancelar',
                      size: media.width * fourteen,
                      fontweight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: media.width * 0.05),

            // Divider
            Divider(height: 1, color: Colors.grey[300]),

            // Local de Retirada
            Padding(
              padding: EdgeInsets.all(media.width * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: 'Local de Retirada',
                    size: media.width * twelve,
                    color: textColor.withOpacity(0.5),
                  ),
                  SizedBox(height: media.width * 0.03),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(media.width * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: Colors.green,
                          size: media.width * 0.055,
                        ),
                      ),
                      SizedBox(width: media.width * 0.03),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: media.width * 0.01),
                          child: MyText(
                            text: coleta.enderecoColeta,
                            size: media.width * fourteen,
                            color: textColor,
                            maxLines: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Progresso
            Padding(
              padding: EdgeInsets.symmetric(horizontal: media.width * 0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyText(
                    text: 'Progresso de Coletas',
                    size: media.width * twelve,
                    color: textColor.withOpacity(0.7),
                  ),
                  MyText(
                    text: '$coletasConcluidas/$totalColetas',
                    size: media.width * twelve,
                    fontweight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ],
              ),
            ),
            SizedBox(height: media.width * 0.02),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: media.width * 0.05),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: totalColetas > 0 ? coletasConcluidas / totalColetas : 0,
                  backgroundColor: Colors.grey[200],
                  color: _primaryColor,
                  minHeight: 6,
                ),
              ),
            ),

            // Botão de ação
            if (!coleta.isColetado && !coleta.isFalhou)
              Padding(
                padding: EdgeInsets.all(media.width * 0.05),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _marcarChegueiColeta(viagem, coleta);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: EdgeInsets.symmetric(vertical: media.width * 0.045),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: MyText(
                      text: !coleta.isChegou ? 'CHEGUEI' : 'RETIREI',
                      size: media.width * sixteen,
                      fontweight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            if (coleta.isColetado || coleta.isFalhou)
              SizedBox(height: media.width * 0.03),
          ],
        ),
      ),
    );
  }

  void _mostrarModalEntrega(Viagem viagem, EntregaViagem entrega, List<EntregaViagem> todasEntregas) {
    final media = MediaQuery.of(context).size;
    final entregasConcluidas = todasEntregas.where((e) => e.isEntregue).length;
    final totalEntregas = todasEntregas.length;

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
            // Botão Abrir Mapa - centralizado no topo
            Padding(
              padding: EdgeInsets.only(top: media.width * 0.05),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _abrirNavegacaoEntrega(entrega);
                  },
                  icon: Icon(Icons.map_outlined, color: Colors.white, size: media.width * 0.05),
                  label: MyText(
                    text: 'Abrir Mapa',
                    size: media.width * fourteen,
                    fontweight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: media.width * 0.08,
                      vertical: media.width * 0.035,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ),

            SizedBox(height: media.width * 0.05),

            // Linha com: Logo | Nome | WhatsApp | Cancelar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: media.width * 0.05),
              child: Row(
                children: [
                  // Logo/Número da entrega (círculo)
                  Container(
                    width: media.width * 0.14,
                    height: media.width * 0.14,
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: _primaryColor.withOpacity(0.3), width: 2),
                    ),
                    child: Center(
                      child: MyText(
                        text: '${entrega.ordemEntrega}',
                        size: media.width * eighteen,
                        fontweight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(width: media.width * 0.03),

                  // Nome do destinatário
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          text: entrega.destinatarioNome ?? entrega.empresaNome,
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

                  // Botão WhatsApp
                  if (entrega.destinatarioTelefone != null)
                    InkWell(
                      onTap: () => _abrirWhatsApp(entrega.destinatarioTelefone!),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: media.width * 0.025,
                          vertical: media.width * 0.015,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone, color: Colors.white, size: media.width * 0.035),
                            SizedBox(width: media.width * 0.01),
                            MyText(
                              text: 'WhatsApp',
                              size: media.width * ten,
                              fontweight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),

                  SizedBox(width: media.width * 0.03),

                  // Cancelar
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: MyText(
                      text: 'Cancelar',
                      size: media.width * fourteen,
                      fontweight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: media.width * 0.05),

            // Divider
            Divider(height: 1, color: Colors.grey[300]),

            // Local de Entrega
            Padding(
              padding: EdgeInsets.all(media.width * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: 'Local de Entrega',
                    size: media.width * twelve,
                    color: textColor.withOpacity(0.5),
                  ),
                  SizedBox(height: media.width * 0.03),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(media.width * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: media.width * 0.055,
                        ),
                      ),
                      SizedBox(width: media.width * 0.03),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: media.width * 0.01),
                          child: MyText(
                            text: entrega.enderecoEntrega,
                            size: media.width * fourteen,
                            color: textColor,
                            maxLines: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Progresso
            Padding(
              padding: EdgeInsets.symmetric(horizontal: media.width * 0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyText(
                    text: 'Progresso de Entregas',
                    size: media.width * twelve,
                    color: textColor.withOpacity(0.7),
                  ),
                  MyText(
                    text: '$entregasConcluidas/$totalEntregas',
                    size: media.width * twelve,
                    fontweight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ],
              ),
            ),
            SizedBox(height: media.width * 0.02),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: media.width * 0.05),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: totalEntregas > 0 ? entregasConcluidas / totalEntregas : 0,
                  backgroundColor: Colors.grey[200],
                  color: _primaryColor,
                  minHeight: 6,
                ),
              ),
            ),

            // Botão de ação
            if (entrega.isPendente)
              Padding(
                padding: EdgeInsets.all(media.width * 0.05),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _marcarComoEntregue(viagem, entrega);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: EdgeInsets.symmetric(vertical: media.width * 0.045),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: MyText(
                      text: 'ENTREGUE',
                      size: media.width * sixteen,
                      fontweight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            if (!entrega.isPendente)
              SizedBox(height: media.width * 0.03),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirNavegacaoColeta(ViagemColeta coleta) async {
    final wazeUrl = Uri.parse(
      'waze://?ll=${coleta.latitude ?? 0},${coleta.longitude ?? 0}&navigate=yes'
    );
    final googleMapsUrl = coleta.latitude != null && coleta.longitude != null
        ? Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${coleta.latitude},${coleta.longitude}')
        : Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(coleta.enderecoColeta)}');

    try {
      if (await canLaunchUrl(wazeUrl)) {
        await launchUrl(wazeUrl);
      } else {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir navegação: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _abrirNavegacaoEntrega(EntregaViagem entrega) async {
    final googleMapsUrl = entrega.latitude != null && entrega.longitude != null
        ? Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${entrega.latitude},${entrega.longitude}')
        : Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(entrega.enderecoEntrega)}');

    try {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir navegação: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _abrirWhatsApp(String telefone) async {
    final telefoneNumeros = telefone.replaceAll(RegExp(r'[^\d]'), '');
    final whatsappUrl = Uri.parse('https://wa.me/55$telefoneNumeros');
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir WhatsApp: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _marcarChegueiColeta(Viagem viagem, ViagemColeta coleta) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final sucesso = await ViagensService.atualizarStatusColeta(
      coletaId: coleta.id,
      status: coleta.isChegou ? 'coletado' : 'chegou',
    );

    Navigator.pop(context); // Fechar loading

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(coleta.isChegou ? 'Coleta registrada!' : 'Chegada registrada!'),
          backgroundColor: Colors.green,
        ),
      );

      // Recarregar dados e reabrir modal com próximo passo
      await _recarregarEMostrarProximoPasso(viagem);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao atualizar status'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _recarregarEMostrarProximoPasso(Viagem viagem) async {
    try {
      // Recarregar coletas e entregas
      final coletas = await ViagensService.getColetasViagem(viagem.id);
      final entregas = await ViagensService.getEntregasViagem(viagem.id);

      // Verificar se todas as coletas estão finalizadas
      final todasColetasFinalizadas = coletas.isEmpty ||
          coletas.every((c) => c.isColetado || c.isFalhou);

      // Verificar se todas as entregas estão finalizadas
      final todasEntregasFinalizadas = entregas.isEmpty ||
          entregas.every((e) => e.isEntregue || e.isFalha);

      if (!todasColetasFinalizadas) {
        // Mostrar próxima coleta pendente
        final coletaPendente = coletas.firstWhere(
          (c) => !c.isColetado && !c.isFalhou,
          orElse: () => coletas.first,
        );
        _mostrarModalColeta(viagem, coletaPendente, coletas);
      } else if (!todasEntregasFinalizadas) {
        // Mostrar próxima entrega pendente
        final entregaPendente = entregas.firstWhere(
          (e) => !e.isEntregue && !e.isFalha,
          orElse: () => entregas.first,
        );
        _mostrarModalEntrega(viagem, entregaPendente, entregas);
      } else {
        // Todas concluídas, apenas recarregar a lista
        _loadViagens();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Viagem concluída!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Atualizar lista em background
      _loadViagens();
    } catch (e) {
      debugPrint('Erro ao recarregar: $e');
      _loadViagens();
    }
  }

  Future<void> _marcarComoEntregue(Viagem viagem, EntregaViagem entrega) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final sucesso = await ViagensService.atualizarStatusEntrega(
      entregaId: entrega.id,
      status: 'entregue',
    );

    Navigator.pop(context); // Fechar loading

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrega concluída!'), backgroundColor: Colors.green),
      );

      // Recarregar dados e reabrir modal com próximo passo
      await _recarregarEMostrarProximoPasso(viagem);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao atualizar status'), backgroundColor: Colors.red),
      );
    }
  }

  void _mostrarDetalhes(Viagem viagem) {
    final media = MediaQuery.of(context).size;

    Color statusColor;
    switch (viagem.status) {
      case 'agendada':
        statusColor = Colors.blue;
        break;
      case 'em_transito':
      case 'em_entrega':
        statusColor = Colors.orange;
        break;
      case 'concluida':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

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
                  child: MyText(
                    text: viagem.rotaNome,
                    size: media.width * eighteen,
                    fontweight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: media.width * 0.03,
                    vertical: media.width * 0.015,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: MyText(
                    text: viagem.statusFormatado,
                    size: media.width * twelve,
                    fontweight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: media.width * 0.05),

            // Grid de informações
            _buildDetalheItem(Icons.calendar_today, 'Data', DateFormat('dd/MM/yyyy').format(viagem.dataViagemDate!), Colors.blue, media),
            _buildDetalheItem(Icons.access_time, 'Horário de Saída', viagem.horarioSaidaPlanejado, Colors.orange, media),
            _buildDetalheItem(Icons.inventory_2, 'Pacotes', '${viagem.pacotesAceitos}', Colors.purple, media),
            _buildDetalheItem(Icons.local_shipping, 'Entregas', '${viagem.entregasConcluidas}/${viagem.totalEntregas}', Colors.indigo, media),
            _buildDetalheItem(Icons.straighten, 'Distância', '${viagem.distanciaKm} km', Colors.teal, media),
            _buildDetalheItem(Icons.timer, 'Tempo Estimado', viagem.tempoEstimadoFormatado, Colors.cyan, media),
            _buildDetalheItem(Icons.attach_money, 'Valor', 'R\$ ${viagem.valorEntregador}', Colors.green, media),

            SizedBox(height: media.width * 0.05),

            // Botões de ação
            if (viagem.podeIniciar)
              SizedBox(
                width: double.infinity,
                height: media.width * 0.12,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _iniciarViagem(viagem);
                  },
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: MyText(
                    text: 'Iniciar Viagem',
                    size: media.width * fourteen,
                    fontweight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            if (viagem.emAndamento)
              SizedBox(
                width: double.infinity,
                height: media.width * 0.12,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _abrirViagem(viagem);
                  },
                  icon: const Icon(Icons.map, color: Colors.white),
                  label: MyText(
                    text: 'Continuar Viagem',
                    size: media.width * fourteen,
                    fontweight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
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

  Future<void> _iniciarViagem(Viagem viagem) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar Viagem'),
        content: Text(
          'Deseja iniciar a viagem?\n\n'
          'Rota: ${viagem.rotaNome}\n'
          'Entregas: ${viagem.totalEntregas}\n'
          'Pacotes: ${viagem.pacotesAceitos}',
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
                  ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)))
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
          color: isSelected ? _primaryColor : Colors.grey[200],
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

    switch (viagem.status) {
      case 'agendada':
        statusColor = Colors.blue;
        break;
      case 'em_transito':
      case 'em_entrega':
        statusColor = Colors.orange;
        break;
      case 'concluida':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return InkWell(
      onTap: () => _mostrarDetalhes(viagem),
      child: Container(
        margin: EdgeInsets.only(bottom: media.width * 0.03),
        padding: EdgeInsets.all(media.width * 0.035),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
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
            // Linha 1: Rota + Status + Data
            Row(
              children: [
                Expanded(
                  child: MyText(
                    text: viagem.rotaNome,
                    size: media.width * fourteen,
                    fontweight: FontWeight.bold,
                    color: textColor,
                    maxLines: 1,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: media.width * 0.02,
                    vertical: media.width * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: MyText(
                    text: viagem.statusFormatado,
                    size: media.width * ten,
                    fontweight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: media.width * 0.02),

            // Linha 2: Todas as informações compactas
            Row(
              children: [
                _buildCompactInfo(Icons.calendar_today, DateFormat('dd/MM').format(viagem.dataViagemDate!), media),
                _buildCompactInfo(Icons.access_time, viagem.horarioSaidaPlanejado, media),
                _buildCompactInfo(Icons.inventory_2, '${viagem.pacotesAceitos}', media),
                _buildCompactInfo(Icons.local_shipping, '${viagem.entregasConcluidas}/${viagem.totalEntregas}', media),
                _buildCompactInfo(Icons.straighten, '${viagem.distanciaKm}km', media),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: media.width * 0.02, vertical: media.width * 0.01),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: MyText(
                      text: 'R\$${viagem.valorEntregador}',
                      size: media.width * ten,
                      fontweight: FontWeight.bold,
                      color: Colors.green[700]!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),

            // Botão de ação (se necessário)
            if (viagem.podeIniciar || viagem.emAndamento) ...[
              SizedBox(height: media.width * 0.025),
              SizedBox(
                width: double.infinity,
                height: media.width * 0.09,
                child: ElevatedButton(
                  onPressed: viagem.podeIniciar ? () => _iniciarViagem(viagem) : () => _abrirViagem(viagem),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: viagem.podeIniciar ? Colors.green : _primaryColor,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: MyText(
                    text: viagem.podeIniciar ? 'Iniciar' : 'Continuar',
                    size: media.width * twelve,
                    fontweight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
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

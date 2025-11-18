// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/viagem.dart';
import '../../models/entrega_viagem.dart';
import '../../models/viagem_coleta.dart';
import '../../models/parada.dart';
import '../../services/viagens_service.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';

class ViagemAtivaScreen extends StatefulWidget {
  final String viagemId;

  const ViagemAtivaScreen({
    super.key,
    required this.viagemId,
  });

  @override
  State<ViagemAtivaScreen> createState() => _ViagemAtivaScreenState();
}

class _ViagemAtivaScreenState extends State<ViagemAtivaScreen> {
  bool _isLoading = true;
  Viagem? _viagem;
  List<ViagemColeta> _coletas = [];
  List<EntregaViagem> _entregas = [];

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 ===== ViagemAtivaScreen INICIADO =====');
    debugPrint('📋 ViagemId: ${widget.viagemId}');
    debugPrint('🔄 Chamando _loadViagem()...');
    _loadViagem();
  }

  Future<void> _loadViagem() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🔄 Carregando viagem: ${widget.viagemId}');

      final viagem = await ViagensService.getViagemDetalhes(widget.viagemId);
      debugPrint('📋 Viagem carregada: ${viagem != null ? "✅" : "❌ NULL"}');

      final coletas = await ViagensService.getColetasViagem(widget.viagemId);
      debugPrint('📦 Coletas carregadas: ${coletas.length} itens');

      final entregas = await ViagensService.getEntregasViagem(widget.viagemId);
      debugPrint('🚚 Entregas carregadas: ${entregas.length} itens');

      setState(() {
        _viagem = viagem;
        _coletas = coletas;
        _entregas = entregas;
        _isLoading = false;
      });

      debugPrint('✅ Estado atualizado - Todas coletas finalizadas: $_todasColetasFinalizadas');
    } catch (e) {
      debugPrint('❌ Erro ao carregar viagem: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool get _todasColetasFinalizadas {
    if (_coletas.isEmpty) return false; // Se não há coletas carregadas, ainda não finalizou
    return _coletas.every((c) => c.isColetado || c.isFalhou);
  }

  // Função para abrir navegação no Waze ou Google Maps
  Future<void> _abrirNavegacao(ViagemColeta coleta) async {
    // Tentar abrir no Waze primeiro
    final wazeUrl = Uri.parse(
      'waze://?ll=${coleta.latitude ?? 0},${coleta.longitude ?? 0}&navigate=yes'
    );

    // Se não tiver coordenadas, usar endereço
    final googleMapsUrl = coleta.latitude != null && coleta.longitude != null
        ? Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${coleta.latitude},${coleta.longitude}')
        : Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(coleta.enderecoColeta)}');

    try {
      // Tentar abrir no Waze
      if (await canLaunchUrl(wazeUrl)) {
        await launchUrl(wazeUrl);
      } else {
        // Se não conseguir abrir no Waze, abrir no Google Maps
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Se falhar, mostrar erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir navegação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _abrirNavegacaoEntrega(EntregaViagem entrega) async {
    // Mostrar dialog para escolher Waze ou Google Maps
    final escolha = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abrir Navegação'),
        content: const Text('Escolha o aplicativo de navegação:'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'waze'),
            icon: const Icon(Icons.navigation, color: Colors.blue),
            label: const Text('Waze'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'maps'),
            icon: const Icon(Icons.map, color: Colors.green),
            label: const Text('Google Maps'),
          ),
        ],
      ),
    );

    if (escolha == null) return;

    try {
      if (escolha == 'waze') {
        // Abrir no Waze
        final wazeUrl = entrega.latitude != null && entrega.longitude != null
            ? Uri.parse('waze://?ll=${entrega.latitude},${entrega.longitude}&navigate=yes')
            : Uri.parse('waze://?q=${Uri.encodeComponent(entrega.enderecoEntrega)}&navigate=yes');

        if (await canLaunchUrl(wazeUrl)) {
          await launchUrl(wazeUrl);
        } else {
          throw 'Waze não está instalado';
        }
      } else {
        // Abrir no Google Maps
        final googleMapsUrl = entrega.latitude != null && entrega.longitude != null
            ? Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${entrega.latitude},${entrega.longitude}')
            : Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(entrega.enderecoEntrega)}');

        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir navegação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _abrirWhatsApp(String telefone) async {
    // Remover caracteres especiais do telefone
    final telefoneNumeros = telefone.replaceAll(RegExp(r'[^\d]'), '');

    // URL do WhatsApp
    final whatsappUrl = Uri.parse('https://wa.me/55$telefoneNumeros');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Não foi possível abrir o WhatsApp';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir WhatsApp: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==================== MÉTODOS DE COLETA ====================

  Future<void> _marcarChegueiColeta(ViagemColeta coleta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Chegada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Empresa: ${coleta.empresaNome}'),
            const SizedBox(height: 8),
            Text('Endereço: ${coleta.enderecoColeta}'),
            const SizedBox(height: 16),
            const Text(
              'Confirma que chegou no local de coleta?',
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
              backgroundColor: Colors.blue,
            ),
            child: const Text('Cheguei', style: TextStyle(color: Colors.white)),
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

      final sucesso = await ViagensService.atualizarStatusColeta(
        coletaId: coleta.id,
        status: 'chegou',
      );

      Navigator.pop(context); // Fechar loading

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chegada registrada!'),
            backgroundColor: Colors.blue,
          ),
        );
        _loadViagem(); // Recarregar
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao registrar chegada'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _marcarColetaRealizada(ViagemColeta coleta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Coleta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Empresa: ${coleta.empresaNome}'),
            const SizedBox(height: 8),
            Text('Pacotes: ${coleta.quantidadePacotes}'),
            const SizedBox(height: 8),
            Text('Peso: ${coleta.pesoKg} kg'),
            const SizedBox(height: 16),
            const Text(
              'Confirma que retirou os pacotes?',
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
            child: const Text('Retirei', style: TextStyle(color: Colors.white)),
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

      final sucesso = await ViagensService.atualizarStatusColeta(
        coletaId: coleta.id,
        status: 'coletado',
      );

      Navigator.pop(context); // Fechar loading

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coleta registrada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadViagem(); // Recarregar
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao registrar coleta'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== MÉTODOS DE ENTREGA ====================

  Future<void> _marcarComoEntregue(EntregaViagem entrega) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Entrega'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pedido: ${entrega.numeroPedido}'),
            const SizedBox(height: 8),
            Text('Destinatário: ${entrega.destinatarioNome ?? "N/A"}'),
            const SizedBox(height: 8),
            Text('Endereço: ${entrega.enderecoEntrega}'),
            const SizedBox(height: 16),
            const Text(
              'Confirma que a entrega foi realizada?',
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
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
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

      final sucesso = await ViagensService.atualizarStatusEntrega(
        entregaId: entrega.id,
        status: 'entregue',
      );

      Navigator.pop(context); // Fechar loading

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrega marcada como concluída!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadViagem(); // Recarregar
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _concluirViagem() async {
    // Confirmar conclusão
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Concluir Viagem'),
        content: const Text(
          'Confirma que todas as entregas foram realizadas e deseja finalizar esta viagem?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme,
            ),
            child: const Text('Concluir', style: TextStyle(color: Colors.white)),
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

      // TODO: Adicionar endpoint no backend para concluir viagem
      // Por enquanto, vamos apenas atualizar o status da viagem
      final sucesso = await ViagensService.concluirViagem(widget.viagemId);

      Navigator.pop(context); // Fechar loading

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Viagem concluída com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Aguardar um pouco para mostrar a mensagem e voltar
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context); // Voltar para tela anterior
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao concluir viagem'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    if (_isLoading || _viagem == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Viagem'),
          backgroundColor: theme,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final coletasPendentes = _coletas.where((c) => c.isPendente || c.isChegou).length;
    final coletasConcluidas = _coletas.where((c) => c.isColetado).length;
    final entregasPendentes = _entregas.where((e) => e.isPendente || e.isChegou).length;
    final entregasConcluidas = _entregas.where((e) => e.isEntregue).length;

    return Material(
      child: Scaffold(
        backgroundColor: page,
        body: Column(
          children: [
            // AppBar customizado
            _buildAppBar(media),

            // Tabs ou Indicador de Fase
            if (_coletas.isNotEmpty) _buildFaseTabs(media),

            // Progresso
            _buildProgressSection(media, coletasPendentes, coletasConcluidas, entregasPendentes, entregasConcluidas),

            // Conteúdo
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadViagem,
                child: !_todasColetasFinalizadas
                    ? _buildColetasView(media)
                    : _buildEntregasView(media),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(Size media) {
    return Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: _viagem!.rotaNome,
                  size: media.width * eighteen,
                  fontweight: FontWeight.bold,
                  color: Colors.white,
                ),
                MyText(
                  text: DateFormat('dd/MM/yyyy').format(_viagem!.dataViagemDate!),
                  size: media.width * fourteen,
                  color: Colors.white.withOpacity(0.9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaseTabs(Size media) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: media.width * 0.03),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Icon(
                  Icons.shopping_bag,
                  color: !_todasColetasFinalizadas ? theme : Colors.green,
                  size: media.width * 0.08,
                ),
                SizedBox(height: media.width * 0.01),
                MyText(
                  text: 'Coleta',
                  size: media.width * twelve,
                  fontweight: FontWeight.bold,
                  color: !_todasColetasFinalizadas ? theme : Colors.green,
                ),
                if (!_todasColetasFinalizadas)
                  Container(
                    margin: EdgeInsets.only(top: media.width * 0.01),
                    height: 3,
                    width: media.width * 0.15,
                    decoration: BoxDecoration(
                      color: theme,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Icon(
                  Icons.local_shipping,
                  color: _todasColetasFinalizadas ? theme : Colors.grey,
                  size: media.width * 0.08,
                ),
                SizedBox(height: media.width * 0.01),
                MyText(
                  text: 'Entrega',
                  size: media.width * twelve,
                  fontweight: FontWeight.bold,
                  color: _todasColetasFinalizadas ? theme : Colors.grey,
                ),
                if (_todasColetasFinalizadas)
                  Container(
                    margin: EdgeInsets.only(top: media.width * 0.01),
                    height: 3,
                    width: media.width * 0.15,
                    decoration: BoxDecoration(
                      color: theme,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(Size media, int coletasPendentes, int coletasConcluidas, int entregasPendentes, int entregasConcluidas) {
    final totalColetas = _coletas.length;
    final totalEntregas = _entregas.length;
    final progressoColetas = totalColetas > 0 ? coletasConcluidas / totalColetas : 0.0;
    final progressoEntregas = totalEntregas > 0 ? entregasConcluidas / totalEntregas : 0.0;

    return Container(
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
      child: Column(
        children: [
          if (!_todasColetasFinalizadas && totalColetas > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyText(
                  text: 'Progresso de Coletas',
                  size: media.width * sixteen,
                  fontweight: FontWeight.bold,
                  color: textColor,
                ),
                MyText(
                  text: '$coletasConcluidas/$totalColetas',
                  size: media.width * sixteen,
                  fontweight: FontWeight.bold,
                  color: theme,
                ),
              ],
            ),
            SizedBox(height: media.width * 0.02),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progressoColetas,
                backgroundColor: Colors.grey[200],
                color: theme,
                minHeight: 8,
              ),
            ),
          ] else if (totalEntregas > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyText(
                  text: 'Progresso de Entregas',
                  size: media.width * sixteen,
                  fontweight: FontWeight.bold,
                  color: textColor,
                ),
                MyText(
                  text: '$entregasConcluidas/$totalEntregas',
                  size: media.width * sixteen,
                  fontweight: FontWeight.bold,
                  color: theme,
                ),
              ],
            ),
            SizedBox(height: media.width * 0.02),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progressoEntregas,
                backgroundColor: Colors.grey[200],
                color: theme,
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColetasView(Size media) {
    if (_coletas.isEmpty) {
      return Center(
        child: MyText(
          text: 'Nenhuma coleta para realizar',
          size: media.width * sixteen,
          color: textColor.withOpacity(0.7),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(media.width * 0.05),
      itemCount: _coletas.length,
      itemBuilder: (context, index) {
        return _buildColetaCard(_coletas[index], media);
      },
    );
  }

  Widget _buildEntregasView(Size media) {
    if (_entregas.isEmpty) {
      return Center(
        child: MyText(
          text: 'Nenhuma entrega para realizar',
          size: media.width * sixteen,
          color: textColor.withOpacity(0.7),
        ),
      );
    }

    // Verificar se todas as entregas estão concluídas
    final todasEntregasConcluidas = _entregas.every((e) => e.isEntregue);

    return ListView.builder(
      padding: EdgeInsets.all(media.width * 0.05),
      itemCount: _entregas.length + (todasEntregasConcluidas ? 1 : 0),
      itemBuilder: (context, index) {
        // Se for o último item e todas entregas concluídas, mostrar botão
        if (index == _entregas.length && todasEntregasConcluidas) {
          return _buildConcluirViagemButton(media);
        }
        return _buildEntregaCard(_entregas[index], media);
      },
    );
  }

  Widget _buildConcluirViagemButton(Size media) {
    return Container(
      margin: EdgeInsets.only(top: media.width * 0.04),
      padding: EdgeInsets.all(media.width * 0.05),
      child: ElevatedButton(
        onPressed: _concluirViagem,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme,
          padding: EdgeInsets.symmetric(vertical: media.width * 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: media.width * 0.06),
            SizedBox(width: media.width * 0.03),
            MyText(
              text: 'Concluir Viagem',
              size: media.width * sixteen,
              fontweight: FontWeight.bold,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColetaCard(ViagemColeta coleta, Size media) {
    Color statusColor;
    IconData statusIcon;

    if (coleta.isColetado) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (coleta.isFalhou) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else if (coleta.isChegou) {
      statusColor = Colors.blue;
      statusIcon = Icons.location_on;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
    }

    return Container(
      margin: EdgeInsets.only(bottom: media.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
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
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
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
                    Icons.shopping_bag,
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
                        text: coleta.empresaNome,
                        size: media.width * sixteen,
                        fontweight: FontWeight.bold,
                        color: textColor,
                      ),
                      MyText(
                        text: '${coleta.quantidadePacotes} pacotes • ${coleta.pesoKg} kg',
                        size: media.width * twelve,
                        color: textColor.withOpacity(0.7),
                      ),
                    ],
                  ),
                ),
                Icon(statusIcon, color: statusColor, size: media.width * 0.06),
              ],
            ),
          ),

          // Conteúdo
          Padding(
            padding: EdgeInsets.all(media.width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Endereço
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, color: Colors.blue, size: media.width * 0.045),
                    SizedBox(width: media.width * 0.02),
                    Expanded(
                      child: MyText(
                        text: coleta.enderecoColeta,
                        size: media.width * fourteen,
                        color: textColor,
                        maxLines: 3,
                      ),
                    ),
                    // Ícone de mapa para abrir navegação
                    IconButton(
                      onPressed: () => _abrirNavegacao(coleta),
                      icon: Icon(
                        Icons.navigation,
                        color: Colors.green,
                        size: media.width * 0.06,
                      ),
                      tooltip: 'Abrir navegação',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                // Motivo falha (se houver)
                if (coleta.isFalhou && coleta.motivoFalha != null) ...[
                  SizedBox(height: media.width * 0.03),
                  Container(
                    padding: EdgeInsets.all(media.width * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: media.width * 0.045),
                        SizedBox(width: media.width * 0.02),
                        Expanded(
                          child: MyText(
                            text: 'Motivo: ${coleta.motivoFalha}',
                            size: media.width * twelve,
                            color: Colors.red[700]!,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Botões de ação
                if (!coleta.isColetado && !coleta.isFalhou) ...[
                  SizedBox(height: media.width * 0.04),
                  if (!coleta.isChegou) ...[
                    // Mostrar botão "Cheguei" se ainda não chegou
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _marcarChegueiColeta(coleta),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: media.width * 0.03),
                        ),
                        child: const Text('Cheguei', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ] else ...[
                    // Mostrar botão "Retirei" se já chegou
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _marcarColetaRealizada(coleta),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: media.width * 0.03),
                        ),
                        child: const Text('Retirei', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntregaCard(EntregaViagem entrega, Size media) {
    Color statusColor;
    IconData statusIcon;

    if (entrega.isEntregue) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (entrega.isFalha) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
    }

    // Se tem múltiplas paradas, mostrar card diferente
    if (entrega.temMultiplasParadas && entrega.paradas != null) {
      return _buildEntregaComParadasCard(entrega, media, statusColor, statusIcon);
    }

    // Card normal (entrega única)
    return Container(
      margin: EdgeInsets.only(bottom: media.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entrega.isPendente ? theme.withOpacity(0.3) : statusColor.withOpacity(0.3),
          width: 2,
        ),
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
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: media.width * 0.12,
                  height: media.width * 0.12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: MyText(
                      text: '${entrega.ordemEntrega}',
                      size: media.width * eighteen,
                      fontweight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
                Icon(statusIcon, color: statusColor, size: media.width * 0.06),
              ],
            ),
          ),

          // Conteúdo
          Padding(
            padding: EdgeInsets.all(media.width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Destinatário
                if (entrega.destinatarioNome != null) ...[
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue, size: media.width * 0.045),
                      SizedBox(width: media.width * 0.02),
                      Expanded(
                        child: MyText(
                          text: entrega.destinatarioNome!,
                          size: media.width * fourteen,
                          fontweight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: media.width * 0.02),
                ],

                // Telefone do destinatário
                if (entrega.destinatarioTelefone != null) ...[
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.green, size: media.width * 0.045),
                      SizedBox(width: media.width * 0.02),
                      Expanded(
                        child: MyText(
                          text: entrega.destinatarioTelefone!,
                          size: media.width * fourteen,
                          color: textColor,
                        ),
                      ),
                      InkWell(
                        onTap: () => _abrirWhatsApp(entrega.destinatarioTelefone!),
                        child: Container(
                          padding: EdgeInsets.all(media.width * 0.02),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.message,
                            color: Colors.white,
                            size: media.width * 0.05,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: media.width * 0.02),
                ],

                // Endereço
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, color: Colors.red, size: media.width * 0.045),
                    SizedBox(width: media.width * 0.02),
                    Expanded(
                      child: MyText(
                        text: entrega.enderecoEntrega,
                        size: media.width * fourteen,
                        color: textColor,
                        maxLines: 3,
                      ),
                    ),
                    InkWell(
                      onTap: () => _abrirNavegacaoEntrega(entrega),
                      child: Container(
                        padding: EdgeInsets.all(media.width * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.navigation,
                          color: Colors.white,
                          size: media.width * 0.05,
                        ),
                      ),
                    ),
                  ],
                ),

                // Motivo falha (se houver)
                if (entrega.isFalha && entrega.motivoFalha != null) ...[
                  SizedBox(height: media.width * 0.03),
                  Container(
                    padding: EdgeInsets.all(media.width * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: media.width * 0.045),
                        SizedBox(width: media.width * 0.02),
                        Expanded(
                          child: MyText(
                            text: 'Motivo: ${entrega.motivoFalha}',
                            size: media.width * twelve,
                            color: Colors.red[700]!,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Botões de ação (apenas para pendentes)
                if (entrega.isPendente) ...[
                  SizedBox(height: media.width * 0.04),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _marcarComoEntregue(entrega),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: media.width * 0.03),
                      ),
                      child: const Text('Entregue', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card para entregas com múltiplas paradas
  Widget _buildEntregaComParadasCard(EntregaViagem entrega, Size media, Color statusColor, IconData statusIcon) {
    return Container(
      margin: EdgeInsets.only(bottom: media.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
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
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: media.width * 0.12,
                      height: media.width * 0.12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: MyText(
                          text: '${entrega.ordemEntrega}',
                          size: media.width * eighteen,
                          fontweight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: media.width * 0.03, vertical: media.width * 0.015),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, color: Colors.white, size: media.width * 0.04),
                          SizedBox(width: media.width * 0.01),
                          MyText(
                            text: '${entrega.numeroParadas} paradas',
                            size: media.width * twelve,
                            fontweight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.03),
                // Barra de progresso
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MyText(
                          text: 'Progresso',
                          size: media.width * twelve,
                          color: textColor.withOpacity(0.7),
                        ),
                        MyText(
                          text: '${entrega.paradasEntregues}/${entrega.paradas!.length} entregues',
                          size: media.width * twelve,
                          fontweight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ],
                    ),
                    SizedBox(height: media.width * 0.02),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: entrega.progressoParadas / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de paradas
          Padding(
            padding: EdgeInsets.all(media.width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: 'Endereços de Entrega',
                  size: media.width * fourteen,
                  fontweight: FontWeight.bold,
                  color: textColor,
                ),
                SizedBox(height: media.width * 0.02),
                ...entrega.paradas!.asMap().entries.map((entry) {
                  return _buildParadaCard(entrega, entry.value, media);
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card individual de cada parada
  Widget _buildParadaCard(EntregaViagem entrega, Parada parada, Size media) {
    Color paradaStatusColor;
    IconData paradaStatusIcon;

    if (parada.isEntregue) {
      paradaStatusColor = Colors.green;
      paradaStatusIcon = Icons.check_circle;
    } else if (parada.isFalhou) {
      paradaStatusColor = Colors.red;
      paradaStatusIcon = Icons.cancel;
    } else {
      paradaStatusColor = Colors.orange;
      paradaStatusIcon = Icons.schedule;
    }

    return Container(
      margin: EdgeInsets.only(bottom: media.width * 0.03),
      padding: EdgeInsets.all(media.width * 0.03),
      decoration: BoxDecoration(
        color: paradaStatusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: paradaStatusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da parada
          Row(
            children: [
              Container(
                width: media.width * 0.08,
                height: media.width * 0.08,
                decoration: BoxDecoration(
                  color: paradaStatusColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: MyText(
                    text: '${parada.ordem}',
                    size: media.width * fourteen,
                    fontweight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: media.width * 0.02),
              Expanded(
                child: MyText(
                  text: parada.statusFormatado,
                  size: media.width * fourteen,
                  fontweight: FontWeight.w600,
                  color: paradaStatusColor,
                ),
              ),
              Icon(paradaStatusIcon, color: paradaStatusColor, size: media.width * 0.05),
            ],
          ),
          SizedBox(height: media.width * 0.02),

          // Destinatário
          if (parada.destinatarioNome != null) ...[
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue, size: media.width * 0.04),
                SizedBox(width: media.width * 0.02),
                Expanded(
                  child: MyText(
                    text: parada.destinatarioNome!,
                    size: media.width * twelve,
                    color: textColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: media.width * 0.01),
          ],

          // Endereço
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, color: Colors.red, size: media.width * 0.04),
              SizedBox(width: media.width * 0.02),
              Expanded(
                child: MyText(
                  text: parada.enderecoCompleto,
                  size: media.width * twelve,
                  color: textColor.withOpacity(0.8),
                  maxLines: 2,
                ),
              ),
            ],
          ),

          // Telefone
          if (parada.destinatarioTelefone != null) ...[
            SizedBox(height: media.width * 0.01),
            Row(
              children: [
                Icon(Icons.phone, color: Colors.green, size: media.width * 0.04),
                SizedBox(width: media.width * 0.02),
                MyText(
                  text: parada.destinatarioTelefone!,
                  size: media.width * twelve,
                  color: textColor.withOpacity(0.8),
                ),
              ],
            ),
          ],

          // Motivo falha (se houver)
          if (parada.isFalhou && parada.motivoFalha != null) ...[
            SizedBox(height: media.width * 0.02),
            Container(
              padding: EdgeInsets.all(media.width * 0.02),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: media.width * 0.04),
                  SizedBox(width: media.width * 0.02),
                  Expanded(
                    child: MyText(
                      text: 'Motivo: ${parada.motivoFalha}',
                      size: media.width * twelve,
                      color: Colors.red[700]!,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Botões de ação (apenas para pendentes)
          if (parada.isPendente) ...[
            SizedBox(height: media.width * 0.03),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _marcarParadaComoFalha(entrega, parada),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: media.width * 0.025),
                    ),
                    child: Text('Falha', style: TextStyle(fontSize: media.width * twelve)),
                  ),
                ),
                SizedBox(width: media.width * 0.02),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _marcarParadaComoEntregue(entrega, parada),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: media.width * 0.025),
                    ),
                    child: Text(
                      'Entregue',
                      style: TextStyle(color: Colors.white, fontSize: media.width * twelve),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Marcar parada como entregue
  Future<void> _marcarParadaComoEntregue(EntregaViagem entrega, Parada parada) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Entrega'),
        content: Text('Confirmar entrega na parada ${parada.ordem}?\n\n${parada.enderecoCompleto}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
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

      final sucesso = await ViagensService.atualizarStatusParada(
        entregaId: entrega.entregaId,
        paradaId: parada.id,
        status: 'entregue',
      );

      Navigator.pop(context); // Fechar loading

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Parada ${parada.ordem} marcada como entregue!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadViagem(); // Recarregar viagem
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar status da parada'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Marcar parada como falha
  Future<void> _marcarParadaComoFalha(EntregaViagem entrega, Parada parada) async {
    final motivoController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Falha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Parada ${parada.ordem}: ${parada.enderecoCompleto}'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo da falha',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      if (motivoController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, informe o motivo da falha'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final sucesso = await ViagensService.atualizarStatusParada(
        entregaId: entrega.entregaId,
        paradaId: parada.id,
        status: 'falhou',
        motivoFalha: motivoController.text,
      );

      Navigator.pop(context); // Fechar loading

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha registrada para parada ${parada.ordem}'),
            backgroundColor: Colors.red,
          ),
        );
        _loadViagem(); // Recarregar viagem
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao registrar falha'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

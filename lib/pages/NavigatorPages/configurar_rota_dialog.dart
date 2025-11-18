// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/rota.dart';
import '../../services/rotas_service.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';

class ConfigurarRotaDialog extends StatefulWidget {
  final Rota rota;

  const ConfigurarRotaDialog({
    super.key,
    required this.rota,
  });

  @override
  State<ConfigurarRotaDialog> createState() => _ConfigurarRotaDialogState();
}

class _ConfigurarRotaDialogState extends State<ConfigurarRotaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _capacidadePacotesController = TextEditingController();
  final _capacidadePesoController = TextEditingController();
  TimeOfDay _horarioSaida = const TimeOfDay(hour: 8, minute: 0);
  Set<int> _diasSelecionados = {1, 2, 3, 4, 5}; // Segunda a Sexta por padrão
  bool _isLoading = false;

  final Map<int, String> _diasSemana = {
    1: 'SEG',
    2: 'TER',
    3: 'QUA',
    4: 'QUI',
    5: 'SEX',
    6: 'SÁB',
    7: 'DOM',
  };

  @override
  void dispose() {
    _capacidadePacotesController.dispose();
    _capacidadePesoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarHorario() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horarioSaida,
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

    if (picked != null && picked != _horarioSaida) {
      setState(() {
        _horarioSaida = picked;
      });
    }
  }

  String _formatarHorario(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_diasSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um dia da semana'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final capacidadePacotes = int.parse(_capacidadePacotesController.text);
      final capacidadePeso = double.parse(_capacidadePesoController.text.replaceAll(',', '.'));
      final horarioSaida = _formatarHorario(_horarioSaida);

      final resultado = await RotasService.configurarRota(
        rotaId: widget.rota.id,
        capacidadePacotes: capacidadePacotes,
        capacidadePesoKg: capacidadePeso,
        horarioSaidaPadrao: horarioSaida,
        diasSemana: _diasSelecionados.toList()..sort(),
      );

      if (resultado != null) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao configurar rota. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao salvar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao configurar rota. Verifique os valores.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(media.width * 0.05),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(media.width * 0.02),
                      decoration: BoxDecoration(
                        color: theme.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.settings,
                        color: theme,
                        size: media.width * 0.06,
                      ),
                    ),
                    SizedBox(width: media.width * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText(
                            text: 'Configurar Rota',
                            size: media.width * eighteen,
                            fontweight: FontWeight.bold,
                            color: textColor,
                          ),
                          MyText(
                            text: '${widget.rota.cidadeOrigemNome} → ${widget.rota.cidadeDestinoNome}',
                            size: media.width * fourteen,
                            color: textColor.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.05),

                // Capacidade de Pacotes
                MyText(
                  text: 'Capacidade de Pacotes',
                  size: media.width * fourteen,
                  fontweight: FontWeight.w600,
                  color: textColor,
                ),
                SizedBox(height: media.width * 0.02),
                TextFormField(
                  controller: _capacidadePacotesController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Ex: 50',
                    prefixIcon: Icon(Icons.inventory_2, color: theme),
                    suffixText: 'pacotes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe a capacidade';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Informe um valor válido';
                    }
                    return null;
                  },
                ),
                SizedBox(height: media.width * 0.04),

                // Capacidade de Peso
                MyText(
                  text: 'Capacidade de Peso (kg)',
                  size: media.width * fourteen,
                  fontweight: FontWeight.w600,
                  color: textColor,
                ),
                SizedBox(height: media.width * 0.02),
                TextFormField(
                  controller: _capacidadePesoController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Ex: 500',
                    prefixIcon: Icon(Icons.scale, color: theme),
                    suffixText: 'kg',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe o peso';
                    }
                    final peso = double.tryParse(value.replaceAll(',', '.'));
                    if (peso == null || peso <= 0) {
                      return 'Informe um valor válido';
                    }
                    return null;
                  },
                ),
                SizedBox(height: media.width * 0.04),

                // Horário de Saída
                MyText(
                  text: 'Horário de Saída Padrão',
                  size: media.width * fourteen,
                  fontweight: FontWeight.w600,
                  color: textColor,
                ),
                SizedBox(height: media.width * 0.02),
                InkWell(
                  onTap: _selecionarHorario,
                  child: Container(
                    padding: EdgeInsets.all(media.width * 0.04),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: theme),
                        SizedBox(width: media.width * 0.03),
                        MyText(
                          text: _formatarHorario(_horarioSaida),
                          size: media.width * sixteen,
                          fontweight: FontWeight.w600,
                          color: textColor,
                        ),
                        Spacer(),
                        Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: media.width * 0.04),

                // Dias da Semana
                MyText(
                  text: 'Dias de Operação',
                  size: media.width * fourteen,
                  fontweight: FontWeight.w600,
                  color: textColor,
                ),
                SizedBox(height: media.width * 0.02),
                Container(
                  padding: EdgeInsets.all(media.width * 0.03),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[50],
                  ),
                  child: Wrap(
                    spacing: media.width * 0.02,
                    runSpacing: media.width * 0.02,
                    children: _diasSemana.entries.map((entry) {
                      final diaSelecionado = _diasSelecionados.contains(entry.key);
                      return ChoiceChip(
                        label: Text(entry.value),
                        selected: diaSelecionado,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _diasSelecionados.add(entry.key);
                            } else {
                              _diasSelecionados.remove(entry.key);
                            }
                          });
                        },
                        selectedColor: theme.withOpacity(0.7),
                        backgroundColor: Colors.grey[200],
                        labelStyle: TextStyle(
                          color: diaSelecionado ? Colors.white : textColor,
                          fontWeight: diaSelecionado ? FontWeight.bold : FontWeight.normal,
                          fontSize: media.width * twelve,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: media.width * 0.02,
                          vertical: media.width * 0.01,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (_diasSelecionados.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: media.width * 0.01),
                    child: MyText(
                      text: 'Selecione pelo menos um dia',
                      size: media.width * twelve,
                      color: Colors.red,
                    ),
                  ),
                SizedBox(height: media.width * 0.05),

                // Botões
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: media.width * 0.04),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                        child: MyText(
                          text: 'Cancelar',
                          size: media.width * sixteen,
                          color: textColor,
                        ),
                      ),
                    ),
                    SizedBox(width: media.width * 0.03),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _salvar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme,
                          padding: EdgeInsets.symmetric(vertical: media.width * 0.04),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: media.width * 0.05,
                                width: media.width * 0.05,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : MyText(
                                text: 'Salvar',
                                size: media.width * sixteen,
                                fontweight: FontWeight.bold,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

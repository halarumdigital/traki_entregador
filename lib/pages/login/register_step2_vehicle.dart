import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';
import 'register_step3_documents.dart';

// Formatador de Placa Brasileira (aceita padrão antigo ABC-1234 e Mercosul ABC1D23)
class BrazilianPlateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    if (text.length > 7) {
      return oldValue;
    }

    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i < 3) {
        // Primeiras 3 posições: apenas letras
        if (RegExp(r'[A-Z]').hasMatch(text[i])) {
          formatted += text[i];
        }
      } else if (i == 3) {
        // 4ª posição: pode ser número (antigo ou mercosul)
        if (RegExp(r'[0-9]').hasMatch(text[i])) {
          formatted += text[i];
        }
      } else if (i == 4) {
        // 5ª posição: número (antigo) ou letra (mercosul)
        if (RegExp(r'[A-Z0-9]').hasMatch(text[i])) {
          formatted += text[i];
        }
      } else {
        // 6ª e 7ª posições: apenas números
        if (RegExp(r'[0-9]').hasMatch(text[i])) {
          formatted += text[i];
        }
      }
    }

    // Adiciona hífen se for padrão antigo (quando 5ª posição é número)
    if (formatted.length > 4 && formatted.length >= 4) {
      // Verifica se é padrão antigo (4 números no final)
      if (formatted.length > 4 && RegExp(r'[0-9]').hasMatch(formatted[4])) {
        formatted = '${formatted.substring(0, 3)}-${formatted.substring(3)}';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class RegisterStep2Vehicle extends StatefulWidget {
  final Map<String, dynamic> personalData;

  const RegisterStep2Vehicle({super.key, required this.personalData});

  @override
  State<RegisterStep2Vehicle> createState() => _RegisterStep2VehicleState();
}

class _RegisterStep2VehicleState extends State<RegisterStep2Vehicle> {
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  String? _selectedVehicleTypeId;
  String? _selectedBrandId;
  String? _selectedModelId;

  List<dynamic> _vehicleTypes = [];
  List<dynamic> _brands = [];
  List<dynamic> _models = [];

  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadVehicleTypes();
    _loadBrands();
  }

  Future<void> _loadVehicleTypes() async {
    setState(() => _isLoading = true);
    try {
      await getvehicleType();
      setState(() {
        _vehicleTypes = vehicleType;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar tipos de veículo';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBrands() async {
    setState(() => _isLoading = true);
    try {
      await getVehicleMake();
      setState(() {
        _brands = vehicleMake;
        _models = [];
        _selectedBrandId = null;
        _selectedModelId = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar marcas';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadModels() async {
    if (_selectedBrandId == null) return;

    setState(() => _isLoading = true);
    try {
      await getVehicleModel(_selectedBrandId!);
      setState(() {
        _models = vehicleModel;
        _selectedModelId = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar modelos';
        _isLoading = false;
      });
    }
  }

  bool _validateFields() {
    if (_selectedVehicleTypeId == null) {
      setState(() => _error = 'Selecione o tipo de veículo');
      return false;
    }
    if (_selectedBrandId == null) {
      setState(() => _error = 'Selecione a marca');
      return false;
    }
    if (_selectedModelId == null) {
      setState(() => _error = 'Selecione o modelo');
      return false;
    }
    if (_plateController.text.trim().isEmpty) {
      setState(() => _error = 'Placa é obrigatória');
      return false;
    }
    if (_colorController.text.trim().isEmpty) {
      setState(() => _error = 'Cor é obrigatória');
      return false;
    }
    if (_yearController.text.trim().isEmpty) {
      setState(() => _error = 'Ano é obrigatório');
      return false;
    }
    return true;
  }

  void _nextStep() {
    if (_validateFields()) {
      // Remover hífen da placa (se houver)
      final plateSemHifen = _plateController.text.trim().replaceAll('-', '');

      final vehicleData = {
        'vehicleTypeId': _selectedVehicleTypeId,
        'carMake': _selectedBrandId,
        'carModel': _selectedModelId,
        'carNumber': plateSemHifen,
        'carColor': _colorController.text.trim(),
        'carYear': _yearController.text.trim(),
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterStep3Documents(
            personalData: widget.personalData,
            vehicleData: vehicleData,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Material(
      child: Directionality(
        textDirection: (languageDirection == 'rtl')
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Scaffold(
          body: Stack(
            children: [
              Container(
                height: media.height * 1,
                width: media.width * 1,
                color: page,
                padding: EdgeInsets.fromLTRB(
                  media.width * 0.05,
                  media.height * 0.05,
                  media.width * 0.05,
                  media.height * 0.02,
                ),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Icon(Icons.arrow_back, color: textColor),
                        ),
                        SizedBox(width: media.width * 0.05),
                        Expanded(
                          child: MyText(
                            text: 'Cadastro - Dados do Veículo',
                            size: media.width * twenty,
                            fontweight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: media.height * 0.03),

                    // Step indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStepIndicator(1, false, true),
                        _buildStepLine(true),
                        _buildStepIndicator(2, true, false),
                        _buildStepLine(false),
                        _buildStepIndicator(3, false, false),
                      ],
                    ),
                    SizedBox(height: media.height * 0.03),

                    // Form
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Tipo de Veículo
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderLines, width: 1.2),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: media.width * 0.025),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedVehicleTypeId,
                                  hint: Text(
                                    'Tipo de Veículo (Moto, Carro, Van)',
                                    style: GoogleFonts.notoSans(color: hintColor),
                                  ),
                                  items: _vehicleTypes.map((type) {
                                    return DropdownMenuItem<String>(
                                      value: type['id'].toString(),
                                      child: Text(
                                        type['name'] ?? '',
                                        style: GoogleFonts.notoSans(color: textColor),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedVehicleTypeId = value;
                                      _error = '';
                                    });
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: media.height * 0.02),

                            // Marca
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderLines, width: 1.2),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: media.width * 0.025),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedBrandId,
                                  hint: Text(
                                    'Marca do Veículo',
                                    style: GoogleFonts.notoSans(color: hintColor),
                                  ),
                                  items: _brands.map((brand) {
                                    return DropdownMenuItem<String>(
                                      value: brand['id'].toString(),
                                      child: Text(
                                        brand['name'] ?? '',
                                        style: GoogleFonts.notoSans(color: textColor),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _brands.isEmpty ? null : (value) {
                                    setState(() {
                                      _selectedBrandId = value;
                                      _error = '';
                                    });
                                    _loadModels();
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: media.height * 0.02),

                            // Modelo
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderLines, width: 1.2),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: media.width * 0.025),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedModelId,
                                  hint: Text(
                                    'Modelo do Veículo',
                                    style: GoogleFonts.notoSans(color: hintColor),
                                  ),
                                  items: _models.map((model) {
                                    return DropdownMenuItem<String>(
                                      value: model['id'].toString(),
                                      child: Text(
                                        model['name'] ?? '',
                                        style: GoogleFonts.notoSans(color: textColor),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _models.isEmpty ? null : (value) {
                                    setState(() {
                                      _selectedModelId = value;
                                      _error = '';
                                    });
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: media.height * 0.02),

                            // Placa
                            InputField(
                              textController: _plateController,
                              text: 'Placa do Veículo (ABC-1234 ou ABC1D23)',
                              onTap: (val) {},
                              inputFormatters: [BrazilianPlateFormatter()],
                            ),
                            SizedBox(height: media.height * 0.02),

                            // Cor
                            InputField(
                              textController: _colorController,
                              text: 'Cor do Veículo',
                              onTap: (val) {},
                            ),
                            SizedBox(height: media.height * 0.02),

                            // Ano
                            InputField(
                              textController: _yearController,
                              text: 'Ano do Veículo',
                              onTap: (val) {},
                              inputType: TextInputType.number,
                              maxLength: 4,
                            ),
                            SizedBox(height: media.height * 0.02),

                            // Error message
                            if (_error.isNotEmpty)
                              Container(
                                padding: EdgeInsets.all(media.width * 0.03),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red),
                                    SizedBox(width: media.width * 0.02),
                                    Expanded(
                                      child: MyText(
                                        text: _error,
                                        size: media.width * fourteen,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            SizedBox(height: media.height * 0.03),

                            // Next button
                            Button(
                              onTap: _nextStep,
                              text: 'Próximo',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Loading
              if (_isLoading)
                Positioned(
                  top: 0,
                  child: Container(
                    height: media.height * 1,
                    width: media.width * 1,
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, bool isActive, bool isCompleted) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? Colors.green
            : isActive
                ? buttonColor
                : Colors.grey.shade300,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : Text(
                '$step',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      width: 50,
      height: 2,
      color: isActive ? buttonColor : Colors.grey.shade300,
    );
  }

  @override
  void dispose() {
    _plateController.dispose();
    _colorController.dispose();
    _yearController.dispose();
    super.dispose();
  }
}

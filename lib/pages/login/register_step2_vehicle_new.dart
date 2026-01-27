import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../functions/functions.dart';
import '../../styles/app_colors.dart';
import '../../components/buttons/primary_button.dart';
import 'register_step3_documents_new.dart';

/// Tela #4 - Cadastro - Dados do Veículo (novo design)
class RegisterStep2VehicleNew extends StatefulWidget {
  final Map<String, dynamic> personalData;

  const RegisterStep2VehicleNew({super.key, required this.personalData});

  @override
  State<RegisterStep2VehicleNew> createState() => _RegisterStep2VehicleNewState();
}

class _RegisterStep2VehicleNewState extends State<RegisterStep2VehicleNew> {
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();
  final _yearController = TextEditingController();
  final _pixKeyController = TextEditingController();

  String? _selectedVehicleTypeId;
  String? _selectedBrandId;
  String? _selectedModelId;
  String? _selectedPixKeyType;

  List<dynamic> _vehicleTypes = [];
  List<dynamic> _brands = [];
  List<dynamic> _models = [];

  // Opções de tipo de chave PIX
  final List<Map<String, String>> pixKeyTypes = [
    {'value': 'CPF', 'label': 'CPF'},
    {'value': 'EMAIL', 'label': 'E-mail'},
    {'value': 'PHONE', 'label': 'Telefone'},
    {'value': 'CNPJ', 'label': 'CNPJ'},
    {'value': 'EVP', 'label': 'Chave Aleatória'},
  ];

  bool _isLoading = false;

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
      setState(() => _isLoading = false);
      _showError('Erro ao carregar tipos de veículo');
    }
  }

  Future<void> _loadBrands() async {
    try {
      await getVehicleMake();
      setState(() {
        _brands = vehicleMake;
      });
    } catch (e) {
      _showError('Erro ao carregar marcas');
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
      setState(() => _isLoading = false);
      _showError('Erro ao carregar modelos');
    }
  }

  String _getPixKeyHint() {
    switch (_selectedPixKeyType) {
      case 'CPF':
        return '000.000.000-00';
      case 'CNPJ':
        return '00.000.000/0000-00';
      case 'EMAIL':
        return 'email@exemplo.com';
      case 'PHONE':
        return '+5511999999999';
      case 'EVP':
        return 'Chave aleatória';
      default:
        return 'Selecione o tipo primeiro';
    }
  }

  TextInputType _getPixKeyKeyboardType() {
    switch (_selectedPixKeyType) {
      case 'CPF':
      case 'CNPJ':
      case 'PHONE':
        return TextInputType.number;
      case 'EMAIL':
        return TextInputType.emailAddress;
      default:
        return TextInputType.text;
    }
  }

  String? _validatePixKey(String value) {
    switch (_selectedPixKeyType) {
      case 'CPF':
        final cpfRegex = RegExp(r'^\d{3}\.?\d{3}\.?\d{3}-?\d{2}$');
        if (!cpfRegex.hasMatch(value)) {
          return 'CPF inválido';
        }
        break;
      case 'CNPJ':
        final cnpjRegex = RegExp(r'^\d{2}\.?\d{3}\.?\d{3}\/?\d{4}-?\d{2}$');
        if (!cnpjRegex.hasMatch(value)) {
          return 'CNPJ inválido';
        }
        break;
      case 'EMAIL':
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value)) {
          return 'E-mail inválido';
        }
        break;
      case 'PHONE':
        final phoneRegex = RegExp(r'^\+?\d{10,14}$');
        if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
          return 'Telefone inválido';
        }
        break;
    }
    return null;
  }

  bool _validateFields() {
    if (_selectedVehicleTypeId == null) {
      _showError('Selecione o tipo de veículo');
      return false;
    }
    if (_selectedBrandId == null) {
      _showError('Selecione a marca');
      return false;
    }
    if (_selectedModelId == null) {
      _showError('Selecione o modelo');
      return false;
    }
    if (_plateController.text.trim().isEmpty) {
      _showError('Placa é obrigatória');
      return false;
    }
    if (_colorController.text.trim().isEmpty) {
      _showError('Cor é obrigatória');
      return false;
    }
    if (_yearController.text.trim().isEmpty) {
      _showError('Ano é obrigatório');
      return false;
    }
    if (_selectedPixKeyType == null) {
      _showError('Selecione o tipo da chave PIX');
      return false;
    }
    if (_pixKeyController.text.trim().isEmpty) {
      _showError('Chave PIX é obrigatória');
      return false;
    }
    final pixKeyError = _validatePixKey(_pixKeyController.text.trim());
    if (pixKeyError != null) {
      _showError(pixKeyError);
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _nextStep() {
    if (_validateFields()) {
      final plateSemHifen = _plateController.text.trim().replaceAll('-', '');

      final vehicleData = {
        'vehicleTypeId': _selectedVehicleTypeId,
        'carMake': _selectedBrandId,
        'carModel': _selectedModelId,
        'carNumber': plateSemHifen,
        'carColor': _colorController.text.trim(),
        'carYear': _yearController.text.trim(),
        'pixKey': _pixKeyController.text.trim(),
        'pixKeyType': _selectedPixKeyType,
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterStep3DocumentsNew(
            personalData: widget.personalData,
            vehicleData: vehicleData,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cadastrar',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Step indicators
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

            const SizedBox(height: 30),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Tipo de Veículo
                    _buildDropdown(
                      label: 'Tipo de veículo',
                      hint: 'Selecione o tipo',
                      value: _selectedVehicleTypeId,
                      items: _vehicleTypes,
                      onChanged: (value) {
                        setState(() => _selectedVehicleTypeId = value);
                      },
                    ),

                    const SizedBox(height: 20),

                    // Marca
                    _buildDropdown(
                      label: 'Marca do Veículo',
                      hint: 'Selecione a marca',
                      value: _selectedBrandId,
                      items: _brands,
                      onChanged: (value) {
                        setState(() {
                          _selectedBrandId = value;
                          _models = [];
                          _selectedModelId = null;
                        });
                        _loadModels();
                      },
                    ),

                    const SizedBox(height: 20),

                    // Modelo
                    _buildDropdown(
                      label: 'Modelo do Veículo',
                      hint: 'Selecione o modelo',
                      value: _selectedModelId,
                      items: _models,
                      onChanged: (value) {
                        setState(() => _selectedModelId = value);
                      },
                      enabled: _selectedBrandId != null,
                    ),

                    const SizedBox(height: 20),

                    // Placa
                    _buildTextField(
                      label: 'Placa do Veículo',
                      controller: _plateController,
                      hint: 'ABC-1234',
                      textCapitalization: TextCapitalization.characters,
                    ),

                    const SizedBox(height: 20),

                    // Cor
                    _buildTextField(
                      label: 'Cor do Veículo',
                      controller: _colorController,
                      hint: 'Ex: Preto',
                    ),

                    const SizedBox(height: 20),

                    // Ano
                    _buildTextField(
                      label: 'Ano do Veículo',
                      controller: _yearController,
                      hint: '2024',
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                    ),

                    const SizedBox(height: 20),

                    // Tipo de Chave PIX
                    _buildPixTypeDropdown(),

                    const SizedBox(height: 20),

                    // Chave PIX
                    _buildTextField(
                      label: 'Chave PIX',
                      controller: _pixKeyController,
                      hint: _getPixKeyHint(),
                      keyboardType: _getPixKeyKeyboardType(),
                    ),

                    const SizedBox(height: 40),

                    // Botão Próximo
                    PrimaryButton(
                      text: 'Próximo',
                      onPressed: _isLoading ? null : _nextStep,
                      isLoading: _isLoading,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
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
            ? AppColors.primary // Roxo do tema
            : isActive
                ? AppColors.primary
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
      color: isActive ? AppColors.primary : Colors.grey.shade300,
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int? maxLength,
    TextCapitalization? textCapitalization,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: maxLength,
            textCapitalization: textCapitalization ?? TextCapitalization.none,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              border: InputBorder.none,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<dynamic> items,
    required Function(String?) onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFF5F5F5) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text(
                hint,
                style: TextStyle(color: Colors.grey[400]),
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item['id'].toString(),
                  child: Text(
                    item['name'] ?? '',
                    style: const TextStyle(color: Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPixTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Chave PIX',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedPixKeyType,
              hint: Text(
                'Selecione o tipo',
                style: TextStyle(color: Colors.grey[400]),
              ),
              items: pixKeyTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['value'],
                  child: Text(
                    type['label']!,
                    style: const TextStyle(color: Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPixKeyType = value;
                  _pixKeyController.clear();
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _plateController.dispose();
    _colorController.dispose();
    _yearController.dispose();
    _pixKeyController.dispose();
    super.dispose();
  }
}

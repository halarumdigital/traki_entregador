import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../functions/functions.dart';
import '../../styles/app_colors.dart';
import '../../components/buttons/primary_button.dart';
import 'register_step2_vehicle_new.dart';

/// Tela #3 - Cadastro - Dados Pessoais (novo design)
class RegisterStep1PersonalNew extends StatefulWidget {
  const RegisterStep1PersonalNew({super.key});

  @override
  State<RegisterStep1PersonalNew> createState() => _RegisterStep1PersonalNewState();
}

class _RegisterStep1PersonalNewState extends State<RegisterStep1PersonalNew> {
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _profileImage;

  // Formatador de CPF: XXX.XXX.XXX-XX
  final cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // Formatador de Telefone: (##) #####-####
  final phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  String? _selectedCityId;
  List<dynamic> _cities = [];
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    setState(() => _isLoading = true);
    try {
      await getServiceLocation();
      setState(() {
        _cities = serviceLocations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar cidades')),
        );
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Câmera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e')),
        );
      }
    }
  }

  bool _validateFields() {
    if (_nameController.text.trim().isEmpty) {
      _showError('Nome é obrigatório');
      return false;
    }
    if (_cpfController.text.trim().isEmpty) {
      _showError('CPF é obrigatório');
      return false;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showError('Telefone é obrigatório');
      return false;
    }
    if (phoneFormatter.getUnmaskedText().length < 11) {
      _showError('Telefone inválido');
      return false;
    }
    if (_emailController.text.trim().isEmpty) {
      _showError('Email é obrigatório');
      return false;
    }
    if (!_emailController.text.contains('@')) {
      _showError('Email inválido');
      return false;
    }
    if (_passwordController.text.isEmpty) {
      _showError('Senha é obrigatória');
      return false;
    }
    if (_passwordController.text.length < 6) {
      _showError('Senha deve ter no mínimo 6 caracteres');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Senhas não coincidem');
      return false;
    }
    if (_selectedCityId == null) {
      _showError('Selecione uma cidade');
      return false;
    }
    if (!_acceptedTerms) {
      _showError('Você deve aceitar os termos e política de privacidade');
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
      final cpfSemFormatacao = cpfFormatter.getUnmaskedText();
      final phoneSemFormatacao = phoneFormatter.getUnmaskedText();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterStep2VehicleNew(
            personalData: {
              'name': _nameController.text.trim(),
              'cpf': cpfSemFormatacao,
              'mobile': '+55$phoneSemFormatacao',
              'email': _emailController.text.trim(),
              'password': _passwordController.text,
              'serviceLocationId': _selectedCityId,
              'referralCode': _referralCodeController.text.trim().isNotEmpty
                  ? _referralCodeController.text.trim()
                  : null,
              'profileImage': _profileImage,
            },
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
                _buildStepIndicator(1, true, false),
                _buildStepLine(false),
                _buildStepIndicator(2, false, false),
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
                    // Foto de perfil
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF5F5F5),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: _profileImage != null
                            ? ClipOval(
                                child: Image.file(
                                  _profileImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Nome
                    _buildTextField(
                      label: 'Nome completo',
                      controller: _nameController,
                      hint: 'Digite seu nome completo',
                    ),

                    const SizedBox(height: 20),

                    // CPF
                    _buildTextField(
                      label: 'CPF',
                      controller: _cpfController,
                      hint: '000.000.000-00',
                      keyboardType: TextInputType.number,
                      inputFormatters: [cpfFormatter],
                    ),

                    const SizedBox(height: 20),

                    // Telefone
                    _buildTextField(
                      label: 'Telefone',
                      controller: _phoneController,
                      hint: '(11) 98765-4321',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [phoneFormatter],
                    ),

                    const SizedBox(height: 20),

                    // Email
                    _buildTextField(
                      label: 'E-mail',
                      controller: _emailController,
                      hint: 'seu@email.com',
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 20),

                    // Senha
                    _buildPasswordField(
                      label: 'Senha',
                      controller: _passwordController,
                      obscure: _obscurePassword,
                      onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),

                    const SizedBox(height: 20),

                    // Confirmar Senha
                    _buildPasswordField(
                      label: 'Confirmar senha',
                      controller: _confirmPasswordController,
                      obscure: _obscureConfirmPassword,
                      onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),

                    const SizedBox(height: 20),

                    // Código de Indicação
                    _buildTextField(
                      label: 'Código de indicação (OPCIONAL)',
                      controller: _referralCodeController,
                      hint: 'Digite o código',
                    ),

                    const SizedBox(height: 20),

                    // Cidade
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cidade',
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
                              value: _selectedCityId,
                              hint: Text(
                                'Selecione sua cidade',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              items: _cities.map((city) {
                                return DropdownMenuItem<String>(
                                  value: city['id'].toString(),
                                  child: Text(
                                    city['name'] ?? '',
                                    style: const TextStyle(color: Colors.black87),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedCityId = value);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Checkbox de termos
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _acceptedTerms,
                            onChanged: (value) {
                              setState(() => _acceptedTerms = value ?? false);
                            },
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Ao criar uma conta, você concorda com nossos Termos de Serviço e Política de Privacidade.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Botão Registrar
                    PrimaryButton(
                      text: 'Registrar',
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
    List<dynamic>? inputFormatters,
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
            inputFormatters: inputFormatters != null ? inputFormatters.cast() : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              border: InputBorder.none,
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

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
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
            obscureText: obscure,
            decoration: InputDecoration(
              hintText: 'Digite sua senha',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey[400],
                ),
                onPressed: onToggle,
              ),
              border: InputBorder.none,
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

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }
}

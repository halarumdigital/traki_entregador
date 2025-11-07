import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';
import 'register_step2_vehicle.dart';

class RegisterStep1Personal extends StatefulWidget {
  const RegisterStep1Personal({super.key});

  @override
  State<RegisterStep1Personal> createState() => _RegisterStep1PersonalState();
}

class _RegisterStep1PersonalState extends State<RegisterStep1Personal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Formatador de CPF: XXX.XXX.XXX-XX
  final cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  String? _selectedCityId;
  List<dynamic> _cities = [];
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('🔄 Carregando cidades...');
      var result = await getServiceLocation();
      debugPrint('✅ Resultado: $result');
      debugPrint('📍 Cidades carregadas: ${serviceLocations.length}');
      debugPrint('📍 Dados: $serviceLocations');
      setState(() {
        _cities = serviceLocations;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erro ao carregar cidades: $e');
      setState(() {
        _error = 'Erro ao carregar cidades';
        _isLoading = false;
      });
    }
  }

  bool _validateFields() {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Nome é obrigatório');
      return false;
    }
    if (_cpfController.text.trim().isEmpty) {
      setState(() => _error = 'CPF é obrigatório');
      return false;
    }
    if (_mobileController.text.trim().isEmpty) {
      setState(() => _error = 'Telefone é obrigatório');
      return false;
    }
    if (_emailController.text.trim().isEmpty) {
      setState(() => _error = 'Email é obrigatório');
      return false;
    }
    if (!_emailController.text.contains('@')) {
      setState(() => _error = 'Email inválido');
      return false;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Senha é obrigatória');
      return false;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _error = 'Senha deve ter no mínimo 6 caracteres');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Senhas não conferem');
      return false;
    }
    if (_selectedCityId == null) {
      setState(() => _error = 'Selecione uma cidade');
      return false;
    }
    return true;
  }

  void _nextStep() {
    if (_validateFields()) {
      // Sempre usar +55 (Brasil)
      // Remover formatação do CPF (remover pontos e traço)
      final cpfSemFormatacao = cpfFormatter.getUnmaskedText();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterStep2Vehicle(
            personalData: {
              'name': _nameController.text.trim(),
              'cpf': cpfSemFormatacao,
              'mobile': '+55${_mobileController.text.trim()}',
              'email': _emailController.text.trim(),
              'password': _passwordController.text,
              'serviceLocationId': _selectedCityId,
            },
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
                            text: 'Cadastro - Dados Pessoais',
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
                        _buildStepIndicator(1, true),
                        _buildStepLine(false),
                        _buildStepIndicator(2, false),
                        _buildStepLine(false),
                        _buildStepIndicator(3, false),
                      ],
                    ),
                    SizedBox(height: media.height * 0.03),

                    // Form
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Nome
                            InputField(
                              textController: _nameController,
                              text: 'Nome Completo',
                              onTap: (val) {},
                            ),
                            SizedBox(height: media.height * 0.02),

                            // CPF
                            InputField(
                              textController: _cpfController,
                              text: 'CPF',
                              onTap: (val) {},
                              inputType: TextInputType.number,
                              inputFormatters: [cpfFormatter],
                            ),
                            SizedBox(height: media.height * 0.02),

                            // Telefone (DDD + Número)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderLines, width: 1.2),
                              ),
                              padding: EdgeInsets.only(left: media.width * 0.025),
                              child: Row(
                                children: [
                                  Container(
                                    height: 50,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '+55',
                                      style: GoogleFonts.notoSans(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: media.width * 0.02),
                                  Expanded(
                                    child: TextField(
                                      controller: _mobileController,
                                      keyboardType: TextInputType.phone,
                                      decoration: InputDecoration(
                                        hintText: 'DDD + Telefone (ex: 11987654321)',
                                        hintStyle: GoogleFonts.notoSans(color: hintColor),
                                        border: InputBorder.none,
                                      ),
                                      style: GoogleFonts.notoSans(color: textColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: media.height * 0.02),

                            // Email
                            InputField(
                              textController: _emailController,
                              text: 'Email',
                              onTap: (val) {},
                              inputType: TextInputType.emailAddress,
                            ),
                            SizedBox(height: media.height * 0.02),

                            // Senha
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderLines, width: 1.2),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: media.width * 0.025),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        hintText: 'Senha (mín. 6 caracteres)',
                                        hintStyle: GoogleFonts.notoSans(color: hintColor),
                                        border: InputBorder.none,
                                      ),
                                      style: GoogleFonts.notoSans(color: textColor),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: textColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: media.height * 0.02),

                            // Confirmar Senha
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderLines, width: 1.2),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: media.width * 0.025),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirmPassword,
                                      decoration: InputDecoration(
                                        hintText: 'Confirmar Senha',
                                        hintStyle: GoogleFonts.notoSans(color: hintColor),
                                        border: InputBorder.none,
                                      ),
                                      style: GoogleFonts.notoSans(color: textColor),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: textColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: media.height * 0.02),

                            // Seletor de Cidade
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderLines, width: 1.2),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: media.width * 0.025),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedCityId,
                                  hint: Text(
                                    'Selecione a cidade',
                                    style: GoogleFonts.notoSans(color: hintColor),
                                  ),
                                  items: _cities.map((city) {
                                    return DropdownMenuItem<String>(
                                      value: city['id'].toString(),
                                      child: Text(
                                        city['name'] ?? '',
                                        style: GoogleFonts.notoSans(color: textColor),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCityId = value;
                                      _error = '';
                                    });
                                  },
                                ),
                              ),
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

  Widget _buildStepIndicator(int step, bool isActive) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? buttonColor : Colors.grey.shade300,
      ),
      child: Center(
        child: Text(
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
    _nameController.dispose();
    _cpfController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

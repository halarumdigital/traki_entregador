import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';

/// Tela #8 - Status do Cadastro
class RegistrationStatusScreenNew extends StatefulWidget {
  final String driverId;

  const RegistrationStatusScreenNew({
    super.key,
    required this.driverId,
  });

  @override
  State<RegistrationStatusScreenNew> createState() => _RegistrationStatusScreenNewState();
}

class _RegistrationStatusScreenNewState extends State<RegistrationStatusScreenNew> {
  // Status dos steps (em produção viria da API)
  final bool _registrationCompleted = true;
  final bool _documentsUploaded = true;
  final bool _documentsUnderReview = true;
  final bool _registrationApproved = false;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    // TODO: Implementar verificação periódica com API para checar se foi aprovado
    // Quando aprovado, navegar para RegistrationApprovedScreen
  }

  Future<void> _loadProfileImage() async {
    final imagePath = await LocalStorageService.getProfileImagePath();
    if (mounted) {
      setState(() {
        _profileImagePath = imagePath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF8719CA), // Roxo do tema
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Status do Cadastro',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              // TODO: Recarregar status da API
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header com fundo roxo
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xFF8719CA), // Roxo do tema
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: EdgeInsets.only(bottom: 40),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Foto de perfil
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                  child: ClipOval(
                    child: _profileImagePath != null && _profileImagePath!.isNotEmpty
                        ? Image.network(
                            _profileImagePath!,
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                            errorBuilder: (context, error, stackTrace) {
                              // Se falhar ao carregar, mostra a letra
                              return Center(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8719CA),
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: Color(0xFF8719CA),
                                  strokeWidth: 2,
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              'G', // Primeira letra do nome
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8719CA), // Roxo do tema
                              ),
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Nome do usuário
                const Text(
                  'Gilliard damaceno',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                // Badge "Em Análise"
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF9800), // Laranja
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Em Análise',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de status com scroll
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progresso do Cadastro',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Lista de status
                  _buildStatusItem(
                    title: 'Cadastro Realizado',
                    subtitle: 'Seus dados foram enviados com sucesso',
                    timestamp: '27/01/2026 18:02',
                    isCompleted: _registrationCompleted,
                  ),

                  const SizedBox(height: 24),

                  _buildStatusItem(
                    title: 'Envio de Documentos',
                    subtitle: 'Todos os documentos foram enviados',
                    timestamp: '27/01/2026 18:09',
                    isCompleted: _documentsUploaded,
                  ),

                  const SizedBox(height: 24),

                  _buildStatusItem(
                    title: 'Análise de Documentos',
                    subtitle: 'Documentos em análise pela equipe',
                    timestamp: '',
                    isCompleted: _documentsUnderReview,
                    isPending: !_registrationApproved,
                  ),

                  const SizedBox(height: 24),

                  _buildStatusItem(
                    title: 'Cadastro Aprovado',
                    subtitle: 'Aguardando aprovação',
                    timestamp: '',
                    isCompleted: _registrationApproved,
                    isPending: !_registrationApproved,
                  ),

                  const Spacer(),

                  // Home indicator
                  Center(
                    child: Container(
                      width: 134,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required String title,
    required String subtitle,
    required String timestamp,
    required bool isCompleted,
    bool isPending = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícone de status
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Color(0xFF8719CA) // Roxo do tema
                : isPending
                    ? Colors.grey[300]
                    : Colors.grey[200],
          ),
          child: isCompleted
              ? Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                )
              : null,
        ),

        const SizedBox(width: 16),

        // Textos
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? Colors.black : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              if (timestamp.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  timestamp,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

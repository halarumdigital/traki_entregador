import 'package:flutter/material.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';
import 'minhas_rotas.dart';
import 'minhas_viagens.dart';

class RotasHubScreen extends StatelessWidget {
  const RotasHubScreen({super.key});

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
                      text: 'Rotas',
                      size: media.width * twenty,
                      fontweight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Conteúdo
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(media.width * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Descrição
                    Container(
                      padding: EdgeInsets.all(media.width * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue, size: media.width * 0.06),
                          SizedBox(width: media.width * 0.03),
                          Expanded(
                            child: MyText(
                              text: 'Gerencie suas rotas intermunicipais e viagens programadas',
                              size: media.width * fourteen,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: media.width * 0.06),

                    // Card: Minhas Rotas
                    _buildOptionCard(
                      context: context,
                      media: media,
                      title: 'Minhas Rotas',
                      description: 'Configure e gerencie suas rotas entre cidades',
                      icon: Icons.route,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MinhasRotasScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: media.width * 0.04),

                    // Card: Minhas Viagens
                    _buildOptionCard(
                      context: context,
                      media: media,
                      title: 'Minhas Viagens',
                      description: 'Acompanhe suas viagens agendadas e em andamento',
                      icon: Icons.map_outlined,
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MinhasViagensScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required Size media,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(media.width * 0.05),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ícone
            Container(
              padding: EdgeInsets.all(media.width * 0.04),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: media.width * 0.08,
              ),
            ),
            SizedBox(width: media.width * 0.04),

            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: title,
                    size: media.width * eighteen,
                    fontweight: FontWeight.bold,
                    color: textColor,
                  ),
                  SizedBox(height: media.width * 0.01),
                  MyText(
                    text: description,
                    size: media.width * fourteen,
                    color: textColor.withOpacity(0.7),
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            // Seta
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: media.width * 0.05,
            ),
          ],
        ),
      ),
    );
  }
}

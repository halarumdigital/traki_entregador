import 'package:flutter/material.dart';
import 'package:flutter_driver/services/delivery_service.dart';
import '../../styles/app_colors.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';

class PromotionsPage extends StatefulWidget {
  const PromotionsPage({super.key});

  @override
  State<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends State<PromotionsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _promotions = [];

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final promotions = await DeliveryService.getPromotions();
      if (mounted) {
        setState(() {
          _promotions = promotions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Material(
      child: Container(
        color: page,
        child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.fromLTRB(
                  media.width * 0.05,
                  MediaQuery.of(context).padding.top + (media.width * 0.05),
                  media.width * 0.05,
                  media.width * 0.05,
                ),
                color: topBar,
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(
                        Icons.arrow_back,
                        color: textColor,
                      ),
                    ),
                    SizedBox(width: media.width * 0.05),
                    Expanded(
                      child: MyText(
                        text: 'Promoções',
                        size: media.width * twenty,
                        fontweight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    InkWell(
                      onTap: _loadPromotions,
                      child: Icon(
                        Icons.refresh,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: buttonColor,
                        ),
                      )
                    : _promotions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.card_giftcard,
                                  size: media.width * 0.2,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: media.width * 0.05),
                                MyText(
                                  text: 'Nenhuma promoção ativa no momento',
                                  size: media.width * sixteen,
                                  color: textColor.withOpacity(0.6),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadPromotions,
                            color: buttonColor,
                            child: ListView.builder(
                              padding: EdgeInsets.all(media.width * 0.05),
                              itemCount: _promotions.length,
                              itemBuilder: (context, index) {
                                return _buildPromotionCard(_promotions[index]);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promotion) {
    final String type = promotion['type'] ?? '';
    final String name = promotion['name'] ?? 'Promoção';
    final String description = promotion['description'] ?? '';
    final String prize = promotion['prize'] ?? '';

    // Cor roxa para ambos os tipos
    const Color cardColor = Color(0xFFF3E5F5); // Roxo claro
    const Color progressColor = AppColors.primary;
    final IconData icon = type == 'top_performer' ? Icons.emoji_events : Icons.local_shipping;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: progressColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: progressColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Badge de prêmio
              if (prize.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.card_giftcard, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        prize,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Descrição da promoção
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (type == 'complete_and_win') ...[
            // Barra de progresso para complete_and_win
            _buildCompleteAndWinProgress(promotion, progressColor),
          ] else if (type == 'top_performer') ...[
            // Exibição de ranking para top_performer
            _buildTopPerformerProgress(promotion, progressColor),
          ],
        ],
      ),
    );
  }

  Widget _buildCompleteAndWinProgress(Map<String, dynamic> promotion, Color color) {
    // Pegar dados do progress se existir, senão usar valores da raiz
    final Map<String, dynamic>? progressData = promotion['progress'];
    final int goal = progressData?['goal'] ?? promotion['goal'] ?? 1;
    final int current = progressData?['current'] ?? 0;
    final int remaining = progressData?['remaining'] ?? (goal - current);
    final double percentage = progressData?['percentage']?.toDouble() ??
        (goal > 0 ? (current / goal * 100) : 0.0);
    final bool goalReached = progressData?['goalReached'] ?? (current >= goal);

    // Formatar datas válidas
    final String validDates = promotion['validDates'] ?? '';
    String formattedDates = '';
    if (validDates.isNotEmpty) {
      final dates = validDates.split(',');
      final formattedList = dates.map((date) {
        try {
          final parts = date.split('-');
          if (parts.length == 3) {
            return '${parts[2]}/${parts[1]}';
          }
        } catch (_) {}
        return date;
      }).toList();
      formattedDates = formattedList.join(', ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Datas válidas
        if (formattedDates.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Válido: $formattedDates',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        // Linha com meta e progresso
        Row(
          children: [
            // Coluna: Entregas feitas
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Suas entregas',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$current',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            // Coluna: Meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Meta',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$goal',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            // Coluna: Faltam
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    goalReached ? 'Concluído!' : 'Faltam',
                    style: TextStyle(
                      fontSize: 12,
                      color: goalReached ? Colors.green : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goalReached ? '0' : '$remaining',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: goalReached ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Barra de progresso
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${percentage.toStringAsFixed(1)}% concluído',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTopPerformerProgress(Map<String, dynamic> promotion, Color color) {
    // Pegar dados do progress se existir, senão usar valores da raiz
    final Map<String, dynamic>? progressData = promotion['progress'];
    final int current = progressData?['current'] ?? 0;
    final int rank = progressData?['rank'] ?? 0;
    final int leaderCount = progressData?['leaderCount'] ?? 0;

    // Formatar datas válidas
    final String validDates = promotion['validDates'] ?? '';
    String formattedDates = '';
    if (validDates.isNotEmpty) {
      final dates = validDates.split(',');
      final formattedList = dates.map((date) {
        try {
          final parts = date.split('-');
          if (parts.length == 3) {
            return '${parts[2]}/${parts[1]}';
          }
        } catch (_) {}
        return date;
      }).toList();
      formattedDates = formattedList.join(', ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Datas válidas
        if (formattedDates.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Válido: $formattedDates',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        // Linha com estatísticas
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Suas entregas',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$current',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Sua posição',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (rank > 0 && rank <= 3)
                        Icon(
                          Icons.emoji_events,
                          color: rank == 1
                              ? Colors.amber
                              : rank == 2
                                  ? Colors.grey.shade400
                                  : Colors.brown.shade300,
                          size: 20,
                        ),
                      Text(
                        rank > 0 ? '$rank°' : '-',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Participantes',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    leaderCount > 0 ? '$leaderCount' : '-',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

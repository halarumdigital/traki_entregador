import 'package:flutter/material.dart';
import 'package:flutter_driver/services/delivery_service.dart';
import 'package:intl/intl.dart';
import '../../functions/functions.dart';
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

  String _formatDates(dynamic validDates) {
    if (validDates == null) return '';

    List<String> dates;

    // Se for uma lista, converte para List<String>
    if (validDates is List) {
      dates = validDates.map((d) => d.toString()).toList();
    }
    // Se for string, faz split por vírgula
    else if (validDates is String) {
      if (validDates.isEmpty) return '';
      dates = validDates.split(',').map((d) => d.trim()).toList();
    }
    else {
      return '';
    }

    if (dates.isEmpty) return '';
    if (dates.length == 1) {
      final date = DateTime.parse(dates[0]);
      return DateFormat('dd/MM/yyyy').format(date);
    }
    final firstDate = DateTime.parse(dates.first);
    final lastDate = DateTime.parse(dates.last);
    return '${DateFormat('dd/MM').format(firstDate)} - ${DateFormat('dd/MM/yyyy').format(lastDate)}';
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
                                final promotion = _promotions[index];
                                return Container(
                                  margin: EdgeInsets.only(
                                    bottom: media.width * 0.05,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.orange.shade400,
                                        Colors.deepOrange.shade600,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header do card
                                      Container(
                                        padding: EdgeInsets.all(
                                          media.width * 0.04,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(
                                                media.width * 0.02,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.card_giftcard,
                                                color: Colors.white,
                                                size: media.width * 0.08,
                                              ),
                                            ),
                                            SizedBox(width: media.width * 0.03),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    promotion['name'] ?? '',
                                                    style: TextStyle(
                                                      fontSize: media.width * 0.045,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(height: media.width * 0.01),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: media.width * 0.02,
                                                      vertical: media.width * 0.005,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.3),
                                                      borderRadius:
                                                          BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      promotion['type'] == 'complete_and_win'
                                                          ? 'Complete e Ganhe'
                                                          : 'Quem fizer mais',
                                                      style: TextStyle(
                                                        fontSize:
                                                            media.width * 0.03,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Descrição da promoção
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: media.width * 0.04,
                                          vertical: media.width * 0.02,
                                        ),
                                        child: Text(
                                          promotion['description'] ?? '',
                                          style: TextStyle(
                                            fontSize: media.width * 0.04,
                                            color: Colors.white,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),

                                      // Prêmio
                                      if (promotion['prize'] != null && promotion['prize'].toString().isNotEmpty)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: media.width * 0.04,
                                            vertical: media.width * 0.02,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.emoji_events,
                                                color: Colors.yellow.shade300,
                                                size: media.width * 0.05,
                                              ),
                                              SizedBox(width: media.width * 0.02),
                                              Expanded(
                                                child: Text(
                                                  'Prêmio: ${promotion['prize']}',
                                                  style: TextStyle(
                                                    fontSize: media.width * 0.04,
                                                    color: Colors.yellow.shade300,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      // Info adicional
                                      Container(
                                        padding: EdgeInsets.all(
                                          media.width * 0.04,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(12),
                                            bottomRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: media.width * 0.04,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(
                                                    width: media.width * 0.02),
                                                Text(
                                                  _formatDates(
                                                      promotion['validDates']),
                                                  style: TextStyle(
                                                    fontSize:
                                                        media.width * 0.035,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (promotion['goal'] != null)
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      media.width * 0.03,
                                                  vertical: media.width * 0.015,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.flag,
                                                      size: media.width * 0.04,
                                                      color: Colors
                                                          .deepOrange.shade600,
                                                    ),
                                                    SizedBox(
                                                        width:
                                                            media.width * 0.01),
                                                    Text(
                                                      'Meta: ${promotion['goal']} entregas',
                                                      style: TextStyle(
                                                        fontSize:
                                                            media.width * 0.035,
                                                        color: Colors.deepOrange
                                                            .shade600,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      );
  }
}

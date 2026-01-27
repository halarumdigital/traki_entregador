import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/functions.dart';
import '../../models/faq.dart' as faq_model;
import '../../services/faq_service.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../login/landingpage.dart';
import '../login/login.dart';
import '../noInternet/nointernet.dart';

class Faq extends StatefulWidget {
  const Faq({super.key});

  @override
  State<Faq> createState() => _FaqState();
}

class _FaqState extends State<Faq> {
  // Cor roxa padrão
  static const Color _primaryColor = Color(0xFF7B1FA2);

  bool _isLoading = true;
  List<faq_model.FaqCategory> _faqCategories = [];
  int? _expandedIndex;

  navigateLogout() {
    if (ownermodule == '1') {
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
            (route) => false);
      });
    } else {
      ischeckownerordriver = 'driver';
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Login()),
            (route) => false);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  Future<void> _loadFaqs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await FaqService.getFaqs();

      if (mounted) {
        setState(() {
          _faqCategories = categories;
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

  // Combina todos os FAQs de todas as categorias em uma lista única
  List<faq_model.Faq> get _allFaqs {
    List<faq_model.Faq> allFaqs = [];
    for (var category in _faqCategories) {
      allFaqs.addAll(category.items);
    }
    return allFaqs;
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    final allFaqs = _allFaqs;

    return SafeArea(
      child: Material(
        child: ValueListenableBuilder(
          valueListenable: valueNotifierHome.value,
          builder: (context, value, child) {
            return Directionality(
              textDirection: (languageDirection == 'rtl')
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Stack(
                children: [
                  Container(
                    height: media.height * 1,
                    width: media.width * 1,
                    color: page,
                    padding: EdgeInsets.fromLTRB(
                        media.width * 0.05, media.width * 0.05, media.width * 0.05, 0),
                    child: Column(
                      children: [
                        SizedBox(height: MediaQuery.of(context).padding.top),
                        Stack(
                          children: [
                            Container(
                              padding: EdgeInsets.only(bottom: media.width * 0.05),
                              width: media.width * 1,
                              alignment: Alignment.center,
                              child: MyText(
                                text: 'FAQ',
                                size: media.width * twenty,
                                fontweight: FontWeight.w600,
                              ),
                            ),
                            Positioned(
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Icon(Icons.arrow_back_ios, color: textColor),
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: media.width * 0.05),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadFaqs,
                            child: allFaqs.isEmpty && !_isLoading
                                ? Center(
                                    child: MyText(
                                      text: 'Nenhuma pergunta encontrada',
                                      size: media.width * sixteen,
                                      fontweight: FontWeight.w500,
                                      color: textColor.withValues(alpha: 0.6),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: allFaqs.length,
                                    itemBuilder: (context, index) {
                                      final faq = allFaqs[index];
                                      final isExpanded = _expandedIndex == index;

                                      return Container(
                                        margin: EdgeInsets.only(
                                          bottom: media.width * 0.03,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isExpanded
                                                ? _primaryColor.withValues(alpha: 0.3)
                                                : borderLines,
                                            width: 1,
                                          ),
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              if (isExpanded) {
                                                _expandedIndex = null;
                                              } else {
                                                _expandedIndex = index;
                                              }
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(12),
                                          child: Padding(
                                            padding: EdgeInsets.all(media.width * 0.04),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    // Pergunta
                                                    Expanded(
                                                      child: Text(
                                                        faq.question,
                                                        style: GoogleFonts.notoSans(
                                                          fontSize: media.width * fourteen,
                                                          fontWeight: FontWeight.w600,
                                                          color: textColor,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: media.width * 0.03),
                                                    // Ícone de seta
                                                    Container(
                                                      width: media.width * 0.08,
                                                      height: media.width * 0.08,
                                                      decoration: BoxDecoration(
                                                        color: _primaryColor,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        isExpanded
                                                            ? Icons.keyboard_arrow_up
                                                            : Icons.keyboard_arrow_right,
                                                        color: Colors.white,
                                                        size: media.width * 0.05,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                // Resposta (quando expandido)
                                                if (isExpanded) ...[
                                                  SizedBox(height: media.width * 0.03),
                                                  Text(
                                                    faq.answer,
                                                    style: GoogleFonts.notoSans(
                                                      fontSize: media.width * twelve,
                                                      color: textColor.withValues(alpha: 0.7),
                                                      height: 1.5,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        )
                      ],
                    ),
                  ),

                  // no internet
                  (internet == false)
                      ? Positioned(
                          top: 0,
                          child: NoInternet(
                            onTap: () {
                              setState(() {
                                internetTrue();
                                _loadFaqs();
                              });
                            },
                          ))
                      : Container(),

                  // loader
                  (_isLoading == true)
                      ? const Positioned(top: 0, child: Loading())
                      : Container()
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

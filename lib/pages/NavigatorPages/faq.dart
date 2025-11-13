import 'package:flutter/material.dart';
import '../../functions/functions.dart';
import '../../models/faq.dart' as faq_model;
import '../../services/faq_service.dart';
import '../../styles/styles.dart';
import '../../translation/translation.dart';
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
  bool _isLoading = true;
  List<faq_model.FaqCategory> _faqCategories = [];
  final Map<String, int?> _expandedIndexByCategory = {};

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

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
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
                                text: languages[choosenLanguage]['text_faq'],
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
                        SizedBox(
                          width: media.width * 0.9,
                          height: media.height * 0.16,
                          child: Image.asset(
                            'assets/images/faqPage.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: media.width * 0.05),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadFaqs,
                            child: _faqCategories.isEmpty && !_isLoading
                                ? Center(
                                    child: MyText(
                                      text: languages[choosenLanguage]['text_noDataFound'],
                                      size: media.width * eighteen,
                                      fontweight: FontWeight.w600,
                                    ),
                                  )
                                : ListView(
                                    children: _faqCategories.map((categoryData) {
                                      final category = categoryData.category;
                                      final faqs = categoryData.items;

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Título da Categoria
                                          Padding(
                                            padding: EdgeInsets.only(
                                              left: media.width * 0.02,
                                              bottom: media.width * 0.03,
                                              top: media.width * 0.04,
                                            ),
                                            child: MyText(
                                              text: category,
                                              size: media.width * eighteen,
                                              fontweight: FontWeight.bold,
                                              color: buttonColor,
                                            ),
                                          ),

                                          // FAQs da Categoria
                                          ...faqs.asMap().entries.map((faqEntry) {
                                            final index = faqEntry.key;
                                            final faq = faqEntry.value;
                                            final isExpanded =
                                                _expandedIndexByCategory[category] == index;

                                            return InkWell(
                                              onTap: () {
                                                setState(() {
                                                  if (isExpanded) {
                                                    _expandedIndexByCategory[category] = null;
                                                  } else {
                                                    _expandedIndexByCategory[category] = index;
                                                  }
                                                });
                                              },
                                              child: Container(
                                                width: media.width * 0.9,
                                                margin: EdgeInsets.only(
                                                  top: media.width * 0.025,
                                                  bottom: media.width * 0.025,
                                                ),
                                                padding: EdgeInsets.all(media.width * 0.05),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(8),
                                                  color: page,
                                                  border: Border.all(
                                                    color: isExpanded
                                                        ? buttonColor
                                                        : borderLines,
                                                    width: isExpanded ? 1.5 : 1.2,
                                                  ),
                                                  boxShadow: isExpanded
                                                      ? [
                                                          BoxShadow(
                                                            color: buttonColor
                                                                .withOpacity(0.1),
                                                            blurRadius: 4,
                                                            offset: const Offset(0, 2),
                                                          )
                                                        ]
                                                      : null,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment.start,
                                                            children: [
                                                              Container(
                                                                margin: EdgeInsets.only(
                                                                  top: media.width * 0.005,
                                                                  right: media.width * 0.03,
                                                                ),
                                                                padding: EdgeInsets.all(
                                                                  media.width * 0.015,
                                                                ),
                                                                decoration: BoxDecoration(
                                                                  color: buttonColor
                                                                      .withOpacity(0.1),
                                                                  shape: BoxShape.circle,
                                                                ),
                                                                child: Icon(
                                                                  Icons.help_outline,
                                                                  color: buttonColor,
                                                                  size: media.width * 0.04,
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: MyText(
                                                                  text: faq.question,
                                                                  size: media.width * fourteen,
                                                                  fontweight: FontWeight.w600,
                                                                  maxLines: null,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        RotatedBox(
                                                          quarterTurns: isExpanded ? 2 : 0,
                                                          child: Image.asset(
                                                            'assets/images/chevron-down.png',
                                                            width: media.width * 0.075,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    AnimatedContainer(
                                                      duration:
                                                          const Duration(milliseconds: 200),
                                                      child: isExpanded
                                                          ? Container(
                                                              padding: EdgeInsets.only(
                                                                top: media.width * 0.03,
                                                                left: media.width * 0.088,
                                                              ),
                                                              child: MyText(
                                                                text: faq.answer,
                                                                size: media.width * twelve,
                                                                color: textColor
                                                                    .withOpacity(0.8),
                                                                maxLines: null,
                                                              ),
                                                            )
                                                          : Container(),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),

                                          SizedBox(height: media.width * 0.02),
                                        ],
                                      );
                                    }).toList(),
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

// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_driver/pages/loadingPage/loading.dart';
import 'package:flutter_driver/pages/login/login.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/functions.dart';
import '../../models/notification.dart' as notification_model;
import '../../services/driver_notification_service.dart';
import '../../styles/styles.dart';
import '../../translation/translation.dart';
import '../../widgets/widgets.dart';
import '../login/landingpage.dart';
import '../noInternet/nointernet.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _isLoading = true;
  List<notification_model.DriverNotification> _notifications = [];
  bool showinfo = false;
  int? showinfovalue;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await DriverNotificationService.getNotifications();

      if (response != null && response.success) {
        if (mounted) {
          setState(() {
            _notifications = response.notifications;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _notifications = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar notificações: $e');
      if (mounted) {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
      }
    }
  }

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
                                text: languages[choosenLanguage]['text_notification'],
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
                            onRefresh: _loadNotifications,
                            child: _notifications.isEmpty && !_isLoading
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          alignment: Alignment.center,
                                          height: media.width * 0.5,
                                          width: media.width * 0.5,
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: AssetImage((isDarkTheme)
                                                  ? 'assets/images/nodatafoundd.gif'
                                                  : 'assets/images/nodatafound.gif'),
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: media.width * 0.07),
                                        SizedBox(
                                          width: media.width * 0.8,
                                          child: MyText(
                                            text: languages[choosenLanguage]['text_noDataFound'],
                                            textAlign: TextAlign.center,
                                            fontweight: FontWeight.w800,
                                            size: media.width * sixteen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    itemCount: _notifications.length,
                                    itemBuilder: (context, index) {
                                      final notification = _notifications[index];
                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            showinfovalue = index;
                                            showinfo = true;
                                          });
                                        },
                                        child: Container(
                                          margin: EdgeInsets.only(
                                            top: media.width * 0.02,
                                            bottom: media.width * 0.02,
                                          ),
                                          width: media.width * 0.9,
                                          padding: EdgeInsets.all(media.width * 0.025),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: borderLines, width: 1.2),
                                            borderRadius: BorderRadius.circular(12),
                                            color: page,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                height: media.width * 0.1067,
                                                width: media.width * 0.1067,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(10),
                                                  color: notification.isCityNotification
                                                      ? buttonColor.withOpacity(0.1)
                                                      : const Color(0xff000000).withOpacity(0.05),
                                                ),
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  notification.isCityNotification
                                                      ? Icons.location_city
                                                      : Icons.notifications,
                                                  color: notification.isCityNotification
                                                      ? buttonColor
                                                      : textColor.withOpacity(0.6),
                                                ),
                                              ),
                                              SizedBox(width: media.width * 0.025),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      notification.title,
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                      style: GoogleFonts.notoSans(
                                                        fontSize: media.width * fourteen,
                                                        color: textColor,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(height: media.width * 0.01),
                                                    Text(
                                                      notification.body,
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                      style: GoogleFonts.notoSans(
                                                        fontSize: media.width * twelve,
                                                        color: hintColor,
                                                      ),
                                                    ),
                                                    SizedBox(height: media.width * 0.01),
                                                    Text(
                                                      notification.formattedDate,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.notoSans(
                                                        fontSize: media.width * twelve,
                                                        color: textColor.withOpacity(0.6),
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Modal de detalhes da notificação
                  if (showinfo && showinfovalue != null)
                    Positioned(
                      top: 0,
                      child: Container(
                        height: media.height * 1,
                        width: media.width * 1,
                        color: Colors.transparent.withOpacity(0.6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: media.width * 0.9,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    height: media.height * 0.1,
                                    width: media.width * 0.1,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: borderLines.withOpacity(0.5),
                                      ),
                                      shape: BoxShape.circle,
                                      color: page,
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          showinfo = false;
                                          showinfovalue = null;
                                        });
                                      },
                                      child: Icon(Icons.cancel_outlined, color: textColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(media.width * 0.05),
                              width: media.width * 0.9,
                              decoration: BoxDecoration(
                                border: Border.all(color: borderLines.withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(12),
                                color: page,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Título
                                  MyText(
                                    text: _notifications[showinfovalue!].title,
                                    size: media.width * sixteen,
                                    fontweight: FontWeight.w600,
                                    maxLines: null,
                                  ),
                                  SizedBox(height: media.width * 0.05),
                                  // Corpo
                                  MyText(
                                    text: _notifications[showinfovalue!].body,
                                    size: media.width * fourteen,
                                    color: textColor.withOpacity(0.8),
                                    maxLines: null,
                                  ),
                                  SizedBox(height: media.width * 0.05),
                                  // Data
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: media.width * 0.04,
                                        color: hintColor,
                                      ),
                                      SizedBox(width: media.width * 0.02),
                                      MyText(
                                        text: _notifications[showinfovalue!].formattedDate,
                                        size: media.width * twelve,
                                        color: hintColor,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // No internet
                  (internet == false)
                      ? Positioned(
                          top: 0,
                          child: NoInternet(
                            onTap: () {
                              setState(() {
                                internetTrue();
                                _loadNotifications();
                              });
                            },
                          ),
                        )
                      : Container(),

                  // Loader
                  (_isLoading == true)
                      ? const Positioned(top: 0, child: Loading())
                      : Container(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

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
  final TextEditingController _searchController = TextEditingController();
  List<notification_model.DriverNotification> _filteredNotifications = [];

  // Cor roxa do tema
  static const Color _purpleColor = Color(0xFF7B2CBF);
  static const Color _lightPurple = Color(0xFFE8D5F2);

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _searchController.addListener(_filterNotifications);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterNotifications() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredNotifications = _notifications;
      } else {
        _filteredNotifications = _notifications.where((notification) {
          return notification.title.toLowerCase().contains(query) ||
              notification.body.toLowerCase().contains(query);
        }).toList();
      }
    });
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
            _filteredNotifications = response.notifications;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _notifications = [];
            _filteredNotifications = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar notificações: $e');
      if (mounted) {
        setState(() {
          _notifications = [];
          _filteredNotifications = [];
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
    return Material(
      child: ValueListenableBuilder(
        valueListenable: valueNotifierHome.value,
        builder: (context, value, child) {
          return Directionality(
            textDirection: (languageDirection == 'rtl')
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: Stack(
              children: [
                Column(
                  children: [
                    // AppBar roxa
                    Container(
                      color: _purpleColor,
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top,
                      ),
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            Text(
                              'Notificações',
                              style: GoogleFonts.notoSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            InkWell(
                              onTap: () {},
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Conteúdo
                    Expanded(
                      child: Container(
                        color: page,
                        child: Column(
                          children: [
                            // Campo de busca
                            Container(
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: borderLines,
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Pesquise por notificação',
                                  hintStyle: GoogleFonts.notoSans(
                                    fontSize: 14,
                                    color: hintColor,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: hintColor,
                                    size: 20,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),

                            // Lista de notificações
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _loadNotifications,
                                color: _purpleColor,
                                child: _filteredNotifications.isEmpty && !_isLoading
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
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        itemCount: _filteredNotifications.length,
                                        itemBuilder: (context, index) {
                                          final notification = _filteredNotifications[index];
                                          return InkWell(
                                            onTap: () {
                                              setState(() {
                                                showinfovalue = index;
                                                showinfo = true;
                                              });
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.only(bottom: 12),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: borderLines,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Ícone de envelope
                                                  Container(
                                                    height: 44,
                                                    width: 44,
                                                    decoration: BoxDecoration(
                                                      color: _lightPurple,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.mail_outline,
                                                      color: _purpleColor,
                                                      size: 22,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  // Título e descrição
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          notification.title,
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 1,
                                                          style: GoogleFonts.notoSans(
                                                            fontSize: 14,
                                                            color: textColor,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          notification.body,
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 2,
                                                          style: GoogleFonts.notoSans(
                                                            fontSize: 12,
                                                            color: hintColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Horário
                                                  Text(
                                                    notification.formattedTime,
                                                    style: GoogleFonts.notoSans(
                                                      fontSize: 12,
                                                      color: hintColor,
                                                      fontWeight: FontWeight.w500,
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
                    ),
                  ],
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
                                  text: _filteredNotifications[showinfovalue!].title,
                                  size: media.width * sixteen,
                                  fontweight: FontWeight.w600,
                                  maxLines: null,
                                ),
                                SizedBox(height: media.width * 0.05),
                                // Corpo
                                MyText(
                                  text: _filteredNotifications[showinfovalue!].body,
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
                                      text: _filteredNotifications[showinfovalue!].formattedDate,
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
    );
  }
}

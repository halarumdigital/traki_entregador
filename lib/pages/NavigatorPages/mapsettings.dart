import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_driver/functions/functions.dart';
import 'package:flutter_driver/styles/styles.dart';
import 'package:flutter_driver/translation/translation.dart';
import 'package:flutter_driver/widgets/widgets.dart';

class MapSettingsPage extends StatefulWidget {
  const MapSettingsPage({super.key});

  @override
  State<MapSettingsPage> createState() => _MapSettingsPageState();
}

class _MapSettingsPageState extends State<MapSettingsPage> {
  @override
  void initState() {
    mapType;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return SafeArea(
      child: Material(
        child: Directionality(
            textDirection: (languageDirection == 'rtl')
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: Scaffold(
              body: Container(
                color: page,
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top),
                    Container(
                      padding: EdgeInsets.only(
                        left: media.width * 0.05,
                        right: media.width * 0.05,
                      ),
                      color: page,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                              onTap: () {
                                Navigator.pop(context, false);
                              },
                              child:
                                  Icon(Icons.arrow_back_ios, color: textColor)),
                          Expanded(
                            child: MyText(
                              textAlign: TextAlign.center,
                              text: languages[choosenLanguage]
                                  ['text_map_settings'],
                              size: media.width * twenty,
                              maxLines: 1,
                              fontweight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: media.width * 1.7,
                      width: media.width,
                      color: page,
                      child: ListView(
                        children: [
                          CarouselSlider(
                            items: [
                              //1st Image of Slider
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    mapType = 'google';
                                    valueNotifierHome.incrementNotifier();
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.all(6.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    image: const DecorationImage(
                                      image: AssetImage(
                                          'assets/images/googlemap.jpeg'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: Container(
                                      alignment: Alignment.bottomCenter,
                                      width: media.width * 0.8,
                                      child: Container(
                                        width: media.width * 0.8,
                                        padding:
                                            EdgeInsets.all(media.width * 0.025),
                                        color: (mapType == 'google')
                                            ? theme
                                            // ignore: deprecated_member_use
                                            : Colors.black.withOpacity(0.5),
                                        child: MyText(
                                          textAlign: TextAlign.center,
                                          text: 'Google Map',
                                          size: media.width * fourteen,
                                          color: topBar,
                                        ),
                                      )),
                                ),
                              ),
      
                              //2nd Image of Slider
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    mapType = '';
                                    valueNotifierHome.incrementNotifier();
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.all(6.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    image: const DecorationImage(
                                      image: AssetImage(
                                          'assets/images/fluttermap.jpg'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: Container(
                                      alignment: Alignment.bottomCenter,
                                      width: media.width * 0.8,
                                      child: Container(
                                        width: media.width * 0.8,
                                        padding:
                                            EdgeInsets.all(media.width * 0.025),
                                        color: (mapType == '')
                                            ? theme
                                            // ignore: deprecated_member_use
                                            : Colors.black.withOpacity(0.5),
                                        child: MyText(
                                          textAlign: TextAlign.center,
                                          text: 'Open Street',
                                          size: media.width * fourteen,
                                          color: topBar,
                                        ),
                                      )),
                                ),
                              ),
                            ],
      
                            //Slider Container properties
                            options: CarouselOptions(
                              height: media.width * 1.5,
                              enlargeCenterPage: true,
                              autoPlay: false,
                              aspectRatio: 16 / 9,
                              // autoPlayCurve: Curves.fastOutSlowIn,
                              enableInfiniteScroll: false,
                              autoPlayAnimationDuration:
                                  const Duration(milliseconds: 800),
                              viewportFraction: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ),
    );
  }
}

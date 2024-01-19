// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/large_widget/custom_card_widget.dart';
import 'package:user_app/screens/features_screen.dart';
import 'package:user_app/small_widgets/custom_text_widgets/custom_text_widget.dart';
import 'package:user_app/transitions_animations/custom_page_transition.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.token});
  final token;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    print(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 0, left: 20, right: 20, bottom: 20),
        // padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monday',
                      style: GoogleFonts.abhayaLibre(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xff7F7F7F),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    const CustomTextWidget(
                      text: '25 October',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff040415),
                    ),
                  ],
                ),
                CircleAvatar(
                  maxRadius: 30,
                  backgroundColor: Colors.transparent,
                  child: Image.asset('assets/logos/circularIndianFlag.png'),
                ),
              ],
            ),
            const SizedBox(
              height: 31,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomTextWidget(
                  text: 'Hi Pruthviraj.',
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
                const SizedBox(
                  height: 18,
                ),
                Text(
                  'Be prepared and Stay Protected!',
                  style: GoogleFonts.archivo(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xff8D8D8D),
                  ),
                ),
                // code here for card view
                const SizedBox(
                  height: 18,
                ),
                Container(
                  width: double.infinity,
                  height: 100,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      // stops: [0.1, 0.8],
                      colors: [
                        Color.fromARGB(255, 120, 103, 232),
                        Color(0xff5451D6),
                      ],
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(16),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CustomTextWidget(
                              text: 'Life Guardian',
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            const Flexible(
                              child: CustomTextWidget(
                                text:
                                    'Disaster Safety, all in one app. Stay prepared, stay safe.',
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              height: 30,
                              width: 100,
                              child: Stack(
                                children: [
                                  Image.asset('assets/logos/ellipse1.png'),
                                  Positioned(
                                    left: 15,
                                    child: Image.asset(
                                        'assets/logos/ellipse2.png'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child:
                              Image.asset('assets/images/disasterImage2.jpg'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 31,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomTextWidget(
                  text: 'Salient Features',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff040415),
                ),
                const SizedBox(
                  height: 21,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                CustomSlideTransition(
                                  direction: AxisDirection.left,
                                  child: FeaturesScreen(
                                      screenType: 'ProgramEvents',
                                      token: widget.token),
                                ),
                              );
                            },
                            child: const CustomCardWidget(
                              width: 170,
                              height: 170,
                              color1: Color(0xffA9FFEA),
                              color2: Color(0xff00B288),
                              title: 'Programs & Events',
                              desc: 'Nearby',
                            ),
                          ),
                          const SizedBox(
                            height: 11,
                          ),
                          const CustomCardWidget(
                            width: 170,
                            height: 120,
                            color1: Color(0xffFFA0BC),
                            color2: Color(0xffFF1B5E),
                            title: 'Agencies',
                            desc: 'Nearby rescue ops',
                          ),
                        ],
                      ),
                    ),
                    // Spacer(flex: 1),
                    Expanded(
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                CustomSlideTransition(
                                  direction: AxisDirection.left,
                                  child: FeaturesScreen(
                                      token: widget.token,
                                      screenType: 'Alerts'),
                                ),
                              );
                            },
                            child: const CustomCardWidget(
                              width: 170,
                              height: 120,
                              color1: Color(0xffFFD29D),
                              color2: Color(0xffFF9E2D),
                              title: 'Alerts',
                              desc: 'Active',
                            ),
                          ),
                          const SizedBox(
                            height: 11,
                          ),
                          const CustomCardWidget(
                            width: 170,
                            height: 170,
                            color1: Color(0xffB1EEFF),
                            color2: Color(0xff29BAE2),
                            title: 'Search',
                            desc: 'Agency details',
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
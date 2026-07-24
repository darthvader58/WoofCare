import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '/config/constants.dart';
import '/services/auth.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    if (AUTH.currentUser != null) {
      Auth.launch(
        context,
        () => Timer(
          const Duration(milliseconds: 150),
          () => Navigator.pushReplacementNamed(context, "/home"),
        ),
      );
    } else {
      Timer(
        const Duration(milliseconds: 150),
        () => Navigator.pushReplacementNamed(context, "/login"),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              // Container for the first background image
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/patterns/BigPawPattern.png"),
                  alignment: Alignment.topLeft,
                ),
              ),
            ),
            Container(
              // Container for the second background image
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    "assets/images/patterns/SmallPawPattern.png",
                  ),
                  alignment: Alignment.bottomRight,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(height: 20),
                  SizedBox(
                    width: 168,
                    height: 168,
                    child: SvgPicture.asset(
                      'assets/images/branding/logo.svg',
                      semanticsLabel: 'WoofCare logo',
                    ),
                  ),
                  Text(
                    "Launching App.\nPlease Wait",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:woofcare/config/colors.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: WoofCareColors.primaryBackground),
        Positioned.fill(
          child: Opacity(
            opacity: 0.28,
            child: Image.asset(
              "assets/images/patterns/BigPawPattern.png",
              repeat: ImageRepeat.repeat,
              scale: 0.5,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

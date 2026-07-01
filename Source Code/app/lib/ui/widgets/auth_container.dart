import 'package:flutter/material.dart';
import 'package:woofcare/config/colors.dart';

class AuthContainer extends StatelessWidget {
  final Widget child;

  const AuthContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: WoofCareColors.secondaryBackground,
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            blurStyle: BlurStyle.normal,
            color: WoofCareColors.cardShadow,
            offset: const Offset(0, 14),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
        child: child,
      ),
    );
  }
}

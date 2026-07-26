import 'package:flutter/material.dart';
import 'package:woofcare/config/colors.dart';
import 'package:woofcare/ui/widgets/web_design_system.dart';

class AuthContainer extends StatelessWidget {
  final Widget child;

  const AuthContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (WoofCareWebDesign.enabled) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 480),
        margin: const EdgeInsets.symmetric(vertical: 32),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 42),
        decoration: BoxDecoration(
          color: WoofCareWebDesign.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WoofCareWebDesign.border),
          boxShadow: WoofCareWebDesign.elevatedShadow,
        ),
        child: child,
      );
    }

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

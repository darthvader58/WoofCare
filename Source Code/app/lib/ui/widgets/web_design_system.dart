import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:woofcare/config/colors.dart';

/// Web-only layout tokens built from WoofCare's existing mobile brand palette.
/// Android and iOS continue to use [WoofCareColors] directly.
abstract final class WoofCareWebDesign {
  static bool get enabled => kIsWeb;

  static const Color canvas = WoofCareColors.postBackground;
  static const Color surface = WoofCareColors.offWhite;
  static const Color surfaceMuted = WoofCareColors.secondaryBackground;
  static const Color sidebar = WoofCareColors.primaryTextAndIcons;
  static const Color sidebarRaised = WoofCareColors.interactibleTextPressed;
  static const Color primary = WoofCareColors.buttonColor;
  static const Color primaryDark = WoofCareColors.interactibleTextPressed;
  static const Color accent = WoofCareColors.floatingActionIcons;
  static const Color text = WoofCareColors.primaryTextAndIcons;
  static const Color textMuted = WoofCareColors.mutedText;
  static const Color border = WoofCareColors.textBoxColor;
  static const Color borderStrong = WoofCareColors.backgroundElementColor;
  static const Color danger = WoofCareColors.errorMessageColor;
  static const Color onPrimary = WoofCareColors.offWhite;

  static const double pageMaxWidth = 1240;
  static const double compactRadius = 10;
  static const double cardRadius = 12;

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: text.withValues(alpha: 0.055),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: text.withValues(alpha: 0.11),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];
}

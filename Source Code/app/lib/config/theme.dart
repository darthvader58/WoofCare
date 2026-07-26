// ignore_for_file: avoid_classes_with_only_static_members

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:woofcare/ui/widgets/web_design_system.dart';

import '/config/colors.dart';

class WoofCareTheme {
  static ThemeData of(BuildContext context) {
    if (kIsWeb) return _webTheme();

    return ThemeData(
      primaryColor: WoofCareColors.primaryBackground,
      scaffoldBackgroundColor: WoofCareColors.primaryBackground,
      highlightColor: WoofCareColors.buttonColor,
      dividerColor: WoofCareColors.inputBackground,
      focusColor: WoofCareColors.focusColor,
      visualDensity: VisualDensity.standard,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        surface: WoofCareColors.secondaryBackground,
        onSurface: WoofCareColors.primaryTextAndIcons,
        primary: WoofCareColors.buttonColor,
        onPrimary: Colors.white,
        secondary: WoofCareColors.buttonColor,
        onSecondary: Colors.white,
        error: WoofCareColors.errorMessageColor,
        onError: Colors.white,
      ),
      textTheme: ThemeData.light().textTheme
          .copyWith(
            bodyMedium: GoogleFonts.aBeeZee(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
            bodyLarge: GoogleFonts.aBeeZee(
              fontSize: 40,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.4,
            ),
            labelLarge: GoogleFonts.aBeeZee(
              fontWeight: FontWeight.w700,
              letterSpacing: 2.8,
            ),
            headlineSmall: GoogleFonts.aBeeZee(
              fontSize: 40,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          )
          .apply(
            displayColor: WoofCareColors.primaryTextAndIcons,
            bodyColor: WoofCareColors.primaryTextAndIcons,
          ),
      appBarTheme: AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: WoofCareColors.secondaryBackground,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: WoofCareColors.primaryTextAndIcons,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          fontFamily: GoogleFonts.aBeeZee().fontFamily,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(10),
        thumbColor: WidgetStateProperty.all(WoofCareColors.buttonColor),
        thickness: WidgetStateProperty.all(2),
        interactive: true,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(
          color: WoofCareColors.mutedText,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: WoofCareColors.textBoxColor,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: WoofCareColors.buttonColor, width: 1.4),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        elevation: 10,
        backgroundColor: WoofCareColors.buttonColor,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        backgroundColor: Color(0xFFF7FFF7),
        modalBackgroundColor: Color(0xFFF7FFF7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(25),
            topLeft: Radius.circular(25),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: WoofCareColors.buttonColor,
        foregroundColor: WoofCareColors.primaryBackground,
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStateProperty.all<TextStyle>(
            const TextStyle(color: WoofCareColors.white60),
          ),
          foregroundColor: WidgetStateProperty.all<Color>(
            WoofCareColors.buttonColor,
          ),
        ),
      ),
    );
  }

  static ThemeData _webTheme() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      displayColor: WoofCareWebDesign.text,
      bodyColor: WoofCareWebDesign.text,
    );

    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: WoofCareWebDesign.primary,
        onPrimary: WoofCareWebDesign.onPrimary,
        secondary: WoofCareWebDesign.accent,
        onSecondary: WoofCareWebDesign.onPrimary,
        surface: WoofCareWebDesign.surface,
        onSurface: WoofCareWebDesign.text,
        error: WoofCareWebDesign.danger,
        onError: WoofCareWebDesign.onPrimary,
        outline: WoofCareWebDesign.borderStrong,
      ),
      scaffoldBackgroundColor: WoofCareWebDesign.canvas,
      canvasColor: WoofCareWebDesign.canvas,
      dividerColor: WoofCareWebDesign.border,
      focusColor: WoofCareWebDesign.primary.withValues(alpha: 0.12),
      highlightColor: WoofCareWebDesign.primary.withValues(alpha: 0.06),
      hoverColor: WoofCareWebDesign.primary.withValues(alpha: 0.045),
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontSize: 30,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontSize: 24,
          height: 1.25,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.35,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.15,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          fontSize: 15,
          height: 1.5,
          letterSpacing: 0,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          height: 1.45,
          letterSpacing: 0,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      appBarTheme: AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: WoofCareWebDesign.surface,
        foregroundColor: WoofCareWebDesign.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 68,
        titleTextStyle: GoogleFonts.inter(
          color: WoofCareWebDesign.text,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: const CardThemeData(
        color: WoofCareWebDesign.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: WoofCareWebDesign.border),
          borderRadius: BorderRadius.all(
            Radius.circular(WoofCareWebDesign.cardRadius),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: WoofCareWebDesign.surface,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(color: WoofCareWebDesign.textMuted, fontSize: 14),
        labelStyle: TextStyle(color: WoofCareWebDesign.textMuted, fontSize: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: WoofCareWebDesign.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: WoofCareWebDesign.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: WoofCareWebDesign.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: WoofCareWebDesign.danger, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: WoofCareWebDesign.primary,
          foregroundColor: WoofCareWebDesign.onPrimary,
          disabledBackgroundColor: WoofCareWebDesign.border,
          disabledForegroundColor: WoofCareWebDesign.textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: WoofCareWebDesign.primary,
          foregroundColor: WoofCareWebDesign.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: WoofCareWebDesign.text,
          side: const BorderSide(color: WoofCareWebDesign.borderStrong),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: WoofCareWebDesign.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: WoofCareWebDesign.borderStrong),
      ),
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(999),
        thumbColor: WidgetStateProperty.all(
          WoofCareWebDesign.textMuted.withValues(alpha: 0.45),
        ),
        thickness: WidgetStateProperty.all(6),
        interactive: true,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: WoofCareWebDesign.sidebar,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: GoogleFonts.inter(
          color: WoofCareWebDesign.onPrimary,
          fontSize: 12,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: WoofCareWebDesign.sidebar,
        contentTextStyle: GoogleFonts.inter(
          color: WoofCareWebDesign.onPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        backgroundColor: WoofCareWebDesign.surface,
        modalBackgroundColor: WoofCareWebDesign.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: WoofCareWebDesign.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
    );
  }
}

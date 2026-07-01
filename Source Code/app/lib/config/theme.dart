// ignore_for_file: avoid_classes_with_only_static_members

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '/config/colors.dart';

class WoofCareTheme {
  static ThemeData of(BuildContext context) {
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
}

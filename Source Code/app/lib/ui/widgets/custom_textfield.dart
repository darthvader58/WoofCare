import 'package:flutter/material.dart';
import 'package:woofcare/config/colors.dart';
import 'package:woofcare/ui/widgets/web_design_system.dart';

import '/config/constants.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final bool autofocus;
  final void Function()? onTap;
  final TextInputType? keyboardType;
  final IconData? suffix;
  final IconData? prefix;
  final double horizontalPadding;
  final int maxLines;
  final int minLines;
  final double top;
  final double bottom;

  final void Function()? onSuffixTap;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.autofocus = false,
    this.onTap,
    this.keyboardType,
    this.suffix,
    this.prefix,
    this.onSuffixTap,
    this.horizontalPadding = 12,
    this.maxLines = 1,
    this.minLines = 1,
    this.top = 0,
    this.bottom = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (WoofCareWebDesign.enabled) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          autofocus: autofocus,
          obscureText: obscureText,
          onTap: onTap,
          maxLines: maxLines,
          minLines: minLines,
          style: const TextStyle(
            color: WoofCareWebDesign.text,
            fontSize: 14,
            height: 1.3,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefix == null
                ? null
                : Icon(prefix, color: WoofCareWebDesign.textMuted, size: 19),
            suffixIcon: suffix == null
                ? null
                : onSuffixTap == null
                ? Icon(suffix, color: WoofCareWebDesign.textMuted, size: 19)
                : IconButton(
                    onPressed: onSuffixTap,
                    icon: Icon(
                      suffix,
                      color: WoofCareWebDesign.textMuted,
                      size: 19,
                    ),
                  ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        autofocus: autofocus,
        obscureText: obscureText,
        style: theme.textTheme.bodyMedium!.copyWith(
          color: WoofCareColors.primaryTextAndIcons,
          fontSize: 15,
          height: 1.25,
        ),
        onTap: onTap,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide(
              color: WoofCareColors.primaryTextAndIcons.withValues(alpha: 0.18),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide(
              color: WoofCareColors.primaryTextAndIcons.withValues(alpha: 0.12),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: const BorderSide(
              color: WoofCareColors.buttonColor,
              width: 1.5,
            ),
          ),
          fillColor: WoofCareColors.offWhite.withValues(alpha: 0.78),
          filled: true,

          //make it so no icon space is taken if no icon is provided
          suffixIcon: suffix != null
              ? (onSuffixTap != null
                    ? IconButton(
                        icon: Icon(
                          suffix,
                          color: WoofCareColors.primaryTextAndIcons,
                        ),
                        onPressed: onSuffixTap,
                      )
                    : Icon(suffix, color: WoofCareColors.primaryTextAndIcons))
              : null,
          prefixIcon: prefix != null
              ? Icon(prefix, color: WoofCareColors.primaryTextAndIcons)
              : null,

          //hint style
          hintText: hintText,
          hintStyle: TextStyle(
            color: WoofCareColors.primaryTextAndIcons.withValues(alpha: 0.55),
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
        ),
        maxLines: maxLines,
        minLines: minLines,
      ),
    );
  }
}

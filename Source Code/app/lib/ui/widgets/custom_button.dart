import 'package:flutter/material.dart';
import 'package:woofcare/config/colors.dart';
import 'package:woofcare/ui/widgets/web_design_system.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final Function()? onTap;
  final double? height;
  final double? width;
  final Color? color;
  final double? fontSize;
  final Color? fontColor;
  // final double padding;
  final double margin;
  final double borderRadius;
  final double verticalPadding;
  final double horizontalPadding;
  final FontWeight? fontWeight;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onTap,
    this.width,
    this.height,
    this.color = const Color(0xFFA66E38),
    this.fontSize = 18,
    this.fontColor = const Color(0xFFF7FFF7),
    this.margin = 20,
    this.borderRadius = 8,
    this.horizontalPadding = 20,
    this.verticalPadding = 20,
    this.fontWeight = FontWeight.bold,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (WoofCareWebDesign.enabled) {
      final enabled = onTap != null;
      final resolvedColor = color == const Color(0xFFA66E38)
          ? WoofCareWebDesign.primary
          : color;
      final resolvedTextColor = fontColor == const Color(0xFFF7FFF7)
          ? WoofCareWebDesign.onPrimary
          : fontColor;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: margin),
        child: SizedBox(
          width: width ?? double.infinity,
          height: height ?? 46,
          child: ElevatedButton.icon(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: resolvedColor,
              foregroundColor: resolvedTextColor,
              disabledBackgroundColor: WoofCareWebDesign.border,
              disabledForegroundColor: WoofCareWebDesign.textMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
            label: Text(
              text,
              style: TextStyle(
                fontSize: fontSize == 18 ? 14 : fontSize,
                color: enabled ? resolvedTextColor : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      margin: EdgeInsets.symmetric(horizontal: margin),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: WoofCareColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: (fontSize ?? 18) + 2, color: fontColor),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: fontSize,
                        color: fontColor,
                        fontWeight: fontWeight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

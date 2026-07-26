import 'package:flutter/material.dart';
import 'package:woofcare/config/colors.dart';
import 'package:woofcare/ui/widgets/web_design_system.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (WoofCareWebDesign.enabled) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 960) {
            return ColoredBox(
              color: WoofCareWebDesign.canvas,
              child: Stack(
                children: [
                  const Positioned(
                    top: 24,
                    left: 28,
                    child: _CompactWebBrand(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 64),
                    child: child,
                  ),
                ],
              ),
            );
          }

          return Row(
            children: [
              const Expanded(flex: 5, child: _WebBrandPanel()),
              Expanded(
                flex: 6,
                child: ColoredBox(
                  color: WoofCareWebDesign.canvas,
                  child: child,
                ),
              ),
            ],
          );
        },
      );
    }

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

class _CompactWebBrand extends StatelessWidget {
  const _CompactWebBrand();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WebBrandMark(size: 34),
        SizedBox(width: 10),
        Text(
          'WoofCare',
          style: TextStyle(
            color: WoofCareWebDesign.text,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _WebBrandPanel extends StatelessWidget {
  const _WebBrandPanel();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: WoofCareWebDesign.sidebar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                _WebBrandMark(size: 42),
                SizedBox(width: 12),
                Text(
                  'WoofCare',
                  style: TextStyle(
                    color: WoofCareWebDesign.onPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coordinate care.\nImprove outcomes.',
                    style: TextStyle(
                      color: WoofCareWebDesign.onPrimary,
                      fontSize: 40,
                      height: 1.13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.1,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'A shared workspace for reporting, rescue coordination, '
                    'community updates, and trusted care resources.',
                    style: TextStyle(
                      color: WoofCareColors.textBoxColor,
                      fontSize: 16,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: WoofCareColors.backgroundElementColor,
                  size: 18,
                ),
                SizedBox(width: 9),
                Text(
                  'Secure community care coordination',
                  style: TextStyle(
                    color: WoofCareColors.backgroundElementColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WebBrandMark extends StatelessWidget {
  final double size;

  const _WebBrandMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: WoofCareWebDesign.primary,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(
        Icons.pets_outlined,
        color: WoofCareWebDesign.onPrimary,
        size: size * 0.52,
      ),
    );
  }
}

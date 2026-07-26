import 'package:flutter/material.dart';

/// Shared layout breakpoints for WoofCare's phone, tablet, and web shells.
abstract final class WoofCareBreakpoints {
  static const double compact = 700;
  static const double navigationRail = 900;
  static const double wide = 1200;
}

/// Centers page content on large displays without changing the phone layout.
class WoofCareContentSurface extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  const WoofCareContentSurface({
    super.key,
    required this.child,
    this.maxWidth = 1040,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

/// Constrains bottom-sheet content on desktop while remaining edge-to-edge on
/// phones. The caller still controls the sheet's height and scrolling.
class WoofCareSheetSurface extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const WoofCareSheetSurface({
    super.key,
    required this.child,
    this.maxWidth = 720,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: MediaQuery.sizeOf(context).height,
        ),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

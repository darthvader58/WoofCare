import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:woofcare/config/colors.dart';

class WoofCareNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onReportTap;

  const WoofCareNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onReportTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: WoofCareColors.offWhite,
          border: Border(
            top: BorderSide(
              color: WoofCareColors.primaryTextAndIcons.withValues(alpha: 0.2),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavIcon(
              icon: FontAwesomeIcons.locationDot,
              selected: currentIndex == 0,
              tooltip: 'Map',
              onTap: () => onTabSelected(0),
            ),
            _NavIcon(
              icon: FontAwesomeIcons.solidComments,
              selected: currentIndex == 1,
              tooltip: 'Messages',
              onTap: () => onTabSelected(1),
            ),
            _ReportAction(onTap: onReportTap),
            _NavIcon(
              icon: FontAwesomeIcons.userGroup,
              selected: currentIndex == 2,
              tooltip: 'Community',
              onTap: () => onTabSelected(2),
            ),
            _NavIcon(
              icon: FontAwesomeIcons.bookOpen,
              selected: currentIndex == 3,
              tooltip: 'Articles',
              onTap: () => onTabSelected(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportAction extends StatelessWidget {
  final VoidCallback onTap;

  const _ReportAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Report',
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: WoofCareColors.buttonColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: WoofCareColors.buttonColor.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: FaIcon(
              FontAwesomeIcons.plus,
              color: WoofCareColors.offWhite,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected
            ? WoofCareColors.buttonColor
            : WoofCareColors.primaryTextAndIcons;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        iconSize: 30,
        color: color,
        splashRadius: 30,
        onPressed: onTap,
        icon: FaIcon(icon),
      ),
    );
  }
}

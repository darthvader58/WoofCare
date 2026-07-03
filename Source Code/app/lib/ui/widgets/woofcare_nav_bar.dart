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
              outlineIcon: Icons.location_on_outlined,
              filledIcon: Icons.location_on_rounded,
              selected: currentIndex == 0,
              tooltip: 'Map',
              onTap: () => onTabSelected(0),
            ),
            _NavIcon(
              outlineIcon: Icons.chat_bubble_outline_rounded,
              filledIcon: Icons.chat_bubble_rounded,
              selected: currentIndex == 1,
              tooltip: 'Messages',
              onTap: () => onTabSelected(1),
            ),
            _ReportAction(onTap: onReportTap),
            _NavIcon(
              outlineIcon: Icons.groups_outlined,
              filledIcon: Icons.groups_rounded,
              selected: currentIndex == 2,
              tooltip: 'Community',
              onTap: () => onTabSelected(2),
            ),
            _NavIcon(
              outlineIcon: Icons.menu_book_outlined,
              filledIcon: Icons.menu_book_rounded,
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
  final IconData outlineIcon;
  final IconData filledIcon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  const _NavIcon({
    required this.outlineIcon,
    required this.filledIcon,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Unselected tabs render as a light dark-brown stroke; the active tab
    // fills in solid, mirroring that screen's own header icon on arrival.
    final color =
        selected
            ? WoofCareColors.buttonColor
            : WoofCareColors.primaryTextAndIcons.withValues(alpha: 0.58);

    return Tooltip(
      message: tooltip,
      child: IconButton(
        iconSize: 31,
        splashRadius: 30,
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor:
              selected
                  ? WoofCareColors.buttonColor.withValues(alpha: 0.12)
                  : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder:
              (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
          child: Icon(
            selected ? filledIcon : outlineIcon,
            key: ValueKey<bool>(selected),
            color: color,
          ),
        ),
      ),
    );
  }
}

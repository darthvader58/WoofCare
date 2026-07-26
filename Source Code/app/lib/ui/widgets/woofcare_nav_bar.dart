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

/// Desktop/tablet counterpart to [WoofCareNavBar].
///
/// It keeps the same four destinations and central report action, but exposes
/// larger pointer targets and optional labels when enough width is available.
class WoofCareNavigationRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onReportTap;
  final bool extended;

  const WoofCareNavigationRail({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onReportTap,
    required this.extended,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      right: false,
      child: Container(
        width: extended ? 232 : 88,
        decoration: BoxDecoration(
          color: WoofCareColors.offWhite,
          border: Border(
            right: BorderSide(
              color: WoofCareColors.primaryTextAndIcons.withValues(alpha: 0.1),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(5, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(extended ? 22 : 16, 22, 16, 18),
              child: Row(
                mainAxisAlignment: extended
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: WoofCareColors.buttonColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      color: WoofCareColors.offWhite,
                      size: 25,
                    ),
                  ),
                  if (extended) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'WoofCare',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: WoofCareColors.primaryTextAndIcons,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 14),
            _RailDestination(
              icon: Icons.location_on_outlined,
              selectedIcon: Icons.location_on_rounded,
              label: 'Map',
              selected: currentIndex == 0,
              extended: extended,
              onTap: () => onTabSelected(0),
            ),
            _RailDestination(
              icon: Icons.chat_bubble_outline_rounded,
              selectedIcon: Icons.chat_bubble_rounded,
              label: 'Messages',
              selected: currentIndex == 1,
              extended: extended,
              onTap: () => onTabSelected(1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Tooltip(
                message: 'Report a dog',
                child: Material(
                  color: WoofCareColors.buttonColor,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onReportTap,
                    child: SizedBox(
                      height: 54,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.plus,
                            color: WoofCareColors.offWhite,
                            size: 22,
                          ),
                          if (extended) ...[
                            const SizedBox(width: 13),
                            const Text(
                              'Report a dog',
                              style: TextStyle(
                                color: WoofCareColors.offWhite,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _RailDestination(
              icon: Icons.groups_outlined,
              selectedIcon: Icons.groups_rounded,
              label: 'Community',
              selected: currentIndex == 2,
              extended: extended,
              onTap: () => onTabSelected(2),
            ),
            _RailDestination(
              icon: Icons.menu_book_outlined,
              selectedIcon: Icons.menu_book_rounded,
              label: 'Articles',
              selected: currentIndex == 3,
              extended: extended,
              onTap: () => onTabSelected(3),
            ),
            const Spacer(),
            if (extended)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Helping every dog find care.',
                  style: TextStyle(
                    color: WoofCareColors.mutedText.withValues(alpha: 0.75),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RailDestination extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  const _RailDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? WoofCareColors.buttonColor
        : WoofCareColors.primaryTextAndIcons.withValues(alpha: 0.68);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Tooltip(
        message: label,
        child: Material(
          color: selected
              ? WoofCareColors.buttonColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: onTap,
            child: SizedBox(
              height: 52,
              child: Row(
                mainAxisAlignment: extended
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  if (extended) const SizedBox(width: 16),
                  Icon(selected ? selectedIcon : icon, color: foreground),
                  if (extended) ...[
                    const SizedBox(width: 16),
                    Text(
                      label,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
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
    final color = selected
        ? WoofCareColors.buttonColor
        : WoofCareColors.primaryTextAndIcons.withValues(alpha: 0.58);

    return Tooltip(
      message: tooltip,
      child: IconButton(
        iconSize: 31,
        splashRadius: 30,
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: selected
              ? WoofCareColors.buttonColor.withValues(alpha: 0.12)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) =>
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

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:woofcare/config/colors.dart';
import 'package:woofcare/ui/widgets/web_design_system.dart';

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
    final web = WoofCareWebDesign.enabled;

    return SafeArea(
      top: false,
      child: Container(
        height: web ? 72 : 96,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: web ? WoofCareWebDesign.surface : WoofCareColors.offWhite,
          border: Border(
            top: BorderSide(
              color: web
                  ? WoofCareWebDesign.border
                  : WoofCareColors.primaryTextAndIcons.withValues(alpha: 0.2),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: WoofCareColors.primaryTextAndIcons.withValues(
                alpha: web ? 0.08 : 0.16,
              ),
              blurRadius: web ? 12 : 18,
              offset: Offset(0, web ? -2 : -4),
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
    final web = WoofCareWebDesign.enabled;

    return SafeArea(
      right: false,
      child: Container(
        width: web ? (extended ? 252 : 76) : (extended ? 232 : 88),
        decoration: BoxDecoration(
          color: web ? WoofCareWebDesign.sidebar : WoofCareColors.offWhite,
          border: Border(
            right: BorderSide(
              color: web
                  ? Colors.white.withValues(alpha: 0.08)
                  : WoofCareColors.primaryTextAndIcons.withValues(alpha: 0.1),
            ),
          ),
          boxShadow: web
              ? const []
              : [
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
              padding: EdgeInsets.fromLTRB(
                extended ? (web ? 20 : 22) : (web ? 14 : 16),
                web ? 24 : 22,
                web ? 16 : 16,
                web ? 22 : 18,
              ),
              child: Row(
                mainAxisAlignment: extended
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  if (web)
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: SvgPicture.asset(
                        'assets/images/branding/logo.svg',
                        semanticsLabel: 'WoofCare logo',
                      ),
                    )
                  else
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
                    Expanded(
                      child: Text(
                        'WoofCare',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: web
                              ? WoofCareWebDesign.onPrimary
                              : WoofCareColors.primaryTextAndIcons,
                          fontSize: web ? 18 : 21,
                          fontWeight: web ? FontWeight.w700 : FontWeight.w800,
                          letterSpacing: web ? -0.35 : 0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Divider(
              height: 1,
              color: web
                  ? Colors.white.withValues(alpha: 0.08)
                  : Theme.of(context).dividerColor,
            ),
            SizedBox(height: web ? 18 : 14),
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
              padding: EdgeInsets.symmetric(
                horizontal: web ? 12 : 12,
                vertical: web ? 12 : 8,
              ),
              child: Tooltip(
                message: 'Report a dog',
                child: Material(
                  color: web
                      ? WoofCareWebDesign.primary
                      : WoofCareColors.buttonColor,
                  borderRadius: BorderRadius.circular(web ? 8 : 16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(web ? 8 : 16),
                    onTap: onReportTap,
                    child: SizedBox(
                      height: web ? 44 : 54,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.plus,
                            color: web
                                ? WoofCareWebDesign.onPrimary
                                : WoofCareColors.offWhite,
                            size: web ? 15 : 22,
                          ),
                          if (extended) ...[
                            const SizedBox(width: 13),
                            Text(
                              'Report a dog',
                              style: TextStyle(
                                color: web
                                    ? WoofCareWebDesign.onPrimary
                                    : WoofCareColors.offWhite,
                                fontSize: web ? 13 : 14,
                                fontWeight: FontWeight.w600,
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
                  web
                      ? 'Community care operations'
                      : 'Helping every dog find care.',
                  style: TextStyle(
                    color: web
                        ? WoofCareColors.backgroundElementColor
                        : WoofCareColors.mutedText.withValues(alpha: 0.75),
                    fontSize: web ? 11 : 12,
                    height: 1.35,
                    fontWeight: web ? FontWeight.w500 : FontWeight.normal,
                    letterSpacing: web ? 0.25 : 0,
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
    final web = WoofCareWebDesign.enabled;
    final foreground = web
        ? selected
              ? WoofCareWebDesign.onPrimary
              : WoofCareColors.textBoxColor
        : selected
        ? WoofCareColors.buttonColor
        : WoofCareColors.primaryTextAndIcons.withValues(alpha: 0.68);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: web ? 10 : 12,
        vertical: web ? 3 : 4,
      ),
      child: Tooltip(
        message: label,
        child: Material(
          color: selected
              ? web
                    ? Colors.white.withValues(alpha: 0.1)
                    : WoofCareColors.buttonColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(web ? 8 : 15),
          child: InkWell(
            borderRadius: BorderRadius.circular(web ? 8 : 15),
            onTap: onTap,
            child: SizedBox(
              height: web ? 44 : 52,
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
                        fontSize: web ? 13 : 14,
                        fontWeight: selected
                            ? (web ? FontWeight.w600 : FontWeight.w800)
                            : web
                            ? FontWeight.w500
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

import 'package:flutter/material.dart';
import 'package:woofcare/config/colors.dart';

class WoofCareScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final TextEditingController? searchController;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final List<Widget> actions;
  final Widget? bottom;
  final double height;

  const WoofCareScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.searchController,
    this.searchHint,
    this.onSearchChanged,
    this.actions = const [],
    this.bottom,
    this.height = 176,
  });

  @override
  Widget build(BuildContext context) {
    final hasSearch = searchController != null && searchHint != null;

    return Container(
      constraints: BoxConstraints(minHeight: height),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: WoofCareColors.offWhite,
        border: Border(
          bottom: BorderSide(
            color: WoofCareColors.primaryTextAndIcons.withValues(alpha: 0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: WoofCareColors.floatingActionIcons.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: WoofCareColors.floatingActionIcons.withValues(
                        alpha: 0.12,
                      ),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: WoofCareColors.floatingActionIcons,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: WoofCareColors.primaryTextAndIcons,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: WoofCareColors.mutedText.withValues(
                            alpha: 0.86,
                          ),
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 10),
                Row(mainAxisSize: MainAxisSize.min, children: actions),
              ],
            ],
          ),
          if (hasSearch) ...[
            const SizedBox(height: 16),
            WoofCareSearchField(
              controller: searchController!,
              hintText: searchHint!,
              onChanged: onSearchChanged,
            ),
          ],
          if (bottom != null) ...[const SizedBox(height: 12), bottom!],
        ],
      ),
    );
  }
}

class WoofCareSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  const WoofCareSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          color: WoofCareColors.primaryTextAndIcons,
          fontSize: 14,
          height: 1.2,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: WoofCareColors.primaryTextAndIcons.withValues(alpha: 0.54),
            fontSize: 14,
          ),
          filled: true,
          fillColor: WoofCareColors.textBoxColor.withValues(alpha: 0.68),
          suffixIcon: const Icon(
            Icons.search,
            color: WoofCareColors.primaryTextAndIcons,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class WoofCareProfileAvatar extends StatelessWidget {
  final VoidCallback? onTap;

  const WoofCareProfileAvatar({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Profile',
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: WoofCareColors.offWhite,
            border: Border.all(
              color: WoofCareColors.floatingActionIcons,
              width: 1.5,
            ),
            image: const DecorationImage(
              image: AssetImage(
                "assets/images/homePageButtons/ProfileButton.png",
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

class WoofCareFilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const WoofCareFilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minWidth: 82),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              selected
                  ? WoofCareColors.buttonColor
                  : WoofCareColors.backgroundElementColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: WoofCareColors.buttonColor.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color:
                selected
                    ? WoofCareColors.offWhite
                    : WoofCareColors.primaryTextAndIcons,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class WoofCareEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const WoofCareEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: WoofCareColors.secondaryBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 42, color: WoofCareColors.buttonColor),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: WoofCareColors.primaryTextAndIcons,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: WoofCareColors.primaryTextAndIcons.withValues(
                  alpha: 0.66,
                ),
                fontSize: 14,
                height: 1.35,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

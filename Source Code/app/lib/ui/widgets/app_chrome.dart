import 'package:flutter/material.dart';
import 'package:woofcare/config/colors.dart';

class WoofCareScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
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
      height: height,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: WoofCareColors.offWhite,
        border: Border(
          bottom: BorderSide(
            color: WoofCareColors.primaryTextAndIcons.withValues(alpha: 0.18),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: WoofCareColors.mutedText.withValues(
                            alpha: 0.82,
                          ),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 12),
                Row(mainAxisSize: MainAxisSize.min, children: actions),
              ],
            ],
          ),
          if (hasSearch) ...[
            const SizedBox(height: 14),
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
      height: 44,
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
            color: WoofCareColors.primaryTextAndIcons.withValues(alpha: 0.58),
            fontSize: 14,
          ),
          filled: true,
          fillColor: WoofCareColors.textBoxColor.withValues(alpha: 0.88),
          suffixIcon: const Icon(
            Icons.search,
            color: WoofCareColors.primaryTextAndIcons,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
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
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 84,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              selected
                  ? WoofCareColors.buttonColor
                  : WoofCareColors.backgroundElementColor,
          borderRadius: BorderRadius.circular(16),
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

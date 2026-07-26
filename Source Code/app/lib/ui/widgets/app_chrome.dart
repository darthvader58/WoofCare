import 'package:flutter/material.dart';
import 'package:woofcare/config/colors.dart';
import 'package:woofcare/ui/widgets/responsive.dart';
import 'package:woofcare/ui/widgets/web_design_system.dart';

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

    if (WoofCareWebDesign.enabled) {
      final hasTools = hasSearch || bottom != null;

      return Container(
        decoration: const BoxDecoration(
          color: WoofCareWebDesign.surface,
          border: Border(bottom: BorderSide(color: WoofCareWebDesign.border)),
        ),
        child: WoofCareContentSurface(
          maxWidth: WoofCareWebDesign.pageMaxWidth,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 18 : 32,
                  vertical: compact ? 16 : 22,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (icon != null) ...[
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: WoofCareWebDesign.primary.withValues(
                                alpha: 0.09,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: WoofCareWebDesign.primary.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: WoofCareWebDesign.primary,
                              size: 20,
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
                                  color: WoofCareWebDesign.text,
                                  fontSize: 23,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.35,
                                ),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  subtitle!,
                                  maxLines: compact ? 2 : 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: WoofCareWebDesign.textMuted,
                                    fontSize: 13,
                                    height: 1.35,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (actions.isNotEmpty) ...[
                          SizedBox(width: compact ? 10 : 20),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: actions,
                          ),
                        ],
                      ],
                    ),
                    if (hasTools) ...[
                      SizedBox(height: compact ? 14 : 20),
                      if (compact)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (hasSearch)
                              WoofCareSearchField(
                                controller: searchController!,
                                hintText: searchHint!,
                                onChanged: onSearchChanged,
                              ),
                            if (hasSearch && bottom != null)
                              const SizedBox(height: 12),
                            if (bottom != null) bottom!,
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (hasSearch)
                              SizedBox(
                                width: 380,
                                child: WoofCareSearchField(
                                  controller: searchController!,
                                  hintText: searchHint!,
                                  onChanged: onSearchChanged,
                                ),
                              ),
                            if (hasSearch && bottom != null)
                              const SizedBox(width: 24),
                            if (bottom != null) Expanded(child: bottom!),
                          ],
                        ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(minHeight: height),
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
      child: WoofCareContentSurface(
        maxWidth: 1120,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
        ),
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
    if (WoofCareWebDesign.enabled) {
      return SizedBox(
        height: 42,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(
            color: WoofCareWebDesign.text,
            fontSize: 13,
            height: 1.3,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: WoofCareWebDesign.textMuted,
              fontSize: 13,
            ),
            filled: true,
            fillColor: WoofCareWebDesign.surfaceMuted,
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: WoofCareWebDesign.textMuted,
              size: 19,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: WoofCareWebDesign.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: WoofCareWebDesign.border),
            ),
          ),
        ),
      );
    }

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
    if (WoofCareWebDesign.enabled) {
      return Tooltip(
        message: 'Profile and account',
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: WoofCareWebDesign.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: WoofCareWebDesign.border),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: WoofCareWebDesign.textMuted,
              size: 20,
            ),
          ),
        ),
      );
    }

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
    if (WoofCareWebDesign.enabled) {
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minWidth: 72),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? WoofCareWebDesign.primary
                : WoofCareWebDesign.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? WoofCareWebDesign.primary
                  : WoofCareWebDesign.borderStrong,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected
                  ? WoofCareWebDesign.onPrimary
                  : WoofCareWebDesign.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

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
          color: selected
              ? WoofCareColors.buttonColor
              : WoofCareColors.backgroundElementColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: selected
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
            color: selected
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
    if (WoofCareWebDesign.enabled) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: WoofCareWebDesign.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: WoofCareWebDesign.border),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: WoofCareWebDesign.textMuted,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: WoofCareWebDesign.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: WoofCareWebDesign.textMuted,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                if (action != null) ...[const SizedBox(height: 20), action!],
              ],
            ),
          ),
        ),
      );
    }

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

enum WoofCareBackendStatus { connecting, connectedEmpty, failed }

/// A factual Firebase stream state for web. It never substitutes mock records
/// for missing data, so an empty collection is distinguishable from a failed
/// backend request.
class WoofCareBackendState extends StatelessWidget {
  final WoofCareBackendStatus status;
  final String collectionLabel;
  final Object? error;
  final Widget? action;

  const WoofCareBackendState({
    super.key,
    required this.status,
    required this.collectionLabel,
    this.error,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final failed = status == WoofCareBackendStatus.failed;
    final connecting = status == WoofCareBackendStatus.connecting;
    final title = connecting
        ? 'Connecting to Firebase'
        : failed
        ? 'Firebase connection failed'
        : 'Connected to Firebase';
    final message = connecting
        ? 'Waiting for the live $collectionLabel stream.'
        : failed
        ? _errorSummary(error)
        : 'The $collectionLabel stream is live, but it returned no records.';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: WoofCareWebDesign.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: failed
                  ? WoofCareWebDesign.danger.withValues(alpha: 0.35)
                  : WoofCareWebDesign.border,
            ),
            boxShadow: WoofCareWebDesign.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      (failed
                              ? WoofCareWebDesign.danger
                              : WoofCareWebDesign.primary)
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: connecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: WoofCareWebDesign.primary,
                        ),
                      )
                    : Icon(
                        failed
                            ? Icons.cloud_off_outlined
                            : Icons.cloud_done_outlined,
                        size: 22,
                        color: failed
                            ? WoofCareWebDesign.danger
                            : WoofCareWebDesign.primary,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: WoofCareWebDesign.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      message,
                      style: const TextStyle(
                        color: WoofCareWebDesign.textMuted,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(height: 16),
                      action!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _errorSummary(Object? value) {
    if (value == null) {
      return 'The $collectionLabel stream returned an unknown error.';
    }

    final text = value.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    return 'The $collectionLabel stream returned: $text';
  }
}

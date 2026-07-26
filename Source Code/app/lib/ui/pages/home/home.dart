import 'package:flutter/material.dart';
import 'package:woofcare/config/colors.dart';
import 'package:woofcare/ui/pages/posts/posts.dart';
import 'package:woofcare/ui/widgets/responsive.dart';
import 'package:woofcare/ui/widgets/web_design_system.dart';
import 'package:woofcare/ui/widgets/woofcare_nav_bar.dart';

import '/ui/pages/export.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPageIndex = 0;

  final List<Widget> pages = const [
    MapPage(),
    ConversationsPage(),
    SocialMediaFeed(),
    ArticlePage(),
  ];

  void _openReportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return WoofCareSheetSurface(
          child: DraggableScrollableSheet(
            initialChildSize: 0.78,
            minChildSize: 0.42,
            maxChildSize: 0.95,
            builder: (sheetContext, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: WoofCareWebDesign.enabled
                      ? WoofCareWebDesign.surface
                      : WoofCareColors.secondaryBackground,
                  borderRadius: WoofCareWebDesign.enabled
                      ? BorderRadius.circular(14)
                      : const BorderRadius.vertical(top: Radius.circular(24)),
                  border: WoofCareWebDesign.enabled
                      ? Border.all(color: WoofCareWebDesign.border)
                      : const Border(
                          top: BorderSide(
                            color: WoofCareColors.borderOutline,
                            width: 1.5,
                          ),
                        ),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 16, bottom: 14),
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: WoofCareColors.primaryTextAndIcons.withValues(
                          alpha: 0.45,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const Text(
                      'Dog Report',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: WoofCareColors.primaryTextAndIcons,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      color: WoofCareColors.primaryTextAndIcons.withValues(
                        alpha: 0.22,
                      ),
                      height: 1,
                    ),
                    Expanded(
                      child: SafeArea(
                        top: false,
                        left: false,
                        right: false,
                        child: ReportPage(scrollController: scrollController),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showRail =
            constraints.maxWidth >= WoofCareBreakpoints.navigationRail;
        final extendRail = constraints.maxWidth >= WoofCareBreakpoints.wide;
        final pageStack = IndexedStack(
          index: currentPageIndex,
          children: pages,
        );

        return Scaffold(
          backgroundColor: WoofCareWebDesign.enabled
              ? WoofCareWebDesign.canvas
              : WoofCareColors.primaryBackground,
          extendBody: !showRail && !WoofCareWebDesign.enabled,
          body: showRail
              ? Row(
                  children: [
                    WoofCareNavigationRail(
                      currentIndex: currentPageIndex,
                      onTabSelected: (index) =>
                          setState(() => currentPageIndex = index),
                      onReportTap: _openReportSheet,
                      extended: extendRail,
                    ),
                    Expanded(child: pageStack),
                  ],
                )
              : pageStack,
          bottomNavigationBar: showRail
              ? null
              : WoofCareNavBar(
                  currentIndex: currentPageIndex,
                  onTabSelected: (index) =>
                      setState(() => currentPageIndex = index),
                  onReportTap: _openReportSheet,
                ),
        );
      },
    );
  }
}

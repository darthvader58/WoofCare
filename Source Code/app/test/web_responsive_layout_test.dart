import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofcare/ui/widgets/app_chrome.dart';
import 'package:woofcare/ui/widgets/woofcare_nav_bar.dart';

void main() {
  testWidgets('compact web article chrome stays top-aligned without overflow', (
    tester,
  ) async {
    if (!kIsWeb) return;

    await tester.binding.setSurfaceSize(const Size(520, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final searchController = TextEditingController();
    addTearDown(searchController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              WoofCareScreenHeader(
                title: 'Articles',
                subtitle: 'Care guides and rescue stories',
                icon: Icons.menu_book_rounded,
                searchController: searchController,
                searchHint: 'Search articles',
                actions: const [WoofCareProfileAvatar()],
                bottom: const SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(width: 72, height: 34),
                      SizedBox(width: 8),
                      SizedBox(width: 72, height: 34),
                      SizedBox(width: 8),
                      SizedBox(width: 72, height: 34),
                      SizedBox(width: 8),
                      SizedBox(width: 72, height: 34),
                    ],
                  ),
                ),
              ),
              const Expanded(child: ColoredBox(color: Colors.transparent)),
            ],
          ),
          bottomNavigationBar: WoofCareNavBar(
            currentIndex: 3,
            onTabSelected: (_) {},
            onReportTap: () {},
          ),
        ),
      ),
    );

    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(tester.getTopLeft(find.text('Articles')).dy, lessThan(80));
  });
}

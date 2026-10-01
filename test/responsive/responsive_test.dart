import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unisphere_mobile/core/responsive/responsive.dart';

Widget buildResponsiveTestApp() {
  return const MaterialApp(
    home: Scaffold(
      body: SizedBox(
        key: Key('responsive-target'),
      ),
    ),
  );
}

BuildContext testContext(WidgetTester tester) {
  return tester.element(
    find.byKey(const Key('responsive-target')),
  );
}

void main() {
  testWidgets('mobile breakpoint is detected', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
        ),
        child: buildResponsiveTestApp(),
      ),
    );

    final context = testContext(tester);

    expect(
      Responsive.deviceType(context),
      DeviceType.mobile,
    );
  });

  testWidgets('tablet breakpoint is detected', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(800, 1200),
        ),
        child: buildResponsiveTestApp(),
      ),
    );

    final context = testContext(tester);

    expect(
      Responsive.deviceType(context),
      DeviceType.tablet,
    );
  });

  testWidgets('desktop breakpoint is detected', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(1440, 900),
        ),
        child: buildResponsiveTestApp(),
      ),
    );

    final context = testContext(tester);

    expect(
      Responsive.deviceType(context),
      DeviceType.desktop,
    );
  });

  testWidgets('mobile horizontal padding is 16', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
        ),
        child: buildResponsiveTestApp(),
      ),
    );

    final context = testContext(tester);

    expect(
      Responsive.horizontalPadding(context),
      16,
    );
  });

  testWidgets('tablet horizontal padding is 24', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(800, 1200),
        ),
        child: buildResponsiveTestApp(),
      ),
    );

    final context = testContext(tester);

    expect(
      Responsive.horizontalPadding(context),
      24,
    );
  });

  testWidgets('desktop grid has at least three columns', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(1280, 800),
        ),
        child: buildResponsiveTestApp(),
      ),
    );

    final context = testContext(tester);

    expect(
      Responsive.gridColumns(context),
      3,
    );
  });
}
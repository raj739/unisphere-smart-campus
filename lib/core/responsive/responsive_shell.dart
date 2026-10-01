import 'package:flutter/material.dart';

import 'responsive.dart';

class ResponsiveShell extends StatelessWidget {
  final Widget child;
  final Widget? mobileBottomNavigation;
  final Widget? mobileDrawer;
  final Widget? desktopNavigation;

  const ResponsiveShell({
    super.key,
    required this.child,
    this.mobileBottomNavigation,
    this.mobileDrawer,
    this.desktopNavigation,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return Scaffold(
        drawer: mobileDrawer,
        body: SafeArea(
          child: child,
        ),
        bottomNavigationBar: mobileBottomNavigation,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            desktopNavigation ?? const SizedBox.shrink(),
            Expanded(
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
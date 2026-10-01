import 'package:flutter/material.dart';

enum DeviceType {
  mobile,
  tablet,
  desktop,
}

class Responsive {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  static DeviceType deviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    }

    if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    }

    return DeviceType.desktop;
  }

  static bool isMobile(BuildContext context) =>
      deviceType(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      deviceType(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) =>
      deviceType(context) == DeviceType.desktop;

  static bool isMobileOrTablet(BuildContext context) =>
      !isDesktop(context);

  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < mobileBreakpoint) {
      return 16;
    }

    if (width < tabletBreakpoint) {
      return 24;
    }

    return 32;
  }

  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width > 1440) {
      return 1400;
    }

    return width;
  }

  static int gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < mobileBreakpoint) {
      return 1;
    }

    if (width < tabletBreakpoint) {
      return 2;
    }

    if (width < 1440) {
      return 3;
    }

    return 4;
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    DeviceType deviceType,
  ) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      Responsive.deviceType(context),
    );
  }
}

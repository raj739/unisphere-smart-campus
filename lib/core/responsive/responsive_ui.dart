import 'package:flutter/material.dart';

import 'responsive.dart';

class ResponsivePage extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const ResponsivePage({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final horizontal =
        Responsive.horizontalPadding(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.contentMaxWidth(context),
        ),
        child: SingleChildScrollView(
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: horizontal,
                vertical: 24,
              ),
          child: child,
        ),
      ),
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.gridColumns(context);

    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio:
          Responsive.isMobile(context) ? 1.25 : 1.5,
      children: children,
    );
  }
}

class ResponsiveVisibility extends StatelessWidget {
  final Widget child;
  final bool mobile;
  final bool tablet;
  final bool desktop;

  const ResponsiveVisibility({
    super.key,
    required this.child,
    this.mobile = true,
    this.tablet = true,
    this.desktop = true,
  });

  @override
  Widget build(BuildContext context) {
    final type = Responsive.deviceType(context);

    final visible = switch (type) {
      DeviceType.mobile => mobile,
      DeviceType.tablet => tablet,
      DeviceType.desktop => desktop,
    };

    return visible ? child : const SizedBox.shrink();
  }
}

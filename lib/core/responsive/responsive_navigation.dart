import 'package:flutter/material.dart';

class ResponsiveNavigationItem {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;

  const ResponsiveNavigationItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });
}

class ResponsiveNavigation {
  static const studentItems = <ResponsiveNavigationItem>[
    ResponsiveNavigationItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    ResponsiveNavigationItem(
      label: 'Academics',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
    ),
    ResponsiveNavigationItem(
      label: 'Attendance',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
    ),
    ResponsiveNavigationItem(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];
}

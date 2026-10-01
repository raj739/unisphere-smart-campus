import 'package:flutter/material.dart';

import 'analytics_dashboard_screen.dart';

void openAnalyticsDashboard(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AnalyticsDashboardScreen()));
}

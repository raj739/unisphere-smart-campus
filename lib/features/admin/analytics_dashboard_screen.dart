import 'package:flutter/material.dart';

import '../../services/unispher_api_service.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  bool _loading = true;
  String? _error;

  Map<String, dynamic> _overview = {};
  Map<String, dynamic> _roles = {};
  Map<String, dynamic> _health = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        UniSphereApiService.getUniversityAnalyticsOverview(),
        UniSphereApiService.getAnalyticsRoleDistribution(),
        UniSphereApiService.getAnalyticsSystemHealth(),
      ]);

      if (!mounted) return;

      setState(() {
        _overview = Map<String, dynamic>.from(results[0] as Map);
        _roles = Map<String, dynamic>.from(results[1] as Map);
        _health = Map<String, dynamic>.from(results[2] as Map);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  num _number(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _display(dynamic value) {
    if (value == null) return '0';
    if (value is double) {
      return value % 1 == 0
          ? value.toInt().toString()
          : value.toStringAsFixed(1);
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('University Analytics'),
        actions: [
          IconButton(
            tooltip: 'Refresh analytics',
            onPressed: _loading ? null : _loadAnalytics,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildOverview(),
                  const SizedBox(height: 24),
                  _buildRoleDistribution(),
                  const SizedBox(height: 24),
                  _buildSystemHealth(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.insights,
                size: 30,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'University Intelligence Center',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text('Monitor users, system activity and platform health.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview() {
    final total = _number(_overview['total_users']);
    final students = _number(_overview['students']);
    final parents = _number(_overview['parents']);
    final administrators = _number(_overview['administrators']);
    final active = _number(_overview['active_users']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'University Overview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 1100
                ? 5
                : width >= 700
                ? 3
                : 2;

            final cardWidth = (width - ((columns - 1) * 12)) / columns;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _metricCard(
                  'Total Users',
                  _display(total),
                  Icons.groups,
                  cardWidth,
                ),
                _metricCard(
                  'Students',
                  _display(students),
                  Icons.school,
                  cardWidth,
                ),
                _metricCard(
                  'Parents',
                  _display(parents),
                  Icons.family_restroom,
                  cardWidth,
                ),
                _metricCard(
                  'Administrators',
                  _display(administrators),
                  Icons.admin_panel_settings,
                  cardWidth,
                ),
                _metricCard(
                  'Active Users',
                  _display(active),
                  Icons.person,
                  cardWidth,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _metricCard(String title, String value, IconData icon, double width) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(title, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDistribution() {
    final distribution = Map<String, dynamic>.from(
      _roles['distribution'] ?? {},
    );

    if (distribution.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No role distribution data available.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final entries = distribution.entries.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Role Distribution',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            ...entries.map((entry) {
              final value = _number(entry.value);

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: value > 0 ? 1 : 0,
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 50,
                      child: Text(_display(value), textAlign: TextAlign.end),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemHealth() {
    final health = _health['health'] is Map
        ? Map<String, dynamic>.from(_health['health'])
        : _health;

    final status = health['status']?.toString().toUpperCase() ?? 'UNKNOWN';

    final database = health['database']?.toString().toUpperCase() ?? 'UNKNOWN';

    final api = health['api']?.toString().toUpperCase() ?? 'UNKNOWN';

    final services = health['services'] is Map
        ? Map<String, dynamic>.from(health['services'])
        : <String, dynamic>{};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Health',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            _healthRow('Overall Status', status),
            _healthRow('Database', database),
            _healthRow('API', api),
            ...services.entries.map(
              (entry) =>
                  _healthRow(entry.key, entry.value.toString().toUpperCase()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _healthRow(String label, String value) {
    final healthy =
        value == 'OK' ||
        value == 'HEALTHY' ||
        value == 'UP' ||
        value == 'ONLINE' ||
        value == 'AVAILABLE';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Icon(healthy ? Icons.check_circle : Icons.info, size: 18),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52),
            const SizedBox(height: 16),
            const Text(
              'Unable to load analytics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_error ?? 'Unknown error', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadAnalytics,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _data = const {};
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await UniSphereApiService.getAdminDashboard();
      if (mounted) setState(() => _data = data);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load the dashboard.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FB),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campus Operations',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172554),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Live university activity, academics and collections.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh dashboard',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(56),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            _ErrorState(message: _error!, onRetry: _load)
          else ...[
            _metricGrid(),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final finance = _financePanel();
                final readiness = _readinessPanel();
                if (constraints.maxWidth < 900)
                  return Column(
                    children: [finance, const SizedBox(height: 14), readiness],
                  );
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: finance),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: readiness),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final departments = _departmentPanel();
                final recent = _recentStudentsPanel();
                if (constraints.maxWidth < 900)
                  return Column(
                    children: [departments, const SizedBox(height: 14), recent],
                  );
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: departments),
                    const SizedBox(width: 14),
                    Expanded(child: recent),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    ),
  );

  Widget _metricGrid() {
    final metrics = [
      (
        'Students',
        _data['total_students'],
        Icons.people_outline,
        const Color(0xFF2563EB),
      ),
      (
        'Academic units',
        _data['total_departments'],
        Icons.account_tree_outlined,
        const Color(0xFF059669),
      ),
      (
        'Programme groups',
        _data['total_programmes'],
        Icons.school_outlined,
        const Color(0xFF7C3AED),
      ),
      (
        'Subject options',
        _data['total_programme_options'],
        Icons.category_outlined,
        const Color(0xFFD97706),
      ),
      (
        'Courses',
        _data['total_courses'],
        Icons.menu_book_outlined,
        const Color(0xFF0891B2),
      ),
      (
        'Active offerings',
        _data['active_offerings'],
        Icons.how_to_reg_outlined,
        const Color(0xFFDB2777),
      ),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: metrics
          .map(
            (metric) => _MetricTile(
              label: metric.$1,
              value: '${metric.$2 ?? 0}',
              icon: metric.$3,
              color: metric.$4,
            ),
          )
          .toList(),
    );
  }

  Widget _financePanel() {
    final finance = Map<String, dynamic>.from(
      _data['finance'] as Map? ?? const {},
    );
    final invoiced = (finance['invoiced'] as num? ?? 0).toDouble();
    final collected = (finance['collected'] as num? ?? 0).toDouble();
    final outstanding = (finance['outstanding'] as num? ?? 0).toDouble();
    final progress = invoiced == 0
        ? 0.0
        : (collected / invoiced).clamp(0.0, 1.0);
    return _Panel(
      title: 'Fee collection',
      subtitle: 'Current invoice ledger',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Money(label: 'Invoiced', value: invoiced),
              ),
              Expanded(
                child: _Money(label: 'Collected', value: collected),
              ),
              Expanded(
                child: _Money(
                  label: 'Outstanding',
                  value: outstanding,
                  warning: outstanding > 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% collected',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readinessPanel() {
    final rows = [
      (
        'Demo curricula',
        _data['total_curricula'],
        Icons.library_books_outlined,
      ),
      ('Semesters', _data['total_semesters'], Icons.date_range_outlined),
      ('Timetable slots', _data['timetable_entries'], Icons.schedule_outlined),
      (
        'Attendance sessions',
        _data['attendance_sessions'],
        Icons.fact_check_outlined,
      ),
      ('Examinations', _data['examinations'], Icons.assignment_outlined),
      ('Documents', _data['documents_issued'], Icons.description_outlined),
    ];
    return _Panel(
      title: 'Operational readiness',
      subtitle: 'Configured live records',
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Row(
                  children: [
                    Icon(row.$3, size: 18, color: const Color(0xFF475569)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(row.$1)),
                    Text(
                      '${row.$2 ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _departmentPanel() {
    final rows = (_data['department_distribution'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final maxStudents = rows.fold<int>(1, (max, item) {
      final count = item['student_count'] as int? ?? 0;
      return count > max ? count : max;
    });
    return _Panel(
      title: 'Students by academic unit',
      subtitle: '${rows.length} units in the registry',
      child: rows.isEmpty
          ? const Text('No department data available.')
          : Column(
              children: rows.take(8).map((row) {
                final count = row['student_count'] as int? ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              row['name']?.toString() ?? 'Academic unit',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$count',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: count / maxStudents,
                        minHeight: 5,
                        backgroundColor: const Color(0xFFE2E8F0),
                        color: const Color(0xFF2563EB),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _recentStudentsPanel() {
    final students = (_data['recent_students'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    return _Panel(
      title: 'Recently registered',
      subtitle: 'Latest student accounts',
      child: students.isEmpty
          ? const Text('No students registered yet.')
          : Column(
              children: students
                  .map(
                    (student) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFEEF2FF),
                            foregroundColor: const Color(0xFF4338CA),
                            child: Text(
                              _initials(
                                student['full_name']?.toString() ?? 'S',
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student['full_name']?.toString() ?? 'Student',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${student['uni_id']}  |  ${student['programme']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Sem ${student['current_semester']}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((part) => part.isEmpty ? '' : part[0])
      .join()
      .toUpperCase();
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 190,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE2E8F0)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE2E8F0)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172554),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );
}

class _Money extends StatelessWidget {
  const _Money({
    required this.label,
    required this.value,
    this.warning = false,
  });
  final String label;
  final double value;
  final bool warning;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
      ),
      const SizedBox(height: 4),
      Text(
        'INR ${value.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: warning ? const Color(0xFFB45309) : const Color(0xFF172554),
        ),
      ),
    ],
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        const Icon(Icons.error_outline, size: 42),
        const SizedBox(height: 10),
        Text(message),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}

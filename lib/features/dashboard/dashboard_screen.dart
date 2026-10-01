import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _student;
  List<dynamic> _attendance = const [];
  List<dynamic> _results = const [];
  List<dynamic> _timetable = const [];
  Map<String, dynamic>? _fees;
  Map<String, dynamic>? _recommendations;
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
      final values = await Future.wait<dynamic>([
        UniSphereApiService.getStudent(),
        UniSphereApiService.getAttendance(),
        UniSphereApiService.getResults(),
        UniSphereApiService.getTimetable(),
        UniSphereApiService.getFeeSummary(),
        UniSphereApiService.getRecommendations(),
      ]);
      if (mounted) {
        setState(() {
          _student = Map<String, dynamic>.from(values[0] as Map);
          _attendance = List<dynamic>.from(values[1] as List);
          _results = List<dynamic>.from(values[2] as List);
          _timetable = List<dynamic>.from(values[3] as List);
          _fees = Map<String, dynamic>.from(values[4] as Map);
          _recommendations = Map<String, dynamic>.from(values[5] as Map);
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load your dashboard.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _attendanceAverage {
    if (_attendance.isEmpty) return 0;
    final total = _attendance.fold<double>(
      0,
      (sum, item) =>
          sum +
          (((item as Map)['attendance_percentage'] as num?)?.toDouble() ??
              ((item)['percentage'] as num?)?.toDouble() ??
              0),
    );
    return total / _attendance.length;
  }

  double get _cgpa {
    if (_results.isEmpty) return 0;
    final total = _results.fold<double>(
      0,
      (sum, item) =>
          sum + ((item as Map)['grade_point'] as num? ?? 0).toDouble(),
    );
    return total / _results.length;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FB),
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(30),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${_student?['full_name'] ?? 'Student'}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your live academic overview.',
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
            const SizedBox(height: 28),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 42),
                    const SizedBox(height: 12),
                    Text(_error!),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else ...[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _metric(
                    'Attendance',
                    '${_attendanceAverage.toStringAsFixed(1)}%',
                    Icons.fact_check_outlined,
                  ),
                  _metric(
                    'CGPA',
                    _cgpa.toStringAsFixed(2),
                    Icons.grade_outlined,
                  ),
                  _metric(
                    'Courses',
                    '${_attendance.length}',
                    Icons.school_outlined,
                  ),
                  _metric(
                    'Fee Outstanding',
                    '${_fees?['outstanding_amount'] ?? '-'}',
                    Icons.account_balance_wallet_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'AI Recommendations',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              _recommendationPanel(),
              const SizedBox(height: 24),
              const Text(
                'Upcoming Timetable',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (_timetable.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('No timetable entries are available.'),
                  ),
                )
              else
                ..._timetable.take(5).map((item) {
                  final entry = Map<String, dynamic>.from(item as Map);
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.schedule),
                      title: Text(entry['course_name']?.toString() ?? '-'),
                      subtitle: Text(
                        '${entry['day_of_week'] ?? '-'} | ${entry['start_time'] ?? '-'} - ${entry['end_time'] ?? '-'}',
                      ),
                      trailing: Text(entry['room']?.toString() ?? '-'),
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _metric(String label, String value, IconData icon) => SizedBox(
    width: 210,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2563EB)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF64748B))),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  List<Map<String, dynamic>> get _recommendationItems =>
      (_recommendations?['recommendations'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

  Widget _recommendationPanel() {
    final status =
        _recommendations?['overall_status']?.toString() ?? 'Not assessed';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes_outlined, color: Color(0xFF2563EB)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  status,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recommendationItems.isEmpty)
            const Text(
              'You are on track. No additional action is recommended from your current records.',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            ..._recommendationItems.take(3).map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']?.toString() ?? 'Recommended action',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['action']?.toString() ??
                                item['message']?.toString() ??
                                '-',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

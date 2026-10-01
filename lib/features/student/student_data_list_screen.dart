import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';

class StudentDataListScreen extends StatefulWidget {
  const StudentDataListScreen({
    super.key,
    required this.title,
    required this.emptyMessage,
    required this.loader,
  });

  final String title;
  final String emptyMessage;
  final Future<List<dynamic>> Function() loader;

  @override
  State<StudentDataListScreen> createState() => _StudentDataListScreenState();
}

class _StudentDataListScreenState extends State<StudentDataListScreen> {
  List<Map<String, dynamic>> _records = const [];
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
      final data = await widget.loader();
      if (mounted) {
        setState(
          () => _records = data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(),
        );
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unable to load ${widget.title.toLowerCase()}.',
        );
      }
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172554),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _subtitle,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh ${widget.title.toLowerCase()}',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (!_loading && _error == null) _summary(),
          const SizedBox(height: 18),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            _errorState()
          else if (_records.isEmpty)
            _emptyState()
          else
            ..._records.map(_recordTile),
        ],
      ),
    ),
  );

  String get _subtitle => switch (widget.title) {
    'Attendance' =>
      'Course-wise attendance calculated from recorded class sessions.',
    'Results' => 'Published semester grades and marks.',
    'Timetable' =>
      'Your enrolled classes, faculty, rooms and teaching schedule.',
    'Examinations' => 'Registered examinations, papers and admit-card details.',
    _ => 'Your live university records.',
  };

  Widget _summary() {
    final secondary = switch (widget.title) {
      'Attendance' =>
        _records.isEmpty
            ? 'No classes recorded'
            : '${(_records.fold<double>(0, (sum, item) => sum + (item['attendance_percentage'] as num? ?? 0).toDouble()) / _records.length).toStringAsFixed(0)}% average',
      'Results' =>
        '${_records.where((item) => item['grade'] != null).length} published',
      'Timetable' =>
        '${_records.map((item) => item['day_of_week']).toSet().length} teaching days',
      'Examinations' =>
        '${_records.where((item) => item['registration_status'] == 'approved').length} approved',
      _ => 'Live records',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF172554),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(_sectionIcon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_records.length}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${widget.title} records',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
          ),
          Text(
            secondary,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordTile(Map<String, dynamic> record) => switch (widget.title) {
    'Attendance' => _attendanceTile(record),
    'Results' => _resultTile(record),
    'Timetable' => _timetableTile(record),
    'Examinations' => _examinationTile(record),
    _ => _fallbackTile(record),
  };

  Widget _attendanceTile(Map<String, dynamic> record) {
    final percentage = (record['attendance_percentage'] as num? ?? 0)
        .toDouble();
    final color = percentage >= 75
        ? const Color(0xFF059669)
        : const Color(0xFFDC2626);
    return _RecordSurface(
      icon: Icons.fact_check_outlined,
      iconColor: color,
      title: record['course_name']?.toString() ?? 'Course attendance',
      subtitle:
          '${record['course_code'] ?? '-'}  |  ${record['academic_session'] ?? '-'}  |  ${record['classes_attended'] ?? 0}/${record['classes_held'] ?? 0} attended',
      trailing: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            LinearProgressIndicator(
              value: (percentage / 100).clamp(0, 1),
              minHeight: 5,
              backgroundColor: const Color(0xFFE2E8F0),
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultTile(Map<String, dynamic> record) => _RecordSurface(
    icon: Icons.assessment_outlined,
    iconColor: const Color(0xFF7C3AED),
    title: record['course_name']?.toString() ?? 'Published result',
    subtitle:
        '${record['course_code'] ?? '-'}  |  Semester ${record['semester_id'] ?? '-'}  |  Marks ${record['marks'] ?? '-'}',
    trailing: _ValueBadge(
      value: record['grade']?.toString() ?? '-',
      label: 'GRADE',
    ),
  );

  Widget _timetableTile(Map<String, dynamic> record) => _RecordSurface(
    icon: Icons.schedule_outlined,
    iconColor: const Color(0xFF2563EB),
    title: record['course_name']?.toString() ?? 'Scheduled class',
    subtitle:
        '${record['course_code'] ?? '-'}  |  ${record['faculty_name'] ?? 'Faculty allocation pending'}  |  ${record['building'] ?? 'Building not set'}, ${record['room'] ?? 'Room not set'}',
    trailing: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _dayName(record['day_of_week'] as int?),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF172554),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${record['start_time']} - ${record['end_time']}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    ),
  );

  Widget _examinationTile(Map<String, dynamic> record) {
    final papers = (record['papers'] as List? ?? const []).length;
    final status =
        record['registration_status']?.toString() ?? 'not registered';
    return _RecordSurface(
      icon: Icons.assignment_outlined,
      iconColor: const Color(0xFFD97706),
      title: record['name']?.toString() ?? 'Examination',
      subtitle:
          '${record['academic_session'] ?? '-'}  |  $papers papers  |  ${record['start_date'] ?? 'Dates pending'}  |  ${record['registration_number'] ?? 'Number pending'}',
      trailing: _StatusBadge(status: status),
    );
  }

  Widget _fallbackTile(Map<String, dynamic> record) => _RecordSurface(
    icon: _sectionIcon,
    iconColor: const Color(0xFF475569),
    title: record['name']?.toString() ?? widget.title,
    subtitle: record.entries
        .where((entry) => entry.value != null)
        .take(4)
        .map((entry) => '${_label(entry.key)}: ${entry.value}')
        .join('  |  '),
  );

  IconData get _sectionIcon => switch (widget.title) {
    'Attendance' => Icons.fact_check_outlined,
    'Results' => Icons.assessment_outlined,
    'Timetable' => Icons.schedule_outlined,
    'Examinations' => Icons.assignment_outlined,
    _ => Icons.description_outlined,
  };

  Widget _emptyState() => Container(
    padding: const EdgeInsets.all(42),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE2E8F0)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Icon(_sectionIcon, size: 44, color: const Color(0xFF94A3B8)),
        const SizedBox(height: 12),
        Text(
          widget.emptyMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        const Text(
          'This page updates automatically when the academic office publishes new records.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      ],
    ),
  );

  Widget _errorState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 42),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );

  String _dayName(int? day) =>
      const {
        1: 'Monday',
        2: 'Tuesday',
        3: 'Wednesday',
        4: 'Thursday',
        5: 'Friday',
        6: 'Saturday',
        7: 'Sunday',
      }[day] ??
      'Day pending';
  String _label(String value) => value
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

class _RecordSurface extends StatelessWidget {
  const _RecordSurface({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE2E8F0)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF172554),
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    ),
  );
}

class _ValueBadge extends StatelessWidget {
  const _ValueBadge({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Color(0xFF6D28D9),
        ),
      ),
      Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
        ),
      ),
    ],
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final good = {'approved', 'registered'}.contains(status.toLowerCase());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: good ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: good ? const Color(0xFF047857) : const Color(0xFFC2410C),
        ),
      ),
    );
  }
}

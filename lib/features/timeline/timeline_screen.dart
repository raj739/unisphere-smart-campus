import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../models/student_identity.dart';
import '../../models/student_lifecycle.dart';
import '../../services/unispher_api_service.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key, required this.student});

  final StudentIdentity? student;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  StudentLifecycle? _lifecycle;
  List<StudentLifecycleEvent> _events = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<Object>([
        UniSphereApiService.getMyLifecycle(),
        UniSphereApiService.getMyLifecycleHistory(),
      ]);
      if (!mounted) return;
      setState(() {
        _lifecycle = results[0] as StudentLifecycle;
        _events = results[1] as List<StudentLifecycleEvent>;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load your lifecycle record.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadTimeline,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Timeline',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your verified admission and lifecycle events.',
                      style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh timeline',
                onPressed: _loading ? null : _loadTimeline,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (_loading && _lifecycle == null)
            const SizedBox(
              height: 280,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_lifecycle == null)
            _TimelineError(
              message: _error ?? 'No lifecycle record is available.',
              onRetry: _loadTimeline,
            )
          else ...[
            _LifecycleHeader(student: widget.student, lifecycle: _lifecycle!),
            const SizedBox(height: 24),
            _LifecycleDetails(lifecycle: _lifecycle!),
            const SizedBox(height: 24),
            const Text(
              'Recorded Events',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            if (_events.isEmpty)
              _EmptyHistory(lifecycle: _lifecycle!)
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    for (var index = 0; index < _events.length; index++)
                      _TimelineItem(
                        event: _events[index],
                        isLast: index == _events.length - 1,
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _LifecycleHeader extends StatelessWidget {
  const _LifecycleHeader({required this.student, required this.lifecycle});

  final StudentIdentity? student;
  final StudentLifecycle lifecycle;

  @override
  Widget build(BuildContext context) {
    final programme = student?.programme.trim();
    final title = programme == null || programme.isEmpty
        ? 'Academic Journey'
        : '$programme Academic Journey';
    final details = <String>[
      if ((student?.academicSession ?? '').trim().isNotEmpty)
        student!.academicSession!,
      if (student != null) 'Semester ${student!.currentSemester}',
      lifecycle.uniId,
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF172554),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timeline_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  details.join(' | '),
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _LifecycleStatus(status: lifecycle.currentStatus),
        ],
      ),
    );
  }
}

class _LifecycleDetails extends StatelessWidget {
  const _LifecycleDetails({required this.lifecycle});

  final StudentLifecycle lifecycle;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Student', lifecycle.studentName),
      ('Current status', _label(lifecycle.currentStatus)),
      ('Admission date', _date(lifecycle.admissionDate)),
      if (lifecycle.graduationDate != null)
        ('Graduation date', _date(lifecycle.graduationDate)),
      if (lifecycle.alumniDate != null)
        ('Alumni date', _date(lifecycle.alumniDate)),
      if ((lifecycle.admissionReference ?? '').trim().isNotEmpty)
        ('Admission reference', lifecycle.admissionReference!),
      if ((lifecycle.notes ?? '').trim().isNotEmpty)
        ('Notes', lifecycle.notes!),
      ('Last updated', _dateTime(lifecycle.updatedAt)),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: Color(0xFF1D4ED8)),
              SizedBox(width: 10),
              Text(
                'Verified Lifecycle Record',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF172554),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      row.$1,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.lifecycle});

  final StudentLifecycle lifecycle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: Color(0xFF64748B), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current status: ${_label(lifecycle.currentStatus)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'No lifecycle transitions have been recorded yet.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.event, required this.isLast});

  final StudentLifecycleEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final from = event.fromStatus == null
        ? 'Initial status'
        : _label(event.fromStatus!);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 42,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 17,
                backgroundColor: Color(0xFFDBEAFE),
                child: Icon(Icons.check, color: Color(0xFF1D4ED8), size: 18),
              ),
              if (!isLast)
                Container(width: 2, height: 76, color: const Color(0xFFE2E8F0)),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$from to ${_label(event.toStatus)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dateTime(event.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
                if ((event.reason ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    event.reason!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LifecycleStatus extends StatelessWidget {
  const _LifecycleStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label(status).toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF166534),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TimelineError extends StatelessWidget {
  const _TimelineError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: Color(0xFF64748B),
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

String _label(String value) {
  final words = value.split('_').where((word) => word.isNotEmpty);
  return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

String _date(DateTime? value) {
  if (value == null) return 'Not recorded';
  return '${_months[value.month - 1]} ${value.day}, ${value.year}';
}

String _dateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${_date(local)} at $hour:$minute $period';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

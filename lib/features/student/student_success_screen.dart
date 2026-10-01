import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

class StudentSuccessScreen extends StatefulWidget {
  const StudentSuccessScreen({super.key});

  @override
  State<StudentSuccessScreen> createState() => _StudentSuccessScreenState();
}

class _StudentSuccessScreenState extends State<StudentSuccessScreen> {
  Map<String, dynamic>? _prediction;
  Map<String, dynamic> _recommendationData = const {};
  List<Map<String, dynamic>> _warnings = const [];
  List<Map<String, dynamic>> _interventions = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Map<String, dynamic>?> _loadPrediction() async {
    try {
      return await UniSphereApiService.getMyPredictiveResult();
    } on ApiException catch (error) {
      if (error.isNotFound) return null;
      rethrow;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait<dynamic>([
        _loadPrediction(),
        UniSphereApiService.getMyEarlyWarnings(),
        UniSphereApiService.getMyInterventionsV2(),
        UniSphereApiService.getRecommendations(),
      ]);
      if (!mounted) return;
      setState(() {
        _prediction = values[0] == null
            ? null
            : Map<String, dynamic>.from(values[0] as Map);
        _warnings = _objectList(values[1]);
        _interventions = _objectList(values[2]);
        _recommendationData = Map<String, dynamic>.from(values[3] as Map);
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load your student success data.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _objectList(dynamic value) => (value as List)
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 36),
          children: [
            _pageHeader(),
            const SizedBox(height: 24),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 100),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _errorState()
            else ...[
              _predictionOverview(),
              const SizedBox(height: 26),
              _sectionTitle(
                icon: Icons.notification_important_outlined,
                title: 'Support alerts',
                subtitle: 'Signals that need your attention or follow-up.',
                count: _warnings.length,
              ),
              const SizedBox(height: 12),
              _warningsSection(),
              const SizedBox(height: 26),
              _sectionTitle(
                icon: Icons.handshake_outlined,
                title: 'My support cases',
                subtitle: 'Actions being coordinated with your support team.',
                count: _interventions.length,
              ),
              const SizedBox(height: 12),
              _interventionsSection(),
              const SizedBox(height: 26),
              _sectionTitle(
                icon: Icons.auto_awesome_outlined,
                title: 'Personalized learning plan',
                subtitle: 'Practical next steps based on your live records.',
                count: _recommendations.length,
              ),
              const SizedBox(height: 12),
              _recommendationsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pageHeader() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.insights_outlined, color: Color(0xFF0369A1)),
      ),
      const SizedBox(width: 14),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Student Success',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Your progress, support alerts, and recommended next steps.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Refresh student success',
        onPressed: _load,
        icon: const Icon(Icons.refresh),
      ),
    ],
  );

  Widget _errorState() => Container(
    padding: const EdgeInsets.all(24),
    decoration: _panelDecoration,
    child: Column(
      children: [
        const Icon(Icons.cloud_off_outlined, size: 42, color: Color(0xFFB91C1C)),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );

  Widget _predictionOverview() {
    if (_prediction == null) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: _panelDecoration,
        child: const Row(
          children: [
            Icon(Icons.hourglass_empty_outlined, color: Color(0xFF64748B)),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Success assessment not available yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your progress summary will appear after attendance and result data are assessed.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final risk = _text(_prediction!['risk_level'], fallback: 'Not assessed');
    final riskColor = _riskColor(risk);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF172554),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Progress outlook',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _statusChip(risk, riskColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _text(_prediction!['explanation'], fallback: 'Assessment completed.'),
            style: const TextStyle(color: Color(0xFFCBD5E1), height: 1.45),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _outlookMetric(
                'Projected performance',
                _text(_prediction!['predicted_performance']),
                Icons.trending_up,
              ),
              _outlookMetric(
                'Risk indicator',
                _percent(_prediction!['dropout_probability']),
                Icons.monitor_heart_outlined,
              ),
              _outlookMetric(
                'Attendance',
                _percent(_prediction!['attendance_percentage']),
                Icons.fact_check_outlined,
              ),
              _outlookMetric(
                'Academic score',
                _percent(_prediction!['academic_percentage']),
                Icons.school_outlined,
              ),
              _outlookMetric(
                'Data confidence',
                _text(_prediction!['data_confidence']).toUpperCase(),
                Icons.verified_outlined,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.route_outlined, color: Color(0xFF7DD3FC), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _text(
                      _prediction!['recommended_action'],
                      fallback: 'Continue following your academic plan.',
                    ),
                    style: const TextStyle(color: Colors.white, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _outlookMetric(String label, String value, IconData icon) => Container(
    width: 190,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF7DD3FC), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
    required int count,
  }) => Row(
    children: [
      Icon(icon, color: const Color(0xFF1D4ED8), size: 23),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('$count', style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    ],
  );

  Widget _warningsSection() {
    if (_warnings.isEmpty) {
      return _emptyPanel(
        Icons.check_circle_outline,
        'No active support alerts',
        'There are no unresolved warning signals on your record.',
      );
    }
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: _warnings.map((warning) {
        final severity = _text(warning['severity'], fallback: 'Info');
        final color = _severityColor(severity);
        return SizedBox(
          width: 370,
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: _panelDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _statusChip(severity, color),
                    const Spacer(),
                    Text(
                      _text(warning['status']),
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _text(warning['title'], fallback: 'Support alert'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  _text(warning['message']),
                  style: const TextStyle(color: Color(0xFF475569), height: 1.4),
                ),
                const SizedBox(height: 12),
                _actionLine(_text(warning['recommended_action'])),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _interventionsSection() {
    if (_interventions.isEmpty) {
      return _emptyPanel(
        Icons.support_agent_outlined,
        'No support case is open',
        'Assigned academic or wellbeing support will appear here.',
      );
    }
    return Column(
      children: _interventions.map((item) {
        final status = _text(item['status'], fallback: 'Open');
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: _panelDecoration,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.handshake_outlined, color: Color(0xFF047857)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _text(item['intervention_type'], fallback: 'Student support'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          _statusChip(status, _statusColor(status)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _text(item['reason'], fallback: _text(item['warning_title'])),
                        style: const TextStyle(color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 22,
                        runSpacing: 8,
                        children: [
                          _detail(Icons.person_outline, 'Advisor', _text(item['assigned_to'], fallback: 'To be assigned')),
                          _detail(Icons.event_outlined, 'Due', _date(item['due_date'])),
                          _detail(Icons.flag_outlined, 'Priority', _text(item['priority'])),
                        ],
                      ),
                      if (_hasText(item['notes']) || _hasText(item['outcome'])) ...[
                        const SizedBox(height: 12),
                        Text(
                          _text(item['outcome'], fallback: _text(item['notes'])),
                          style: const TextStyle(color: Color(0xFF64748B), height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> get _recommendations =>
      (_recommendationData['recommendations'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

  Widget _recommendationsSection() {
    if (_recommendations.isEmpty) {
      return _emptyPanel(
        Icons.track_changes_outlined,
        'You are on track',
        'No additional actions are recommended from your current records.',
      );
    }
    return Container(
      decoration: _panelDecoration,
      child: Column(
        children: _recommendations.indexed.map((entry) {
          final index = entry.$1;
          final item = entry.$2;
          final priority = _text(item['priority'], fallback: 'Normal');
          return Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              border: index == _recommendations.length - 1
                  ? null
                  : const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _text(item['title'], fallback: 'Recommended action'),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ),
                          _statusChip(priority, _severityColor(priority)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _text(item['message']),
                        style: const TextStyle(color: Color(0xFF64748B), height: 1.35),
                      ),
                      const SizedBox(height: 9),
                      _actionLine(_text(item['action'])),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _actionLine(String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF1D4ED8)),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.w600, height: 1.35),
        ),
      ),
    ],
  );

  Widget _detail(IconData icon, String label, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: const Color(0xFF64748B)),
      const SizedBox(width: 5),
      Text('$label: ', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
    ],
  );

  Widget _emptyPanel(IconData icon, String title, String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: _panelDecoration,
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF059669), size: 28),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(message, style: const TextStyle(color: Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _statusChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
    ),
  );

  BoxDecoration get _panelDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFDCE3EC)),
  );

  String _text(dynamic value, {String fallback = '-'}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  bool _hasText(dynamic value) => value != null && value.toString().trim().isNotEmpty;

  String _percent(dynamic value) {
    if (value is num) return '${value.toStringAsFixed(1)}%';
    return '-';
  }

  String _date(dynamic value) {
    final text = _text(value);
    return text.length >= 10 ? text.substring(0, 10) : text;
  }

  Color _riskColor(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('high')) return const Color(0xFFFCA5A5);
    if (normalized.contains('medium')) return const Color(0xFFFCD34D);
    return const Color(0xFF6EE7B7);
  }

  Color _severityColor(String value) {
    final normalized = value.toLowerCase();
    if (normalized == 'high' || normalized == 'urgent') return const Color(0xFFB91C1C);
    if (normalized == 'medium') return const Color(0xFFB45309);
    return const Color(0xFF047857);
  }

  Color _statusColor(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('progress')) return const Color(0xFF1D4ED8);
    if (normalized.contains('complete')) return const Color(0xFF047857);
    return const Color(0xFFB45309);
  }
}

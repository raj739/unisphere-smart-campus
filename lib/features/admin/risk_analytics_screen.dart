import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

class RiskAnalyticsScreen extends StatefulWidget {
  const RiskAnalyticsScreen({super.key});

  @override
  State<RiskAnalyticsScreen> createState() => _RiskAnalyticsScreenState();
}

class _RiskAnalyticsScreenState extends State<RiskAnalyticsScreen> {
  List<Map<String, dynamic>> _assessments = const [];
  String? _error;
  bool _loading = true;
  bool _running = false;
  String _filter = 'All';
  String _query = '';

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
      final data = await UniSphereApiService.getPredictiveRiskDashboard();
      if (mounted) setState(() => _assessments = data);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load predictive analytics.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runPrediction() async {
    setState(() => _running = true);
    try {
      final result = await UniSphereApiService.recalculatePredictiveRisk();
      if (!mounted) return;
      setState(() {
        _assessments = (result['assessments'] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      });
      _message(
        'Prediction completed for ${result['students_evaluated'] ?? 0} students; '
        '${result['warnings_created'] ?? 0} warnings created.',
      );
    } on ApiException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('Predictive analysis could not be completed.');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final needle = _query.trim().toLowerCase();
    return _assessments.where((item) {
      final matchesLevel = _filter == 'All' || item['risk_level'] == _filter;
      final matchesQuery = needle.isEmpty ||
          [item['student_name'], item['uni_id'], item['programme']].any(
            (value) => value.toString().toLowerCase().contains(needle),
          );
      return matchesLevel && matchesQuery;
    }).toList();
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF4F7FA),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _header(),
                const SizedBox(height: 20),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_error != null)
                  _errorView()
                else ...[
                  _summary(),
                  const SizedBox(height: 16),
                  _filters(),
                  const SizedBox(height: 16),
                  if (_filtered.isEmpty)
                    _emptyView()
                  else
                    ..._filtered.map(_studentRisk),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _header() => Row(
        children: [
          const Icon(
            Icons.query_stats_rounded,
            color: Color(0xFFB45309),
            size: 32,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Predictive Student Success',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Explainable risk signals from attendance, published results, engagement, and outstanding balances.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loading || _running ? null : _load,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _loading || _running ? null : _runPrediction,
            icon: _running
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_graph_rounded),
            label: Text(_running ? 'Analyzing' : 'Run prediction'),
          ),
        ],
      );

  Widget _summary() {
    int count(String level) =>
        _assessments.where((item) => item['risk_level'] == level).length;
    final lowConfidence = _assessments
        .where((item) => item['data_confidence'] == 'low')
        .length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 36) / 4;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _summaryItem(
              'Students analyzed',
              _assessments.length,
              const Color(0xFF2563EB),
              Icons.groups_outlined,
              width,
            ),
            _summaryItem(
              'High risk',
              count('High'),
              const Color(0xFFB91C1C),
              Icons.crisis_alert_outlined,
              width,
            ),
            _summaryItem(
              'Medium risk',
              count('Medium'),
              const Color(0xFFB45309),
              Icons.warning_amber_outlined,
              width,
            ),
            _summaryItem(
              'Low evidence',
              lowConfidence,
              const Color(0xFF6D28D9),
              Icons.data_usage_outlined,
              width,
            ),
          ],
        );
      },
    );
  }

  Widget _summaryItem(
    String label,
    int value,
    Color color,
    IconData icon,
    double width,
  ) =>
      Container(
        width: width.clamp(190, 320),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _filters() => Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search student, ID, or programme',
              ),
            ),
          ),
          const SizedBox(width: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'All', label: Text('All')),
              ButtonSegment(value: 'High', label: Text('High')),
              ButtonSegment(value: 'Medium', label: Text('Medium')),
              ButtonSegment(value: 'Low', label: Text('Low')),
            ],
            selected: {_filter},
            onSelectionChanged: (value) =>
                setState(() => _filter = value.first),
          ),
        ],
      );

  Widget _studentRisk(Map<String, dynamic> item) {
    final level = item['risk_level']?.toString() ?? 'Low';
    final color = level == 'High'
        ? const Color(0xFFB91C1C)
        : level == 'Medium'
        ? const Color(0xFFB45309)
        : level == 'Insufficient Data'
        ? const Color(0xFF64748B)
        : const Color(0xFF0F766E);
    final confidence = item['data_confidence']?.toString() ?? 'low';
    final hasPrediction = item['dropout_probability'] != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Text(
                  (item['student_name']?.toString() ?? '?')
                      .substring(0, 1)
                      .toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['student_name']?.toString() ?? 'Student',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${item['uni_id']}  |  ${item['programme']}',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              _badge(
                level == 'Insufficient Data' ? 'Insufficient data' : '$level risk',
                color,
              ),
              const SizedBox(width: 8),
              Text(
                hasPrediction
                    ? '${(item['risk_score'] as num? ?? 0).toStringAsFixed(1)} / 100'
                    : 'Not scored',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _signal(
                'Performance',
                item['predicted_performance']?.toString() ?? 'Not available',
                Icons.trending_up_outlined,
              ),
              _signal(
                'Dropout likelihood',
                hasPrediction
                    ? '${(item['dropout_probability'] as num).toStringAsFixed(1)}%'
                    : 'Not available',
                Icons.person_off_outlined,
              ),
              _signal(
                'Attendance',
                _percentage(item['attendance_percentage']),
                Icons.fact_check_outlined,
              ),
              _signal(
                'Academic',
                _percentage(item['academic_percentage']),
                Icons.school_outlined,
              ),
              _signal(
                'Engagement',
                _percentage(item['engagement_percentage']),
                Icons.bolt_outlined,
              ),
              _signal(
                'Outstanding',
                'INR ${(item['outstanding_fees'] as num? ?? 0).toStringAsFixed(0)}',
                Icons.account_balance_wallet_outlined,
              ),
              _signal(
                'Evidence',
                '${item['attendance_records']} attendance / ${item['result_count']} results',
                Icons.dataset_outlined,
              ),
              _signal(
                'Confidence',
                confidence.toUpperCase(),
                Icons.verified_outlined,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item['explanation']?.toString() ?? '',
            style: const TextStyle(color: Color(0xFF475569)),
          ),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: Color(0xFF6D28D9),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  item['recommended_action']?.toString() ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4C1D95),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _percentage(dynamic value) => value == null
      ? 'Not available'
      : '${(value as num).toStringAsFixed(1)}%';

  Widget _signal(String label, String value, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              '$label: ',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
        ),
      );

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );

  Widget _emptyView() => Container(
        padding: const EdgeInsets.all(44),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.auto_graph_outlined,
              size: 42,
              color: Color(0xFF64748B),
            ),
            SizedBox(height: 10),
            Text(
              'No matching predictions. Run prediction after attendance or results have been recorded.',
            ),
          ],
        ),
      );

  Widget _errorView() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 42,
              color: Color(0xFFB91C1C),
            ),
            const SizedBox(height: 10),
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
}

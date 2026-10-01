import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';
import 'admin_operation_dialogs.dart';

class AdminCertificatesScreen extends StatefulWidget {
  const AdminCertificatesScreen({super.key});

  @override
  State<AdminCertificatesScreen> createState() =>
      _AdminCertificatesScreenState();
}

class _AdminCertificatesScreenState extends State<AdminCertificatesScreen> {
  Map<String, dynamic> _data = const {};
  bool _loading = true;
  String? _error;
  int _tab = 0;
  String _requestFilter = 'all';

  Map<String, dynamic> get _metrics => _map(_data['metrics']);
  List<Map<String, dynamic>> get _requests => _list(_data['requests']);
  List<Map<String, dynamic>> get _certificates => _list(_data['certificates']);

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
      final data = await UniSphereApiService.getAdminCertificateOverview();
      if (mounted) {
        setState(() => _data = data);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load certificate administration.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _review(Map<String, dynamic> request, String action) async {
    String? remarks;
    if (action == 'approved' || action == 'rejected') {
      final values = await showAdminForm(
        context,
        title: action == 'approved' ? 'Approve request' : 'Reject request',
        labels: [
          action == 'approved' ? 'Remarks (optional)' : 'Rejection reason',
        ],
      );
      if (values == null) return;
      remarks = values[0].isEmpty ? null : values[0];
    }
    await _run(
      () => UniSphereApiService.reviewCertificateRequest(
        requestId: request['id'] as int,
        action: action,
        remarks: remarks,
      ),
      action == 'rejected' ? 'Request rejected.' : 'Request updated.',
    );
  }

  Future<void> _issue(Map<String, dynamic> request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Issue certificate'),
        content: Text(
          'Issue ${_text(request['certificate_type_label'])} to ${_text(request['student_name'])}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.workspace_premium_outlined),
            label: const Text('Issue'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(
      () => UniSphereApiService.issueCertificate(request['id'] as int),
      'Certificate issued successfully.',
    );
  }

  Future<void> _revoke(Map<String, dynamic> certificate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revoke certificate'),
        content: Text(
          'Revoke ${_text(certificate['certificate_id'])}? Verification will mark it invalid.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFBE123C),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(
      () => UniSphereApiService.revokeCertificate(certificate['id'] as int),
      'Certificate revoked.',
    );
  }

  Future<void> _run(
    Future<dynamic> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7FA),
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(28),
          children: [
            _header(),
            const SizedBox(height: 22),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _empty(
                Icons.error_outline_rounded,
                'Certificate data unavailable',
                _error!,
              )
            else ...[
              _metricBand(),
              const SizedBox(height: 20),
              _tabs(),
              const SizedBox(height: 20),
              if (_tab == 0) _requestView() else _issuedView(),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _header() => Row(
    children: [
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Certificate Operations',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172554),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Review, approve, issue and verify student certificates',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Refresh',
        onPressed: _loading ? null : _load,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
  );

  Widget _metricBand() => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      _metric(
        'Requests',
        _metrics['total_requests'],
        Icons.description_outlined,
        const Color(0xFF1D4ED8),
      ),
      _metric(
        'Pending review',
        _metrics['pending_review'],
        Icons.pending_actions_outlined,
        const Color(0xFFD97706),
      ),
      _metric(
        'Ready to issue',
        _metrics['approved'],
        Icons.approval_outlined,
        const Color(0xFF7C3AED),
      ),
      _metric(
        'Valid',
        _metrics['valid'],
        Icons.verified_outlined,
        const Color(0xFF047857),
      ),
      _metric(
        'Revoked',
        _metrics['revoked'],
        Icons.gpp_bad_outlined,
        const Color(0xFFBE123C),
      ),
    ],
  );

  Widget _metric(
    String label,
    dynamic value,
    IconData icon,
    Color color,
  ) => Container(
    width: 178,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _text(value, '0'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _tabs() => SegmentedButton<int>(
    segments: const [
      ButtonSegment(
        value: 0,
        icon: Icon(Icons.pending_actions_outlined),
        label: Text('Requests'),
      ),
      ButtonSegment(
        value: 1,
        icon: Icon(Icons.workspace_premium_outlined),
        label: Text('Issued certificates'),
      ),
    ],
    selected: {_tab},
    onSelectionChanged: (value) => setState(() => _tab = value.first),
  );

  Widget _requestView() {
    final visible = _requestFilter == 'all'
        ? _requests
        : _requests.where((item) => item['status'] == _requestFilter).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 8,
            children: [
              for (final filter in const [
                'all',
                'submitted',
                'under_review',
                'approved',
                'issued',
                'rejected',
              ])
                ChoiceChip(
                  label: Text(filter.replaceAll('_', ' ')),
                  selected: _requestFilter == filter,
                  onSelected: (_) => setState(() => _requestFilter = filter),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          _empty(
            Icons.pending_actions_outlined,
            'No matching requests',
            'Certificate requests will appear here.',
          )
        else
          ...visible.map(_requestCard),
      ],
    );
  }

  Widget _requestCard(Map<String, dynamic> item) {
    final status = _text(item['status']);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE0F2FE),
            foregroundColor: Color(0xFF0369A1),
            child: Icon(Icons.person_outline_rounded),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _text(item['student_name']),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _status(status.replaceAll('_', ' '), _statusColor(status)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${_text(item['student_uni_id'])} | ${_text(item['student_programme'])}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const Divider(height: 24),
                Text(
                  _text(item['certificate_type_label']),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_text(item['request_number'])} | ${_date(item['requested_at'])}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Text('Purpose: ${_text(item['purpose'])}'),
                if (item['rejection_reason'] != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    'Rejection reason: ${_text(item['rejection_reason'])}',
                    style: const TextStyle(
                      color: Color(0xFFBE123C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _requestActions(item, status),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _requestActions(Map<String, dynamic> item, String status) {
    if (status == 'submitted') {
      return [
        OutlinedButton.icon(
          onPressed: () => _review(item, 'under_review'),
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Start review'),
        ),
        FilledButton.tonalIcon(
          onPressed: () => _review(item, 'approved'),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Approve'),
        ),
        TextButton.icon(
          onPressed: () => _review(item, 'rejected'),
          icon: const Icon(Icons.close_rounded),
          label: const Text('Reject'),
        ),
      ];
    }
    if (status == 'under_review') {
      return [
        FilledButton.tonalIcon(
          onPressed: () => _review(item, 'approved'),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Approve'),
        ),
        TextButton.icon(
          onPressed: () => _review(item, 'rejected'),
          icon: const Icon(Icons.close_rounded),
          label: const Text('Reject'),
        ),
      ];
    }
    if (status == 'approved') {
      return [
        FilledButton.icon(
          onPressed: () => _issue(item),
          icon: const Icon(Icons.workspace_premium_outlined),
          label: const Text('Issue certificate'),
        ),
      ];
    }
    return const [];
  }

  Widget _issuedView() => _certificates.isEmpty
      ? _empty(
          Icons.workspace_premium_outlined,
          'No certificates issued',
          'Approved certificate requests can be issued from the Requests tab.',
        )
      : Column(children: _certificates.map(_issuedCard).toList());

  Widget _issuedCard(Map<String, dynamic> item) {
    final valid = item['status'] == 'Valid';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: valid
                ? const Color(0xFFDCFCE7)
                : const Color(0xFFFFE4E6),
            foregroundColor: valid
                ? const Color(0xFF047857)
                : const Color(0xFFBE123C),
            child: Icon(
              valid ? Icons.verified_outlined : Icons.gpp_bad_outlined,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(item['certificate_type_label']),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_text(item['student_name'])} | ${_text(item['student_uni_id'])}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_text(item['certificate_id'])} | Issued ${_text(item['issue_date'])}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _status(
                _text(item['status']),
                valid ? const Color(0xFF047857) : const Color(0xFFBE123C),
              ),
              if (valid) ...[
                const SizedBox(height: 7),
                TextButton.icon(
                  onPressed: () => _revoke(item),
                  icon: const Icon(Icons.block_outlined),
                  label: const Text('Revoke'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _status(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
    ),
  );

  Color _statusColor(String status) => switch (status) {
    'issued' || 'approved' => const Color(0xFF047857),
    'rejected' || 'cancelled' => const Color(0xFFBE123C),
    'under_review' => const Color(0xFF1D4ED8),
    _ => const Color(0xFFD97706),
  };

  Widget _empty(IconData icon, String title, String message) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 34, color: const Color(0xFF0F766E)),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(message, style: const TextStyle(color: Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    ),
  );

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  List<Map<String, dynamic>> _list(dynamic value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : <Map<String, dynamic>>[];

  String _text(dynamic value, [String fallback = '-']) =>
      value == null || value.toString().trim().isEmpty
      ? fallback
      : value.toString();

  String _date(dynamic value) {
    final text = _text(value);
    return text == '-' ? text : text.split('T').first;
  }
}

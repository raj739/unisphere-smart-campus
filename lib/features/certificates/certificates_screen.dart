import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  List<Map<String, dynamic>> _certificates = const [];
  List<Map<String, dynamic>> _requests = const [];
  List<Map<String, dynamic>> _types = const [];
  Map<String, dynamic>? _verification;
  bool _loading = true;
  bool _verifying = false;
  String? _error;
  int _tab = 0;

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
      final results = await Future.wait([
        UniSphereApiService.getCertificates(),
        UniSphereApiService.getMyCertificateRequests(),
        UniSphereApiService.getCertificateTypes(),
      ]);
      if (!mounted) return;
      setState(() {
        _certificates = results[0];
        _requests = results[1];
        _types = results[2];
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load certificates.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestCertificate() async {
    final result = await showDialog<_CertificateRequestValues>(
      context: context,
      builder: (_) => _CertificateRequestDialog(types: _types),
    );
    if (!mounted || result == null) return;
    await _run(
      () => UniSphereApiService.requestCertificate(
        certificateType: result.type,
        purpose: result.purpose,
      ),
      'Certificate request submitted.',
    );
  }

  Future<void> _cancelRequest(int requestId) async {
    await _run(
      () => UniSphereApiService.cancelCertificateRequest(requestId),
      'Certificate request cancelled.',
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

  Future<void> _download(Map<String, dynamic> certificate) async {
    try {
      final bytes = await UniSphereApiService.downloadCertificatePdf(
        certificate['id'] as int,
      );
      final directory =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}${Platform.pathSeparator}${certificate['certificate_id']}.pdf',
      );
      await file.writeAsBytes(bytes, flush: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Certificate saved to ${file.path}')),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to save certificate: $error')),
        );
      }
    }
  }

  Future<void> _verify(String number) async {
    if (number.trim().isEmpty) return;
    setState(() {
      _verifying = true;
      _verification = null;
    });
    try {
      final result = await UniSphereApiService.verifyCertificate(number.trim());
      if (mounted) setState(() => _verification = result);
    } on ApiException catch (error) {
      if (mounted) {
        setState(
          () => _verification = {'valid': false, 'error': error.message},
        );
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(width < 700 ? 18 : 30),
            children: [
              _header(width < 650),
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
                  'Certificates unavailable',
                  _error!,
                )
              else ...[
                _summary(),
                const SizedBox(height: 20),
                _tabs(),
                const SizedBox(height: 20),
                _content(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(bool compact) => Wrap(
    spacing: 12,
    runSpacing: 14,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      SizedBox(
        width: compact ? double.infinity : 520,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digital Certificates',
              style: TextStyle(
                fontSize: 28,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172554),
              ),
            ),
            SizedBox(height: 7),
            Text(
              'Request, track, download and verify university certificates',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Refresh certificates',
        onPressed: _loading ? null : _load,
        icon: const Icon(Icons.refresh_rounded),
      ),
      FilledButton.icon(
        onPressed: _types.isEmpty ? null : _requestCertificate,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Request certificate'),
      ),
    ],
  );

  Widget _summary() {
    final activeRequests = _requests
        .where(
          (item) => {
            'submitted',
            'under_review',
            'approved',
          }.contains(item['status']),
        )
        .length;
    final valid = _certificates
        .where((item) => item['status'] == 'Valid')
        .length;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _metric(
          'Issued',
          _certificates.length,
          Icons.workspace_premium_outlined,
          const Color(0xFF1D4ED8),
        ),
        _metric(
          'Valid',
          valid,
          Icons.verified_outlined,
          const Color(0xFF047857),
        ),
        _metric(
          'Active requests',
          activeRequests,
          Icons.pending_actions_outlined,
          const Color(0xFFD97706),
        ),
      ],
    );
  }

  Widget _metric(
    String label,
    int value,
    IconData icon,
    Color color,
  ) => Container(
    width: 190,
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
              '$value',
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

  Widget _tabs() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SegmentedButton<int>(
      segments: const [
        ButtonSegment(
          value: 0,
          icon: Icon(Icons.workspace_premium_outlined),
          label: Text('My certificates'),
        ),
        ButtonSegment(
          value: 1,
          icon: Icon(Icons.pending_actions_outlined),
          label: Text('My requests'),
        ),
        ButtonSegment(
          value: 2,
          icon: Icon(Icons.qr_code_scanner_outlined),
          label: Text('Verify'),
        ),
      ],
      selected: {_tab},
      onSelectionChanged: (value) => setState(() => _tab = value.first),
    ),
  );

  Widget _content() => switch (_tab) {
    0 => _certificateList(),
    1 => _requestList(),
    _ => _verificationPanel(),
  };

  Widget _certificateList() => _certificates.isEmpty
      ? _empty(
          Icons.workspace_premium_outlined,
          'No issued certificates',
          'Approved and issued certificates will appear here.',
        )
      : Column(children: _certificates.map(_certificateCard).toList());

  Widget _certificateCard(Map<String, dynamic> item) {
    final valid = item['status'] == 'Valid';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 92,
            height: 92,
            padding: const EdgeInsets.all(6),
            color: Colors.white,
            child: QrImageView(
              data: _text(item['verification_url']),
              version: QrVersions.auto,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _text(
                          item['certificate_type_label'],
                          item['title']?.toString() ?? 'Certificate',
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF172554),
                        ),
                      ),
                    ),
                    _status(
                      item['status'],
                      valid ? const Color(0xFF047857) : const Color(0xFFBE123C),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _text(item['student_name']),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_text(item['student_uni_id'])} | ${_text(item['student_programme'])}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_text(item['certificate_id'])} | Issued ${_text(item['issue_date'])}',
                  style: const TextStyle(color: Color(0xFF475569)),
                ),
                const SizedBox(height: 14),
                FilledButton.tonalIcon(
                  onPressed: valid ? () => _download(item) : null,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Download PDF'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestList() => _requests.isEmpty
      ? _empty(
          Icons.pending_actions_outlined,
          'No certificate requests',
          'Use Request certificate to submit your first request.',
        )
      : Column(children: _requests.map((item) => _requestCard(item)).toList());

  Widget _requestCard(Map<String, dynamic> item) {
    final status = _text(item['status']);
    final canCancel = status == 'submitted' || status == 'under_review';
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
            child: Icon(Icons.description_outlined),
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
                const SizedBox(height: 4),
                Text(
                  '${_text(item['request_number'])} | ${_date(item['requested_at'])}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Text(_text(item['purpose'])),
                if (item['rejection_reason'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Reason: ${_text(item['rejection_reason'])}',
                    style: const TextStyle(
                      color: Color(0xFFBE123C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _status(status.replaceAll('_', ' '), _statusColor(status)),
              if (canCancel) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _cancelRequest(item['id'] as int),
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _verificationPanel() => _VerificationPanel(
    loading: _verifying,
    result: _verification,
    onVerify: _verify,
  );

  Widget _status(dynamic value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      _text(value),
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

  String _text(dynamic value, [String fallback = '-']) =>
      value == null || value.toString().trim().isEmpty
      ? fallback
      : value.toString();

  String _date(dynamic value) {
    final text = _text(value);
    return text == '-' ? text : text.split('T').first;
  }
}

class _CertificateRequestValues {
  const _CertificateRequestValues(this.type, this.purpose);
  final String type;
  final String purpose;
}

class _CertificateRequestDialog extends StatefulWidget {
  const _CertificateRequestDialog({required this.types});
  final List<Map<String, dynamic>> types;

  @override
  State<_CertificateRequestDialog> createState() =>
      _CertificateRequestDialogState();
}

class _CertificateRequestDialogState extends State<_CertificateRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _purpose = TextEditingController();
  String? _type;

  @override
  void dispose() {
    _purpose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Request certificate'),
    content: SizedBox(
      width: 520,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Certificate type',
                prefixIcon: Icon(Icons.workspace_premium_outlined),
                border: OutlineInputBorder(),
              ),
              items: widget.types
                  .map(
                    (item) => DropdownMenuItem(
                      value: item['code']?.toString(),
                      child: Text(item['label']?.toString() ?? '-'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _type = value),
              validator: (value) =>
                  value == null ? 'Select a certificate type' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _purpose,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Purpose',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().length < 5
                  ? 'Enter the purpose for this certificate'
                  : null,
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Delivery: Digital PDF',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: () {
          if (!(_formKey.currentState?.validate() ?? false)) return;
          Navigator.pop(
            context,
            _CertificateRequestValues(_type!, _purpose.text.trim()),
          );
        },
        icon: const Icon(Icons.send_outlined),
        label: const Text('Submit request'),
      ),
    ],
  );
}

class _VerificationPanel extends StatefulWidget {
  const _VerificationPanel({
    required this.loading,
    required this.result,
    required this.onVerify,
  });
  final bool loading;
  final Map<String, dynamic>? result;
  final ValueChanged<String> onVerify;

  @override
  State<_VerificationPanel> createState() => _VerificationPanelState();
}

class _VerificationPanelState extends State<_VerificationPanel> {
  final _number = TextEditingController();

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final valid = result?['valid'] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _number,
                  decoration: const InputDecoration(
                    labelText: 'Certificate number',
                    hintText: 'VU-BON-2026-XXXXXXXX',
                    prefixIcon: Icon(Icons.verified_user_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: widget.onVerify,
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: widget.loading
                    ? null
                    : () => widget.onVerify(_number.text),
                icon: widget.loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded),
                label: const Text('Verify'),
              ),
            ],
          ),
        ),
        if (result != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: valid ? const Color(0xFFF0FDF4) : const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: valid
                    ? const Color(0xFF86EFAC)
                    : const Color(0xFFFDA4AF),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  valid ? Icons.verified_rounded : Icons.gpp_bad_outlined,
                  size: 36,
                  color: valid
                      ? const Color(0xFF047857)
                      : const Color(0xFFBE123C),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        valid
                            ? 'Certificate is valid'
                            : 'Certificate could not be validated',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (result['error'] != null)
                        Text(result['error'].toString())
                      else ...[
                        Text(
                          '${result['certificate_type_label']} | ${result['certificate_id']}',
                        ),
                        Text(
                          '${result['student_name']} | ${result['student_uni_id']}',
                        ),
                        Text(
                          '${result['student_programme']} | Issued ${result['issue_date']}',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

class AdminDocumentsScreen extends StatefulWidget {
  const AdminDocumentsScreen({super.key});

  @override
  State<AdminDocumentsScreen> createState() => _AdminDocumentsScreenState();
}

class _AdminDocumentsScreenState extends State<AdminDocumentsScreen> {
  List<Map<String, dynamic>> _documents = const [];
  List<Map<String, dynamic>> _students = const [];
  String _query = '';
  String _status = 'all';
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
      final result = await Future.wait<dynamic>([
        UniSphereApiService.getAdminDocuments(),
        UniSphereApiService.getAdminStudents(),
      ]);
      if (!mounted) return;
      setState(() {
        _documents = List<Map<String, dynamic>>.from(result[0] as List);
        _students = (result[1] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load documents.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered => _documents.where((document) {
    final matchesStatus =
        _status == 'all' || document['status']?.toString() == _status;
    final needle = _query.trim().toLowerCase();
    final matchesQuery = needle.isEmpty ||
        [
          document['student_name'],
          document['uni_id'],
          document['document_number'],
          document['title'],
          document['document_type'],
        ].any((value) => value.toString().toLowerCase().contains(needle));
    return matchesStatus && matchesQuery;
  }).toList();

  Future<void> _issueDocument() async {
    if (_students.isEmpty) {
      _message('Register a student before issuing a document.');
      return;
    }
    final formKey = GlobalKey<FormState>();
    var studentId = _students.first['id'] as int;
    var documentType = 'student_id';
    final title = TextEditingController(text: 'University Student Identity');
    final issueDate = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    final validUntil = TextEditingController();
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Issue digital document'),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: studentId,
                      decoration: const InputDecoration(labelText: 'Student'),
                      items: _students
                          .map(
                            (student) => DropdownMenuItem(
                              value: student['id'] as int,
                              child: Text(
                                '${student['full_name']} (${student['uni_id']})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) => setDialogState(
                                () => studentId = value ?? studentId,
                              ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: documentType,
                      decoration:
                          const InputDecoration(labelText: 'Document type'),
                      items: const {
                        'student_id': 'Student ID',
                        'admit_card': 'Admit card',
                        'fee_receipt': 'Fee receipt',
                        'migration': 'Migration document',
                        'transfer_certificate': 'Transfer certificate',
                        'character_certificate': 'Character certificate',
                        'other': 'Other digital record',
                      }
                          .entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) => setDialogState(
                                () => documentType = value ?? documentType,
                              ),
                    ),
                    const SizedBox(height: 14),
                    _field(title, 'Title'),
                    const SizedBox(height: 14),
                    _field(issueDate, 'Issue date (YYYY-MM-DD)'),
                    const SizedBox(height: 14),
                    _field(
                      validUntil,
                      'Valid until (optional)',
                      required: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      try {
                        await UniSphereApiService.createDigitalDocument(
                          studentId: studentId,
                          documentType: documentType,
                          title: title.text.trim(),
                          issueDate: issueDate.text.trim(),
                          validUntil: validUntil.text.trim().isEmpty
                              ? null
                              : validUntil.text.trim(),
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        await _load();
                        _message('Digital document issued.');
                      } on ApiException catch (error) {
                        setDialogState(() => saving = false);
                        _message(error.message);
                      }
                    },
              icon: const Icon(Icons.verified_outlined),
              label: Text(saving ? 'Issuing...' : 'Issue'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    issueDate.dispose();
    validUntil.dispose();
  }

  Future<void> _changeStatus(Map<String, dynamic> document) async {
    final status = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 250, 24, 0),
      items: const [
        PopupMenuItem(value: 'active', child: Text('Mark active')),
        PopupMenuItem(value: 'revoked', child: Text('Revoke')),
        PopupMenuItem(value: 'expired', child: Text('Mark expired')),
      ],
    );
    if (status == null) return;
    try {
      await UniSphereApiService.updateDigitalDocumentStatus(
        documentId: document['id'] as int,
        status: status,
      );
      await _load();
      _message('Document status updated.');
    } on ApiException catch (error) {
      _message(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final issued = _documents.length;
    final active = _documents
        .where((item) => {'issued', 'active'}.contains(item['status']))
        .length;
    final revoked =
        _documents.where((item) => item['status'] == 'revoked').length;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _Header(
              onRefresh: _loading ? null : _load,
              onIssue: _loading ? null : _issueDocument,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Metric(label: 'Total issued', value: '$issued', color: const Color(0xFF2563EB)),
                _Metric(label: 'Valid records', value: '$active', color: const Color(0xFF059669)),
                _Metric(label: 'Revoked', value: '$revoked', color: const Color(0xFFDC2626)),
                _Metric(label: 'Students covered', value: '${_documents.map((e) => e['student_id']).toSet().length}', color: const Color(0xFF7C3AED)),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search student, number, title or type',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _status,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All statuses')),
                    DropdownMenuItem(value: 'issued', child: Text('Issued')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'revoked', child: Text('Revoked')),
                    DropdownMenuItem(value: 'expired', child: Text('Expired')),
                  ],
                  onChanged: (value) => setState(() => _status = value ?? 'all'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
            else if (_error != null)
              _ErrorState(message: _error!, onRetry: _load)
            else if (_filtered.isEmpty)
              const _EmptyState()
            else
              ..._filtered.map(_documentTile),
          ],
        ),
      ),
    );
  }

  Widget _documentTile(Map<String, dynamic> document) {
    final status = document['status']?.toString() ?? 'issued';
    final valid = status == 'issued' || status == 'active';
    return Container(
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
              color: valid ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(Icons.description_outlined, color: valid ? const Color(0xFF047857) : const Color(0xFFB91C1C)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(document['title']?.toString() ?? 'Digital document', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF172554))),
                const SizedBox(height: 4),
                Text('${document['student_name']}  |  ${document['uni_id']}  |  ${document['programme']}', style: const TextStyle(color: Color(0xFF475569))),
                const SizedBox(height: 3),
                Text('${document['document_number']}  |  Issued ${document['issue_date']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          _StatusBadge(status: status),
          IconButton(tooltip: 'Change status', onPressed: () => _changeStatus(document), icon: const Icon(Icons.more_vert)),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {bool required = true}) => TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: (value) => required && (value == null || value.trim().isEmpty) ? 'Required' : null,
      );

  void _message(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh, required this.onIssue});
  final VoidCallback? onRefresh;
  final VoidCallback? onIssue;

  @override
  Widget build(BuildContext context) => Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Digital Documents', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF172554))),
          SizedBox(height: 5),
          Text('Issue, trace and revoke verifiable student records.', style: TextStyle(color: Color(0xFF64748B))),
        ])),
        IconButton(tooltip: 'Refresh documents', onPressed: onRefresh, icon: const Icon(Icons.refresh)),
        const SizedBox(width: 6),
        FilledButton.icon(onPressed: onIssue, icon: const Icon(Icons.add), label: const Text('Issue document')),
      ]);
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 190,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [Container(width: 4, height: 42, color: color), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))])]),
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final valid = status == 'issued' || status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: valid ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: valid ? const Color(0xFF047857) : const Color(0xFFB91C1C))),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Padding(padding: EdgeInsets.all(48), child: Column(children: [Icon(Icons.folder_open_outlined, size: 44, color: Color(0xFF94A3B8)), SizedBox(height: 12), Text('No documents match this view.', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height: 4), Text('Issue a document or change the filters.', style: TextStyle(color: Color(0xFF64748B))) ]));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Column(children: [Text(message), const SizedBox(height: 10), FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry'))]));
}

import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  List<Map<String, dynamic>> _documents = const [];
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
      final documents = await UniSphereApiService.getKnowledgeDocuments();
      if (mounted) setState(() => _documents = documents);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load the knowledge base.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addDocument() async {
    final title = TextEditingController();
    final category = TextEditingController();
    final content = TextEditingController();
    final source = TextEditingController();
    final key = GlobalKey<FormState>();
    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Add verified knowledge'),
          content: SizedBox(
            width: 540,
            child: Form(
              key: key,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _field(title, 'Title'),
                  _field(category, 'Category'),
                  _field(content, 'Verified answer or policy text', maxLines: 5),
                  _field(source, 'Source (optional)'),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!key.currentState!.validate()) return;
                try {
                  await UniSphereApiService.createKnowledgeDocument(
                    title: title.text.trim(),
                    category: category.text.trim(),
                    content: content.text.trim(),
                    source: source.text.trim().isEmpty ? null : source.text.trim(),
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } on ApiException catch (error) {
                  if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(error.message)));
                }
              },
              child: const Text('Add to knowledge base'),
            ),
          ],
        ),
      );
      if (saved == true) await _load();
    } finally {
      title.dispose();
      category.dispose();
      content.dispose();
      source.dispose();
    }
  }

  Widget _field(TextEditingController controller, String label, {int maxLines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          validator: (value) => label.contains('optional') || (value?.trim().isNotEmpty ?? false) ? null : 'Required',
        ),
      );

  Future<void> _deactivate(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate knowledge entry?'),
        content: const Text('It will no longer be used to answer campus questions.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Deactivate')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await UniSphereApiService.deactivateKnowledgeDocument(id);
      await _load();
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(padding: const EdgeInsets.all(24), children: [
              Row(children: [
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('AI Knowledge Base', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('Verified campus information used by UniSphere AI.', style: TextStyle(color: Color(0xFF64748B)))])),
                IconButton(tooltip: 'Refresh', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
                FilledButton.icon(onPressed: _loading ? null : _addDocument, icon: const Icon(Icons.add), label: const Text('Add knowledge')),
              ]),
              const SizedBox(height: 20),
              if (_loading) const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
              else if (_error != null) Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 42), const SizedBox(height: 12), Text(_error!), const SizedBox(height: 12), FilledButton(onPressed: _load, child: const Text('Retry'))]))
              else if (_documents.isEmpty) const Padding(padding: EdgeInsets.all(48), child: Center(child: Text('No verified knowledge has been added yet.')))
              else ..._documents.map((document) {
                final active = document['is_active'] == 1 || document['is_active'] == true;
                return Card(child: ListTile(
                  title: Text(document['title']?.toString() ?? 'Knowledge entry'),
                  subtitle: Text('${document['category'] ?? '-'} | ${active ? 'Active' : 'Inactive'}\n${document['content'] ?? ''}', maxLines: 3, overflow: TextOverflow.ellipsis),
                  isThreeLine: true,
                  trailing: active && document['id'] is int ? IconButton(tooltip: 'Deactivate', onPressed: () => _deactivate(document['id'] as int), icon: const Icon(Icons.pause_circle_outline)) : null,
                ));
              }),
            ]),
          ),
        ),
      );
}

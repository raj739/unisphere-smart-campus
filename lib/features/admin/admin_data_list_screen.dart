import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';

class AdminDataListScreen extends StatefulWidget {
  const AdminDataListScreen({
    super.key,
    required this.title,
    required this.loader,
    this.unavailableReason,
  });

  final String title;
  final Future<List<Map<String, dynamic>>> Function()? loader;
  final String? unavailableReason;

  @override
  State<AdminDataListScreen> createState() => _AdminDataListScreenState();
}

class _AdminDataListScreenState extends State<AdminDataListScreen> {
  List<Map<String, dynamic>> _records = const [];
  String? _error;
  bool _loading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.loader == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final records = await widget.loader!();
      if (mounted) setState(() => _records = records);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load ${widget.title.toLowerCase()}.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered => _records.where((record) {
        final needle = _query.trim().toLowerCase();
        if (needle.isEmpty) return true;
        return record.values.any((value) => value.toString().toLowerCase().contains(needle));
      }).toList();

  @override
  Widget build(BuildContext context) {
    if (widget.loader == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 16),
              Text(widget.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(widget.unavailableReason ?? 'This module is not available from the current backend.', textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(padding: const EdgeInsets.all(24), children: [
            Row(children: [
              Expanded(child: Text(widget.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800))),
              IconButton(tooltip: 'Refresh', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
            ]),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search records', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (_error != null)
              Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, size: 42), const SizedBox(height: 12), Text(_error!), const SizedBox(height: 12),
                FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
              ]))
            else if (_filtered.isEmpty)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No records available.')))
            else
              ..._filtered.map((record) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 8,
                        children: record.entries.where((entry) => entry.value != null).map((entry) => SizedBox(
                          width: 180,
                          child: Text('${entry.key}: ${entry.value}', maxLines: 2, overflow: TextOverflow.ellipsis),
                        )).toList(),
                      ),
                    ),
                  )),
          ]),
        ),
      ),
    );
  }
}

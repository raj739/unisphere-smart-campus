import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

class HelpdeskScreen extends StatefulWidget {
  const HelpdeskScreen({super.key});

  @override
  State<HelpdeskScreen> createState() => _HelpdeskScreenState();
}

class _HelpdeskScreenState extends State<HelpdeskScreen> {
  List<Map<String, dynamic>> _tickets = const [];
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
      final tickets = await UniSphereApiService.getHelpdeskTickets();
      if (mounted) setState(() => _tickets = tickets.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList());
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load helpdesk requests.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showNewTicketDialog() async {
    final formKey = GlobalKey<FormState>();
    final subject = TextEditingController();
    final description = TextEditingController();
    String category = 'Academic';
    String priority = 'Medium';
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Helpdesk Request'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(controller: subject, decoration: const InputDecoration(labelText: 'Subject'), validator: _required),
                const SizedBox(height: 12),
                TextFormField(controller: description, maxLines: 4, decoration: const InputDecoration(labelText: 'Description'), validator: _required),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'Category'), items: const ['Academic', 'Fees', 'Hostel', 'Transport', 'Examination', 'Technical', 'Other'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: saving ? null : (value) => setDialogState(() => category = value ?? category)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(value: priority, decoration: const InputDecoration(labelText: 'Priority'), items: const ['Low', 'Medium', 'High'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: saving ? null : (value) => setDialogState(() => priority = value ?? priority)),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton.icon(
              onPressed: saving ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => saving = true);
                try {
                  await UniSphereApiService.createHelpdeskTicket(subject: subject.text.trim(), description: description.text.trim(), category: category, priority: priority);
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  await _load();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Helpdesk request submitted.')));
                } on ApiException catch (error) {
                  setDialogState(() => saving = false);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
                } catch (_) {
                  setDialogState(() => saving = false);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to submit the request.')));
                }
              },
              icon: const Icon(Icons.send),
              label: Text(saving ? 'Submitting...' : 'Submit request'),
            ),
          ],
        ),
      ),
    );
  }

  static String? _required(String? value) => value == null || value.trim().isEmpty ? 'This field is required' : null;

  @override
  Widget build(BuildContext context) {
    final open = _tickets.where((ticket) => ticket['status']?.toString().toLowerCase() != 'resolved' && ticket['status']?.toString().toLowerCase() != 'closed').length;
    final resolved = _tickets.where((ticket) => ticket['status']?.toString().toLowerCase() == 'resolved').length;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(28), children: [
          Row(children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Student Helpdesk', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Color(0xFF172554))), SizedBox(height: 8), Text('Raise requests and track service tickets.', style: TextStyle(color: Color(0xFF64748B)))])), IconButton(tooltip: 'Refresh', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)), FilledButton.icon(onPressed: _loading ? null : _showNewTicketDialog, icon: const Icon(Icons.add), label: const Text('New Request'))]),
          const SizedBox(height: 24),
          Wrap(spacing: 18, runSpacing: 18, children: [_stat('Open Tickets', '$open', Icons.pending_actions_outlined), _stat('Resolved', '$resolved', Icons.check_circle_outline), _stat('Total Requests', '${_tickets.length}', Icons.confirmation_number_outlined)]),
          const SizedBox(height: 28),
          if (_loading) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_error != null) _errorState()
          else if (_tickets.isEmpty) const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No helpdesk requests yet. Create one when you need support.')))
          else
                ..._tickets.map(
                  (ticket) => Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.support_agent_outlined,
                        color: Color(0xFF1D4ED8),
                      ),
                      title: Text(
                        ticket['subject']?.toString() ?? 'Helpdesk request',
                      ),
                      subtitle: Text(
                        '${ticket['ticket_number'] ?? '-'} | '
                        '${ticket['category'] ?? '-'} | '
                        '${ticket['created_date'] ?? '-'}',
                      ),
                      trailing: Text(ticket['status']?.toString() ?? '-'),
                    ),
                  ),
                ),
        ]),
      )),
    );
  }

  Widget _stat(String label, String value, IconData icon) => SizedBox(width: 210, child: Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [Icon(icon, color: const Color(0xFF1D4ED8)), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Color(0xFF64748B))), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))])]))));

  Widget _errorState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 42), const SizedBox(height: 12), Text(_error!), const SizedBox(height: 12), FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry'))]));
}


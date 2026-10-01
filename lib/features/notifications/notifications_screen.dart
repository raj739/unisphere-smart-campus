import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = const [];
  bool _loading = true;
  String? _error;

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
      final items = await UniSphereApiService.getMyNotifications();
      if (mounted) setState(() => _notifications = items);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load notifications.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    final id = item['id'];
    if (id is! int || item['is_read'] == true) return;
    try {
      await UniSphereApiService.markNotificationRead(id);
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(28),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notifications', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Color(0xFF172554))),
                        SizedBox(height: 8),
                        Text('Live university notifications and service updates.', style: TextStyle(color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
                ],
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
              else if (_error != null)
                Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [Text(_error!), const SizedBox(height: 12), FilledButton(onPressed: _load, child: const Text('Retry'))])))
              else if (_notifications.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(28), child: Center(child: Text('No notifications yet.'))))
              else
                ..._notifications.map(
                  (item) => Card(
                    color: item['is_read'] == true ? Colors.white : const Color(0xFFEFF6FF),
                    child: ListTile(
                      leading: Icon(item['is_read'] == true ? Icons.notifications_none : Icons.notifications_active, color: const Color(0xFF2563EB)),
                      title: Text(item['title']?.toString() ?? 'Notification', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('${item['message'] ?? ''}\n${item['created_at'] ?? ''}'),
                      ),
                      isThreeLine: true,
                      trailing: item['is_read'] == true ? null : TextButton(onPressed: () => _markRead(item), child: const Text('Mark read')),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

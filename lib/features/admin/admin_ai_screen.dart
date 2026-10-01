import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';
import 'knowledge_base_screen.dart';

class AdminAiScreen extends StatefulWidget {
  const AdminAiScreen({super.key});

  @override
  State<AdminAiScreen> createState() => _AdminAiScreenState();
}

class _AdminAiScreenState extends State<AdminAiScreen> {
  final _controller = TextEditingController();
  final List<_ChatEntry> _messages = [];
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _controller.text.trim();
    if (message.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatEntry(message, true));
      _controller.clear();
      _error = null;
      _sending = true;
    });

    try {
      final response = await UniSphereApiService.chatWithAI(message);
      if (mounted) {
        setState(() => _messages.add(
              _ChatEntry(response['answer']?.toString() ?? 'No response received.', false),
            ));
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'AI assistant is unavailable.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Row(children: [
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('University AI Assistant', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Ask about university operations, policy, and campus knowledge.', style: TextStyle(color: Color(0xFF64748B))),
                ])),
                IconButton(tooltip: 'Manage knowledge base', icon: const Icon(Icons.library_books_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KnowledgeBaseScreen()))),
              ]),
            ),
            Expanded(
              child: _messages.isEmpty
                  ? const Center(child: Text('Start a conversation with UniSphere AI.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final item = _messages[index];
                        return Align(
                          alignment: item.isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 620),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: item.isUser ? const Color(0xFF3730A3) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(item.message, style: TextStyle(color: item.isUser ? Colors.white : const Color(0xFF0F172A))),
                          ),
                        );
                      },
                    ),
            ),
            if (_error != null)
              Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C)))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(hintText: 'Ask UniSphere AI', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Send message',
                  onPressed: _sending ? null : _send,
                  icon: _sending ? const CircularProgressIndicator() : const Icon(Icons.send),
                ),
              ]),
            ),
          ]),
        ),
      );
}

class _ChatEntry {
  const _ChatEntry(this.message, this.isUser);

  final String message;
  final bool isUser;
}

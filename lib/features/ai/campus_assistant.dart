import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';
import '../../services/voice_service.dart';

class CampusAssistantButton extends StatelessWidget {
  const CampusAssistantButton({super.key});

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
        heroTag: 'campus-assistant',
        backgroundColor: const Color(0xFF4338CA),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.mic_none_rounded),
        label: const Text('Ask UniSphere'),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const _CampusAssistantSheet(),
        ),
      );
}

class _CampusAssistantSheet extends StatefulWidget {
  const _CampusAssistantSheet();

  @override
  State<_CampusAssistantSheet> createState() => _CampusAssistantSheetState();
}

class _CampusAssistantSheetState extends State<_CampusAssistantSheet> {
  final _voice = VoiceService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_AssistantMessage> _messages = [
    const _AssistantMessage(
      text: 'Hello! I am UniSphere Voice Assistant. Ask me about campus services in English or Hindi.',
      fromUser: false,
    ),
  ];

  bool _hindi = false;
  bool _listening = false;
  bool _sending = false;
  bool _speaking = false;
  String? _sessionId;

  String get _speechLocale => _hindi ? 'hi_IN' : 'en_IN';
  String get _ttsLocale => _hindi ? 'hi-IN' : 'en-IN';

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _voice.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _voice.stopListening();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final started = await _voice.startListening(
      localeId: _speechLocale,
      onResult: (text) {
        if (!mounted) return;
        setState(() {
          _input.text = text;
          _input.selection = TextSelection.collapsed(offset: text.length);
        });
      },
    );
    if (!mounted) return;
    setState(() => _listening = started);
    if (!started) _showMessage('Speech recognition is unavailable on this device. You can still type your question.');
  }

  Future<void> _send() async {
    final message = _input.text.trim();
    if (message.isEmpty || _sending) return;
    if (_listening) await _voice.stopListening();
    _input.clear();
    setState(() {
      _listening = false;
      _sending = true;
      _messages.add(_AssistantMessage(text: message, fromUser: true));
    });
    _scrollToEnd();
    try {
      final languageInstruction = _hindi
          ? 'Please reply in Hindi. User question: $message'
          : 'Please reply in English. User question: $message';
      final response = await UniSphereApiService.chatWithAI(
        languageInstruction,
        sessionId: _sessionId,
        language: _hindi ? 'hi' : 'en',
      );
      final answer = response['answer']?.toString();
      if (answer == null || answer.isEmpty) {
        throw ApiException(statusCode: 502, message: 'The AI service returned an empty response.');
      }
      if (!mounted) return;
      setState(() {
        _sessionId = response['session_id']?.toString() ?? _sessionId;
        _messages.add(_AssistantMessage(text: answer, fromUser: false));
      });
      _scrollToEnd();
      await _speak(answer);
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('UniSphere AI is temporarily unavailable. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _speak(String text) async {
    setState(() => _speaking = true);
    try {
      await _voice.speak(text, languageCode: _ttsLocale);
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    });
  }

  void _showMessage(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.76,
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(children: [
              const SizedBox(height: 10),
              Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(children: [
                  const CircleAvatar(backgroundColor: Color(0xFF4338CA), foregroundColor: Colors.white, child: Icon(Icons.smart_toy_outlined)),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('UniSphere Voice Assistant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF172554))), SizedBox(height: 2), Text('Campus help, powered by your secure account', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))])),
                  SegmentedButton<bool>(
                    segments: const [ButtonSegment(value: false, label: Text('EN')), ButtonSegment(value: true, label: Text('HI'))],
                    selected: {_hindi},
                    showSelectedIcon: false,
                    onSelectionChanged: _sending ? null : (value) => setState(() => _hindi = value.first),
                  ),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_sending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) return const Padding(padding: EdgeInsets.all(12), child: Align(alignment: Alignment.centerLeft, child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
                    final item = _messages[index];
                    return Align(
                      alignment: item.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 560),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(color: item.fromUser ? const Color(0xFF4338CA) : Colors.white, borderRadius: BorderRadius.circular(10)),
                        child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Flexible(child: Text(item.text, style: TextStyle(color: item.fromUser ? Colors.white : const Color(0xFF172554), height: 1.35))),
                          if (!item.fromUser) IconButton(tooltip: 'Speak response', onPressed: _speaking ? null : () => _speak(item.text), icon: const Icon(Icons.volume_up_outlined, size: 18)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
                decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
                child: Row(children: [
                  IconButton(tooltip: _listening ? 'Stop listening' : 'Speak your question', onPressed: _sending ? null : _toggleListening, icon: Icon(_listening ? Icons.stop_circle_outlined : Icons.mic_none_rounded, color: _listening ? Colors.red : const Color(0xFF4338CA))),
                  Expanded(child: TextField(controller: _input, textInputAction: TextInputAction.send, onSubmitted: (_) => _send(), decoration: const InputDecoration(hintText: 'Ask about your campus...', border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  IconButton(tooltip: 'Send', onPressed: _sending ? null : _send, icon: const Icon(Icons.send_rounded, color: Color(0xFF4338CA))),
                ]),
              ),
            ]),
          ),
        ),
      );
}

class _AssistantMessage {
  const _AssistantMessage({required this.text, required this.fromUser});

  final String text;
  final bool fromUser;
}

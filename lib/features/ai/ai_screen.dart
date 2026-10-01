import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unisphere_mobile/models/recommendation.dart';
import 'package:unisphere_mobile/services/unispher_api_service.dart';

import '../../core/network/api_exception.dart';
import '../../services/voice_service.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  // ---------------------------------------------------------------------------
  // SERVICES
  // ---------------------------------------------------------------------------

  final VoiceService _voiceService = VoiceService();

  // ---------------------------------------------------------------------------
  // CONTROLLERS
  // ---------------------------------------------------------------------------

  final TextEditingController _messageController = TextEditingController();

  final ScrollController _chatScrollController = ScrollController();

  // ---------------------------------------------------------------------------
  // UI STATE
  // ---------------------------------------------------------------------------

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _sendingMessage = false;
  bool _voiceTranscriptPending = false;
  String? _sessionId;
  String _language = 'auto';
  String _responseLanguage = 'en';
  List<String> _followUpSuggestions = const [];

  // ---------------------------------------------------------------------------
  // RECOMMENDATIONS
  // ---------------------------------------------------------------------------

  List<Recommendation> _recommendations = [];

  String _recommendationStatus = '';

  bool _loadingRecommendations = false;

  // ---------------------------------------------------------------------------
  // CHAT
  // ---------------------------------------------------------------------------

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: 'Hello! I am UniSphere AI. I can help with attendance, results, fees, timetable, certificates and university services.',
      isUser: false,
      source: 'assistant_capabilities',
    ),
  ];

  // ---------------------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _loadRecommendations();
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    _voiceService.dispose();

    super.dispose();
  }

  // ===========================================================================
  // RECOMMENDATIONS
  // ===========================================================================

  Future<void> _loadRecommendations() async {
    if (mounted) {
      setState(() {
        _loadingRecommendations = true;
      });
    }

    try {
      final data = await UniSphereApiService.getRecommendations();

      final items = (data['recommendations'] as List? ?? [])
          .map(
            (item) => Recommendation.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _recommendations = items;

        _recommendationStatus = data['overall_status']?.toString() ?? '';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _recommendations = [];
        _recommendationStatus = '';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingRecommendations = false;
        });
      }
    }
  }

  // ===========================================================================
  // VOICE INPUT
  // ===========================================================================

  Future<void> _startVoiceInput() async {
    if (_sendingMessage) return;

    setState(() {
      _isListening = true;
    });

    final started = await _voiceService.startListening(
      localeId: _language == 'hi' ? 'hi_IN' : 'en_IN',
      onResult: (text) {
        if (!mounted) return;

        setState(() {
          _messageController.text = text;
          _voiceTranscriptPending = text.trim().isNotEmpty;

          _messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: _messageController.text.length),
          );
        });
      },
    );

    if (!started && mounted) {
      setState(() {
        _isListening = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition is not available.')),
      );
    }
  }

  Future<void> _stopVoiceInput() async {
    await _voiceService.stopListening();

    if (!mounted) return;

    setState(() {
      _isListening = false;
    });
  }

  // ===========================================================================
  // TEXT TO SPEECH
  // ===========================================================================

  Future<void> _speakAIResponse(String text) async {
    if (text.trim().isEmpty) return;

    if (mounted) {
      setState(() {
        _isSpeaking = true;
      });
    }

    try {
      await _voiceService.speak(
        text,
        languageCode: _responseLanguage == 'hi' ? 'hi-IN' : 'en-IN',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    }
  }

  Future<void> _stopSpeaking() async {
    await _voiceService.stopSpeaking();

    if (!mounted) return;

    setState(() {
      _isSpeaking = false;
    });
  }

  // ===========================================================================
  // SEND MESSAGE
  // ===========================================================================

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    final isVoiceMessage = _voiceTranscriptPending;

    if (message.isEmpty || _sendingMessage) {
      return;
    }

    // Stop microphone if it is currently listening.
    if (_isListening) {
      await _stopVoiceInput();
    }

    // Stop previous TTS.
    if (_isSpeaking) {
      await _stopSpeaking();
    }

    // Clear input.
    _messageController.clear();
    _voiceTranscriptPending = false;

    setState(() {
      _messages.add(_ChatMessage(text: message, isUser: true));

      _sendingMessage = true;
    });

    _scrollToBottom();

    try {
      final response = isVoiceMessage
          ? await UniSphereApiService.voiceChat(
              transcript: message,
              sessionId: _sessionId,
              language: _language == 'auto' ? 'auto' : '${_language}-IN',
            )
          : await UniSphereApiService.chatWithAI(
              message,
              sessionId: _sessionId,
              language: _language,
            );

      final aiResponse =
          response['answer']?.toString() ??
          'I could not generate a response right now.';

      if (!mounted) return;

      setState(() {
        _sessionId = response['session_id']?.toString() ?? _sessionId;
        _responseLanguage =
            response['detected_language']?.toString() ?? _responseLanguage;
        _followUpSuggestions = (response['suggestions'] as List? ?? const [])
            .map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .toList();
        _messages.add(
          _ChatMessage(
            text: aiResponse,
            isUser: false,
            source: response['source']?.toString() ??
                (isVoiceMessage ? 'voice' : null),
          ),
        );
      });

      _scrollToBottom();

      if (isVoiceMessage) await _speakAIResponse(aiResponse);
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _messages.add(
          _ChatMessage(
            text: error.message,
            isUser: false,
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const _ChatMessage(
            text: 'UniSphere AI is temporarily unavailable. Please try again.',
            isUser: false,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _sendingMessage = false;
        });
      }

      _scrollToBottom();
    }
  }

  // ===========================================================================
  // QUICK QUESTIONS
  // ===========================================================================

  Future<void> _askQuickQuestion(String question) async {
    _messageController.text = question;

    await _sendMessage();
  }

  void _startNewChat() {
    if (_sendingMessage) return;
    setState(() {
      _sessionId = null;
      _followUpSuggestions = const [];
      _messages
        ..clear()
        ..add(
          const _ChatMessage(
            text: 'New conversation started. Ask me about any part of your student account.',
            isUser: false,
            source: 'assistant_capabilities',
          ),
        );
    });
  }

  // ===========================================================================
  // SCROLL
  // ===========================================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScrollController.hasClients) {
        return;
      }

      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 20),

              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _buildChatPanel()),

                    const SizedBox(width: 20),

                    Expanded(flex: 4, child: _buildRecommendationPanel()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF182A56),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
        ),

        const SizedBox(width: 14),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UniSphere AI',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF17213C),
                ),
              ),

              SizedBox(height: 3),

              Text(
                'Your intelligent university assistant',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),

        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'auto', label: Text('Auto')),
            ButtonSegment(value: 'en', label: Text('EN')),
            ButtonSegment(value: 'hi', label: Text('HI')),
          ],
          selected: {_language},
          showSelectedIcon: false,
          onSelectionChanged: _sendingMessage
              ? null
              : (selection) {
                  setState(() {
                    _language = selection.first;
                    if (_language != 'auto') _responseLanguage = _language;
                    _followUpSuggestions = const [];
                  });
                },
        ),

        const SizedBox(width: 10),

        OutlinedButton.icon(
          onPressed: _sendingMessage ? null : _startNewChat,
          icon: const Icon(Icons.add_comment_outlined),
          label: const Text('New chat'),
        ),

        const SizedBox(width: 10),

        IconButton.outlined(
          tooltip: 'Refresh insights',
          onPressed: _loadingRecommendations ? null : _loadRecommendations,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  // ===========================================================================
  // CHAT PANEL
  // ===========================================================================

  Widget _buildChatPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          // CHAT HEADER
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE9EBF1))),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, color: Color(0xFF182A56)),

                const SizedBox(width: 10),

                const Text(
                  'Ask UniSphere AI',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),

                const Spacer(),

                if (_isSpeaking)
                  TextButton.icon(
                    onPressed: _stopSpeaking,
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: const Text('Stop'),
                  ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7EF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'AI Online',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF187A42),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CHAT MESSAGES
          Expanded(
            child: ListView.builder(
              controller: _chatScrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_sendingMessage ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                final message = _messages[index];

                return _buildChatMessage(message);
              },
            ),
          ),

          // QUICK QUESTIONS
          _buildQuickQuestions(),

          // INPUT
          _buildInputArea(),
        ],
      ),
    );
  }

  // ===========================================================================
  // CHAT MESSAGE
  // ===========================================================================

  Widget _buildChatMessage(_ChatMessage message) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 650),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF182A56) : const Color(0xFFF1F3F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isUser ? Colors.white : const Color(0xFF242B3A),
              ),
            ),

            if (!isUser && message.source != null) ...[
              const SizedBox(height: 7),
              Text(
                _sourceLabel(message.source!),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ],

            // SPEAKER BUTTON
            if (!isUser) ...[
              const SizedBox(height: 8),

              Row(
                children: [
                  IconButton(
                    tooltip: 'Listen',
                    onPressed: () {
                      _speakAIResponse(message.text);
                    },
                    icon: Icon(
                      _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                      size: 18,
                    ),
                    color: const Color(0xFF182A56),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),

                  IconButton(
                    tooltip: 'Copy response',
                    onPressed: () => _copyMessage(message.text),
                    icon: const Icon(Icons.copy_outlined, size: 17),
                    color: const Color(0xFF182A56),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),

                  IconButton(
                    tooltip: 'Helpful response',
                    onPressed: () => _rateMessage(true),
                    icon: const Icon(Icons.thumb_up_outlined, size: 17),
                    color: const Color(0xFF182A56),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),

                  IconButton(
                    tooltip: 'Response needs improvement',
                    onPressed: () => _rateMessage(false),
                    icon: const Icon(Icons.thumb_down_outlined, size: 17),
                    color: const Color(0xFF182A56),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),

                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // QUICK QUESTIONS
  // ===========================================================================

  Widget _buildQuickQuestions() {
    final questions = _followUpSuggestions.isNotEmpty
        ? _followUpSuggestions
        : _language == 'hi'
        ? [
            'मेरी उपस्थिति दिखाएं',
            'मेरा परिणाम बताएं',
            'आज की समय-सारणी दिखाएं',
            'मेरी परीक्षा समय-सारणी दिखाएं',
            'मेरी बकाया फीस बताएं',
            'मेरा छात्रावास कमरा दिखाएं',
            'मेरी बस का विवरण दिखाएं',
            'परीक्षा की तैयारी कैसे करूं?',
          ]
        : [
            'Show my attendance',
            'What is my CGPA?',
            "What's my timetable today?",
            'Show my exam schedule',
            'What fees are outstanding?',
            'Show my hostel room',
            'Show my bus details',
            'How should I prepare for exams?',
          ];

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: questions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(questions[index]),
            onPressed: _sendingMessage
                ? null
                : () => _askQuickQuestion(questions[index]),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // INPUT AREA
  // ===========================================================================

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // TEXT INPUT
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !_sendingMessage,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Ask about your academics or university services...',
                filled: true,
                fillColor: const Color(0xFFF6F7FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // MICROPHONE
          SizedBox(
            height: 48,
            width: 48,
            child: IconButton(
              tooltip: _isListening ? 'Stop listening' : 'Voice input',
              onPressed: _sendingMessage
                  ? null
                  : () {
                      if (_isListening) {
                        _stopVoiceInput();
                      } else {
                        _startVoiceInput();
                      }
                    },
              style: IconButton.styleFrom(
                backgroundColor: _isListening
                    ? const Color(0xFFFFEEEE)
                    : const Color(0xFFF1F3F8),
                foregroundColor: _isListening
                    ? const Color(0xFFC62828)
                    : const Color(0xFF182A56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none_rounded),
            ),
          ),

          const SizedBox(width: 8),

          // SEND
          SizedBox(
            height: 48,
            width: 48,
            child: ElevatedButton(
              onPressed: _sendingMessage ? null : _sendMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF182A56),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              child: _sendingMessage
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // RECOMMENDATION PANEL
  // ===========================================================================

  Widget _buildRecommendationPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.insights_outlined, color: Color(0xFF182A56)),

                const SizedBox(width: 10),

                const Expanded(
                  child: Text(
                    'Personalized Insights',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(child: _buildRecommendationContent()),
        ],
      ),
    );
  }

  // ===========================================================================
  // RECOMMENDATION CONTENT
  // ===========================================================================

  Widget _buildRecommendationContent() {
    if (_loadingRecommendations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recommendations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No additional recommendations are available right now.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.5),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_recommendationStatus.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.assessment_outlined, size: 20),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    _recommendationStatus,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

        ..._recommendations.map(_buildRecommendationItem),
      ],
    );
  }

  // ===========================================================================
  // RECOMMENDATION ITEM
  // ===========================================================================

  Widget _buildRecommendationItem(Recommendation item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE4E6EC)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              _priorityBadge(item.priority),
            ],
          ),

          const SizedBox(height: 9),

          Text(
            item.message,
            style: const TextStyle(fontSize: 13, height: 1.45),
          ),

          const SizedBox(height: 12),

          const Text(
            'Recommended action',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 4),

          Text(item.action, style: const TextStyle(fontSize: 12, height: 1.4)),

          const SizedBox(height: 10),

          const Text(
            'Why',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            item.reason,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PRIORITY BADGE
  // ===========================================================================

  Widget _priorityBadge(String priority) {
    final isHigh = priority.toLowerCase() == 'high';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isHigh ? const Color(0xFFFFEEEE) : const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isHigh ? const Color(0xFFC62828) : const Color(0xFF9A6500),
        ),
      ),
    );
  }

  String _sourceLabel(String source) {
    switch (source) {
      case 'live_student_record':
        return 'LIVE STUDENT RECORD';
      case 'verified_knowledge':
        return 'APPROVED CAMPUS GUIDANCE';
      case 'assistant_capabilities':
        return 'UNISPHERE ASSISTANT';
      case 'safe_fallback':
        return 'SAFE RESPONSE';
      case 'general_information':
        return 'GENERAL STUDENT GUIDANCE';
      case 'voice':
        return 'VOICE ASSISTANT';
      default:
        return 'UNISPHERE AI';
    }
  }

  Widget _buildTypingIndicator() => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 9),
          Text('Checking your records...'),
        ],
      ),
    ),
  );

  Future<void> _copyMessage(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Response copied.')),
    );
  }

  void _rateMessage(bool helpful) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          helpful
              ? 'Thanks. This response was marked helpful.'
              : 'Thanks. This response was marked for improvement.',
        ),
      ),
    );
  }
}

// =============================================================================
// CHAT MESSAGE MODEL
// =============================================================================

class _ChatMessage {
  final String text;
  final bool isUser;
  final String? source;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.source,
  });
}

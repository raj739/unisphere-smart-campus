import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'realtime_event.dart';

class RealtimeMessage {
  final String event;
  final String channel;
  final Map<String, dynamic> data;

  RealtimeMessage({
    required this.event,
    required this.channel,
    required this.data,
  });

  factory RealtimeMessage.fromJson(Map<String, dynamic> json) {
    return RealtimeMessage(
      event: json['event'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : <String, dynamic>{},
    );
  }
}

class RealtimeService {
  WebSocket? _socket;

  StreamSubscription<dynamic>? _subscription;

  final StreamController<RealtimeMessage> _messageController =
      StreamController<RealtimeMessage>.broadcast();

  final StreamController<RealtimeEvent> _eventController =
      StreamController<RealtimeEvent>.broadcast();

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<RealtimeMessage> get messages => _messageController.stream;

  Stream<RealtimeEvent> get events => _eventController.stream;

  Stream<bool> get connectionState => _connectionController.stream;

  bool get isConnected => _socket != null;

  Future<void> connect({
    required String baseUrl,
    required String channel,
  }) async {
    await disconnect();

    final normalizedBase = baseUrl
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'/$'), '');

    final scheme = baseUrl.startsWith('https://') ? 'wss' : 'ws';

    final uri = Uri.parse(
      '$scheme://$normalizedBase/api/v1/realtime/ws/$channel',
    );

    _socket = await WebSocket.connect(uri.toString());

    _connectionController.add(true);

    _subscription = _socket!.listen(
      (message) {
        try {
          final decoded = jsonDecode(message.toString());

          if (decoded is Map<String, dynamic>) {
            _messageController.add(RealtimeMessage.fromJson(decoded));
          }
        } catch (_) {
          // Ignore malformed realtime payloads.
        }
      },
      onDone: () {
        _socket = null;
        _connectionController.add(false);
      },
      onError: (_) {
        _socket = null;
        _connectionController.add(false);
      },
      cancelOnError: false,
    );

    send(event: 'subscribe', data: {'channel': channel});
  }

  void send({required String event, Map<String, dynamic> data = const {}}) {
    final socket = _socket;

    if (socket == null) {
      return;
    }

    socket.add(jsonEncode({'event': event, 'data': data}));
  }

  void ping() {
    send(event: 'ping');
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;

    await _socket?.close();
    _socket = null;

    if (!_connectionController.isClosed) {
      _connectionController.add(false);
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _messageController.close();
    await _eventController.close();
    await _connectionController.close();
  }
}

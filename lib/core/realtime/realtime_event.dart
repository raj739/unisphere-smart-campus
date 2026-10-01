class RealtimeEvent {
  final String event;
  final String channel;
  final Map<String, dynamic> data;
  final DateTime? timestamp;

  RealtimeEvent({
    required this.event,
    required this.channel,
    required this.data,
    this.timestamp,
  });

  factory RealtimeEvent.fromMessage(
    String event,
    String channel,
    Map<String, dynamic> data,
  ) {
    return RealtimeEvent(
      event: event,
      channel: channel,
      data: data,
      timestamp: data['timestamp'] != null
          ? DateTime.tryParse(data['timestamp'].toString())
          : null,
    );
  }
}

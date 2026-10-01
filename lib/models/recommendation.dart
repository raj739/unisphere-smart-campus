class Recommendation {
  final String type;
  final String priority;
  final String title;
  final String message;
  final String action;
  final String reason;

  Recommendation({
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    required this.action,
    required this.reason,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      type: json['type']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
    );
  }
}

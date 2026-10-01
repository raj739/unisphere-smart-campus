class EarlyWarning {
  final int id;
  final int studentId;
  final int? riskAssessmentId;
  final String warningType;
  final String severity;
  final String title;
  final String message;
  final String? triggerValue;
  final String? thresholdValue;
  final String recommendedAction;
  final String status;

  const EarlyWarning({
    required this.id,
    required this.studentId,
    required this.riskAssessmentId,
    required this.warningType,
    required this.severity,
    required this.title,
    required this.message,
    required this.triggerValue,
    required this.thresholdValue,
    required this.recommendedAction,
    required this.status,
  });

  factory EarlyWarning.fromJson(Map<String, dynamic> json) {
    return EarlyWarning(
      id: json['id'] as int,
      studentId: json['student_id'] as int,
      riskAssessmentId: json['risk_assessment_id'] as int?,
      warningType: json['warning_type'] as String,
      severity: json['severity'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      triggerValue: json['trigger_value'] as String?,
      thresholdValue: json['threshold_value'] as String?,
      recommendedAction: json['recommended_action'] as String,
      status: json['status'] as String,
    );
  }
}

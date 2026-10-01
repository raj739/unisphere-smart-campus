class RiskAssessment {
  final int id;
  final int studentId;
  final double riskScore;
  final String riskLevel;
  final double attendanceScore;
  final double academicScore;
  final double feeScore;
  final double engagementScore;
  final String explanation;
  final String recommendedAction;

  const RiskAssessment({
    required this.id,
    required this.studentId,
    required this.riskScore,
    required this.riskLevel,
    required this.attendanceScore,
    required this.academicScore,
    required this.feeScore,
    required this.engagementScore,
    required this.explanation,
    required this.recommendedAction,
  });

  factory RiskAssessment.fromJson(Map<String, dynamic> json) {
    return RiskAssessment(
      id: json['id'] as int,
      studentId: json['student_id'] as int,
      riskScore: (json['risk_score'] as num).toDouble(),
      riskLevel: json['risk_level'] as String,
      attendanceScore: (json['attendance_score'] as num).toDouble(),
      academicScore: (json['academic_score'] as num).toDouble(),
      feeScore: (json['fee_score'] as num).toDouble(),
      engagementScore: (json['engagement_score'] as num).toDouble(),
      explanation: json['explanation'] as String,
      recommendedAction: json['recommended_action'] as String,
    );
  }
}

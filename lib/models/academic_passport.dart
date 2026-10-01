class AcademicPassport {
  final int id;
  final String passportNumber;
  final String verificationToken;
  final String fullName;
  final String uniId;
  final String? programme;
  final int? currentSemester;
  final String? academicSession;
  final String status;
  final String summary;
  final bool isVerified;

  const AcademicPassport({
    required this.id,
    required this.passportNumber,
    required this.verificationToken,
    required this.fullName,
    required this.uniId,
    required this.programme,
    required this.currentSemester,
    required this.academicSession,
    required this.status,
    required this.summary,
    required this.isVerified,
  });

  factory AcademicPassport.fromJson(Map<String, dynamic> json) {
    return AcademicPassport(
      id: json['id'] as int,
      passportNumber: json['passport_number'] as String,
      verificationToken: json['verification_token'] as String,
      fullName: json['full_name'] as String,
      uniId: json['uni_id'] as String,
      programme: json['programme'] as String?,
      currentSemester: json['current_semester'] as int?,
      academicSession: json['academic_session'] as String?,
      status: json['status'] as String,
      summary: json['summary'] as String,
      isVerified: json['is_verified'] as bool,
    );
  }
}

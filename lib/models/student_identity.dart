class StudentIdentity {
  const StudentIdentity({
    required this.studentId,
    required this.userId,
    required this.uniId,
    required this.fullName,
    required this.email,
    required this.programme,
    required this.currentSemester,
    required this.departmentId,
    required this.role,
    required this.isActive,
    this.universityId,
    this.enrollmentNumber,
    this.academicSession,
  });

  final int studentId;
  final int userId;
  final String uniId;
  final String fullName;
  final String email;
  final String? universityId;
  final String? enrollmentNumber;
  final String programme;
  final int currentSemester;
  final String? academicSession;
  final int departmentId;
  final String role;
  final bool isActive;

  factory StudentIdentity.fromJson(Map<String, dynamic> json) {
    return StudentIdentity(
      studentId: (json['student_id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      uniId: json['uni_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      universityId: json['university_id']?.toString(),
      enrollmentNumber: json['enrollment_number']?.toString(),
      programme: json['programme']?.toString() ?? '',
      currentSemester: (json['current_semester'] as num?)?.toInt() ?? 0,
      academicSession: json['academic_session']?.toString(),
      departmentId: (json['department_id'] as num?)?.toInt() ?? 0,
      role: json['role']?.toString() ?? 'student',
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '--';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get academicLabel => '$programme | Semester $currentSemester';
}

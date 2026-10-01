class StudentLifecycle {
  const StudentLifecycle({
    required this.studentId,
    required this.uniId,
    required this.studentName,
    required this.currentStatus,
    required this.updatedAt,
    this.admissionDate,
    this.graduationDate,
    this.alumniDate,
    this.admissionReference,
    this.notes,
  });

  final int studentId;
  final String uniId;
  final String studentName;
  final String currentStatus;
  final DateTime? admissionDate;
  final DateTime? graduationDate;
  final DateTime? alumniDate;
  final String? admissionReference;
  final String? notes;
  final DateTime updatedAt;

  factory StudentLifecycle.fromJson(Map<String, dynamic> json) {
    return StudentLifecycle(
      studentId: (json['student_id'] as num).toInt(),
      uniId: json['uni_id']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? '',
      currentStatus: json['current_status']?.toString() ?? 'active',
      admissionDate: _dateTime(json['admission_date']),
      graduationDate: _dateTime(json['graduation_date']),
      alumniDate: _dateTime(json['alumni_date']),
      admissionReference: json['admission_reference']?.toString(),
      notes: json['notes']?.toString(),
      updatedAt: _dateTime(json['updated_at']) ?? DateTime.now(),
    );
  }
}

class StudentLifecycleEvent {
  const StudentLifecycleEvent({
    required this.id,
    required this.studentId,
    required this.toStatus,
    required this.changedByUserId,
    required this.createdAt,
    this.fromStatus,
    this.reason,
  });

  final int id;
  final int studentId;
  final String? fromStatus;
  final String toStatus;
  final String? reason;
  final int changedByUserId;
  final DateTime createdAt;

  factory StudentLifecycleEvent.fromJson(Map<String, dynamic> json) {
    return StudentLifecycleEvent(
      id: (json['id'] as num).toInt(),
      studentId: (json['student_id'] as num).toInt(),
      fromStatus: json['from_status']?.toString(),
      toStatus: json['to_status']?.toString() ?? '',
      reason: json['reason']?.toString(),
      changedByUserId: (json['changed_by_user_id'] as num).toInt(),
      createdAt: _dateTime(json['created_at']) ?? DateTime.now(),
    );
  }
}

DateTime? _dateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

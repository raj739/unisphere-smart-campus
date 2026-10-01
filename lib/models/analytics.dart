class UniversityOverview {
  final int totalUsers;
  final int students;
  final int parents;
  final int administrators;
  final int activeUsers;

  UniversityOverview({
    required this.totalUsers,
    required this.students,
    required this.parents,
    required this.administrators,
    required this.activeUsers,
  });

  factory UniversityOverview.fromJson(Map<String, dynamic> json) {
    return UniversityOverview(
      totalUsers: json['total_users'] as int? ?? 0,
      students: json['students'] as int? ?? 0,
      parents: json['parents'] as int? ?? 0,
      administrators: json['administrators'] as int? ?? 0,
      activeUsers: json['active_users'] as int? ?? 0,
    );
  }
}

class RoleDistribution {
  final String role;
  final int count;

  RoleDistribution({required this.role, required this.count});

  factory RoleDistribution.fromJson(Map<String, dynamic> json) {
    return RoleDistribution(
      role: json['role'] as String? ?? 'unknown',
      count: json['count'] as int? ?? 0,
    );
  }
}

class SystemHealth {
  final String database;
  final int totalUsers;
  final int activeUsers;
  final double activeUserPercentage;

  SystemHealth({
    required this.database,
    required this.totalUsers,
    required this.activeUsers,
    required this.activeUserPercentage,
  });

  factory SystemHealth.fromJson(Map<String, dynamic> json) {
    return SystemHealth(
      database: json['database'] as String? ?? 'unknown',
      totalUsers: json['total_users'] as int? ?? 0,
      activeUsers: json['active_users'] as int? ?? 0,
      activeUserPercentage:
          (json['active_user_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

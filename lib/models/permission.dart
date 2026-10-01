class Permission {
  final int id;
  final String code;
  final String name;
  final String description;
  final String module;
  final bool isActive;

  const Permission({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.module,
    required this.isActive,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      module: json['module'] as String,
      isActive: json['is_active'] as bool,
    );
  }
}

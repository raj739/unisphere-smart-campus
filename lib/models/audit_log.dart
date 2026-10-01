class AuditLog {
  final int id;
  final int? userId;
  final String action;
  final String module;
  final String? entityType;
  final String? entityId;
  final String? description;
  final String? ipAddress;
  final String? userAgent;
  final Map<String, dynamic>? metadata;
  final bool success;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    this.userId,
    required this.action,
    required this.module,
    this.entityType,
    this.entityId,
    this.description,
    this.ipAddress,
    this.userAgent,
    this.metadata,
    required this.success,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      action: json['action'] as String,
      module: json['module'] as String,
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      description: json['description'] as String?,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      metadata: json['metadata_json'] != null
          ? Map<String, dynamic>.from(json['metadata_json'] as Map)
          : null,
      success: json['success'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class AuditLogListResponse {
  final List<AuditLog> items;
  final int total;
  final int limit;
  final int offset;

  AuditLogListResponse({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory AuditLogListResponse.fromJson(Map<String, dynamic> json) {
    return AuditLogListResponse(
      items: (json['items'] as List<dynamic>? ?? [])
          .map(
            (item) => AuditLog.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 50,
      offset: json['offset'] as int? ?? 0,
    );
  }
}

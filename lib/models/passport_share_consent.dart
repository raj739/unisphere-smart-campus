class PassportShareConsent {
  final int id;
  final int passportId;
  final String shareToken;
  final String recipientName;
  final String? recipientEmail;
  final String purpose;
  final String scope;
  final String status;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime? revokedAt;
  final bool isActive;

  const PassportShareConsent({
    required this.id,
    required this.passportId,
    required this.shareToken,
    required this.recipientName,
    required this.recipientEmail,
    required this.purpose,
    required this.scope,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    required this.revokedAt,
    required this.isActive,
  });

  factory PassportShareConsent.fromJson(Map<String, dynamic> json) {
    return PassportShareConsent(
      id: json['id'] as int,
      passportId: json['passport_id'] as int,
      shareToken: json['share_token'] as String,
      recipientName: json['recipient_name'] as String,
      recipientEmail: json['recipient_email'] as String?,
      purpose: json['purpose'] as String,
      scope: json['scope'] as String,
      status: json['status'] as String,
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.tryParse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      revokedAt: json['revoked_at'] == null
          ? null
          : DateTime.tryParse(json['revoked_at'] as String),
      isActive: json['is_active'] as bool,
    );
  }
}

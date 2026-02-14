enum UserRole { platform_admin, tenant_admin, branch_manager, cashier, driver }

class StaffMember {
  final String id;
  final String tenantId;
  final String? branchId;
  final String email;
  final String fullName;
  final UserRole role;
  final String? avatarUrl;
  final DateTime? lastLoginAt;
  final DateTime createdAt;

  StaffMember({
    required this.id,
    required this.tenantId,
    this.branchId,
    required this.email,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.lastLoginAt,
    required this.createdAt,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'],
      tenantId: json['tenant_id'],
      branchId: json['branch_id'],
      email: json['email'] ?? '',
      fullName: json['full_name'],
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.cashier,
      ),
      avatarUrl: json['avatar_url'],
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class StaffInvitation {
  final String id;
  final String tenantId;
  final String email;
  final String fullName;
  final UserRole role;
  final String status; // pending, accepted, revoked
  final String invitationToken;
  final DateTime expiresAt;

  StaffInvitation({
    required this.id,
    required this.tenantId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.status,
    required this.invitationToken,
    required this.expiresAt,
  });

  factory StaffInvitation.fromJson(Map<String, dynamic> json) {
    return StaffInvitation(
      id: json['id'],
      tenantId: json['tenant_id'],
      email: json['email'],
      fullName: json['full_name'],
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.cashier,
      ),
      status: json['status'],
      invitationToken: json['invitation_token'],
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }
}

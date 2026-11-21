enum AuthRole {
  superAdmin('SUPER_ADMIN'),
  contractor('CONTRACTOR'),
  supervisor('SUPERVISOR'),
  client('CLIENT'),
  unknown('UNKNOWN');

  const AuthRole(this.apiValue);

  final String apiValue;

  static AuthRole fromApi(String value) {
    final normalized = value.trim().toUpperCase();
    return AuthRole.values.firstWhere(
      (role) => role.apiValue == normalized,
      orElse: () => AuthRole.unknown,
    );
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.siteIds,
    required this.blocked,
    this.username,
    this.companyId,
    this.companyName,
    this.plan,
    this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: '${json['id'] ?? ''}',
    email: '${json['email'] ?? ''}',
    fullName: '${json['full_name'] ?? json['name'] ?? ''}',
    role: '${json['role'] ?? ''}'.toUpperCase(),
    username: json['username'] as String?,
    companyId: json['company_id'] as String?,
    companyName: json['company_name'] as String?,
    plan: json['plan'] as String?,
    siteIds: (json['site_ids'] as List? ?? const [])
        .map((siteId) => '$siteId')
        .toList(growable: false),
    blocked: json['blocked'] == true,
    createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
  );

  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? username;
  final String? companyId;
  final String? companyName;
  final String? plan;
  final List<String> siteIds;
  final bool blocked;
  final DateTime? createdAt;

  String get name => fullName;
  AuthRole get authRole => AuthRole.fromApi(role);
  bool get isSuperAdmin => authRole == AuthRole.superAdmin;
  bool get isContractor => authRole == AuthRole.contractor;
  bool get isSupervisor => authRole == AuthRole.supervisor;
  bool get isClient => authRole == AuthRole.client;
  bool get canManageSites => isContractor || isSuperAdmin;
  bool get canManageFinance => isContractor || isSuperAdmin;
  bool get canManageFieldOperations =>
      isContractor || isSupervisor || isSuperAdmin;
  bool get isSupportedMobileRole => authRole != AuthRole.unknown;

  String get roleLabel => role
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'role': role,
    'username': username,
    'company_id': companyId,
    'company_name': companyName,
    'plan': plan,
    'site_ids': siteIds,
    'blocked': blocked,
    'created_at': createdAt?.toIso8601String(),
  };
}

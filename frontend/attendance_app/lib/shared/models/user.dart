enum UserRole { employee, manager, unknown }

UserRole roleFromString(String? value) => switch (value) {
      'Manager' => UserRole.manager,
      'Employee' => UserRole.employee,
      _ => UserRole.unknown,
    };

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    this.departmentId,
    this.departmentName,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final bool isActive;
  final String? departmentId;
  final String? departmentName;

  bool get isManager => role == UserRole.manager;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: roleFromString(json['role'] as String?),
        isActive: json['isActive'] as bool? ?? true,
        departmentId: json['departmentId'] as String?,
        departmentName: json['departmentName'] as String?,
      );
}

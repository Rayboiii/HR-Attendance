class UserSummary {
  const UserSummary({
    required this.id,
    required this.fullName,
    this.departmentName,
  });

  final String id;
  final String fullName;
  final String? departmentName;

  factory UserSummary.fromJson(Map<String, dynamic> json) => UserSummary(
        id: json['id'] as String,
        fullName: json['fullName'] as String? ?? '',
        departmentName: json['departmentName'] as String?,
      );
}

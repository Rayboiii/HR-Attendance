class ShiftAssignee {
  const ShiftAssignee({required this.userId, required this.fullName});

  final String userId;
  final String fullName;

  factory ShiftAssignee.fromJson(Map<String, dynamic> json) => ShiftAssignee(
        userId: json['userId'] as String,
        fullName: json['fullName'] as String? ?? '',
      );
}

class Shift {
  const Shift({
    required this.id,
    required this.name,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.assignees,
    this.departmentName,
  });

  final String id;
  final String name;
  final DateTime date;

  /// Wall-clock times as returned by the API ("HH:mm:ss").
  final String startTime;
  final String endTime;
  final String? departmentName;
  final List<ShiftAssignee> assignees;

  /// "09:00" style display, dropping the seconds component.
  String get startLabel => _hhmm(startTime);
  String get endLabel => _hhmm(endTime);

  static String _hhmm(String time) {
    final parts = time.split(':');
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : time;
  }

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
        startTime: json['startTime'] as String? ?? '',
        endTime: json['endTime'] as String? ?? '',
        departmentName: json['departmentName'] as String?,
        assignees: (json['assignees'] as List<dynamic>? ?? [])
            .map((e) => ShiftAssignee.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

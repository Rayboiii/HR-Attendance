enum ClockInMethod { pin, qr, manual }

extension ClockInMethodApi on ClockInMethod {
  /// Matches the API's PascalCase enum names.
  String get apiValue => switch (this) {
        ClockInMethod.pin => 'Pin',
        ClockInMethod.qr => 'Qr',
        ClockInMethod.manual => 'Manual',
      };
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.userId,
    required this.clockInTime,
    required this.method,
    required this.status,
    this.shiftId,
    this.shiftName,
    this.clockOutTime,
    this.workedHours,
  });

  final String id;
  final String userId;
  final DateTime clockInTime;
  final DateTime? clockOutTime;
  final String method;
  final String status;
  final String? shiftId;
  final String? shiftName;
  final double? workedHours;

  bool get isClockedOut => clockOutTime != null;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        id: json['id'] as String,
        userId: json['userId'] as String,
        clockInTime: DateTime.parse(json['clockInTime'] as String).toLocal(),
        clockOutTime: json['clockOutTime'] == null
            ? null
            : DateTime.parse(json['clockOutTime'] as String).toLocal(),
        method: json['clockInMethod'] as String? ?? '',
        status: json['status'] as String? ?? '',
        shiftId: json['shiftId'] as String?,
        shiftName: json['shiftName'] as String?,
        workedHours: (json['workedHours'] as num?)?.toDouble(),
      );
}

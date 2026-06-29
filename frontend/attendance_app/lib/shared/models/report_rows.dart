class AttendanceReportRow {
  const AttendanceReportRow({
    required this.userId,
    required this.fullName,
    required this.totalDays,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.halfDayCount,
    required this.totalWorkedHours,
  });

  final String userId;
  final String fullName;
  final int totalDays;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int halfDayCount;
  final double totalWorkedHours;

  factory AttendanceReportRow.fromJson(Map<String, dynamic> json) =>
      AttendanceReportRow(
        userId: json['userId'] as String,
        fullName: json['fullName'] as String? ?? '',
        totalDays: json['totalDays'] as int? ?? 0,
        presentCount: json['presentCount'] as int? ?? 0,
        lateCount: json['lateCount'] as int? ?? 0,
        absentCount: json['absentCount'] as int? ?? 0,
        halfDayCount: json['halfDayCount'] as int? ?? 0,
        totalWorkedHours: (json['totalWorkedHours'] as num?)?.toDouble() ?? 0,
      );
}

class OvertimeReportRow {
  const OvertimeReportRow({
    required this.userId,
    required this.fullName,
    required this.totalWorkedHours,
    required this.standardHours,
    required this.overtimeHours,
  });

  final String userId;
  final String fullName;
  final double totalWorkedHours;
  final double standardHours;
  final double overtimeHours;

  factory OvertimeReportRow.fromJson(Map<String, dynamic> json) =>
      OvertimeReportRow(
        userId: json['userId'] as String,
        fullName: json['fullName'] as String? ?? '',
        totalWorkedHours: (json['totalWorkedHours'] as num?)?.toDouble() ?? 0,
        standardHours: (json['standardHours'] as num?)?.toDouble() ?? 0,
        overtimeHours: (json['overtimeHours'] as num?)?.toDouble() ?? 0,
      );
}

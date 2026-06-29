using AttendanceApi.Domain.Enums;

namespace AttendanceApi.Application.DTOs.Reports;

public record AttendanceReportRow(
    Guid UserId,
    string FullName,
    int TotalDays,
    int PresentCount,
    int LateCount,
    int AbsentCount,
    int HalfDayCount,
    double TotalWorkedHours);

public record OvertimeReportRow(
    Guid UserId,
    string FullName,
    double TotalWorkedHours,
    double StandardHours,
    double OvertimeHours);

using AttendanceApi.Application.DTOs.Reports;

namespace AttendanceApi.Application.Services.Interfaces;

public interface IReportService
{
    Task<IReadOnlyList<AttendanceReportRow>> GetAttendanceReportAsync(DateOnly from, DateOnly to, Guid? departmentId, CancellationToken ct = default);
    Task<IReadOnlyList<OvertimeReportRow>> GetOvertimeReportAsync(DateOnly from, DateOnly to, Guid? departmentId, CancellationToken ct = default);
}

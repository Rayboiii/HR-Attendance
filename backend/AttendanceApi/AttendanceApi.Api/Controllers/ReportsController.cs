using AttendanceApi.Application.DTOs.Reports;
using AttendanceApi.Application.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Api.Controllers;

[Authorize(Roles = "Manager")]
public class ReportsController(IReportService reportService) : ApiControllerBase
{
    [HttpGet("attendance")]
    public Task<IReadOnlyList<AttendanceReportRow>> Attendance(
        [FromQuery] DateOnly from, [FromQuery] DateOnly to, [FromQuery] Guid? departmentId, CancellationToken ct)
        => reportService.GetAttendanceReportAsync(from, to, departmentId, ct);

    [HttpGet("overtime")]
    public Task<IReadOnlyList<OvertimeReportRow>> Overtime(
        [FromQuery] DateOnly from, [FromQuery] DateOnly to, [FromQuery] Guid? departmentId, CancellationToken ct)
        => reportService.GetOvertimeReportAsync(from, to, departmentId, ct);
}

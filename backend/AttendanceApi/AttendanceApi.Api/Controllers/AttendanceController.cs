using AttendanceApi.Application.DTOs.Attendance;
using AttendanceApi.Application.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Api.Controllers;

[Authorize]
public class AttendanceController(IAttendanceService attendanceService) : ApiControllerBase
{
    [HttpPost("clock-in")]
    public Task<AttendanceRecordDto> ClockIn(ClockInRequest request, CancellationToken ct)
        => attendanceService.ClockInAsync(CurrentUserId, request, ct);

    [HttpPost("clock-out")]
    public Task<AttendanceRecordDto> ClockOut(ClockOutRequest request, CancellationToken ct)
        => attendanceService.ClockOutAsync(CurrentUserId, request, ct);

    [HttpGet("today")]
    public Task<AttendanceRecordDto?> Today(CancellationToken ct)
        => attendanceService.GetTodayAsync(CurrentUserId, ct);

    [HttpGet("my")]
    public Task<IReadOnlyList<AttendanceRecordDto>> Mine([FromQuery] DateOnly? from, [FromQuery] DateOnly? to, CancellationToken ct)
        => attendanceService.GetMyAsync(CurrentUserId, from, to, ct);

    [Authorize(Roles = "Manager")]
    [HttpGet]
    public Task<IReadOnlyList<AttendanceRecordDto>> GetAll(
        [FromQuery] DateOnly? from, [FromQuery] DateOnly? to, [FromQuery] Guid? departmentId, CancellationToken ct)
        => attendanceService.GetAllAsync(from, to, departmentId, ct);

    [Authorize(Roles = "Manager")]
    [HttpGet("{userId:guid}")]
    public Task<IReadOnlyList<AttendanceRecordDto>> GetByUser(
        Guid userId, [FromQuery] DateOnly? from, [FromQuery] DateOnly? to, CancellationToken ct)
        => attendanceService.GetByUserAsync(userId, from, to, ct);
}

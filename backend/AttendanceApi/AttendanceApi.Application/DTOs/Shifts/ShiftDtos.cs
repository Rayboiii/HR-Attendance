using System.ComponentModel.DataAnnotations;

namespace AttendanceApi.Application.DTOs.Shifts;

public record ShiftDto(
    Guid Id,
    Guid DepartmentId,
    string? DepartmentName,
    string Name,
    DateOnly Date,
    TimeOnly StartTime,
    TimeOnly EndTime,
    IReadOnlyList<ShiftAssigneeDto> Assignees);

public record ShiftAssigneeDto(
    Guid UserId,
    string FullName,
    DateTime AssignedAt);

public record CreateShiftRequest(
    [Required] Guid DepartmentId,
    [Required] string Name,
    DateOnly Date,
    TimeOnly StartTime,
    TimeOnly EndTime);

public record UpdateShiftRequest(
    [Required] string Name,
    DateOnly Date,
    TimeOnly StartTime,
    TimeOnly EndTime);

public record AssignShiftRequest(
    [Required, MinLength(1)] IReadOnlyList<Guid> UserIds);

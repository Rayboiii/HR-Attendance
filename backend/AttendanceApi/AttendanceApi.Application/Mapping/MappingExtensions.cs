using AttendanceApi.Application.DTOs.Attendance;
using AttendanceApi.Application.DTOs.Departments;
using AttendanceApi.Application.DTOs.Notifications;
using AttendanceApi.Application.DTOs.Qr;
using AttendanceApi.Application.DTOs.Shifts;
using AttendanceApi.Application.DTOs.ShiftSwaps;
using AttendanceApi.Application.DTOs.Users;
using AttendanceApi.Domain.Entities;

namespace AttendanceApi.Application.Mapping;

/// <summary>
/// Manual entity → DTO mapping. Preferred over a convention mapper here because
/// most DTO fields are flattened/computed from navigation properties.
/// Callers are responsible for eager-loading the navigations each mapper reads.
/// </summary>
public static class MappingExtensions
{
    public static UserDto ToDto(this User u) => new(
        u.Id,
        u.FullName,
        u.Email,
        u.Role,
        u.DepartmentId,
        u.Department?.Name,
        u.IsActive,
        u.CreatedAt);

    public static DepartmentDto ToDto(this Department d) => new(
        d.Id,
        d.Name,
        d.LocationLat,
        d.LocationLng,
        d.RadiusMeters);

    public static ShiftDto ToDto(this Shift s) => new(
        s.Id,
        s.DepartmentId,
        s.Department?.Name,
        s.Name,
        s.Date,
        s.StartTime,
        s.EndTime,
        s.Assignments
            .Select(a => new ShiftAssigneeDto(a.UserId, a.User?.FullName ?? string.Empty, a.AssignedAt))
            .ToList());

    public static AttendanceRecordDto ToDto(this AttendanceRecord r) => new(
        r.Id,
        r.UserId,
        r.User?.FullName,
        r.ShiftId,
        r.Shift?.Name,
        r.ClockInTime,
        r.ClockOutTime,
        r.ClockInMethod,
        r.LocationLat,
        r.LocationLng,
        r.Status,
        r.ClockOutTime is null
            ? null
            : Math.Round((r.ClockOutTime.Value - r.ClockInTime).TotalHours, 2));

    public static QrTokenDto ToDto(this QrToken q) => new(
        q.Id,
        q.ShiftId,
        q.Token,
        q.ExpiresAt,
        q.IsUsed);

    public static ShiftSwapDto ToDto(this ShiftSwapRequest r) => new(
        r.Id,
        r.RequesterId,
        r.Requester?.FullName,
        r.TargetUserId,
        r.TargetUser?.FullName,
        r.RequesterShiftId,
        r.RequesterShift?.Name,
        r.Status,
        r.ManagerNote,
        r.CreatedAt,
        r.ResolvedAt);

    public static NotificationDto ToDto(this Notification n) => new(
        n.Id,
        n.Title,
        n.Message,
        n.IsRead,
        n.CreatedAt);
}

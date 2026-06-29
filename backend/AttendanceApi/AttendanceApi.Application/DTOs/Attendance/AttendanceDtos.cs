using System.ComponentModel.DataAnnotations;
using AttendanceApi.Domain.Enums;

namespace AttendanceApi.Application.DTOs.Attendance;

public record ClockInRequest(
    ClockInMethod Method,
    string? Pin,
    string? QrToken,
    double? Lat,
    double? Lng);

public record ClockOutRequest(
    double? Lat,
    double? Lng);

public record AttendanceRecordDto(
    Guid Id,
    Guid UserId,
    string? UserFullName,
    Guid? ShiftId,
    string? ShiftName,
    DateTime ClockInTime,
    DateTime? ClockOutTime,
    ClockInMethod ClockInMethod,
    double? LocationLat,
    double? LocationLng,
    AttendanceStatus Status,
    double? WorkedHours);

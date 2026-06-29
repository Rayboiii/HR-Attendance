using System.ComponentModel.DataAnnotations;
using AttendanceApi.Domain.Enums;

namespace AttendanceApi.Application.DTOs.ShiftSwaps;

public record CreateSwapRequest(
    [Required] Guid TargetUserId,
    [Required] Guid RequesterShiftId);

public record ResolveSwapRequest(
    string? ManagerNote);

public record ShiftSwapDto(
    Guid Id,
    Guid RequesterId,
    string? RequesterName,
    Guid TargetUserId,
    string? TargetUserName,
    Guid RequesterShiftId,
    string? RequesterShiftName,
    SwapStatus Status,
    string? ManagerNote,
    DateTime CreatedAt,
    DateTime? ResolvedAt);

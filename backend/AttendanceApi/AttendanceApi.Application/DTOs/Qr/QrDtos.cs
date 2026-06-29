using System.ComponentModel.DataAnnotations;

namespace AttendanceApi.Application.DTOs.Qr;

public record GenerateQrRequest(
    [Range(1, 1440)] int ValidMinutes = 15);

public record QrTokenDto(
    Guid Id,
    Guid ShiftId,
    string Token,
    DateTime ExpiresAt,
    bool IsUsed);

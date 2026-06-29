using AttendanceApi.Application.DTOs.Qr;

namespace AttendanceApi.Application.Services.Interfaces;

public interface IQrService
{
    Task<QrTokenDto> GenerateAsync(Guid shiftId, GenerateQrRequest request, CancellationToken ct = default);
}

using AttendanceApi.Application.Common.Exceptions;
using AttendanceApi.Application.Common.Interfaces;
using AttendanceApi.Application.DTOs.Qr;
using AttendanceApi.Application.Mapping;
using AttendanceApi.Application.Services.Interfaces;
using AttendanceApi.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Application.Services;

public class QrService(IAppDbContext db) : IQrService
{
    public async Task<QrTokenDto> GenerateAsync(Guid shiftId, GenerateQrRequest request, CancellationToken ct = default)
    {
        if (!await db.Shifts.AnyAsync(s => s.Id == shiftId, ct))
            throw new NotFoundException("Shift not found.");

        var token = new QrToken
        {
            ShiftId = shiftId,
            // Two GUIDs give an unguessable, single-use token without extra dependencies.
            Token = $"{Guid.NewGuid():N}{Guid.NewGuid():N}",
            ExpiresAt = DateTime.UtcNow.AddMinutes(request.ValidMinutes),
            IsUsed = false
        };

        db.QrTokens.Add(token);
        await db.SaveChangesAsync(ct);
        return token.ToDto();
    }
}

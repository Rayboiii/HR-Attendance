using AttendanceApi.Application.Common;
using AttendanceApi.Application.Common.Exceptions;
using AttendanceApi.Application.Common.Interfaces;
using AttendanceApi.Application.DTOs.Attendance;
using AttendanceApi.Application.Mapping;
using AttendanceApi.Application.Services.Interfaces;
using AttendanceApi.Domain.Entities;
using AttendanceApi.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Application.Services;

public class AttendanceService(IAppDbContext db, IPasswordHasher passwordHasher) : IAttendanceService
{
    public async Task<AttendanceRecordDto> ClockInAsync(Guid userId, ClockInRequest request, CancellationToken ct = default)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == userId && u.IsActive, ct)
            ?? throw new NotFoundException("User not found.");

        var today = DateOnly.FromDateTime(DateTime.UtcNow);

        var shift = await db.Shifts
            .Include(s => s.Department)
            .Where(s => s.Date == today && s.Assignments.Any(a => a.UserId == userId))
            .OrderBy(s => s.StartTime)
            .FirstOrDefaultAsync(ct)
            ?? throw new ValidationException("You have no shift assigned for today.");

        if (await db.AttendanceRecords.AnyAsync(a => a.UserId == userId && a.ShiftId == shift.Id, ct))
            throw new ConflictException("You have already clocked in for today's shift.");

        await ValidateMethodAsync(request, user, shift, ct);

        var now = DateTime.UtcNow;
        var shiftStart = shift.Date.ToDateTime(shift.StartTime, DateTimeKind.Utc);
        var isLate = now > shiftStart.AddMinutes(AttendancePolicy.LateGraceMinutes);

        var record = new AttendanceRecord
        {
            UserId = userId,
            ShiftId = shift.Id,
            ClockInTime = now,
            ClockInMethod = request.Method,
            LocationLat = request.Lat,
            LocationLng = request.Lng,
            Status = isLate ? AttendanceStatus.Late : AttendanceStatus.Present
        };

        db.AttendanceRecords.Add(record);
        await db.SaveChangesAsync(ct);

        record.User = user;
        record.Shift = shift;
        return record.ToDto();
    }

    public async Task<AttendanceRecordDto> ClockOutAsync(Guid userId, ClockOutRequest request, CancellationToken ct = default)
    {
        var record = await db.AttendanceRecords
            .Include(a => a.User)
            .Include(a => a.Shift)
            .Where(a => a.UserId == userId && a.ClockOutTime == null)
            .OrderByDescending(a => a.ClockInTime)
            .FirstOrDefaultAsync(ct)
            ?? throw new ValidationException("You have no open clock-in to close.");

        record.ClockOutTime = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return record.ToDto();
    }

    public async Task<AttendanceRecordDto?> GetTodayAsync(Guid userId, CancellationToken ct = default)
    {
        var todayStart = DateTime.UtcNow.Date;
        var tomorrow = todayStart.AddDays(1);

        var record = await db.AttendanceRecords
            .Include(a => a.User)
            .Include(a => a.Shift)
            .Where(a => a.UserId == userId && a.ClockInTime >= todayStart && a.ClockInTime < tomorrow)
            .OrderByDescending(a => a.ClockInTime)
            .FirstOrDefaultAsync(ct);

        return record?.ToDto();
    }

    public Task<IReadOnlyList<AttendanceRecordDto>> GetMyAsync(Guid userId, DateOnly? from, DateOnly? to, CancellationToken ct = default)
        => QueryRecordsAsync(userId, from, to, null, ct);

    public Task<IReadOnlyList<AttendanceRecordDto>> GetByUserAsync(Guid userId, DateOnly? from, DateOnly? to, CancellationToken ct = default)
        => QueryRecordsAsync(userId, from, to, null, ct);

    public Task<IReadOnlyList<AttendanceRecordDto>> GetAllAsync(DateOnly? from, DateOnly? to, Guid? departmentId, CancellationToken ct = default)
        => QueryRecordsAsync(null, from, to, departmentId, ct);

    private async Task<IReadOnlyList<AttendanceRecordDto>> QueryRecordsAsync(
        Guid? userId, DateOnly? from, DateOnly? to, Guid? departmentId, CancellationToken ct)
    {
        var query = db.AttendanceRecords
            .Include(a => a.User)
            .Include(a => a.Shift)
            .AsQueryable();

        if (userId is not null)
            query = query.Where(a => a.UserId == userId);

        if (departmentId is not null)
            query = query.Where(a => a.User != null && a.User.DepartmentId == departmentId);

        if (from is not null)
            query = query.Where(a => a.ClockInTime >= from.Value.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc));

        if (to is not null)
            query = query.Where(a => a.ClockInTime < to.Value.AddDays(1).ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc));

        var records = await query
            .OrderByDescending(a => a.ClockInTime)
            .ToListAsync(ct);

        return records.Select(a => a.ToDto()).ToList();
    }

    private async Task ValidateMethodAsync(ClockInRequest request, User user, Shift shift, CancellationToken ct)
    {
        switch (request.Method)
        {
            case ClockInMethod.Pin:
                ValidatePin(request, user);
                break;

            case ClockInMethod.Qr:
                await ValidateQrAsync(request, shift, ct);
                break;

            case ClockInMethod.Manual:
                ValidateLocation(request, shift);
                break;

            default:
                throw new ValidationException("Unsupported clock-in method.");
        }
    }

    private void ValidatePin(ClockInRequest request, User user)
    {
        if (string.IsNullOrWhiteSpace(user.PinHash))
            throw new ValidationException("No PIN is configured for your account.");

        if (string.IsNullOrWhiteSpace(request.Pin) || !passwordHasher.Verify(request.Pin, user.PinHash))
            throw new UnauthorizedAppException("Incorrect PIN.");
    }

    private async Task ValidateQrAsync(ClockInRequest request, Shift shift, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.QrToken))
            throw new ValidationException("A QR token is required for QR clock-in.");

        var token = await db.QrTokens.FirstOrDefaultAsync(t => t.Token == request.QrToken, ct)
            ?? throw new ValidationException("Invalid QR code.");

        if (token.ShiftId != shift.Id)
            throw new ValidationException("This QR code is not valid for your shift.");

        if (token.IsUsed)
            throw new ConflictException("This QR code has already been used.");

        if (token.ExpiresAt <= DateTime.UtcNow)
            throw new ValidationException("This QR code has expired.");

        token.IsUsed = true;
    }

    private static void ValidateLocation(ClockInRequest request, Shift shift)
    {
        if (request.Lat is null || request.Lng is null)
            throw new ValidationException("Location coordinates are required for manual clock-in.");

        var department = shift.Department
            ?? throw new ValidationException("This shift has no department to geofence against.");

        if (department.LocationLat is null || department.LocationLng is null)
            throw new ValidationException("This department has no location configured for geofencing.");

        var distance = GeoHelper.DistanceMeters(
            request.Lat.Value, request.Lng.Value,
            department.LocationLat.Value, department.LocationLng.Value);

        if (distance > department.RadiusMeters)
            throw new ValidationException(
                $"You are {distance:F0}m from {department.Name}, outside the allowed {department.RadiusMeters:F0}m radius.");
    }
}

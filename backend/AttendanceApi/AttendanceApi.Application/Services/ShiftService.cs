using AttendanceApi.Application.Common.Exceptions;
using AttendanceApi.Application.Common.Interfaces;
using AttendanceApi.Application.DTOs.Shifts;
using AttendanceApi.Application.Mapping;
using AttendanceApi.Application.Services.Interfaces;
using AttendanceApi.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Application.Services;

public class ShiftService(IAppDbContext db) : IShiftService
{
    private IQueryable<Shift> ShiftsWithDetails() => db.Shifts
        .Include(s => s.Department)
        .Include(s => s.Assignments).ThenInclude(a => a.User);

    public async Task<IReadOnlyList<ShiftDto>> GetAllAsync(DateOnly? from, DateOnly? to, CancellationToken ct = default)
    {
        var query = ShiftsWithDetails();
        if (from is not null) query = query.Where(s => s.Date >= from);
        if (to is not null) query = query.Where(s => s.Date <= to);

        var shifts = await query
            .OrderBy(s => s.Date).ThenBy(s => s.StartTime)
            .ToListAsync(ct);

        return shifts.Select(s => s.ToDto()).ToList();
    }

    public async Task<ShiftDto> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var shift = await ShiftsWithDetails().FirstOrDefaultAsync(s => s.Id == id, ct)
            ?? throw new NotFoundException("Shift not found.");
        return shift.ToDto();
    }

    public async Task<ShiftDto> CreateAsync(CreateShiftRequest request, CancellationToken ct = default)
    {
        if (!await db.Departments.AnyAsync(d => d.Id == request.DepartmentId, ct))
            throw new ValidationException("The specified department does not exist.");

        if (request.EndTime <= request.StartTime)
            throw new ValidationException("Shift end time must be after the start time.");

        var shift = new Shift
        {
            DepartmentId = request.DepartmentId,
            Name = request.Name.Trim(),
            Date = request.Date,
            StartTime = request.StartTime,
            EndTime = request.EndTime
        };

        db.Shifts.Add(shift);
        await db.SaveChangesAsync(ct);
        return await GetByIdAsync(shift.Id, ct);
    }

    public async Task<ShiftDto> UpdateAsync(Guid id, UpdateShiftRequest request, CancellationToken ct = default)
    {
        var shift = await db.Shifts.FirstOrDefaultAsync(s => s.Id == id, ct)
            ?? throw new NotFoundException("Shift not found.");

        if (request.EndTime <= request.StartTime)
            throw new ValidationException("Shift end time must be after the start time.");

        shift.Name = request.Name.Trim();
        shift.Date = request.Date;
        shift.StartTime = request.StartTime;
        shift.EndTime = request.EndTime;

        await db.SaveChangesAsync(ct);
        return await GetByIdAsync(shift.Id, ct);
    }

    public async Task DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var shift = await db.Shifts
            .Include(s => s.Assignments)
            .Include(s => s.QrTokens)
            .FirstOrDefaultAsync(s => s.Id == id, ct)
            ?? throw new NotFoundException("Shift not found.");

        if (await db.AttendanceRecords.AnyAsync(a => a.ShiftId == id, ct))
            throw new ConflictException("Cannot delete a shift that already has attendance records.");

        db.ShiftAssignments.RemoveRange(shift.Assignments);
        db.QrTokens.RemoveRange(shift.QrTokens);
        db.Shifts.Remove(shift);
        await db.SaveChangesAsync(ct);
    }

    public async Task<IReadOnlyList<ShiftDto>> GetMyShiftsAsync(Guid userId, DateOnly? from, DateOnly? to, CancellationToken ct = default)
    {
        var query = ShiftsWithDetails().Where(s => s.Assignments.Any(a => a.UserId == userId));
        if (from is not null) query = query.Where(s => s.Date >= from);
        if (to is not null) query = query.Where(s => s.Date <= to);

        var shifts = await query
            .OrderBy(s => s.Date).ThenBy(s => s.StartTime)
            .ToListAsync(ct);

        return shifts.Select(s => s.ToDto()).ToList();
    }

    public async Task<ShiftDto> AssignAsync(Guid shiftId, AssignShiftRequest request, CancellationToken ct = default)
    {
        var shift = await db.Shifts
            .Include(s => s.Assignments)
            .FirstOrDefaultAsync(s => s.Id == shiftId, ct)
            ?? throw new NotFoundException("Shift not found.");

        var requestedIds = request.UserIds.Distinct().ToList();

        var validIds = await db.Users
            .Where(u => requestedIds.Contains(u.Id) && u.IsActive)
            .Select(u => u.Id)
            .ToListAsync(ct);

        var missing = requestedIds.Except(validIds).ToList();
        if (missing.Count > 0)
            throw new ValidationException($"One or more users were not found or are inactive: {string.Join(", ", missing)}");

        var alreadyAssigned = shift.Assignments.Select(a => a.UserId).ToHashSet();
        foreach (var userId in validIds.Where(id => !alreadyAssigned.Contains(id)))
        {
            db.ShiftAssignments.Add(new ShiftAssignment { ShiftId = shiftId, UserId = userId });
        }

        await db.SaveChangesAsync(ct);
        return await GetByIdAsync(shiftId, ct);
    }

    public async Task<ShiftDto> UnassignAsync(Guid shiftId, Guid userId, CancellationToken ct = default)
    {
        var assignment = await db.ShiftAssignments
            .FirstOrDefaultAsync(a => a.ShiftId == shiftId && a.UserId == userId, ct)
            ?? throw new NotFoundException("That user is not assigned to this shift.");

        db.ShiftAssignments.Remove(assignment);
        await db.SaveChangesAsync(ct);
        return await GetByIdAsync(shiftId, ct);
    }
}

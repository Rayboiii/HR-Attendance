using AttendanceApi.Application.Common.Exceptions;
using AttendanceApi.Application.Common.Interfaces;
using AttendanceApi.Application.DTOs.ShiftSwaps;
using AttendanceApi.Application.Mapping;
using AttendanceApi.Application.Services.Interfaces;
using AttendanceApi.Domain.Entities;
using AttendanceApi.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Application.Services;

public class ShiftSwapService(IAppDbContext db) : IShiftSwapService
{
    private IQueryable<ShiftSwapRequest> SwapsWithDetails() => db.ShiftSwapRequests
        .Include(r => r.Requester)
        .Include(r => r.TargetUser)
        .Include(r => r.RequesterShift);

    public async Task<ShiftSwapDto> CreateAsync(Guid requesterId, CreateSwapRequest request, CancellationToken ct = default)
    {
        if (request.TargetUserId == requesterId)
            throw new ValidationException("You cannot request a swap with yourself.");

        var target = await db.Users.FirstOrDefaultAsync(u => u.Id == request.TargetUserId && u.IsActive, ct)
            ?? throw new ValidationException("The target user was not found or is inactive.");

        var shift = await db.Shifts
            .Include(s => s.Assignments)
            .FirstOrDefaultAsync(s => s.Id == request.RequesterShiftId, ct)
            ?? throw new NotFoundException("Shift not found.");

        if (!shift.Assignments.Any(a => a.UserId == requesterId))
            throw new ValidationException("You are not assigned to the shift you are trying to swap.");

        var pendingExists = await db.ShiftSwapRequests.AnyAsync(r =>
            r.RequesterId == requesterId
            && r.RequesterShiftId == request.RequesterShiftId
            && r.Status == SwapStatus.Pending, ct);
        if (pendingExists)
            throw new ConflictException("You already have a pending swap request for this shift.");

        var swap = new ShiftSwapRequest
        {
            RequesterId = requesterId,
            TargetUserId = request.TargetUserId,
            RequesterShiftId = request.RequesterShiftId,
            Status = SwapStatus.Pending
        };

        db.ShiftSwapRequests.Add(swap);
        db.Notifications.Add(new Notification
        {
            UserId = target.Id,
            Title = "New shift swap request",
            Message = $"{(await db.Users.FindAsync([requesterId], ct))?.FullName ?? "A colleague"} requested to swap the '{shift.Name}' shift on {shift.Date:yyyy-MM-dd}."
        });

        await db.SaveChangesAsync(ct);
        return await GetByIdAsync(swap.Id, ct);
    }

    public async Task<IReadOnlyList<ShiftSwapDto>> GetMyAsync(Guid userId, CancellationToken ct = default)
    {
        var swaps = await SwapsWithDetails()
            .Where(r => r.RequesterId == userId || r.TargetUserId == userId)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync(ct);

        return swaps.Select(r => r.ToDto()).ToList();
    }

    public async Task<IReadOnlyList<ShiftSwapDto>> GetAllAsync(CancellationToken ct = default)
    {
        var swaps = await SwapsWithDetails()
            .OrderBy(r => r.Status)
            .ThenByDescending(r => r.CreatedAt)
            .ToListAsync(ct);

        return swaps.Select(r => r.ToDto()).ToList();
    }

    public async Task<ShiftSwapDto> ApproveAsync(Guid id, ResolveSwapRequest request, CancellationToken ct = default)
    {
        var swap = await db.ShiftSwapRequests
            .Include(r => r.RequesterShift).ThenInclude(s => s!.Assignments)
            .FirstOrDefaultAsync(r => r.Id == id, ct)
            ?? throw new NotFoundException("Swap request not found.");

        if (swap.Status != SwapStatus.Pending)
            throw new ConflictException("This swap request has already been resolved.");

        // Reassign the shift from requester to target.
        var shift = swap.RequesterShift!;
        var requesterAssignment = shift.Assignments.FirstOrDefault(a => a.UserId == swap.RequesterId);
        if (requesterAssignment is not null)
            db.ShiftAssignments.Remove(requesterAssignment);

        if (!shift.Assignments.Any(a => a.UserId == swap.TargetUserId))
            db.ShiftAssignments.Add(new ShiftAssignment { ShiftId = shift.Id, UserId = swap.TargetUserId });

        swap.Status = SwapStatus.Approved;
        swap.ManagerNote = request.ManagerNote;
        swap.ResolvedAt = DateTime.UtcNow;

        db.Notifications.Add(new Notification
        {
            UserId = swap.RequesterId,
            Title = "Shift swap approved",
            Message = $"Your swap request for '{shift.Name}' on {shift.Date:yyyy-MM-dd} was approved."
        });

        await db.SaveChangesAsync(ct);
        return await GetByIdAsync(swap.Id, ct);
    }

    public async Task<ShiftSwapDto> RejectAsync(Guid id, ResolveSwapRequest request, CancellationToken ct = default)
    {
        var swap = await db.ShiftSwapRequests
            .Include(r => r.RequesterShift)
            .FirstOrDefaultAsync(r => r.Id == id, ct)
            ?? throw new NotFoundException("Swap request not found.");

        if (swap.Status != SwapStatus.Pending)
            throw new ConflictException("This swap request has already been resolved.");

        swap.Status = SwapStatus.Rejected;
        swap.ManagerNote = request.ManagerNote;
        swap.ResolvedAt = DateTime.UtcNow;

        db.Notifications.Add(new Notification
        {
            UserId = swap.RequesterId,
            Title = "Shift swap rejected",
            Message = $"Your swap request for '{swap.RequesterShift?.Name}' was rejected."
        });

        await db.SaveChangesAsync(ct);
        return await GetByIdAsync(swap.Id, ct);
    }

    private async Task<ShiftSwapDto> GetByIdAsync(Guid id, CancellationToken ct)
    {
        var swap = await SwapsWithDetails().FirstOrDefaultAsync(r => r.Id == id, ct)
            ?? throw new NotFoundException("Swap request not found.");
        return swap.ToDto();
    }
}

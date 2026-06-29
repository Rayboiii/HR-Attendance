using AttendanceApi.Application.Common.Exceptions;
using AttendanceApi.Application.Common.Interfaces;
using AttendanceApi.Application.DTOs.Users;
using AttendanceApi.Application.Mapping;
using AttendanceApi.Application.Services.Interfaces;
using AttendanceApi.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Application.Services;

public class UserService(IAppDbContext db, IPasswordHasher passwordHasher) : IUserService
{
    public async Task<IReadOnlyList<UserDto>> GetAllAsync(CancellationToken ct = default)
    {
        var users = await db.Users
            .Include(u => u.Department)
            .OrderBy(u => u.FullName)
            .ToListAsync(ct);

        return users.Select(u => u.ToDto()).ToList();
    }

    public async Task<IReadOnlyList<UserSummaryDto>> GetDirectoryAsync(CancellationToken ct = default)
    {
        return await db.Users
            .Where(u => u.IsActive)
            .OrderBy(u => u.FullName)
            .Select(u => new UserSummaryDto(u.Id, u.FullName, u.Department!.Name))
            .ToListAsync(ct);
    }

    public async Task<UserDto> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var user = await db.Users
            .Include(u => u.Department)
            .FirstOrDefaultAsync(u => u.Id == id, ct)
            ?? throw new NotFoundException("User not found.");

        return user.ToDto();
    }

    public async Task<UserDto> CreateAsync(CreateUserRequest request, CancellationToken ct = default)
    {
        var email = request.Email.Trim().ToLowerInvariant();

        if (await db.Users.AnyAsync(u => u.Email == email, ct))
            throw new ConflictException("A user with this email already exists.");

        await EnsureDepartmentExistsAsync(request.DepartmentId, ct);

        var user = new User
        {
            FullName = request.FullName.Trim(),
            Email = email,
            PasswordHash = passwordHasher.Hash(request.Password),
            PinHash = string.IsNullOrWhiteSpace(request.Pin) ? null : passwordHasher.Hash(request.Pin),
            Role = request.Role,
            DepartmentId = request.DepartmentId,
            IsActive = true
        };

        db.Users.Add(user);
        await db.SaveChangesAsync(ct);

        // Populate the department navigation for the response.
        await LoadDepartmentAsync(user, ct);
        return user.ToDto();
    }

    public async Task<UserDto> UpdateAsync(Guid id, UpdateUserRequest request, CancellationToken ct = default)
    {
        var user = await db.Users
            .Include(u => u.Department)
            .FirstOrDefaultAsync(u => u.Id == id, ct)
            ?? throw new NotFoundException("User not found.");

        var email = request.Email.Trim().ToLowerInvariant();
        if (await db.Users.AnyAsync(u => u.Email == email && u.Id != id, ct))
            throw new ConflictException("A user with this email already exists.");

        await EnsureDepartmentExistsAsync(request.DepartmentId, ct);

        user.FullName = request.FullName.Trim();
        user.Email = email;
        user.Role = request.Role;
        user.DepartmentId = request.DepartmentId;
        if (!string.IsNullOrWhiteSpace(request.Pin))
            user.PinHash = passwordHasher.Hash(request.Pin);

        await db.SaveChangesAsync(ct);

        await LoadDepartmentAsync(user, ct);
        return user.ToDto();
    }

    public async Task DeactivateAsync(Guid id, CancellationToken ct = default)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == id, ct)
            ?? throw new NotFoundException("User not found.");

        user.IsActive = false;
        user.RefreshToken = null;
        user.RefreshTokenExpiry = null;
        await db.SaveChangesAsync(ct);
    }

    public async Task ReactivateAsync(Guid id, CancellationToken ct = default)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == id, ct)
            ?? throw new NotFoundException("User not found.");

        user.IsActive = true;
        await db.SaveChangesAsync(ct);
    }

    public async Task DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == id, ct)
            ?? throw new NotFoundException("User not found.");

        if (user.IsActive)
            throw new ValidationException("Deactivate the user before permanently deleting them.");

        // Swap requests reference users with a restrict rule, so remove them
        // first; attendance records, assignments and notifications cascade.
        var swaps = await db.ShiftSwapRequests
            .Where(s => s.RequesterId == id || s.TargetUserId == id)
            .ToListAsync(ct);
        db.ShiftSwapRequests.RemoveRange(swaps);

        db.Users.Remove(user);
        await db.SaveChangesAsync(ct);
    }

    public async Task ResetPasswordAsync(Guid id, string newPassword, CancellationToken ct = default)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == id, ct)
            ?? throw new NotFoundException("User not found.");

        user.PasswordHash = passwordHasher.Hash(newPassword);
        // Invalidate existing sessions so the user must sign in with the new password.
        user.RefreshToken = null;
        user.RefreshTokenExpiry = null;
        await db.SaveChangesAsync(ct);
    }

    private async Task EnsureDepartmentExistsAsync(Guid? departmentId, CancellationToken ct)
    {
        if (departmentId is null) return;
        if (!await db.Departments.AnyAsync(d => d.Id == departmentId, ct))
            throw new ValidationException("The specified department does not exist.");
    }

    private async Task LoadDepartmentAsync(User user, CancellationToken ct)
    {
        user.Department = user.DepartmentId is null
            ? null
            : await db.Departments.FirstOrDefaultAsync(d => d.Id == user.DepartmentId, ct);
    }
}

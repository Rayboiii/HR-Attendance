using AttendanceApi.Application.Common.Exceptions;
using AttendanceApi.Application.Common.Interfaces;
using AttendanceApi.Application.DTOs.Auth;
using AttendanceApi.Application.DTOs.Users;
using AttendanceApi.Application.Mapping;
using AttendanceApi.Application.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Application.Services;

public class AuthService(
    IAppDbContext db,
    IPasswordHasher passwordHasher,
    IJwtTokenService jwt) : IAuthService
{
    public async Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken ct = default)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var user = await db.Users
            .Include(u => u.Department)
            .FirstOrDefaultAsync(u => u.Email == email, ct);

        if (user is null || !user.IsActive || !passwordHasher.Verify(request.Password, user.PasswordHash))
            throw new UnauthorizedAppException("Invalid email or password.");

        return await IssueTokensAsync(user, ct);
    }

    public async Task<AuthResponse> RefreshAsync(RefreshRequest request, CancellationToken ct = default)
    {
        var user = await db.Users
            .Include(u => u.Department)
            .FirstOrDefaultAsync(u => u.RefreshToken == request.RefreshToken, ct);

        if (user is null || !user.IsActive
            || user.RefreshTokenExpiry is null || user.RefreshTokenExpiry <= DateTime.UtcNow)
            throw new UnauthorizedAppException("Invalid or expired refresh token.");

        return await IssueTokensAsync(user, ct);
    }

    public async Task LogoutAsync(Guid userId, CancellationToken ct = default)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct)
            ?? throw new NotFoundException("User not found.");

        user.RefreshToken = null;
        user.RefreshTokenExpiry = null;
        await db.SaveChangesAsync(ct);
    }

    public async Task<UserDto> GetMeAsync(Guid userId, CancellationToken ct = default)
    {
        var user = await db.Users
            .Include(u => u.Department)
            .FirstOrDefaultAsync(u => u.Id == userId, ct)
            ?? throw new NotFoundException("User not found.");

        return user.ToDto();
    }

    private async Task<AuthResponse> IssueTokensAsync(Domain.Entities.User user, CancellationToken ct)
    {
        var accessToken = jwt.GenerateAccessToken(user);
        var refreshToken = jwt.GenerateRefreshToken();

        user.RefreshToken = refreshToken;
        user.RefreshTokenExpiry = jwt.GetRefreshTokenExpiry();
        await db.SaveChangesAsync(ct);

        return new AuthResponse(accessToken, refreshToken, jwt.GetAccessTokenExpiry(), user.ToDto());
    }
}

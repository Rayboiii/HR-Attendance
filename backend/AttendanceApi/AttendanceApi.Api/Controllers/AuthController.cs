using AttendanceApi.Application.DTOs.Auth;
using AttendanceApi.Application.DTOs.Users;
using AttendanceApi.Application.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Api.Controllers;

[Authorize]
public class AuthController(IAuthService authService) : ApiControllerBase
{
    [AllowAnonymous]
    [HttpPost("login")]
    public Task<AuthResponse> Login(LoginRequest request, CancellationToken ct)
        => authService.LoginAsync(request, ct);

    [AllowAnonymous]
    [HttpPost("refresh")]
    public Task<AuthResponse> Refresh(RefreshRequest request, CancellationToken ct)
        => authService.RefreshAsync(request, ct);

    [HttpPost("logout")]
    public async Task<IActionResult> Logout(CancellationToken ct)
    {
        await authService.LogoutAsync(CurrentUserId, ct);
        return NoContent();
    }

    [HttpGet("me")]
    public Task<UserDto> Me(CancellationToken ct) => authService.GetMeAsync(CurrentUserId, ct);
}

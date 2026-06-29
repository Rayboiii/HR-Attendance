using AttendanceApi.Application.DTOs.Users;
using AttendanceApi.Application.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Api.Controllers;

[Authorize]
public class UsersController(IUserService userService) : ApiControllerBase
{
    /// Minimal directory of active users, available to any signed-in user
    /// (e.g. so an employee can pick a swap target).
    [HttpGet("directory")]
    public Task<IReadOnlyList<UserSummaryDto>> Directory(CancellationToken ct)
        => userService.GetDirectoryAsync(ct);

    [Authorize(Roles = "Manager")]
    [HttpGet]
    public Task<IReadOnlyList<UserDto>> GetAll(CancellationToken ct) => userService.GetAllAsync(ct);

    [Authorize(Roles = "Manager")]
    [HttpGet("{id:guid}")]
    public Task<UserDto> GetById(Guid id, CancellationToken ct) => userService.GetByIdAsync(id, ct);

    [Authorize(Roles = "Manager")]
    [HttpPost]
    public async Task<ActionResult<UserDto>> Create(CreateUserRequest request, CancellationToken ct)
    {
        var user = await userService.CreateAsync(request, ct);
        return CreatedAtAction(nameof(GetById), new { id = user.Id }, user);
    }

    [Authorize(Roles = "Manager")]
    [HttpPut("{id:guid}")]
    public Task<UserDto> Update(Guid id, UpdateUserRequest request, CancellationToken ct)
        => userService.UpdateAsync(id, request, ct);

    [Authorize(Roles = "Manager")]
    [HttpPatch("{id:guid}/deactivate")]
    public async Task<IActionResult> Deactivate(Guid id, CancellationToken ct)
    {
        await userService.DeactivateAsync(id, ct);
        return NoContent();
    }

    [Authorize(Roles = "Manager")]
    [HttpPatch("{id:guid}/reactivate")]
    public async Task<IActionResult> Reactivate(Guid id, CancellationToken ct)
    {
        await userService.ReactivateAsync(id, ct);
        return NoContent();
    }

    [Authorize(Roles = "Manager")]
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        await userService.DeleteAsync(id, ct);
        return NoContent();
    }

    [Authorize(Roles = "Manager")]
    [HttpPatch("{id:guid}/reset-password")]
    public async Task<IActionResult> ResetPassword(Guid id, ResetPasswordRequest request, CancellationToken ct)
    {
        await userService.ResetPasswordAsync(id, request.NewPassword, ct);
        return NoContent();
    }
}

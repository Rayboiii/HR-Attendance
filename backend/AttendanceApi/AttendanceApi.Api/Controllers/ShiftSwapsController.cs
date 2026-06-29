using AttendanceApi.Application.DTOs.ShiftSwaps;
using AttendanceApi.Application.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Api.Controllers;

[Authorize]
[Route("api/shift-swaps")]
public class ShiftSwapsController(IShiftSwapService swapService) : ApiControllerBase
{
    [HttpPost]
    public Task<ShiftSwapDto> Create(CreateSwapRequest request, CancellationToken ct)
        => swapService.CreateAsync(CurrentUserId, request, ct);

    [HttpGet("my")]
    public Task<IReadOnlyList<ShiftSwapDto>> Mine(CancellationToken ct)
        => swapService.GetMyAsync(CurrentUserId, ct);

    [Authorize(Roles = "Manager")]
    [HttpGet]
    public Task<IReadOnlyList<ShiftSwapDto>> GetAll(CancellationToken ct)
        => swapService.GetAllAsync(ct);

    [Authorize(Roles = "Manager")]
    [HttpPatch("{id:guid}/approve")]
    public Task<ShiftSwapDto> Approve(Guid id, ResolveSwapRequest request, CancellationToken ct)
        => swapService.ApproveAsync(id, request, ct);

    [Authorize(Roles = "Manager")]
    [HttpPatch("{id:guid}/reject")]
    public Task<ShiftSwapDto> Reject(Guid id, ResolveSwapRequest request, CancellationToken ct)
        => swapService.RejectAsync(id, request, ct);
}

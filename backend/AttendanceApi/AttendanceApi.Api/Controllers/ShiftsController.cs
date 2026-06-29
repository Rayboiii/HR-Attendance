using AttendanceApi.Application.DTOs.Shifts;
using AttendanceApi.Application.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Api.Controllers;

[Authorize]
public class ShiftsController(IShiftService shiftService) : ApiControllerBase
{
    [Authorize(Roles = "Manager")]
    [HttpGet]
    public Task<IReadOnlyList<ShiftDto>> GetAll([FromQuery] DateOnly? from, [FromQuery] DateOnly? to, CancellationToken ct)
        => shiftService.GetAllAsync(from, to, ct);

    [HttpGet("my")]
    public Task<IReadOnlyList<ShiftDto>> GetMine([FromQuery] DateOnly? from, [FromQuery] DateOnly? to, CancellationToken ct)
        => shiftService.GetMyShiftsAsync(CurrentUserId, from, to, ct);

    [Authorize(Roles = "Manager")]
    [HttpGet("{id:guid}")]
    public Task<ShiftDto> GetById(Guid id, CancellationToken ct) => shiftService.GetByIdAsync(id, ct);

    [Authorize(Roles = "Manager")]
    [HttpPost]
    public async Task<ActionResult<ShiftDto>> Create(CreateShiftRequest request, CancellationToken ct)
    {
        var shift = await shiftService.CreateAsync(request, ct);
        return CreatedAtAction(nameof(GetById), new { id = shift.Id }, shift);
    }

    [Authorize(Roles = "Manager")]
    [HttpPut("{id:guid}")]
    public Task<ShiftDto> Update(Guid id, UpdateShiftRequest request, CancellationToken ct)
        => shiftService.UpdateAsync(id, request, ct);

    [Authorize(Roles = "Manager")]
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        await shiftService.DeleteAsync(id, ct);
        return NoContent();
    }

    [Authorize(Roles = "Manager")]
    [HttpPost("{id:guid}/assign")]
    public Task<ShiftDto> Assign(Guid id, AssignShiftRequest request, CancellationToken ct)
        => shiftService.AssignAsync(id, request, ct);

    [Authorize(Roles = "Manager")]
    [HttpDelete("{id:guid}/assign/{userId:guid}")]
    public Task<ShiftDto> Unassign(Guid id, Guid userId, CancellationToken ct)
        => shiftService.UnassignAsync(id, userId, ct);
}

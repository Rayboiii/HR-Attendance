using AttendanceApi.Application.DTOs.Departments;
using AttendanceApi.Application.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Api.Controllers;

[Authorize]
public class DepartmentsController(IDepartmentService departmentService) : ApiControllerBase
{
    [HttpGet]
    public Task<IReadOnlyList<DepartmentDto>> GetAll(CancellationToken ct) => departmentService.GetAllAsync(ct);

    [Authorize(Roles = "Manager")]
    [HttpPost]
    public async Task<ActionResult<DepartmentDto>> Create(CreateDepartmentRequest request, CancellationToken ct)
    {
        var department = await departmentService.CreateAsync(request, ct);
        return CreatedAtAction(nameof(GetAll), new { id = department.Id }, department);
    }

    [Authorize(Roles = "Manager")]
    [HttpPut("{id:guid}")]
    public Task<DepartmentDto> Update(Guid id, UpdateDepartmentRequest request, CancellationToken ct)
        => departmentService.UpdateAsync(id, request, ct);

    [Authorize(Roles = "Manager")]
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        await departmentService.DeleteAsync(id, ct);
        return NoContent();
    }
}

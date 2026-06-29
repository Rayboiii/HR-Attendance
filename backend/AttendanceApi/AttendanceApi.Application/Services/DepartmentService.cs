using AttendanceApi.Application.Common.Exceptions;
using AttendanceApi.Application.Common.Interfaces;
using AttendanceApi.Application.DTOs.Departments;
using AttendanceApi.Application.Mapping;
using AttendanceApi.Application.Services.Interfaces;
using AttendanceApi.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Application.Services;

public class DepartmentService(IAppDbContext db) : IDepartmentService
{
    public async Task<IReadOnlyList<DepartmentDto>> GetAllAsync(CancellationToken ct = default)
    {
        var departments = await db.Departments
            .OrderBy(d => d.Name)
            .ToListAsync(ct);

        return departments.Select(d => d.ToDto()).ToList();
    }

    public async Task<DepartmentDto> CreateAsync(CreateDepartmentRequest request, CancellationToken ct = default)
    {
        var department = new Department
        {
            Name = request.Name.Trim(),
            LocationLat = request.LocationLat,
            LocationLng = request.LocationLng,
            RadiusMeters = request.RadiusMeters
        };

        db.Departments.Add(department);
        await db.SaveChangesAsync(ct);
        return department.ToDto();
    }

    public async Task<DepartmentDto> UpdateAsync(Guid id, UpdateDepartmentRequest request, CancellationToken ct = default)
    {
        var department = await db.Departments.FirstOrDefaultAsync(d => d.Id == id, ct)
            ?? throw new NotFoundException("Department not found.");

        department.Name = request.Name.Trim();
        department.LocationLat = request.LocationLat;
        department.LocationLng = request.LocationLng;
        department.RadiusMeters = request.RadiusMeters;

        await db.SaveChangesAsync(ct);
        return department.ToDto();
    }

    public async Task DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var department = await db.Departments.FirstOrDefaultAsync(d => d.Id == id, ct)
            ?? throw new NotFoundException("Department not found.");

        if (await db.Users.AnyAsync(u => u.DepartmentId == id, ct))
            throw new ConflictException("Cannot delete a department that still has users assigned.");

        if (await db.Shifts.AnyAsync(s => s.DepartmentId == id, ct))
            throw new ConflictException("Cannot delete a department that still has shifts.");

        db.Departments.Remove(department);
        await db.SaveChangesAsync(ct);
    }
}

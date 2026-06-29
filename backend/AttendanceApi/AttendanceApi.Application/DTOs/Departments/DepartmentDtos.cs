using System.ComponentModel.DataAnnotations;

namespace AttendanceApi.Application.DTOs.Departments;

public record DepartmentDto(
    Guid Id,
    string Name,
    double? LocationLat,
    double? LocationLng,
    double RadiusMeters);

public record CreateDepartmentRequest(
    [Required] string Name,
    double? LocationLat,
    double? LocationLng,
    [Range(1, 100000)] double RadiusMeters = 200);

public record UpdateDepartmentRequest(
    [Required] string Name,
    double? LocationLat,
    double? LocationLng,
    [Range(1, 100000)] double RadiusMeters);

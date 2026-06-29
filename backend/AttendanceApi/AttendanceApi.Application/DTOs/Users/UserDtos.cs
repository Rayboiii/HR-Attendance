using System.ComponentModel.DataAnnotations;
using AttendanceApi.Domain.Enums;

namespace AttendanceApi.Application.DTOs.Users;

/// Minimal user info any authenticated user may read (e.g. to pick a swap target).
public record UserSummaryDto(
    Guid Id,
    string FullName,
    string? DepartmentName);

public record UserDto(
    Guid Id,
    string FullName,
    string Email,
    UserRole Role,
    Guid? DepartmentId,
    string? DepartmentName,
    bool IsActive,
    DateTime CreatedAt);

public record CreateUserRequest(
    [Required] string FullName,
    [Required, EmailAddress] string Email,
    [Required, MinLength(6)] string Password,
    UserRole Role,
    Guid? DepartmentId,
    [RegularExpression(@"^\d{4,6}$", ErrorMessage = "PIN must be 4-6 digits.")] string? Pin);

public record ResetPasswordRequest(
    [Required, MinLength(6)] string NewPassword);

public record UpdateUserRequest(
    [Required] string FullName,
    [Required, EmailAddress] string Email,
    UserRole Role,
    Guid? DepartmentId,
    [RegularExpression(@"^\d{4,6}$", ErrorMessage = "PIN must be 4-6 digits.")] string? Pin);

using AttendanceApi.Application.DTOs.Attendance;

namespace AttendanceApi.Application.Services.Interfaces;

public interface IAttendanceService
{
    Task<AttendanceRecordDto> ClockInAsync(Guid userId, ClockInRequest request, CancellationToken ct = default);
    Task<AttendanceRecordDto> ClockOutAsync(Guid userId, ClockOutRequest request, CancellationToken ct = default);
    Task<AttendanceRecordDto?> GetTodayAsync(Guid userId, CancellationToken ct = default);
    Task<IReadOnlyList<AttendanceRecordDto>> GetMyAsync(Guid userId, DateOnly? from, DateOnly? to, CancellationToken ct = default);
    Task<IReadOnlyList<AttendanceRecordDto>> GetAllAsync(DateOnly? from, DateOnly? to, Guid? departmentId, CancellationToken ct = default);
    Task<IReadOnlyList<AttendanceRecordDto>> GetByUserAsync(Guid userId, DateOnly? from, DateOnly? to, CancellationToken ct = default);
}

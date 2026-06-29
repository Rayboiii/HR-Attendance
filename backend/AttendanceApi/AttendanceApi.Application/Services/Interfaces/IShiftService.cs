using AttendanceApi.Application.DTOs.Shifts;

namespace AttendanceApi.Application.Services.Interfaces;

public interface IShiftService
{
    Task<IReadOnlyList<ShiftDto>> GetAllAsync(DateOnly? from, DateOnly? to, CancellationToken ct = default);
    Task<ShiftDto> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<ShiftDto> CreateAsync(CreateShiftRequest request, CancellationToken ct = default);
    Task<ShiftDto> UpdateAsync(Guid id, UpdateShiftRequest request, CancellationToken ct = default);
    Task DeleteAsync(Guid id, CancellationToken ct = default);
    Task<IReadOnlyList<ShiftDto>> GetMyShiftsAsync(Guid userId, DateOnly? from, DateOnly? to, CancellationToken ct = default);
    Task<ShiftDto> AssignAsync(Guid shiftId, AssignShiftRequest request, CancellationToken ct = default);
    Task<ShiftDto> UnassignAsync(Guid shiftId, Guid userId, CancellationToken ct = default);
}

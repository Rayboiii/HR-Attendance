using AttendanceApi.Application.DTOs.ShiftSwaps;

namespace AttendanceApi.Application.Services.Interfaces;

public interface IShiftSwapService
{
    Task<ShiftSwapDto> CreateAsync(Guid requesterId, CreateSwapRequest request, CancellationToken ct = default);
    Task<IReadOnlyList<ShiftSwapDto>> GetMyAsync(Guid userId, CancellationToken ct = default);
    Task<IReadOnlyList<ShiftSwapDto>> GetAllAsync(CancellationToken ct = default);
    Task<ShiftSwapDto> ApproveAsync(Guid id, ResolveSwapRequest request, CancellationToken ct = default);
    Task<ShiftSwapDto> RejectAsync(Guid id, ResolveSwapRequest request, CancellationToken ct = default);
}

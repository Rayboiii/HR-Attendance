using AttendanceApi.Domain.Enums;

namespace AttendanceApi.Domain.Entities;

public class ShiftSwapRequest
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid RequesterId { get; set; }
    public Guid TargetUserId { get; set; }
    public Guid RequesterShiftId { get; set; }
    public SwapStatus Status { get; set; } = SwapStatus.Pending;
    public string? ManagerNote { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ResolvedAt { get; set; }

    public User? Requester { get; set; }
    public User? TargetUser { get; set; }
    public Shift? RequesterShift { get; set; }
}

namespace AttendanceApi.Domain.Entities;

public class ShiftAssignment
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ShiftId { get; set; }
    public Guid UserId { get; set; }
    public DateTime AssignedAt { get; set; } = DateTime.UtcNow;

    public Shift? Shift { get; set; }
    public User? User { get; set; }
}

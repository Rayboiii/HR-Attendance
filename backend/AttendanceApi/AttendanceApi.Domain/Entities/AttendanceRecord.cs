using AttendanceApi.Domain.Enums;

namespace AttendanceApi.Domain.Entities;

public class AttendanceRecord
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public Guid? ShiftId { get; set; }
    public DateTime ClockInTime { get; set; }
    public DateTime? ClockOutTime { get; set; }
    public ClockInMethod ClockInMethod { get; set; }
    public double? LocationLat { get; set; }
    public double? LocationLng { get; set; }
    public AttendanceStatus Status { get; set; } = AttendanceStatus.Present;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
    public Shift? Shift { get; set; }
}

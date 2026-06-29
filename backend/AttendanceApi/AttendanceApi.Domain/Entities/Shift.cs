namespace AttendanceApi.Domain.Entities;

public class Shift
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid DepartmentId { get; set; }
    public string Name { get; set; } = string.Empty;
    public DateOnly Date { get; set; }
    public TimeOnly StartTime { get; set; }
    public TimeOnly EndTime { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Department? Department { get; set; }
    public ICollection<ShiftAssignment> Assignments { get; set; } = [];
    public ICollection<QrToken> QrTokens { get; set; } = [];
}

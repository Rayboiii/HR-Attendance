namespace AttendanceApi.Domain.Entities;

public class Department
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = string.Empty;
    public double? LocationLat { get; set; }
    public double? LocationLng { get; set; }
    public double RadiusMeters { get; set; } = 200;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<User> Users { get; set; } = [];
    public ICollection<Shift> Shifts { get; set; } = [];
}

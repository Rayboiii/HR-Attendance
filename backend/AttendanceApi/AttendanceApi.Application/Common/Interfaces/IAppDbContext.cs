using AttendanceApi.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Application.Common.Interfaces;

public interface IAppDbContext
{
    DbSet<User> Users { get; }
    DbSet<Department> Departments { get; }
    DbSet<Shift> Shifts { get; }
    DbSet<ShiftAssignment> ShiftAssignments { get; }
    DbSet<AttendanceRecord> AttendanceRecords { get; }
    DbSet<ShiftSwapRequest> ShiftSwapRequests { get; }
    DbSet<Notification> Notifications { get; }
    DbSet<QrToken> QrTokens { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}

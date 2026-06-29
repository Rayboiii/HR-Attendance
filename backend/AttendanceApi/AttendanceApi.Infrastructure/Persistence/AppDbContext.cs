using AttendanceApi.Application.Common.Interfaces;
using AttendanceApi.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Infrastructure.Persistence;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options), IAppDbContext
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Department> Departments => Set<Department>();
    public DbSet<Shift> Shifts => Set<Shift>();
    public DbSet<ShiftAssignment> ShiftAssignments => Set<ShiftAssignment>();
    public DbSet<AttendanceRecord> AttendanceRecords => Set<AttendanceRecord>();
    public DbSet<ShiftSwapRequest> ShiftSwapRequests => Set<ShiftSwapRequest>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<QrToken> QrTokens => Set<QrToken>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        base.OnModelCreating(b);

        b.Entity<User>(e =>
        {
            e.Property(u => u.FullName).IsRequired().HasMaxLength(200);
            e.Property(u => u.Email).IsRequired().HasMaxLength(256);
            e.HasIndex(u => u.Email).IsUnique();
            e.Property(u => u.PasswordHash).IsRequired();

            e.HasOne(u => u.Department)
                .WithMany(d => d.Users)
                .HasForeignKey(u => u.DepartmentId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        b.Entity<Department>(e =>
        {
            e.Property(d => d.Name).IsRequired().HasMaxLength(200);
        });

        b.Entity<Shift>(e =>
        {
            e.Property(s => s.Name).IsRequired().HasMaxLength(200);

            e.HasOne(s => s.Department)
                .WithMany(d => d.Shifts)
                .HasForeignKey(s => s.DepartmentId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        b.Entity<ShiftAssignment>(e =>
        {
            e.HasIndex(a => new { a.ShiftId, a.UserId }).IsUnique();

            e.HasOne(a => a.Shift)
                .WithMany(s => s.Assignments)
                .HasForeignKey(a => a.ShiftId)
                .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(a => a.User)
                .WithMany(u => u.ShiftAssignments)
                .HasForeignKey(a => a.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        b.Entity<AttendanceRecord>(e =>
        {
            e.HasOne(a => a.User)
                .WithMany(u => u.AttendanceRecords)
                .HasForeignKey(a => a.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(a => a.Shift)
                .WithMany()
                .HasForeignKey(a => a.ShiftId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        b.Entity<ShiftSwapRequest>(e =>
        {
            // Multiple FKs into the same tables — keep them non-cascading to
            // avoid PostgreSQL multiple-cascade-path errors.
            e.HasOne(r => r.Requester)
                .WithMany()
                .HasForeignKey(r => r.RequesterId)
                .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(r => r.TargetUser)
                .WithMany()
                .HasForeignKey(r => r.TargetUserId)
                .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(r => r.RequesterShift)
                .WithMany()
                .HasForeignKey(r => r.RequesterShiftId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        b.Entity<Notification>(e =>
        {
            e.Property(n => n.Title).IsRequired().HasMaxLength(200);

            e.HasOne(n => n.User)
                .WithMany(u => u.Notifications)
                .HasForeignKey(n => n.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        b.Entity<QrToken>(e =>
        {
            e.Property(q => q.Token).IsRequired().HasMaxLength(128);
            e.HasIndex(q => q.Token).IsUnique();

            e.HasOne(q => q.Shift)
                .WithMany(s => s.QrTokens)
                .HasForeignKey(q => q.ShiftId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}

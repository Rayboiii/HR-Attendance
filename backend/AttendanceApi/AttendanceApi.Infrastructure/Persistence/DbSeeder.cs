using AttendanceApi.Application.Common.Interfaces;
using AttendanceApi.Domain.Entities;
using AttendanceApi.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace AttendanceApi.Infrastructure.Persistence;

public static class DbSeeder
{
    public const string DefaultManagerEmail = "admin@kaizenhr.local";
    public const string DefaultManagerPassword = "Admin123!";

    /// <summary>
    /// Applies pending migrations and ensures a bootstrap Manager account exists.
    /// Intended for development so the very first user can sign in and create others.
    /// </summary>
    public static async Task SeedAsync(IServiceProvider services, CancellationToken ct = default)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var hasher = scope.ServiceProvider.GetRequiredService<IPasswordHasher>();

        await db.Database.MigrateAsync(ct);

        if (await db.Users.AnyAsync(u => u.Role == UserRole.Manager, ct))
            return;

        db.Users.Add(new User
        {
            FullName = "System Admin",
            Email = DefaultManagerEmail,
            PasswordHash = hasher.Hash(DefaultManagerPassword),
            Role = UserRole.Manager,
            IsActive = true
        });

        await db.SaveChangesAsync(ct);
    }
}

using AttendanceApi.Application.Common.Exceptions;
using AttendanceApi.Application.Common.Interfaces;
using AttendanceApi.Application.DTOs.Notifications;
using AttendanceApi.Application.Mapping;
using AttendanceApi.Application.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Application.Services;

public class NotificationService(IAppDbContext db) : INotificationService
{
    public async Task<IReadOnlyList<NotificationDto>> GetAsync(Guid userId, bool unreadOnly, CancellationToken ct = default)
    {
        var query = db.Notifications.Where(n => n.UserId == userId);
        if (unreadOnly)
            query = query.Where(n => !n.IsRead);

        var notifications = await query
            .OrderByDescending(n => n.CreatedAt)
            .ToListAsync(ct);

        return notifications.Select(n => n.ToDto()).ToList();
    }

    public async Task MarkReadAsync(Guid userId, Guid notificationId, CancellationToken ct = default)
    {
        var notification = await db.Notifications
            .FirstOrDefaultAsync(n => n.Id == notificationId && n.UserId == userId, ct)
            ?? throw new NotFoundException("Notification not found.");

        notification.IsRead = true;
        await db.SaveChangesAsync(ct);
    }
}

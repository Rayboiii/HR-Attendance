using AttendanceApi.Application.DTOs.Notifications;

namespace AttendanceApi.Application.Services.Interfaces;

public interface INotificationService
{
    Task<IReadOnlyList<NotificationDto>> GetAsync(Guid userId, bool unreadOnly, CancellationToken ct = default);
    Task MarkReadAsync(Guid userId, Guid notificationId, CancellationToken ct = default);
}

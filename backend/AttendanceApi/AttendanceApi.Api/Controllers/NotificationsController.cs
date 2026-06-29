using AttendanceApi.Application.DTOs.Notifications;
using AttendanceApi.Application.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Api.Controllers;

[Authorize]
public class NotificationsController(INotificationService notificationService) : ApiControllerBase
{
    [HttpGet]
    public Task<IReadOnlyList<NotificationDto>> Get([FromQuery] bool unreadOnly = false, CancellationToken ct = default)
        => notificationService.GetAsync(CurrentUserId, unreadOnly, ct);

    [HttpPatch("{id:guid}/read")]
    public async Task<IActionResult> MarkRead(Guid id, CancellationToken ct)
    {
        await notificationService.MarkReadAsync(CurrentUserId, id, ct);
        return NoContent();
    }
}

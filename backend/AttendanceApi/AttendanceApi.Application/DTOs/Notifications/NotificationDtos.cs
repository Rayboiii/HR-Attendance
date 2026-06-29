namespace AttendanceApi.Application.DTOs.Notifications;

public record NotificationDto(
    Guid Id,
    string Title,
    string Message,
    bool IsRead,
    DateTime CreatedAt);

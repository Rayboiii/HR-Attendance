using AttendanceApi.Application.Services;
using AttendanceApi.Application.Services.Interfaces;
using Microsoft.Extensions.DependencyInjection;

namespace AttendanceApi.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<IDepartmentService, DepartmentService>();
        services.AddScoped<IShiftService, ShiftService>();
        services.AddScoped<IAttendanceService, AttendanceService>();
        services.AddScoped<IQrService, QrService>();
        services.AddScoped<IShiftSwapService, ShiftSwapService>();
        services.AddScoped<INotificationService, NotificationService>();
        services.AddScoped<IReportService, ReportService>();

        return services;
    }
}

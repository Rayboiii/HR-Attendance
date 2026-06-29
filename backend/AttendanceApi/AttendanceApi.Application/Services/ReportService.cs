using AttendanceApi.Application.Common;
using AttendanceApi.Application.Common.Interfaces;
using AttendanceApi.Application.DTOs.Reports;
using AttendanceApi.Application.Services.Interfaces;
using AttendanceApi.Domain.Entities;
using AttendanceApi.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace AttendanceApi.Application.Services;

public class ReportService(IAppDbContext db) : IReportService
{
    public async Task<IReadOnlyList<AttendanceReportRow>> GetAttendanceReportAsync(
        DateOnly from, DateOnly to, Guid? departmentId, CancellationToken ct = default)
    {
        var records = await FetchRecordsAsync(from, to, departmentId, ct);

        return records
            .GroupBy(r => new { r.UserId, Name = r.User?.FullName ?? string.Empty })
            .Select(g => new AttendanceReportRow(
                g.Key.UserId,
                g.Key.Name,
                TotalDays: g.Count(),
                PresentCount: g.Count(r => r.Status == AttendanceStatus.Present),
                LateCount: g.Count(r => r.Status == AttendanceStatus.Late),
                AbsentCount: g.Count(r => r.Status == AttendanceStatus.Absent),
                HalfDayCount: g.Count(r => r.Status == AttendanceStatus.HalfDay),
                TotalWorkedHours: Math.Round(g.Sum(WorkedHours), 2)))
            .OrderBy(r => r.FullName)
            .ToList();
    }

    public async Task<IReadOnlyList<OvertimeReportRow>> GetOvertimeReportAsync(
        DateOnly from, DateOnly to, Guid? departmentId, CancellationToken ct = default)
    {
        var records = await FetchRecordsAsync(from, to, departmentId, ct);

        return records
            .Where(r => r.ClockOutTime is not null)
            .GroupBy(r => new { r.UserId, Name = r.User?.FullName ?? string.Empty })
            .Select(g =>
            {
                var worked = Math.Round(g.Sum(WorkedHours), 2);
                var standard = g.Count() * AttendancePolicy.StandardHoursPerDay;
                return new OvertimeReportRow(
                    g.Key.UserId,
                    g.Key.Name,
                    worked,
                    standard,
                    Math.Round(Math.Max(0, worked - standard), 2));
            })
            .OrderByDescending(r => r.OvertimeHours)
            .ToList();
    }

    private async Task<List<AttendanceRecord>> FetchRecordsAsync(
        DateOnly from, DateOnly to, Guid? departmentId, CancellationToken ct)
    {
        if (to < from)
            throw new Common.Exceptions.ValidationException("'to' date must not be before 'from' date.");

        var fromUtc = from.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc);
        var toUtc = to.AddDays(1).ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc);

        var query = db.AttendanceRecords
            .Include(a => a.User)
            .Where(a => a.ClockInTime >= fromUtc && a.ClockInTime < toUtc);

        if (departmentId is not null)
            query = query.Where(a => a.User != null && a.User.DepartmentId == departmentId);

        return await query.ToListAsync(ct);
    }

    private static double WorkedHours(AttendanceRecord r) =>
        r.ClockOutTime is null ? 0 : (r.ClockOutTime.Value - r.ClockInTime).TotalHours;
}

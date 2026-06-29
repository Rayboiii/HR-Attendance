namespace AttendanceApi.Application.Common;

/// <summary>
/// Business rules for attendance evaluation. Kept here so the domain logic
/// lives in the Application layer rather than being scattered across services.
/// </summary>
public static class AttendancePolicy
{
    /// <summary>Minutes after shift start before a clock-in counts as Late.</summary>
    public const int LateGraceMinutes = 15;

    /// <summary>Standard paid hours per worked day; anything beyond is overtime.</summary>
    public const double StandardHoursPerDay = 8.0;
}

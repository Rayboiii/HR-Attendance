namespace AttendanceApi.Application.Common.Exceptions;

/// <summary>
/// Base class for expected, handled application errors. The global exception
/// middleware maps each subtype to an HTTP status code.
/// </summary>
public abstract class AppException(string message) : Exception(message)
{
    public abstract int StatusCode { get; }
}

public sealed class NotFoundException(string message) : AppException(message)
{
    public override int StatusCode => 404;
}

public sealed class ValidationException(string message) : AppException(message)
{
    public override int StatusCode => 400;
}

public sealed class ConflictException(string message) : AppException(message)
{
    public override int StatusCode => 409;
}

public sealed class UnauthorizedAppException(string message) : AppException(message)
{
    public override int StatusCode => 401;
}

public sealed class ForbiddenException(string message) : AppException(message)
{
    public override int StatusCode => 403;
}

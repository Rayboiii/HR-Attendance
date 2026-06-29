using AttendanceApi.Application.Common.Interfaces;

namespace AttendanceApi.Infrastructure.Services;

public class PasswordHasher : IPasswordHasher
{
    public string Hash(string plainText) => BCrypt.Net.BCrypt.HashPassword(plainText);

    public bool Verify(string plainText, string hash)
    {
        try
        {
            return BCrypt.Net.BCrypt.Verify(plainText, hash);
        }
        catch (BCrypt.Net.SaltParseException)
        {
            // Malformed/legacy hash – treat as a failed verification rather than throwing.
            return false;
        }
    }
}

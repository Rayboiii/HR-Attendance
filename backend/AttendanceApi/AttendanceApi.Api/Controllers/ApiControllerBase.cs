using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public abstract class ApiControllerBase : ControllerBase
{
    /// <summary>The authenticated user's id, taken from the JWT. Only valid on [Authorize] actions.</summary>
    protected Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)
                   ?? throw new InvalidOperationException("Authenticated user has no id claim."));
}

using AttendanceApi.Application.DTOs.Qr;
using AttendanceApi.Application.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Api.Controllers;

[Authorize(Roles = "Manager")]
[Route("api/qr")]
public class QrController(IQrService qrService) : ApiControllerBase
{
    [HttpPost("generate/{shiftId:guid}")]
    public Task<QrTokenDto> Generate(Guid shiftId, GenerateQrRequest request, CancellationToken ct)
        => qrService.GenerateAsync(shiftId, request, ct);
}

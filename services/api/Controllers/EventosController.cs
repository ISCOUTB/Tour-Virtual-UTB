using Microsoft.AspNetCore.Mvc;
using TourVirtualUTB.Api.DTOs;
using TourVirtualUTB.Api.Services;

namespace TourVirtualUTB.Api.Controllers;

/// <summary>
/// La app avisa aquí lo que pasa en el tour (abrir el mapa, ver una escena...).
/// Es público: no lleva clave. Con estos eventos se calculan las métricas.
/// </summary>
[ApiController]
[Route("api/eventos")]
public class EventosController(PanelService panel) : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> Registrar([FromBody] RegistrarEventoRequest request)
    {
        var error = await panel.RegistrarEventoAsync(request);
        if (error is not null) return BadRequest(error);
        return NoContent();
    }
}

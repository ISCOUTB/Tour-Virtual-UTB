using Microsoft.AspNetCore.Mvc;
using TourVirtualUTB.Api.DTOs;
using TourVirtualUTB.Api.Services;

namespace TourVirtualUTB.Api.Controllers;

[ApiController]
[Route("api/admin/hotspots")]
[RequiereClaveAdmin]
public class AdminHotspotsController(IContenidoService contenidoService) : ControllerBase
{
    [HttpPost]
    public async Task<ActionResult<HotspotDto>> CrearHotspot([FromBody] CrearHotspotRequest request)
    {
        var hotspot = await contenidoService.CrearHotspotAsync(request);
        return Ok(hotspot);
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<HotspotDto>> ActualizarHotspot(int id, [FromBody] ActualizarHotspotRequest request)
    {
        var hotspot = await contenidoService.ActualizarHotspotAsync(id, request);
        if (hotspot == null) return NotFound("El hotspot no existe.");
        
        return Ok(hotspot);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> EliminarHotspot(int id)
    {
        var eliminado = await contenidoService.EliminarHotspotAsync(id);
        if (!eliminado) return NotFound("El hotspot no existe.");

        return NoContent();
    }
}
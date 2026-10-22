using Microsoft.AspNetCore.Mvc;
using TourVirtualUTB.Api.DTOs;
using TourVirtualUTB.Api.Services;

namespace TourVirtualUTB.Api.Controllers;

[ApiController]
[Route("api/admin/rutas")]
[RequiereClaveAdmin]
public class AdminRutasController(IContenidoService contenidoService) : ControllerBase
{
    [HttpPost]
    public async Task<ActionResult<RutaDto>> CrearRuta([FromBody] CrearRutaRequest request)
    {
        var ruta = await contenidoService.CrearRutaAsync(request);
        return Ok(ruta);
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<RutaDto>> ActualizarRuta(int id, [FromBody] ActualizarRutaRequest request)
    {
        var ruta = await contenidoService.ActualizarRutaAsync(id, request);
        if (ruta == null) return NotFound("La ruta sugerida no existe.");
        
        return Ok(ruta);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> EliminarRuta(int id)
    {
        var eliminado = await contenidoService.EliminarRutaAsync(id);
        if (!eliminado) return NotFound("La ruta sugerida no existe.");

        return NoContent();
    }
}
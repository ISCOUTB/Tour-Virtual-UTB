using Microsoft.AspNetCore.Mvc;
using TourVirtualUTB.Api.DTOs;
using TourVirtualUTB.Api.Models;
using TourVirtualUTB.Api.Services;

namespace TourVirtualUTB.Api.Controllers;

[ApiController]
[Route("api/admin/lugares")]
public class AdminLugaresController(IContenidoService contenidoService) : ControllerBase
{
    [HttpPost]
    public async Task<ActionResult<Lugar>> CrearLugar([FromBody] CrearLugarRequest request)
    {
        var lugar = await contenidoService.CrearLugarAsync(request);
        return Ok(lugar);
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<Lugar>> ActualizarLugar(int id, [FromBody] ActualizarLugarRequest request)
    {
        var lugar = await contenidoService.ActualizarLugarAsync(id, request);
        if (lugar == null) return NotFound("El lugar no existe.");
        
        return Ok(lugar);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> EliminarLugar(int id)
    {
        var eliminado = await contenidoService.EliminarLugarAsync(id);
        if (!eliminado) return NotFound("El lugar no existe.");

        return NoContent();
    }
}
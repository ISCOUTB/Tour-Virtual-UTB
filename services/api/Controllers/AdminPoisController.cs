using Microsoft.AspNetCore.Mvc;
using TourVirtualUTB.Api.DTOs;
using TourVirtualUTB.Api.Services;

namespace TourVirtualUTB.Api.Controllers;

[ApiController]
[Route("api/admin/pois")]
public class AdminPoisController(IContenidoService contenidoService) : ControllerBase
{
    [HttpPost]
    public async Task<ActionResult<PoiDto>> CrearPoi([FromBody] CrearPoiRequest request)
    {
        var poi = await contenidoService.CrearPoiAsync(request);
        // Devuelve 201 Created y la ruta para consultar el nuevo recurso
        return CreatedAtAction(
            actionName: "ObtenerPoi", 
            controllerName: "Contenido", 
            routeValues: new { poiId = poi.id }, 
            value: poi);
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<PoiDto>> ActualizarPoi(int id, [FromBody] ActualizarPoiRequest request)
    {
        var poi = await contenidoService.ActualizarPoiAsync(id, request);
        if (poi == null) return NotFound("El punto de interés no existe.");
        
        return Ok(poi);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> EliminarPoi(int id)
    {
        var eliminado = await contenidoService.EliminarPoiAsync(id);
        if (!eliminado) return NotFound("El punto de interés no existe.");

        return NoContent(); // 204 No Content para eliminaciones exitosas
    }
}
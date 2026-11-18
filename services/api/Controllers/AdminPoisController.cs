using Microsoft.AspNetCore.Mvc;
using TourVirtualUTB.Api.DTOs;
using TourVirtualUTB.Api.Services;

namespace TourVirtualUTB.Api.Controllers;

[ApiController]
[Route("api/admin/pois")]
[RequiereClaveAdmin]
public class AdminPoisController(IContenidoService contenidoService) : ControllerBase
{
    /// <summary>
    /// Detalle de un POI (activo o inactivo) con medios y escenas.
    /// </summary>
    // Declarar el 404 hace que Swagger deje de deducir el 200: van los dos.
    [HttpGet("{id:int}")]
    [ProducesResponseType<PoiDetalleAdminDto>(StatusCodes.Status200OK)]
    [ProducesResponseType<string>(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PoiDetalleAdminDto>> ObtenerPoiAdmin(int id)
    {
        var detalle = await contenidoService.ObtenerPoiAdminPorIdAsync(id);
        if (detalle is null) return NotFound("El punto de interés no existe.");
        return Ok(detalle);
    }

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
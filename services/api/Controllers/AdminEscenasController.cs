using Microsoft.AspNetCore.Mvc;
using TourVirtualUTB.Api.DTOs;
using TourVirtualUTB.Api.Services;
using TourVirtualUTB.Api.Data;

namespace TourVirtualUTB.Api.Controllers;

[ApiController]
[Route("api/admin/escenas")]
public class AdminEscenasController(
    IContenidoService contenidoService, 
    IAlmacenamientoService almacenamientoService, 
    TourDbContext db) : ControllerBase
{
    [HttpPost]
    public async Task<ActionResult<EscenaDto>> CrearEscena([FromBody] CrearEscenaRequest request)
    {
        var escena = await contenidoService.CrearEscenaAsync(request);
        return Ok(escena); // Podrías usar CreatedAtAction si tuvieras un GET de escena individual
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<EscenaDto>> ActualizarEscena(int id, [FromBody] ActualizarEscenaRequest request)
    {
        var escena = await contenidoService.ActualizarEscenaAsync(id, request);
        if (escena == null) return NotFound("La escena no existe.");
        
        return Ok(escena);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> EliminarEscena(int id)
    {
        var eliminado = await contenidoService.EliminarEscenaAsync(id);
        if (!eliminado) return NotFound("La escena no existe.");

        return NoContent();
    }

    [HttpPost("{id:int}/imagen")]
    public async Task<IActionResult> SubirImagenEscena(int id, [FromForm] SubirMultimediaRequest request, [FromQuery] bool esBajaResolucion = false)
    {
        if (request.Archivo == null || request.Archivo.Length == 0)
            return BadRequest("No se proporcionó ningún archivo.");

        // Subimos a S3
        var rutaS3 = await almacenamientoService.SubirArchivoAsync(request.Archivo, request.Carpeta ?? "panoramas");

        // Actualizamos la base de datos
        var escena = await db.Escenas.FindAsync(id);
        if (escena == null) return NotFound("La escena no existe.");

        if (esBajaResolucion)
            escena.ImagenUrlBaja = rutaS3;
        else
            escena.ImagenUrl = rutaS3;

        await db.SaveChangesAsync();

        return Ok(new { mensaje = "Imagen de escena subida correctamente", rutaS3 });
    }
}
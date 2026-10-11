using Microsoft.AspNetCore.Mvc;
using TourVirtualUTB.Api.DTOs;
using TourVirtualUTB.Api.Services;
using TourVirtualUTB.Api.Data;

namespace TourVirtualUTB.Api.Controllers;

[ApiController]
[Route("api/admin/medios")]
public class AdminMediosController(
    IContenidoService contenidoService, 
    IAlmacenamientoService almacenamientoService, 
    TourDbContext db) : ControllerBase
{
    [HttpPost]
    public async Task<ActionResult<MedioDto>> CrearMedio([FromBody] CrearMedioRequest request)
    {
        var medio = await contenidoService.CrearMedioAsync(request);
        return Ok(medio);
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<MedioDto>> ActualizarMedio(int id, [FromBody] ActualizarMedioRequest request)
    {
        var medio = await contenidoService.ActualizarMedioAsync(id, request);
        if (medio == null) return NotFound("El medio (multimedia) no existe.");
        
        return Ok(medio);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> EliminarMedio(int id)
    {
        var eliminado = await contenidoService.EliminarMedioAsync(id);
        if (!eliminado) return NotFound("El medio (multimedia) no existe.");

        return NoContent();
    }

    [HttpPost("{id:int}/archivo")]
    public async Task<IActionResult> SubirArchivoMedio(int id, [FromForm] SubirMultimediaRequest request)
    {
        if (request.Archivo == null || request.Archivo.Length == 0)
            return BadRequest("No se proporcionó ningún archivo.");

        // Subimos a S3
        var rutaS3 = await almacenamientoService.SubirArchivoAsync(request.Archivo, request.Carpeta ?? "medios");

        // Actualizamos la base de datos
        var medio = await db.Medios.FindAsync(id);
        if (medio == null) return NotFound("El medio no existe.");

        medio.Url = rutaS3;
        await db.SaveChangesAsync();

        return Ok(new { mensaje = "Archivo multimedia subido correctamente", rutaS3 });
    }
}
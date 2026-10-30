using Microsoft.AspNetCore.Mvc;
using TourVirtualUTB.Api.DTOs;
using TourVirtualUTB.Api.Services;
using TourVirtualUTB.Api.Data;

namespace TourVirtualUTB.Api.Controllers;

[ApiController]
[Route("api/admin/escenas")]
[RequiereClaveAdmin]
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

    /// <summary>
    /// Sube la panorámica de la escena. El servidor la reduce a 4096x2048,
    /// genera la versión de 1024x512 y borra los metadatos, y guarda ambas
    /// (ImagenUrl e ImagenUrlBaja) de una vez.
    /// </summary>
    [HttpPost("{id:int}/imagen")]
    [RequestSizeLimit(TiposArchivo.TamanoMaximoBytes + 1024 * 1024)]
    [RequestFormLimits(MultipartBodyLengthLimit = TiposArchivo.TamanoMaximoBytes + 1024 * 1024)]
    public async Task<IActionResult> SubirImagenEscena(int id, [FromForm] SubirMultimediaRequest request)
    {
        // Se busca antes de subir: con un id equivocado el archivo quedaba
        // huérfano en el bucket.
        var escena = await db.Escenas.FindAsync(id);
        if (escena == null) return NotFound("La escena no existe.");

        if (request.Archivo == null || request.Archivo.Length == 0)
            return BadRequest("No se proporcionó ningún archivo.");

        if (!TiposArchivo.TieneExtension(request.Archivo.FileName, TiposArchivo.ExtensionesPanorama))
            return BadRequest($"La panorámica debe ser {string.Join(", ", TiposArchivo.ExtensionesPanorama)}.");

        var carpeta = TiposArchivo.ResolverCarpeta(request.Carpeta, "panoramas");
        if (carpeta is null) return BadRequest(TiposArchivo.MensajeCarpetaInvalida);

        PanoramaProcesada panorama;
        try
        {
            await using var original = request.Archivo.OpenReadStream();
            panorama = ProcesadorImagenes.ProcesarPanorama(original);
        }
        catch (ImagenNoValidaException ex)
        {
            return BadRequest(ex.Message);
        }

        await using (panorama.Completa.Contenido)
        await using (panorama.Baja.Contenido)
        {
            var nombre = Path.GetFileNameWithoutExtension(request.Archivo.FileName);
            escena.ImagenUrl = await almacenamientoService.SubirStreamAsync(
                panorama.Completa.Contenido, carpeta, $"{nombre}.jpg", "image/jpeg");
            escena.ImagenUrlBaja = await almacenamientoService.SubirStreamAsync(
                panorama.Baja.Contenido, carpeta, $"{nombre}-baja.jpg", "image/jpeg");
        }

        await db.SaveChangesAsync();

        return Ok(new
        {
            mensaje = "Panorámica subida correctamente",
            imagenUrl = escena.ImagenUrl,
            imagenUrlBaja = escena.ImagenUrlBaja,
            tamano = $"{panorama.Completa.Ancho}x{panorama.Completa.Alto}",
            tamanoBaja = $"{panorama.Baja.Ancho}x{panorama.Baja.Alto}",
            // El visor espera equirectangular 2:1; otra proporción se ve deformada.
            advertencia = Math.Abs((double)panorama.Completa.Ancho / panorama.Completa.Alto - 2) > 0.05
                ? "La imagen no tiene proporción 2:1; en el visor 360 se verá deformada."
                : null
        });
    }
}

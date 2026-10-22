using Microsoft.AspNetCore.Mvc;
using TourVirtualUTB.Api.DTOs;
using TourVirtualUTB.Api.Models;
using TourVirtualUTB.Api.Services;

namespace TourVirtualUTB.Api.Controllers;

[ApiController]
[Route("api")]
public class ContenidoController(
    IContenidoService contenidoService, 
    IAlmacenamientoService almacenamientoService) : ControllerBase // <-- ¡Eliminamos TourDbContext!
{
    private Audiencia AudienciaActual =>
        Request.Headers.TryGetValue("X-UTB-Audiencia", out var value) &&
        Enum.TryParse<Audiencia>(value, true, out var audiencia)
            ? audiencia
            : Audiencia.externo;

    // --- Endpoints de Contenido ---

    [HttpGet("lugares/{lugarId:int}/pois")]
    public async Task<ActionResult<IReadOnlyList<PoiDto>>> ObtenerPois(int lugarId)
    {
        var pois = await contenidoService.ObtenerPoisAsync(lugarId, AudienciaActual);
        return Ok(pois);
    }

    [HttpGet("lugares/{lugarId:int}/recorrido")]
    public async Task<ActionResult<RecorridoDto>> ObtenerRecorrido(int lugarId)
    {
        var recorrido = await contenidoService.ObtenerRecorridoAsync(lugarId, AudienciaActual);
        if (recorrido is null) return NotFound();
        return Ok(recorrido);
    }

    [HttpGet("pois/{poiId:int}")]
    public async Task<ActionResult<PoiDetalleDto>> ObtenerPoi(int poiId)
    {
        var detalle = await contenidoService.ObtenerPoiPorIdAsync(poiId, AudienciaActual);
        if (detalle is null) return NotFound();
        return Ok(detalle);
    }

    [HttpGet("lugares/{lugarId:int}/ruta")]
    public async Task<ActionResult<RutaDto?>> ObtenerRuta(int lugarId)
    {
        var ruta = await contenidoService.ObtenerRutaActivaAsync(lugarId, AudienciaActual);
        return Ok(ruta);
    }

    // --- Endpoints de Gestión de Multimedia del Mapa ---

    // Escribe en la base y en el bucket: necesita la clave de administración
    // igual que los endpoints de /api/admin.
    [HttpPost("lugares/{lugarId:int}/mapa")]
    [RequiereClaveAdmin]
    public async Task<IActionResult> SubirOActualizarMapa(int lugarId, [FromForm] SubirMultimediaRequest request)
    {
        if (request.Archivo == null || request.Archivo.Length == 0)
            return BadRequest("No se proporcionó ningún archivo.");

        if (!TiposArchivo.TieneExtension(request.Archivo.FileName, TiposArchivo.ExtensionesMapa))
            return BadRequest($"El mapa debe ser {string.Join(", ", TiposArchivo.ExtensionesMapa)}.");

        var carpeta = TiposArchivo.ResolverCarpeta(request.Carpeta, "mapas");
        if (carpeta is null) return BadRequest(TiposArchivo.MensajeCarpetaInvalida);

        // 1. Subimos el archivo a Supabase S3
        var rutaS3 = await almacenamientoService.SubirArchivoAsync(request.Archivo, carpeta);

        // 2. Guardamos la ruta en la base de datos a través del servicio
        var actualizado = await contenidoService.ActualizarMapaLugarAsync(lugarId, rutaS3);
        
        if (!actualizado)
            return NotFound("El lugar especificado no existe en la base de datos.");

        return Ok(new 
        { 
            mensaje = "Mapa actualizado y guardado en la base de datos correctamente", 
            rutaS3,
            lugarId 
        });
    }

    [HttpGet("lugares/{lugarId:int}/mapa")]
    public async Task<IActionResult> ObtenerUrlMapa(int lugarId)
    {
        // 1. Buscamos la ruta del mapa en la BD a través del servicio
        var mapaUrl = await contenidoService.ObtenerRutaMapaLugarAsync(lugarId);
        
        if (string.IsNullOrEmpty(mapaUrl))
            return NotFound("Este lugar no existe o aún no tiene un mapa asociado.");

        // 2. Generamos la URL firmada temporal con S3
        var urlFirmada = await almacenamientoService.ObtenerUrlFirmadaAsync(mapaUrl, TimeSpan.FromHours(1));

        return Ok(new { urlMapa = urlFirmada });
    }
}
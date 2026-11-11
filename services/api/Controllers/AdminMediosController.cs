using Microsoft.AspNetCore.Mvc;
using TourVirtualUTB.Api.DTOs;
using TourVirtualUTB.Api.Models;
using TourVirtualUTB.Api.Services;
using TourVirtualUTB.Api.Data;

namespace TourVirtualUTB.Api.Controllers;

[ApiController]
[Route("api/admin/medios")]
[RequiereClaveAdmin]
public class AdminMediosController(
    IContenidoService contenidoService,
    IAlmacenamientoService almacenamientoService,
    TourDbContext db) : ControllerBase
{
    // El cuerpo multipart lleva algo más que el archivo (campos y separadores).
    private const long LimiteCuerpo =
        TiposArchivo.TamanoMaximoBytes + TiposArchivo.TamanoMaximoSubtitulosBytes + 1024 * 1024;

    [HttpPost]
    public async Task<ActionResult<MedioDto>> CrearMedio([FromBody] CrearMedioRequest request)
    {
        if (await db.Pois.FindAsync(request.PoiId) is null)
            return NotFound("El POI no existe.");

        if (!Idiomas.TryNormalizar(request.Idioma, out var idioma))
            return BadRequest(Idiomas.MensajeInvalido);

        var medio = await contenidoService.CrearMedioAsync(request with { Idioma = idioma });
        return Ok(medio);
    }

    /// <summary>
    /// Sube un video, audio o foto y lo asocia al POI en un solo paso.
    /// Es la forma recomendada: con POST /api/admin/medios había que inventar
    /// una URL temporal y luego reemplazarla con /archivo.
    /// </summary>
    [HttpPost("/api/admin/pois/{poiId:int}/medios")]
    [RequestSizeLimit(LimiteCuerpo)]
    [RequestFormLimits(MultipartBodyLengthLimit = LimiteCuerpo)]
    public async Task<ActionResult<MedioDto>> SubirMedio(int poiId, [FromForm] SubirMedioRequest request)
    {
        if (await db.Pois.FindAsync(poiId) is null)
            return NotFound("El POI no existe.");

        if (request.Tipo == TipoMedio.imagen && string.IsNullOrWhiteSpace(request.TextoAlt))
            return BadRequest("Las imágenes necesitan TextoAlt (lo leen los lectores de pantalla).");

        if (!Idiomas.TryNormalizar(request.Idioma, out var idioma))
            return BadRequest(Idiomas.MensajeInvalido);

        // Los subtítulos se revisan antes de subir nada, para no dejar el
        // archivo principal huérfano en el bucket si el .vtt está mal.
        var errorSubtitulos = await ValidarSubtitulosAsync(request.Subtitulos, request.Tipo);
        if (errorSubtitulos is not null) return BadRequest(errorSubtitulos);

        var (rutaS3, error) = await GuardarArchivoAsync(request.Archivo, request.Tipo, request.Carpeta);
        if (error is not null) return BadRequest(error);

        string? rutaSubtitulos = null;
        if (request.Subtitulos is not null)
            rutaSubtitulos = await almacenamientoService.SubirArchivoAsync(request.Subtitulos, "subtitulos");

        var medio = await contenidoService.CrearMedioAsync(new CrearMedioRequest(
            poiId, request.Tipo, rutaS3!, request.Orden, request.DuracionSeg,
            string.IsNullOrWhiteSpace(request.TextoAlt) ? null : request.TextoAlt.Trim(), rutaSubtitulos, idioma));

        return Ok(medio);
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<MedioDto>> ActualizarMedio(int id, [FromBody] ActualizarMedioRequest request)
    {
        if (!Idiomas.TryNormalizar(request.Idioma, out var idioma))
            return BadRequest(Idiomas.MensajeInvalido);

        var medio = await contenidoService.ActualizarMedioAsync(id, request with { Idioma = idioma });
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

    /// <summary>Reemplaza el archivo de un medio que ya existe.</summary>
    [HttpPost("{id:int}/archivo")]
    [RequestSizeLimit(LimiteCuerpo)]
    [RequestFormLimits(MultipartBodyLengthLimit = LimiteCuerpo)]
    public async Task<IActionResult> SubirArchivoMedio(int id, [FromForm] SubirMultimediaRequest request)
    {
        // Antes se subía primero y se buscaba después: con un id equivocado el
        // archivo quedaba huérfano en el bucket.
        var medio = await db.Medios.FindAsync(id);
        if (medio == null) return NotFound("El medio no existe.");

        var (rutaS3, error) = await GuardarArchivoAsync(request.Archivo, medio.Tipo, request.Carpeta);
        if (error is not null) return BadRequest(error);

        medio.Url = rutaS3!;
        await db.SaveChangesAsync();

        return Ok(new { mensaje = "Archivo multimedia subido correctamente", rutaS3 });
    }

    /// <summary>
    /// Devuelve un mensaje de error si los subtítulos no sirven, o null si están
    /// bien o no se mandaron. Solo audios y videos llevan subtítulos.
    /// </summary>
    private static async Task<string?> ValidarSubtitulosAsync(IFormFile? subtitulos, TipoMedio tipo)
    {
        if (subtitulos is null) return null;

        if (tipo == TipoMedio.imagen)
            return "Las imágenes no llevan subtítulos; usa TextoAlt.";

        if (subtitulos.Length == 0)
            return "El archivo de subtítulos está vacío.";

        if (subtitulos.Length > TiposArchivo.TamanoMaximoSubtitulosBytes)
            return $"Los subtítulos pesan más de {TiposArchivo.TamanoMaximoSubtitulosBytes / (1024 * 1024)} MB.";

        if (!TiposArchivo.TieneExtension(subtitulos.FileName, TiposArchivo.ExtensionesSubtitulos))
            return "Los subtítulos deben ser un archivo WebVTT (.vtt).";

        // Todo WebVTT empieza con la palabra WEBVTT (puede llevar BOM delante).
        using var lector = new StreamReader(subtitulos.OpenReadStream());
        var primeraLinea = await lector.ReadLineAsync();
        if (primeraLinea is null || !primeraLinea.TrimStart('\uFEFF').StartsWith("WEBVTT", StringComparison.Ordinal))
            return "El archivo .vtt no es un WebVTT válido: la primera línea debe empezar con WEBVTT.";

        return null;
    }

    private async Task<(string? rutaS3, string? error)> GuardarArchivoAsync(IFormFile? archivo, TipoMedio tipo, string? carpetaPedida)
    {
        if (archivo == null || archivo.Length == 0)
            return (null, "No se proporcionó ningún archivo.");

        if (archivo.Length > TiposArchivo.TamanoMaximoBytes)
            return (null, $"El archivo pesa más de {TiposArchivo.TamanoMaximoBytes / (1024 * 1024)} MB. Comprímelo antes de subirlo.");

        if (!TiposArchivo.EsDeTipo(archivo.FileName, tipo))
            return (null, $"Un medio de tipo {tipo} debe ser {TiposArchivo.ExtensionesDe(tipo)}.");

        var carpeta = TiposArchivo.ResolverCarpeta(carpetaPedida, TiposArchivo.CarpetaPorDefecto(tipo));
        if (carpeta is null) return (null, TiposArchivo.MensajeCarpetaInvalida);

        if (tipo != TipoMedio.imagen)
            return (await almacenamientoService.SubirArchivoAsync(archivo, carpeta), null);

        ImagenProcesada foto;
        try
        {
            await using var original = archivo.OpenReadStream();
            foto = ProcesadorImagenes.ProcesarFoto(original);
        }
        catch (ImagenNoValidaException ex)
        {
            return (null, ex.Message);
        }

        await using (foto.Contenido)
        {
            var nombre = Path.ChangeExtension(archivo.FileName, ".jpg");
            return (await almacenamientoService.SubirStreamAsync(foto.Contenido, carpeta, nombre, "image/jpeg"), null);
        }
    }
}

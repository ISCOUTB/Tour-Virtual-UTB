using TourVirtualUTB.Api.Models;

namespace TourVirtualUTB.Api.Services;

/// <summary>
/// Qué archivos acepta cada tipo de medio y en qué carpetas del bucket se
/// pueden guardar.
/// </summary>
public static class TiposArchivo
{
    // Supabase rechaza objetos de más de 50 MB en el plan gratuito; subir uno
    // más grande fallaría tarde y con un error poco claro.
    public const long TamanoMaximoBytes = 50L * 1024 * 1024;

    private static readonly Dictionary<string, string> ContentTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        [".jpg"] = "image/jpeg",
        [".jpeg"] = "image/jpeg",
        [".png"] = "image/png",
        [".webp"] = "image/webp",
        [".mp4"] = "video/mp4",
        [".m4v"] = "video/mp4",
        [".mov"] = "video/quicktime",
        [".webm"] = "video/webm",
        [".mp3"] = "audio/mpeg",
        [".m4a"] = "audio/mp4",
        [".aac"] = "audio/aac",
        [".ogg"] = "audio/ogg",
        [".wav"] = "audio/wav",
    };

    private static readonly Dictionary<TipoMedio, string[]> ExtensionesPorTipo = new()
    {
        [TipoMedio.imagen] = [".jpg", ".jpeg", ".png", ".webp"],
        // MP4 (H.264 + AAC) es lo único que reproducen Android, iOS y web por igual.
        [TipoMedio.video] = [".mp4", ".m4v", ".mov", ".webm"],
        [TipoMedio.audio] = [".mp3", ".m4a", ".aac", ".ogg", ".wav"],
    };

    public static readonly string[] ExtensionesPanorama = [".jpg", ".jpeg", ".png", ".webp"];
    // Sin SVG: es un documento que puede llevar scripts, y quien abra su URL
    // firmada los ejecutaría. Todo lo que se acepta aquí se vuelve a codificar
    // como JPEG antes de subirse.
    public static readonly string[] ExtensionesMapa = [".jpg", ".jpeg", ".png", ".webp"];

    private static readonly string[] CarpetasPermitidas =
        ["panoramas", "mapas", "medios", "imagenes", "videos", "audios"];

    public static bool EsDeTipo(string nombreArchivo, TipoMedio tipo) =>
        ExtensionesPorTipo[tipo].Contains(Path.GetExtension(nombreArchivo), StringComparer.OrdinalIgnoreCase);

    public static bool TieneExtension(string nombreArchivo, string[] extensiones) =>
        extensiones.Contains(Path.GetExtension(nombreArchivo), StringComparer.OrdinalIgnoreCase);

    public static string ExtensionesDe(TipoMedio tipo) => string.Join(", ", ExtensionesPorTipo[tipo]);

    /// <summary>
    /// El navegador o Swagger a veces mandan application/octet-stream; con ese
    /// tipo el video se descarga en lugar de reproducirse, así que se deduce
    /// de la extensión.
    /// </summary>
    public static string ContentTypeDe(string nombreArchivo, string? declarado) =>
        ContentTypes.TryGetValue(Path.GetExtension(nombreArchivo), out var tipo)
            ? tipo
            : string.IsNullOrWhiteSpace(declarado) ? "application/octet-stream" : declarado;

    public static string CarpetaPorDefecto(TipoMedio tipo) => tipo switch
    {
        TipoMedio.imagen => "imagenes",
        TipoMedio.video => "videos",
        _ => "audios",
    };

    /// <summary>
    /// Devuelve la carpeta a usar, o null si la pedida no es válida. Vacío y
    /// "string" (el valor de ejemplo que rellena Swagger) cuentan como "no
    /// indicada" y se usa la carpeta por defecto.
    /// </summary>
    public static string? ResolverCarpeta(string? pedida, string porDefecto)
    {
        if (string.IsNullOrWhiteSpace(pedida) || pedida.Trim().Equals("string", StringComparison.OrdinalIgnoreCase))
            return porDefecto;

        var limpia = pedida.Trim().ToLowerInvariant();
        return CarpetasPermitidas.Contains(limpia) ? limpia : null;
    }

    public static string MensajeCarpetaInvalida =>
        $"Carpeta no válida. Usa una de: {string.Join(", ", CarpetasPermitidas)}, o déjala vacía.";
}

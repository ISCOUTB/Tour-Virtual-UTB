using System.Text.RegularExpressions;

namespace TourVirtualUTB.Api.Services;

/// <summary>
/// Valida y normaliza el idioma de un medio. Se guarda como código BCP 47
/// ("es", "en", "pt-BR", "zh-Hans"...); nulo significa español.
/// </summary>
public static partial class Idiomas
{
    public const string MensajeInvalido =
        "Idioma no válido. Usa un código BCP 47 como \"es\", \"en\" o \"pt-BR\", o déjalo vacío para español.";

    // Idioma de 2 o 3 letras y, opcionalmente, subetiquetas de 2 a 8 caracteres.
    [GeneratedRegex("^[A-Za-z]{2,3}(-[A-Za-z0-9]{2,8})*$")]
    private static partial Regex FormatoBcp47();

    /// <summary>
    /// Devuelve false si el código no es válido. Vacío y "string" (el valor de
    /// ejemplo que rellena Swagger) cuentan como "sin idioma", es decir, español.
    /// </summary>
    public static bool TryNormalizar(string? valor, out string? idioma)
    {
        idioma = null;
        if (string.IsNullOrWhiteSpace(valor) || valor.Trim().Equals("string", StringComparison.OrdinalIgnoreCase))
            return true;

        var limpio = valor.Trim().Replace('_', '-');
        if (limpio.Length > 35 || !FormatoBcp47().IsMatch(limpio))
            return false;

        // Forma canónica: idioma en minúsculas, región en mayúsculas y
        // escritura con inicial mayúscula ("PT-br" -> "pt-BR", "zh-hans" -> "zh-Hans").
        var partes = limpio.Split('-');
        partes[0] = partes[0].ToLowerInvariant();
        for (var i = 1; i < partes.Length; i++)
        {
            partes[i] = partes[i].Length switch
            {
                2 => partes[i].ToUpperInvariant(),
                4 => char.ToUpperInvariant(partes[i][0]) + partes[i][1..].ToLowerInvariant(),
                _ => partes[i].ToLowerInvariant(),
            };
        }

        idioma = string.Join('-', partes);
        return true;
    }
}

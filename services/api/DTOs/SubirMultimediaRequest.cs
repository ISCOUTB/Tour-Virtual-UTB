using TourVirtualUTB.Api.Models;

public class SubirMultimediaRequest
{
    public IFormFile Archivo { get; set; } = null!;

    /// <summary>Opcional. Si se deja vacía se usa la carpeta por defecto del endpoint.</summary>
    public string? Carpeta { get; set; }
}

/// <summary>Sube el archivo y crea el medio del POI en un solo paso.</summary>
public class SubirMedioRequest
{
    public IFormFile Archivo { get; set; } = null!;
    public TipoMedio Tipo { get; set; }
    public int Orden { get; set; }
    public int? DuracionSeg { get; set; }

    /// <summary>Descripción para lectores de pantalla. Obligatoria en imágenes.</summary>
    public string? TextoAlt { get; set; }

    /// <summary>Opcional. Si se deja vacía se usa imagenes, videos o audios según el tipo.</summary>
    public string? Carpeta { get; set; }
}

using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TourVirtualUTB.Api.Models;

public enum Audiencia
{
    externo,
    estudiante,
    docente
}

public enum TipoHotspot
{
    navegacion,
    info
}

public enum TipoMedio
{
    imagen,
    video,
    audio
}

public class Lugar
{
    [Key]
    public int Id { get; set; }

    [Required, MaxLength(100)]
    public string Nombre { get; set; } = string.Empty;

    [Required, MaxLength(120)]
    public string Slug { get; set; } = string.Empty;

    public ICollection<Poi> Pois { get; set; } = new List<Poi>();
    public ICollection<Escena> Escenas { get; set; } = new List<Escena>();
    public ICollection<Ruta> Rutas { get; set; } = new List<Ruta>();
}

public class Poi
{
    [Key]
    public int Id { get; set; }
    public int LugarId { get; set; }
    public Lugar? Lugar { get; set; }

    [Required, MaxLength(120)]
    public string Nombre { get; set; } = string.Empty;
    public string? Categoria { get; set; }
    public string? Descripcion { get; set; }
    public double? Lat { get; set; }
    public double? Lng { get; set; }
    public double? MapX { get; set; }
    public double? MapY { get; set; }

    [Required]
    public string Audiencias { get; set; } = "externo,estudiante,docente";
    public bool Activo { get; set; } = true;
    public int? EscenaPrincipalId { get; set; }
    public Escena? EscenaPrincipal { get; set; }
    public ICollection<Escena> Escenas { get; set; } = new List<Escena>();
    public ICollection<Medio> Medios { get; set; } = new List<Medio>();
}

public class Escena
{
    [Key]
    public int Id { get; set; }
    public int LugarId { get; set; }
    public Lugar? Lugar { get; set; }
    public int? PoiId { get; set; }
    public Poi? Poi { get; set; }
    [Required]
    public string ImagenUrl { get; set; } = string.Empty;
    public string? ImagenUrlBaja { get; set; }
    public string? Nombre { get; set; }
    public bool EsEscenaPrincipal { get; set; }
    public int Orden { get; set; }
    public double? VistaInicialYaw { get; set; }
    public double? VistaInicialPitch { get; set; }
    public ICollection<Hotspot> Hotspots { get; set; } = new List<Hotspot>();
}

public class Hotspot
{
    [Key]
    public int Id { get; set; }
    public int EscenaId { get; set; }
    public Escena? Escena { get; set; }
    public TipoHotspot Tipo { get; set; }
    public double Pitch { get; set; }
    public double Yaw { get; set; }
    public int? EscenaDestinoId { get; set; }
    public Escena? EscenaDestino { get; set; }
    public int? PoiId { get; set; }
    public Poi? Poi { get; set; }
    public string? Etiqueta { get; set; }
}

public class Medio
{
    [Key]
    public int Id { get; set; }
    public int PoiId { get; set; }
    public Poi? Poi { get; set; }
    public TipoMedio Tipo { get; set; }
    [Required]
    public string Url { get; set; } = string.Empty;
    public int Orden { get; set; }
    public int? DuracionSeg { get; set; }
    public string? TextoAlt { get; set; }
    public string? SubtitulosUrl { get; set; }
}

public class Ruta
{
    [Key]
    public int Id { get; set; }
    public int LugarId { get; set; }
    public Lugar? Lugar { get; set; }
    [Required]
    public string Nombre { get; set; } = string.Empty;
    public string? Descripcion { get; set; }
    public Audiencia Audiencia { get; set; }
    public bool Activa { get; set; } = true;
    public ICollection<RutaPoi> Pois { get; set; } = new List<RutaPoi>();
}

public class RutaPoi
{
    public int RutaId { get; set; }
    public Ruta? Ruta { get; set; }
    public int PoiId { get; set; }
    public Poi? Poi { get; set; }
    public int Orden { get; set; }
}

using System.ComponentModel.DataAnnotations;

namespace TourVirtualUTB.Api.Models;

public class Escena
{
    [Key]
    public int Id { get; set; }
    public int LugarId { get; set; }
    public Lugar? Lugar { get; set; }
    public int? PoiId { get; set; }
    public Poi? Poi { get; set; }
    
    // Null mientras no se haya subido la panorámica (antes se rellenaba con
    // "temp" porque el campo era obligatorio).
    public string? ImagenUrl { get; set; }
    public string? ImagenUrlBaja { get; set; }
    public string? Nombre { get; set; }
    public bool EsEscenaPrincipal { get; set; }
    public int Orden { get; set; }
    public double? VistaInicialYaw { get; set; }
    public double? VistaInicialPitch { get; set; }

    /// <summary>
    /// Qué se ve en la panorámica, para quien no la ve. Lo lee el lector de
    /// pantalla en el visor 360 (WCAG 1.1.1); si falta, la app lee la
    /// descripción del POI.
    /// </summary>
    public string? TextoAlt { get; set; }
    public ICollection<Hotspot> Hotspots { get; set; } = new List<Hotspot>();
}
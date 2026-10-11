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
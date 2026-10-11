using System.ComponentModel.DataAnnotations;

namespace TourVirtualUTB.Api.Models;

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
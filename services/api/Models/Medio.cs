using System.ComponentModel.DataAnnotations;

namespace TourVirtualUTB.Api.Models;

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
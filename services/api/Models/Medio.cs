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

    /// <summary>
    /// Código de idioma BCP 47 ("es", "en", "pt-BR"...). Nulo significa español.
    /// Un POI puede tener un audio por idioma; la app elige el del idioma de la
    /// interfaz y deja cambiarlo en «Escuchar en».
    /// </summary>
    [MaxLength(35)]
    public string? Idioma { get; set; }
}
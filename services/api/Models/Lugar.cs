using System.ComponentModel.DataAnnotations;

namespace TourVirtualUTB.Api.Models;

public class Lugar
{
    [Key]
    public int Id { get; set; }

    [Required, MaxLength(100)]
    public string Nombre { get; set; } = string.Empty;

    [Required, MaxLength(120)]
    public string Slug { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? MapaUrl { get; set; }

    public ICollection<Poi> Pois { get; set; } = new List<Poi>();
    public ICollection<Escena> Escenas { get; set; } = new List<Escena>();
    public ICollection<Ruta> Rutas { get; set; } = new List<Ruta>();
}
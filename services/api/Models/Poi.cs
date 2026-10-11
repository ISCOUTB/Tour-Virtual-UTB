using System.ComponentModel.DataAnnotations;

namespace TourVirtualUTB.Api.Models;

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
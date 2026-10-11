using System.ComponentModel.DataAnnotations;

namespace TourVirtualUTB.Api.Models;

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


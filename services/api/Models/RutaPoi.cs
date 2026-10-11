using System.ComponentModel.DataAnnotations;

namespace TourVirtualUTB.Api.Models;

public class RutaPoi
{
    public int RutaId { get; set; }
    public Ruta? Ruta { get; set; }
    public int PoiId { get; set; }
    public Poi? Poi { get; set; }
    public int Orden { get; set; }
}

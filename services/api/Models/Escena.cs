using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TourVirtualUTB.Api.Models
{
    public class Escena
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int LugarId { get; set; }
        [ForeignKey("LugarId")]
        public Lugar? Lugar { get; set; }

        [Required]
        public string ImagenUrl { get; set; } = string.Empty;

        public bool EsPanoramica { get; set; } = true;
        public bool EsEscenaPrincipal { get; set; } = false;

        public ICollection<Hotspot> HotspotsOrigen { get; set; } = new List<Hotspot>();
    }
}
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TourVirtualUTB.Api.Models
{
    public class Hotspot
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int EscenaOrigenId { get; set; }
        [ForeignKey("EscenaOrigenId")]
        public Escena? EscenaOrigen { get; set; }

        [Required]
        public int EscenaDestinoId { get; set; }
        public Escena? EscenaDestino { get; set; }

        public double Pitch { get; set; } 
        public double Yaw { get; set; }   
    }
}
using System.ComponentModel.DataAnnotations;

namespace TourVirtualUTB.Api.Models
{
    public class Lugar
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string Nombre { get; set; } = string.Empty;

        [MaxLength(50)]
        public string Categoria { get; set; } = string.Empty;

        public double Latitud { get; set; }
        public double Longitud { get; set; }

        public ICollection<Escena> Escenas { get; set; } = new List<Escena>();
    }
}
using System.ComponentModel.DataAnnotations;

namespace TourVirtualUTB.Api.DTOs
{
    public class EscenaCreateDto
    {
        [Required]
        public int LugarId { get; set; }
        
        public bool EsPanoramica { get; set; } = true;
        
        public bool EsEscenaPrincipal { get; set; } = false;
        
        [Required]
        public IFormFile ArchivoImagen { get; set; } // permite recibir archivos
    }
}
using TourVirtualUTB.Api.Models;

public class SubirMultimediaRequest
{
    public IFormFile Archivo { get; set; } = null!;
    public string Carpeta { get; set; } = "general";
}
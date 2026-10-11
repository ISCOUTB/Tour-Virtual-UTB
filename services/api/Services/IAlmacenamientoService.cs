using TourVirtualUTB.Api.DTOs;
using TourVirtualUTB.Api.Models;

namespace TourVirtualUTB.Api.Services;

public interface IAlmacenamientoService
{
    Task<string> SubirArchivoAsync(IFormFile archivo, string carpeta);
    Task<string> ObtenerUrlFirmadaAsync(string rutaArchivo, TimeSpan duracion);
}

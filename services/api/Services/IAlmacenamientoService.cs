namespace TourVirtualUTB.Api.Services;

public interface IAlmacenamientoService
{
    Task<string> SubirArchivoAsync(IFormFile archivo, string carpeta);
    Task<string> SubirStreamAsync(Stream contenido, string carpeta, string nombreArchivo, string contentType);
    Task<string> ObtenerUrlFirmadaAsync(string rutaArchivo, TimeSpan duracion);
}

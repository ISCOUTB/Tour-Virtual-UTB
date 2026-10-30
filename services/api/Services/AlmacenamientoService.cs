using System.Text.RegularExpressions;
using Amazon.S3;
using Amazon.S3.Model;

namespace TourVirtualUTB.Api.Services;

public partial class AlmacenamientoService : IAlmacenamientoService
{
    private readonly IAmazonS3 _s3Client;
    private readonly string _bucketName; // El bucket privado en Supabase

    public AlmacenamientoService(IConfiguration configuration)
    {
        // Leemos las credenciales S3 proporcionadas por Supabase
        var serviceUrl = configuration["SupabaseS3:ServiceUrl"]; // Ej: https://xyz.supabase.co/storage/v1/s3
        var accessKey = configuration["SupabaseS3:AccessKey"];
        var secretKey = configuration["SupabaseS3:SecretKey"];
        _bucketName = configuration["SupabaseS3:Bucket"] ?? "tour-media";

        var config = new AmazonS3Config
        {
            ServiceURL = serviceUrl,
            ForcePathStyle = true
        };

        _s3Client = new AmazonS3Client(accessKey, secretKey, config);
    }

    public async Task<string> ObtenerUrlFirmadaAsync(string rutaArchivo, TimeSpan duracion)
    {
        // Un medio puede apuntar a un archivo alojado fuera del bucket (por
        // ejemplo un video institucional ya publicado). Esa URL no se firma.
        if (Uri.TryCreate(rutaArchivo, UriKind.Absolute, out var uri) &&
            (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps))
            return rutaArchivo;

        var request = new GetPreSignedUrlRequest
        {
            BucketName = _bucketName,
            Key = rutaArchivo,
            Expires = DateTime.UtcNow.Add(duracion)
        };

        // Genera una URL temporal firmada criptográficamente por Supabase/S3
        return await _s3Client.GetPreSignedURLAsync(request);
    }

    public async Task<string> SubirArchivoAsync(IFormFile archivo, string carpeta)
    {
        using var stream = archivo.OpenReadStream();
        var contentType = TiposArchivo.ContentTypeDe(archivo.FileName, archivo.ContentType);
        return await SubirStreamAsync(stream, carpeta, archivo.FileName, contentType);
    }

    public async Task<string> SubirStreamAsync(Stream contenido, string carpeta, string nombreArchivo, string contentType)
    {
        var nombreUnico = $"{carpeta}/{Guid.NewGuid()}_{Limpiar(nombreArchivo)}";

        var putRequest = new PutObjectRequest
        {
            BucketName = _bucketName,
            Key = nombreUnico,
            InputStream = contenido,
            ContentType = contentType
        };

        await _s3Client.PutObjectAsync(putRequest);
        return nombreUnico; // Guardamos esta ruta relativa en la base de datos
    }

    // Espacios, tildes y símbolos en la clave rompen la URL firmada en algunos
    // reproductores; se dejan solo letras, números, punto, guion y guion bajo.
    private static string Limpiar(string nombreArchivo)
    {
        var sinTildes = new string(Path.GetFileName(nombreArchivo)
            .Normalize(System.Text.NormalizationForm.FormD)
            .Where(c => char.GetUnicodeCategory(c) != System.Globalization.UnicodeCategory.NonSpacingMark)
            .ToArray());
        var nombre = CaracteresNoPermitidos().Replace(sinTildes, "-").Trim('-');
        return string.IsNullOrEmpty(nombre) ? "archivo" : nombre;
    }

    [GeneratedRegex(@"[^A-Za-z0-9._-]+")]
    private static partial Regex CaracteresNoPermitidos();
}

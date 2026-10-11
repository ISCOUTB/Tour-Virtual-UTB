using Amazon.S3;
using Amazon.S3.Model;

namespace TourVirtualUTB.Api.Services;

public class AlmacenamientoService : IAlmacenamientoService
{
    private readonly IAmazonS3 _s3Client;
    private readonly string _bucketName = "tour-media"; // El nombre de tu bucket privado en Supabase

    public AlmacenamientoService(IConfiguration configuration)
    {
        // Leemos las credenciales S3 proporcionadas por Supabase
        var serviceUrl = configuration["SupabaseS3:ServiceUrl"]; // Ej: https://xyz.supabase.co/storage/v1/s3
        var accessKey = configuration["SupabaseS3:AccessKey"];
        var secretKey = configuration["SupabaseS3:SecretKey"];

        var config = new AmazonS3Config
        {
            ServiceURL = serviceUrl,
            ForcePathStyle = true
        };

        _s3Client = new AmazonS3Client(accessKey, secretKey, config);
    }

    public async Task<string> ObtenerUrlFirmadaAsync(string rutaArchivo, TimeSpan duracion)
    {
        var request = new GetPreSignedUrlRequest
        {
            BucketName = _bucketName,
            Key = rutaArchivo,
            Expires = DateTime.UtcNow.Add(duracion)
        };

        // Genera una URL temporal firmada criptográficamente por Supabase/S3
        return await Task.Run(() => _s3Client.GetPreSignedURL(request));
    }
    public async Task<string> SubirArchivoAsync(IFormFile archivo, string carpeta)
    {

        var nombreUnico = $"{carpeta}/{Guid.NewGuid()}_{archivo.FileName}";
    
        using var stream = archivo.OpenReadStream();
        var putRequest = new PutObjectRequest
        {
            BucketName = "tour-media",
            Key = nombreUnico,
            InputStream = stream,
            ContentType = archivo.ContentType
        };

        await _s3Client.PutObjectAsync(putRequest);
        return nombreUnico; // Guardamos esta ruta relacional en la base de datos

    }
  
}
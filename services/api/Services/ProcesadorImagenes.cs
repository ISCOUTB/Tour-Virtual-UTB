using SkiaSharp;

namespace TourVirtualUTB.Api.Services;

/// <summary>Imagen ya convertida a JPEG, lista para subir.</summary>
public sealed record ImagenProcesada(MemoryStream Contenido, int Ancho, int Alto);

public sealed record PanoramaProcesada(ImagenProcesada Completa, ImagenProcesada Baja);

public sealed class ImagenNoValidaException(string mensaje = "El archivo no es una imagen válida.")
    : Exception(mensaje);

/// <summary>
/// Hace en el servidor lo mismo que scripts/subir_medios.py: las panorámicas
/// originales rondan los 9000 px y pesan entre 7 y 17 MB, demasiado para una
/// wifi compartida. Se reducen a 4096x2048, se genera una versión de 1024x512
/// que la app muestra mientras baja la completa, y se descartan los metadatos
/// EXIF/XMP (modelo de teléfono, fecha y a veces GPS): al volver a codificar
/// con Skia solo se escriben los píxeles.
/// </summary>
public static class ProcesadorImagenes
{
    // Un PNG de pocos KB puede declarar 50 000 x 50 000 px y pedir más de
    // 10 GB al decodificarse, lo que tumba el servidor. Las panorámicas
    // originales rondan los 40 MP y una foto de teléfono, 12 a 50.
    private const long PixelesMaximos = 64_000_000;

    public static PanoramaProcesada ProcesarPanorama(Stream original)
    {
        using var imagen = Decodificar(original, aplicarOrientacion: false);
        using var completa = Reducir(imagen, 4096, 2048);
        // La baja sale de la ya reducida: menos trabajo y menos dientes de sierra.
        using var baja = Reducir(completa, 1024, 512);
        return new PanoramaProcesada(Codificar(completa, 82), Codificar(baja, 70));
    }

    /// <summary>Fotos de la galería: máximo 2048 px por lado y sin metadatos.</summary>
    public static ImagenProcesada ProcesarFoto(Stream original)
    {
        // Las fotos de teléfono guardan el giro en EXIF; como el EXIF se
        // descarta, el giro hay que aplicarlo antes o la foto queda de lado.
        using var imagen = Decodificar(original, aplicarOrientacion: true);
        using var reducida = Reducir(imagen, 2048, 2048);
        return Codificar(reducida, 82);
    }

    /// <summary>
    /// Mapas ilustrados: máximo 4096 px por lado y sin metadatos. Volver a
    /// codificar también garantiza que lo guardado es una imagen y no otro
    /// archivo con extensión de imagen.
    /// </summary>
    public static ImagenProcesada ProcesarMapa(Stream original)
    {
        using var imagen = Decodificar(original, aplicarOrientacion: false);
        using var reducida = Reducir(imagen, 4096, 4096);
        return Codificar(reducida, 88);
    }

    private static SKBitmap Decodificar(Stream original, bool aplicarOrientacion)
    {
        using var datos = SKData.Create(original) ?? throw new ImagenNoValidaException();
        using var codec = SKCodec.Create(datos) ?? throw new ImagenNoValidaException();
        // El codec lee las dimensiones de la cabecera sin decodificar nada.
        if ((long)codec.Info.Width * codec.Info.Height > PixelesMaximos)
            throw new ImagenNoValidaException(
                $"La imagen pasa de {PixelesMaximos / 1_000_000} megapíxeles. Redúcela antes de subirla.");
        var bitmap = SKBitmap.Decode(codec) ?? throw new ImagenNoValidaException();

        if (!aplicarOrientacion || codec.EncodedOrigin == SKEncodedOrigin.TopLeft)
            return bitmap;

        using (bitmap)
            return Orientar(bitmap, codec.EncodedOrigin);
    }

    private static SKBitmap Orientar(SKBitmap origen, SKEncodedOrigin orientacion)
    {
        var gira90 = orientacion is SKEncodedOrigin.RightTop or SKEncodedOrigin.LeftBottom;
        var destino = gira90
            ? new SKBitmap(origen.Height, origen.Width)
            : new SKBitmap(origen.Width, origen.Height);

        using var lienzo = new SKCanvas(destino);
        switch (orientacion)
        {
            case SKEncodedOrigin.BottomRight:
                lienzo.RotateDegrees(180, origen.Width / 2f, origen.Height / 2f);
                break;
            case SKEncodedOrigin.RightTop:
                lienzo.Translate(destino.Width, 0);
                lienzo.RotateDegrees(90);
                break;
            case SKEncodedOrigin.LeftBottom:
                lienzo.Translate(0, destino.Height);
                lienzo.RotateDegrees(270);
                break;
            // Las variantes en espejo casi no aparecen en fotos de teléfono.
        }
        using var imagen = SKImage.FromBitmap(origen);
        lienzo.DrawImage(imagen, 0, 0, new SKSamplingOptions(SKFilterMode.Nearest));
        return destino;
    }

    /// <summary>
    /// Reduce sin deformar hasta caber en ancho x alto. Nunca agranda: una
    /// imagen pequeña no gana detalle por estirarla.
    /// </summary>
    private static SKBitmap Reducir(SKBitmap origen, int maxAncho, int maxAlto)
    {
        var escala = Math.Min(1.0, Math.Min((double)maxAncho / origen.Width, (double)maxAlto / origen.Height));
        var ancho = Math.Max(1, (int)Math.Round(origen.Width * escala));
        var alto = Math.Max(1, (int)Math.Round(origen.Height * escala));

        // Bajar de golpe de 9000 a 1024 px deja dientes de sierra; se va por
        // mitades hasta quedar cerca y el último paso lo hace el filtro cúbico.
        var actual = origen.Copy();
        while (actual.Width / 2 >= ancho && actual.Height / 2 >= alto)
        {
            var mitad = actual.Resize(new SKImageInfo(actual.Width / 2, actual.Height / 2), new SKSamplingOptions(SKFilterMode.Linear));
            actual.Dispose();
            actual = mitad;
        }

        if (actual.Width == ancho && actual.Height == alto)
            return actual;

        var final = actual.Resize(new SKImageInfo(ancho, alto), new SKSamplingOptions(SKCubicResampler.Mitchell));
        actual.Dispose();
        return final;
    }

    private static ImagenProcesada Codificar(SKBitmap bitmap, int calidad)
    {
        using var imagen = SKImage.FromBitmap(bitmap);
        using var jpeg = imagen.Encode(SKEncodedImageFormat.Jpeg, calidad);
        var salida = new MemoryStream();
        jpeg.SaveTo(salida);
        salida.Position = 0;
        return new ImagenProcesada(salida, bitmap.Width, bitmap.Height);
    }
}

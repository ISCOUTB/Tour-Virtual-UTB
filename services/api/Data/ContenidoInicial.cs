using Microsoft.EntityFrameworkCore;
using TourVirtualUTB.Api.Models;

namespace TourVirtualUTB.Api.Data;

public static class ContenidoInicial
{
    public static async Task InicializarAsync(TourDbContext db)
    {
        await db.Database.EnsureCreatedAsync();
        if (await db.Lugares.AnyAsync()) return;

        var lugar = new Lugar
        {
            Id = 1,
            Nombre = "Campus Tecnologico Ternera",
            Slug = "campus-ternera"
        };
        db.Lugares.Add(lugar);

        var pois = new[]
        {
            Poi(1, "Biblioteca", "Recursos", "Mas que una biblioteca: concentracion, disciplina, tecnologia y construccion de suenos.", .4067, .2745, "externo,estudiante,docente"),
            Poi(2, "Puente A3 - A5", "Academico", "Pasarela elevada que une los edificios A3 y A5 sin bajar a nivel de calle.", .6191, .1793, "estudiante,docente"),
            Poi(3, "Enfermeria", "Bienestar", "Servicio de atencion primaria del campus: consulta, curaciones y primeros auxilios.", .6186, .5055, "externo,estudiante,docente"),
            Poi(4, "Zona T", "Servicios", "Zona de mesas al aire libre y a la sombra, junto al Centro Deportivo y Cultural.", .545, .555, "externo,estudiante,docente"),
            Poi(5, "Cancha de softbol", "Deporte", "Campo abierto del area deportiva, usado para softbol y entrenamientos.", .5195, .658, "externo,estudiante,docente")
        };
        db.Pois.AddRange(pois);

        var escenas = new[]
        {
            Escena(1, 1, "Biblioteca", "panoramas/biblioteca.jpg", true, 0, 152, -5),
            Escena(2, 2, "Puente A3 - A5", "panoramas/puente-a3-a5.jpg", false, 1, -58, -5),
            Escena(3, 3, "Enfermeria", "panoramas/enfermeria.jpg", false, 2, -158, -6),
            Escena(4, 4, "Zona T", "panoramas/zona-t.jpg", false, 3, -55, -6),
            Escena(5, 5, "Cancha de softbol", "panoramas/cancha-softbol.jpg", false, 4, -40, -3)
        };
        db.Escenas.AddRange(escenas);
        await db.SaveChangesAsync();

        foreach (var poi in pois)
        {
            poi.EscenaPrincipalId = poi.Id;
        }

        db.Hotspots.AddRange(
            Hotspot(1, 1, -12, 140, 2, "Ir al puente A3 - A5"),
            Hotspot(2, 2, -10, -68, 1, "Ir a la Biblioteca"),
            Hotspot(3, 3, -8, -172, 4, "Ir a la Zona T"),
            Hotspot(4, 4, -4, -66, 5, "Ir a la cancha de softbol"),
            Hotspot(5, 4, 1, -156, 3, "Ir a Enfermeria"),
            Hotspot(6, 5, -2, -34, 4, "Ir a la Zona T"));
        db.Medios.AddRange(
            Medio(1, "audios/biblioteca.mp3", 10, "Audio narrado de la Biblioteca"),
            Medio(2, "audios/puente-a3-a5.mp3", 16, "Audio narrado del puente A3 - A5"),
            Medio(3, "audios/enfermeria.mp3", 11, "Audio narrado de la Enfermeria"),
            Medio(4, "audios/zona-t.mp3", 11, "Audio narrado de la Zona T"),
            Medio(5, "audios/cancha-softbol.mp3", 12, "Audio narrado de la cancha de softbol"));
        db.Rutas.AddRange(
            Ruta(1, "Conoce la UTB", "Recorrido institucional para visitantes.", Audiencia.externo),
            Ruta(2, "Tu dia a dia", "Espacios de uso frecuente.", Audiencia.estudiante),
            Ruta(3, "Espacios academicos", "Aulas y recursos docentes.", Audiencia.docente));
        await db.SaveChangesAsync();
        db.RutaPois.AddRange(
            RutaPoi(1, 1, 0), RutaPoi(1, 3, 1), RutaPoi(1, 4, 2), RutaPoi(1, 5, 3),
            RutaPoi(2, 1, 0), RutaPoi(2, 2, 1), RutaPoi(2, 3, 2), RutaPoi(2, 4, 3), RutaPoi(2, 5, 4),
            RutaPoi(3, 1, 0), RutaPoi(3, 2, 1), RutaPoi(3, 3, 2));
        await db.SaveChangesAsync();
    }

    private static Poi Poi(int id, string nombre, string categoria, string descripcion, double x, double y, string audiencias) =>
        new() { Id = id, LugarId = 1, Nombre = nombre, Categoria = categoria, Descripcion = descripcion, MapX = x, MapY = y, Audiencias = audiencias };

    private static Escena Escena(int id, int poiId, string nombre, string url, bool principal, int orden, double yaw, double pitch) =>
        new() { Id = id, LugarId = 1, PoiId = poiId, Nombre = nombre, ImagenUrl = url, ImagenUrlBaja = url.Replace(".jpg", "-baja.jpg"), EsEscenaPrincipal = principal, Orden = orden, VistaInicialYaw = yaw, VistaInicialPitch = pitch };

    private static Hotspot Hotspot(int id, int escenaId, double pitch, double yaw, int destino, string etiqueta) =>
        new() { Id = id, EscenaId = escenaId, Tipo = TipoHotspot.navegacion, Pitch = pitch, Yaw = yaw, EscenaDestinoId = destino, Etiqueta = etiqueta };

    private static Medio Medio(int poiId, string url, int duracion, string alt) =>
        new() { PoiId = poiId, Tipo = TipoMedio.audio, Url = url, DuracionSeg = duracion, TextoAlt = alt };

    private static Ruta Ruta(int id, string nombre, string descripcion, Audiencia audiencia) =>
        new() { Id = id, LugarId = 1, Nombre = nombre, Descripcion = descripcion, Audiencia = audiencia };

    private static RutaPoi RutaPoi(int rutaId, int poiId, int orden) =>
        new() { RutaId = rutaId, PoiId = poiId, Orden = orden };
}

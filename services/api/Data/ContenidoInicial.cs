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
            // Las cinco paradas, con panorámica. Lugares, lat/lng y textos del
            // guion de estaciones: catálogo de scripts/mapa_campus.py.
            Poi(1, "Biblioteca", "Recursos", "Más que una biblioteca: concentración, disciplina, tecnología y construcción de sueños.", 10.3699965, -75.4650668),
            Poi(2, "Puente A3 - A5", "Academico", "Un punto que conecta espacios, personas y recorridos dentro del campus. Cada trayecto en la UTB hace parte de una experiencia que conecta tu presente con lo que quieres construir.", 10.3692169, -75.4647217),
            Poi(3, "Enfermería", "Bienestar", "Bienestar y cuidado integral. Un espacio para atender tu salud, recibir orientación y recordar que cuidar de ti también hace parte de la experiencia universitaria.", 10.3692651, -75.4655196),
            Poi(4, "Zona T", "Servicios", "Punto de encuentro, pausa y conexión. Un lugar para compartir con otros estudiantes, conversar y disfrutar los espacios que hacen del campus una comunidad.", 10.3691852, -75.4655576),
            Poi(5, "Cancha de softbol", "Deporte", "El campus también se vive en movimiento. Espacio para el deporte, la disciplina, el trabajo en equipo y las experiencias que se construyen más allá del aula.", 10.3695823, -75.4663148),
            // Lugares del campus sin panorámica todavía.
            Poi(6, "Edificio A1", "Academico", null, 10.3697646, -75.465347),
            Poi(7, "Edificio A2", "Academico", null, 10.3707763, -75.4656241),
            Poi(8, "Edificio A3", "Academico", null, 10.3692983, -75.4648329),
            Poi(9, "Edificio A4", "Academico", null, 10.3695805, -75.4645402),
            Poi(10, "Edificio A5", "Academico", null, 10.3691355, -75.4646105),
            Poi(11, "Edificio Alcatraz", "Academico", null, 10.3703807, -75.4652636),
            Poi(12, "Auditorio", "Cultura", null, 10.3705694, -75.4657944),
            Poi(13, "Plaza Maloca", "Cultura", null, 10.3700456, -75.4657625),
            Poi(14, "Rectoría", "Administrativo", null, 10.3695939, -75.4652554),
            Poi(15, "Laboratorio El Patio", "Academico", null, 10.3696815, -75.4650578),
            Poi(16, "Centro de Cuidado Integral (QUID)", "Bienestar", null, 10.3690673, -75.4658707),
            Poi(17, "Centro Deportivo y Cultural", "Deporte", null, 10.3692615, -75.4656845),
            Poi(18, "Cancha de fútbol", "Deporte", null, 10.3701542, -75.4667058),
            Poi(19, "Salas de estudio", "Recursos", null, 10.3705483, -75.4654429),
            Poi(20, "Cafetería", "Servicios", null, 10.37042, -75.4653547),
            Poi(21, "Tienda", "Servicios", null, 10.3692206, -75.4661076),
            Poi(22, "Cajero automático", "Servicios", null, 10.3705307, -75.4659036),
            Poi(23, "Pasillo de la conexión", "Administrativo", null, 10.3707567, -75.4659942),
            Poi(24, "Solo Café", "Servicios", "Espacio de conexión, ideas y conversaciones que también transforman la experiencia universitaria. Aquí nacen amistades, proyectos y networking.", 10.3702285, -75.4655508),
            Poi(25, "La Placita", "Cultura", "Inspirada en las plazas del Caribe. Un espacio creado para compartir, desconectarse y sentirse en casa dentro de la UTB.", 10.3704913, -75.465484),
            Poi(26, "QuantaLab", "Academico", "Laboratorio de analítica, IA y datos. El futuro pertenece a quienes saben interpretar información y tomar decisiones.", 10.3690907, -75.4646518)
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

        foreach (var escena in escenas)
        {
            pois.Single(p => p.Id == escena.PoiId).EscenaPrincipalId = escena.Id;
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

    private static Poi Poi(int id, string nombre, string categoria, string? descripcion, double? lat, double? lng) =>
        new() { Id = id, LugarId = 1, Nombre = nombre, Categoria = categoria, Descripcion = descripcion, Lat = lat, Lng = lng, Audiencias = "externo,estudiante,docente" };

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

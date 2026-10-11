using TourVirtualUTB.Api.Models;

namespace TourVirtualUTB.Api.DTOs;

internal static class Dto
{
    public static PoiDto Poi(Poi p) => new(p.Id, p.LugarId, p.Nombre, p.Categoria,
        p.Descripcion, p.Lat, p.Lng, p.MapX, p.MapY, p.EscenaPrincipalId,
        p.Audiencias.Split(',', StringSplitOptions.RemoveEmptyEntries)
            .Select(Enum.Parse<Audiencia>).ToList(), p.Activo);

    public static EscenaDto Escena(Escena e) => new(e.Id, e.LugarId, e.PoiId, e.Nombre,
        e.ImagenUrl, e.ImagenUrlBaja, e.EsEscenaPrincipal, e.Orden,
        e.VistaInicialYaw, e.VistaInicialPitch);

    public static HotspotDto Hotspot(Hotspot h) => new(h.Id, h.EscenaId, h.Tipo,
        h.Pitch, h.Yaw, h.EscenaDestinoId, h.PoiId, h.Etiqueta);

    public static MedioDto Medio(Medio m) => new(m.Id, m.PoiId, m.Tipo, m.Url,
        m.Orden, m.DuracionSeg, m.TextoAlt, m.SubtitulosUrl);

    public static RutaDto Ruta(Ruta r) => new(r.Id, r.LugarId, r.Nombre,
        r.Descripcion, r.Audiencia, r.Activa);
}
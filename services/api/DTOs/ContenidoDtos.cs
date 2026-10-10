using TourVirtualUTB.Api.Models;

namespace TourVirtualUTB.Api.DTOs;

public sealed record PoiDto(int id, int lugar_id, string nombre, string? categoria,
    string? descripcion, double? lat, double? lng, double? map_x, double? map_y,
    int? escena_principal_id, IReadOnlyList<Audiencia> audiencias, bool activo);

public sealed record EscenaDto(int id, int lugar_id, int? poi_id, string? nombre,
    string imagen_url, string? imagen_url_baja, bool es_escena_principal, int orden,
    double? vista_inicial_yaw, double? vista_inicial_pitch);

public sealed record HotspotDto(int id, int escena_id, TipoHotspot tipo, double pitch,
    double yaw, int? escena_destino_id, int? poi_id, string? etiqueta);

public sealed record MedioDto(int id, int poi_id, TipoMedio tipo, string url, int orden,
    int? duracion_seg, string? texto_alt, string? subtitulos_url);

public sealed record RutaDto(int id, int lugar_id, string nombre, string? descripcion,
    Audiencia audiencia, bool activa);

public sealed record PoiDetalleDto(PoiDto poi, IReadOnlyList<MedioDto> medios);

public sealed record RecorridoDto(IReadOnlyList<EscenaDto> escenas,
    IReadOnlyList<HotspotDto> hotspots);

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

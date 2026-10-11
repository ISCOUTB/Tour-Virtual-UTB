using Microsoft.EntityFrameworkCore;
using TourVirtualUTB.Api.Data;
using TourVirtualUTB.Api.DTOs;
using TourVirtualUTB.Api.Models;

namespace TourVirtualUTB.Api.Services;

public class ContenidoService(TourDbContext db, IAlmacenamientoService almacenamiento) : IContenidoService{
    public async Task<IReadOnlyList<PoiDto>> ObtenerPoisAsync(int lugarId, Audiencia audiencia)
    {
        var audStr = audiencia.ToString();
        var pois = await db.Pois
            .AsNoTracking()
            .Where(p => p.LugarId == lugarId && p.Activo &&
                        ("," + p.Audiencias + ",").Contains("," + audStr + ","))
            .OrderBy(p => p.Id)
            .ToListAsync();

        return pois.Select(Dto.Poi).ToList();
    }

    public async Task<RecorridoDto?> ObtenerRecorridoAsync(int lugarId, Audiencia audiencia)
    {
        var audStr = audiencia.ToString();
        var escenas = await db.Escenas
            .AsNoTracking()
            .Include(e => e.Poi)
            .Where(e => e.LugarId == lugarId &&
                        (e.PoiId == null || (e.Poi!.Activo &&
                            ("," + e.Poi.Audiencias + ",").Contains("," + audStr + ","))))
            .OrderBy(e => e.Orden)
            .ToListAsync();

        if (escenas.Count == 0) return null;

        // Firmar las URLs de las escenas
        foreach (var escena in escenas)
        {
            if (!string.IsNullOrEmpty(escena.ImagenUrl))
                escena.ImagenUrl = await almacenamiento.ObtenerUrlFirmadaAsync(escena.ImagenUrl, TimeSpan.FromHours(2));
            
            if (!string.IsNullOrEmpty(escena.ImagenUrlBaja))
                escena.ImagenUrlBaja = await almacenamiento.ObtenerUrlFirmadaAsync(escena.ImagenUrlBaja, TimeSpan.FromHours(2));
        }

        var ids = escenas.Select(e => e.Id).ToList();
        var hotspots = await db.Hotspots.AsNoTracking()
            .Where(h => ids.Contains(h.EscenaId))
            .OrderBy(h => h.Id)
            .ToListAsync();

        var visibles = ids.ToHashSet();
        var hotspotsFiltrados = hotspots
            .Where(h => h.Tipo != TipoHotspot.navegacion ||
                        (h.EscenaDestinoId.HasValue && visibles.Contains(h.EscenaDestinoId.Value)))
            .Select(Dto.Hotspot)
            .ToList();

        return new RecorridoDto(escenas.Select(Dto.Escena).ToList(), hotspotsFiltrados);
    }

    public async Task<PoiDetalleDto?> ObtenerPoiPorIdAsync(int poiId, Audiencia audiencia)
    {
        var audStr = audiencia.ToString();
        var poi = await db.Pois.AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == poiId && p.Activo &&
                ("," + p.Audiencias + ",").Contains("," + audStr + ","));

        if (poi is null) return null;

        var medios = await db.Medios.AsNoTracking()
            .Where(m => m.PoiId == poiId)
            .OrderBy(m => m.Orden)
            .ToListAsync();

        // Firmar las URLs de los medios (audios, videos, fotos)
        foreach (var medio in medios)
        {
            if (!string.IsNullOrEmpty(medio.Url))
                medio.Url = await almacenamiento.ObtenerUrlFirmadaAsync(medio.Url, TimeSpan.FromHours(2));
                
            if (!string.IsNullOrEmpty(medio.SubtitulosUrl))
                medio.SubtitulosUrl = await almacenamiento.ObtenerUrlFirmadaAsync(medio.SubtitulosUrl, TimeSpan.FromHours(2));
        }

        return new PoiDetalleDto(Dto.Poi(poi), medios.Select(Dto.Medio).ToList());
    }

    public async Task<RutaDto?> ObtenerRutaActivaAsync(int lugarId, Audiencia audiencia)
    {
        var ruta = await db.Rutas.AsNoTracking()
            .FirstOrDefaultAsync(r => r.LugarId == lugarId && r.Activa && r.Audiencia == audiencia);

        return ruta is null ? null : Dto.Ruta(ruta);
    }

    public async Task<string?> ObtenerRutaMapaLugarAsync(int lugarId)
    {
        var lugar = await db.Lugares.AsNoTracking().FirstOrDefaultAsync(l => l.Id == lugarId);
        return lugar?.MapaUrl;
    }

    public async Task<bool> ActualizarMapaLugarAsync(int lugarId, string rutaS3)
    {
        var lugar = await db.Lugares.FindAsync(lugarId);
        if (lugar == null) return false;

        lugar.MapaUrl = rutaS3;
        await db.SaveChangesAsync();
        return true;
    }

    public async Task<PoiDto> CrearPoiAsync(CrearPoiRequest request)
    {
        var poi = new Poi
        {
            LugarId = request.LugarId,
            Nombre = request.Nombre,
            Categoria = request.Categoria,
            Descripcion = request.Descripcion,
            MapX = request.MapX,
            MapY = request.MapY,
            Audiencias = request.Audiencias,
            Activo = request.Activo,
            EscenaPrincipalId = request.EscenaPrincipalId
        };

        db.Pois.Add(poi);
        await db.SaveChangesAsync();

        return Dto.Poi(poi);
    }

    public async Task<PoiDto?> ActualizarPoiAsync(int id, ActualizarPoiRequest request)
    {
        var poi = await db.Pois.FindAsync(id);
        if (poi == null) return null;

        poi.Nombre = request.Nombre;
        poi.Categoria = request.Categoria;
        poi.Descripcion = request.Descripcion;
        poi.MapX = request.MapX;
        poi.MapY = request.MapY;
        poi.Audiencias = request.Audiencias;
        poi.Activo = request.Activo;
        poi.EscenaPrincipalId = request.EscenaPrincipalId;

        await db.SaveChangesAsync();
        return Dto.Poi(poi);
    }

    public async Task<bool> EliminarPoiAsync(int id)
    {
        var poi = await db.Pois.FindAsync(id);
        if (poi == null) return false;

        db.Pois.Remove(poi);
        await db.SaveChangesAsync();
        return true;
    }

        // --- ESCENAS ---
    public async Task<EscenaDto> CrearEscenaAsync(CrearEscenaRequest request)
    {
        var escena = new Escena
        {
            LugarId = request.LugarId,
            PoiId = request.PoiId,
            Nombre = request.Nombre,
            ImagenUrl = request.ImagenUrl,
            ImagenUrlBaja = request.ImagenUrlBaja,
            EsEscenaPrincipal = request.EsEscenaPrincipal,
            Orden = request.Orden,
            VistaInicialYaw = request.VistaInicialYaw,
            VistaInicialPitch = request.VistaInicialPitch
        };

        db.Escenas.Add(escena);
        await db.SaveChangesAsync();
        return Dto.Escena(escena);
    }

    public async Task<EscenaDto?> ActualizarEscenaAsync(int id, ActualizarEscenaRequest request)
    {
        var escena = await db.Escenas.FindAsync(id);
        if (escena == null) return null;

        escena.PoiId = request.PoiId;
        escena.Nombre = request.Nombre;
        escena.ImagenUrl = request.ImagenUrl;
        escena.ImagenUrlBaja = request.ImagenUrlBaja;
        escena.EsEscenaPrincipal = request.EsEscenaPrincipal;
        escena.Orden = request.Orden;
        escena.VistaInicialYaw = request.VistaInicialYaw;
        escena.VistaInicialPitch = request.VistaInicialPitch;

        await db.SaveChangesAsync();
        return Dto.Escena(escena);
    }

    public async Task<bool> EliminarEscenaAsync(int id)
    {
        var escena = await db.Escenas.FindAsync(id);
        if (escena == null) return false;

        db.Escenas.Remove(escena);
        await db.SaveChangesAsync();
        return true;
    }

    // --- MEDIOS (Multimedia) ---
    public async Task<MedioDto> CrearMedioAsync(CrearMedioRequest request)
    {
        var medio = new Medio
        {
            PoiId = request.PoiId,
            Tipo = request.Tipo,
            Url = request.Url,
            Orden = request.Orden,
            DuracionSeg = request.DuracionSeg,
            TextoAlt = request.TextoAlt,
            SubtitulosUrl = request.SubtitulosUrl
        };

        db.Medios.Add(medio);
        await db.SaveChangesAsync();
        return Dto.Medio(medio);
    }

    public async Task<MedioDto?> ActualizarMedioAsync(int id, ActualizarMedioRequest request)
    {
        var medio = await db.Medios.FindAsync(id);
        if (medio == null) return null;

        medio.Tipo = request.Tipo;
        medio.Url = request.Url;
        medio.Orden = request.Orden;
        medio.DuracionSeg = request.DuracionSeg;
        medio.TextoAlt = request.TextoAlt;
        medio.SubtitulosUrl = request.SubtitulosUrl;

        await db.SaveChangesAsync();
        return Dto.Medio(medio);
    }

    public async Task<bool> EliminarMedioAsync(int id)

    {
        var medio = await db.Medios.FindAsync(id);
        if (medio == null) return false;

        db.Medios.Remove(medio);
        await db.SaveChangesAsync();
        return true;
    }

        // --- HOTSPOTS ---
    public async Task<HotspotDto> CrearHotspotAsync(CrearHotspotRequest request)
    {
        var hotspot = new Hotspot
        {
            EscenaId = request.EscenaId,
            Tipo = request.Tipo,
            Pitch = request.Pitch,
            Yaw = request.Yaw,
            EscenaDestinoId = request.EscenaDestinoId,
            PoiId = request.PoiId,
            Etiqueta = request.Etiqueta
        };

        db.Hotspots.Add(hotspot);
        await db.SaveChangesAsync();
        return Dto.Hotspot(hotspot);
    }

    public async Task<HotspotDto?> ActualizarHotspotAsync(int id, ActualizarHotspotRequest request)
    {
        var hotspot = await db.Hotspots.FindAsync(id);
        if (hotspot == null) return null;

        hotspot.Tipo = request.Tipo;
        hotspot.Pitch = request.Pitch;
        hotspot.Yaw = request.Yaw;
        hotspot.EscenaDestinoId = request.EscenaDestinoId;
        hotspot.PoiId = request.PoiId;
        hotspot.Etiqueta = request.Etiqueta;

        await db.SaveChangesAsync();
        return Dto.Hotspot(hotspot);
    }

    public async Task<bool> EliminarHotspotAsync(int id)
    {
        var hotspot = await db.Hotspots.FindAsync(id);
        if (hotspot == null) return false;

        db.Hotspots.Remove(hotspot);
        await db.SaveChangesAsync();
        return true;
    }

    // --- LUGARES ---
    public async Task<Lugar> CrearLugarAsync(CrearLugarRequest request)
    {
        var lugar = new Lugar
        {
            Nombre = request.Nombre,
            Slug = request.Slug
        };

        db.Lugares.Add(lugar);
        await db.SaveChangesAsync();
        return lugar;
    }

    public async Task<Lugar?> ActualizarLugarAsync(int id, ActualizarLugarRequest request)
    {
        var lugar = await db.Lugares.FindAsync(id);
        if (lugar == null) return null;

        lugar.Nombre = request.Nombre;
        lugar.Slug = request.Slug;

        await db.SaveChangesAsync();
        return lugar;
    }

    public async Task<bool> EliminarLugarAsync(int id)
    {
        var lugar = await db.Lugares.FindAsync(id);
        if (lugar == null) return false;

        db.Lugares.Remove(lugar);
        await db.SaveChangesAsync();
        return true;
    }

    // --- RUTAS ---
    public async Task<RutaDto> CrearRutaAsync(CrearRutaRequest request)
    {
        var ruta = new Ruta
        {
            LugarId = request.LugarId,
            Nombre = request.Nombre,
            Descripcion = request.Descripcion,
            Audiencia = request.Audiencia,
            Activa = request.Activa
        };

        db.Rutas.Add(ruta);
        await db.SaveChangesAsync();
        return Dto.Ruta(ruta);
    }

    public async Task<RutaDto?> ActualizarRutaAsync(int id, ActualizarRutaRequest request)
    {
        var ruta = await db.Rutas.FindAsync(id);
        if (ruta == null) return null;

        ruta.Nombre = request.Nombre;
        ruta.Descripcion = request.Descripcion;
        ruta.Audiencia = request.Audiencia;
        ruta.Activa = request.Activa;

        await db.SaveChangesAsync();
        return Dto.Ruta(ruta);
    }

    public async Task<bool> EliminarRutaAsync(int id)
    {
        var ruta = await db.Rutas.FindAsync(id);
        if (ruta == null) return false;

        db.Rutas.Remove(ruta);
        await db.SaveChangesAsync();
        return true;
    }

}
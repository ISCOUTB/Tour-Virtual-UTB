using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TourVirtualUTB.Api.Data;
using TourVirtualUTB.Api.DTOs;
using TourVirtualUTB.Api.Models;

namespace TourVirtualUTB.Api.Controllers;

[ApiController]
[Route("api")]
public class ContenidoController(TourDbContext db) : ControllerBase
{
    private Audiencia AudienciaActual =>
        Request.Headers.TryGetValue("X-UTB-Audiencia", out var value) &&
        Enum.TryParse<Audiencia>(value, true, out var audiencia)
            ? audiencia
            : Audiencia.externo;

    [HttpGet("lugares/{lugarId:int}/pois")]
    public async Task<ActionResult<IReadOnlyList<PoiDto>>> ObtenerPois(int lugarId)
    {
        var audiencia = AudienciaActual.ToString();
        var pois = await db.Pois
            .AsNoTracking()
            .Where(p => p.LugarId == lugarId && p.Activo &&
                        ("," + p.Audiencias + ",").Contains("," + audiencia + ","))
            .OrderBy(p => p.Id)
            .ToListAsync();
        return Ok(pois.Select(Dto.Poi).ToList());
    }

    [HttpGet("lugares/{lugarId:int}/recorrido")]
    public async Task<ActionResult<RecorridoDto>> ObtenerRecorrido(int lugarId)
    {
        var audiencia = AudienciaActual.ToString();
        var escenas = await db.Escenas
            .AsNoTracking()
            .Include(e => e.Poi)
            .Where(e => e.LugarId == lugarId &&
                        (e.PoiId == null || (e.Poi!.Activo &&
                            ("," + e.Poi.Audiencias + ",").Contains("," + audiencia + ","))))
            .OrderBy(e => e.Orden)
            .ToListAsync();
        if (escenas.Count == 0)
            return NotFound();

        var ids = escenas.Select(e => e.Id).ToList();
        var hotspots = await db.Hotspots.AsNoTracking()
            .Where(h => ids.Contains(h.EscenaId))
            .OrderBy(h => h.Id)
            .ToListAsync();
        var visibles = ids.ToHashSet();
        return Ok(new RecorridoDto(
            escenas.Select(Dto.Escena).ToList(),
            hotspots.Where(h => h.Tipo != TipoHotspot.navegacion ||
                                h.EscenaDestinoId.HasValue && visibles.Contains(h.EscenaDestinoId.Value))
                .Select(Dto.Hotspot).ToList()));
    }

    [HttpGet("pois/{poiId:int}")]
    public async Task<ActionResult<PoiDetalleDto>> ObtenerPoi(int poiId)
    {
        var audiencia = AudienciaActual.ToString();
        var poi = await db.Pois.AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == poiId && p.Activo &&
                ("," + p.Audiencias + ",").Contains("," + audiencia + ","));
        if (poi is null) return NotFound();
        var medios = await db.Medios.AsNoTracking()
            .Where(m => m.PoiId == poiId).OrderBy(m => m.Orden)
            .ToListAsync();
        return Ok(new PoiDetalleDto(Dto.Poi(poi), medios.Select(Dto.Medio).ToList()));
    }

    [HttpGet("lugares/{lugarId:int}/ruta")]
    public async Task<ActionResult<RutaDto?>> ObtenerRuta(int lugarId)
    {
        var ruta = await db.Rutas.AsNoTracking()
            .FirstOrDefaultAsync(r => r.LugarId == lugarId &&
                r.Activa && r.Audiencia == AudienciaActual);
        return Ok(ruta is null ? null : Dto.Ruta(ruta));
    }
}

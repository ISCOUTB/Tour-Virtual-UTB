using TourVirtualUTB.Api.DTOs;
using TourVirtualUTB.Api.Models;

namespace TourVirtualUTB.Api.Services;

public interface IContenidoService
{
    Task<IReadOnlyList<PoiDto>> ObtenerPoisAsync(int lugarId, Audiencia audiencia);
    Task<RecorridoDto?> ObtenerRecorridoAsync(int lugarId, Audiencia audiencia);
    Task<PoiDetalleDto?> ObtenerPoiPorIdAsync(int poiId, Audiencia audiencia);
    Task<RutaDto?> ObtenerRutaActivaAsync(int lugarId, Audiencia audiencia);
    Task<string?> ObtenerRutaMapaLugarAsync(int lugarId);
    Task<bool> ActualizarMapaLugarAsync(int lugarId, string rutaS3);
    Task<PoiDto> CrearPoiAsync(CrearPoiRequest request);
    Task<PoiDto?> ActualizarPoiAsync(int id, ActualizarPoiRequest request);
    Task<bool> EliminarPoiAsync(int id);
    // Lugares
    Task<Models.Lugar> CrearLugarAsync(CrearLugarRequest request);
    Task<Models.Lugar?> ActualizarLugarAsync(int id, ActualizarLugarRequest request);
    Task<bool> EliminarLugarAsync(int id);

    // Escenas
    Task<EscenaDto> CrearEscenaAsync(CrearEscenaRequest request);
    Task<EscenaDto?> ActualizarEscenaAsync(int id, ActualizarEscenaRequest request);
    Task<bool> EliminarEscenaAsync(int id);

    // Hotspots
    Task<HotspotDto> CrearHotspotAsync(CrearHotspotRequest request);
    Task<HotspotDto?> ActualizarHotspotAsync(int id, ActualizarHotspotRequest request);
    Task<bool> EliminarHotspotAsync(int id);

    // Medios
    Task<MedioDto> CrearMedioAsync(CrearMedioRequest request);
    Task<MedioDto?> ActualizarMedioAsync(int id, ActualizarMedioRequest request);
    Task<bool> EliminarMedioAsync(int id);

    // Rutas
    Task<RutaDto> CrearRutaAsync(CrearRutaRequest request);
    Task<RutaDto?> ActualizarRutaAsync(int id, ActualizarRutaRequest request);
    Task<bool> EliminarRutaAsync(int id);
}
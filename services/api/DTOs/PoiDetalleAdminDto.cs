namespace TourVirtualUTB.Api.DTOs;

/// <summary>
/// Detalle de un POI para el panel de administración: incluye inactivos,
/// medios y escenas asociadas.
/// </summary>
public sealed record PoiDetalleAdminDto(
    PoiDto poi,
    IReadOnlyList<MedioDto> medios,
    IReadOnlyList<EscenaDto> escenas);

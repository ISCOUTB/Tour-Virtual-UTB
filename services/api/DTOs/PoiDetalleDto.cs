using TourVirtualUTB.Api.Models;

namespace TourVirtualUTB.Api.DTOs;

public sealed record PoiDetalleDto(PoiDto poi, IReadOnlyList<MedioDto> medios);
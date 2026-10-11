using TourVirtualUTB.Api.Models;

namespace TourVirtualUTB.Api.DTOs;

public sealed record RecorridoDto(IReadOnlyList<EscenaDto> escenas,
    IReadOnlyList<HotspotDto> hotspots);
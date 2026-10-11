using TourVirtualUTB.Api.Models;

namespace TourVirtualUTB.Api.DTOs;

public sealed record MedioDto(int id, int poi_id, TipoMedio tipo, string url, int orden,
    int? duracion_seg, string? texto_alt, string? subtitulos_url);
    
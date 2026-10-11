using TourVirtualUTB.Api.Models;

namespace TourVirtualUTB.Api.DTOs;

public sealed record PoiDto(int id, int lugar_id, string nombre, string? categoria,
    string? descripcion, double? lat, double? lng, double? map_x, double? map_y,
    int? escena_principal_id, IReadOnlyList<Audiencia> audiencias, bool activo);

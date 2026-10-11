using TourVirtualUTB.Api.Models;

namespace TourVirtualUTB.Api.DTOs;

public sealed record EscenaDto(int id, int lugar_id, int? poi_id, string? nombre,
    string imagen_url, string? imagen_url_baja, bool es_escena_principal, int orden,
    double? vista_inicial_yaw, double? vista_inicial_pitch);
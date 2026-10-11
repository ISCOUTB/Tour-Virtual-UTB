using TourVirtualUTB.Api.Models;

namespace TourVirtualUTB.Api.DTOs;

public sealed record HotspotDto(int id, int escena_id, TipoHotspot tipo, double pitch,
    double yaw, int? escena_destino_id, int? poi_id, string? etiqueta);
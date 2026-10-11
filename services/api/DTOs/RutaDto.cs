using TourVirtualUTB.Api.Models;

namespace TourVirtualUTB.Api.DTOs;

public sealed record RutaDto(int id, int lugar_id, string nombre, string? descripcion,
    Audiencia audiencia, bool activa);
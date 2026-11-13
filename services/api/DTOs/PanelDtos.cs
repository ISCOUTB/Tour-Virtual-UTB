using System.Text.Json;

namespace TourVirtualUTB.Api.DTOs;

// --- Métricas (tabla eventos) ---
public sealed record MetricasDto(DateOnly desde, DateOnly hasta, int visitas, int eventos,
    IReadOnlyList<ConteoTipoDto> por_tipo, IReadOnlyList<VisitasDiaDto> por_dia,
    IReadOnlyList<PoiVistoDto> pois_mas_vistos);
public sealed record ConteoTipoDto(string tipo, int eventos);
public sealed record VisitasDiaDto(DateOnly dia, int visitas, int eventos);
public sealed record PoiVistoDto(int poi_id, string nombre, int visitas, int eventos);

// --- Actividad (tabla auditoria) ---
public sealed record ActividadPaginaDto(int pagina, int tamano, int total,
    IReadOnlyList<ActividadDto> items);
public sealed record ActividadDto(long id, DateTimeOffset ts, Guid? actor_id, string? actor_correo,
    string accion, string entidad, string? entidad_id, JsonElement? antes, JsonElement? despues);

// --- Administradores (tabla perfiles) ---
public sealed record PerfilDto(Guid user_id, string? correo, string rol, bool verificado,
    DateTimeOffset creado_en);
public sealed record CambiarRolRequest(string Rol);

// --- Registro de eventos de la app ---
public sealed record RegistrarEventoRequest(Guid SesionId, string Tipo, int? PoiId, int? EscenaId,
    JsonElement? Payload);

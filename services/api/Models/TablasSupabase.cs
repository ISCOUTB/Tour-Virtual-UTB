namespace TourVirtualUTB.Api.Models;

// Tablas que viven en Supabase y que la API solo consulta (o, en el caso de
// eventos, solo agrega filas). Las crea scripts/datos/perfiles_eventos_auditoria.sql,
// no las migraciones de EF: en TourDbContext van con ExcludeFromMigrations.

/// <summary>Un evento de uso que manda la app (tabla public.eventos).</summary>
public class Evento
{
    public long Id { get; set; }
    public Guid SesionId { get; set; }
    public Guid? UserId { get; set; }
    public string Tipo { get; set; } = string.Empty;
    public int? PoiId { get; set; }
    public int? EscenaId { get; set; }
    public string Payload { get; set; } = "{}";
    public DateTimeOffset Ts { get; set; }
}

/// <summary>Un cambio registrado (tabla public.auditoria).</summary>
public class RegistroAuditoria
{
    public long Id { get; set; }
    public Guid? ActorId { get; set; }
    public string Accion { get; set; } = string.Empty;
    public string Entidad { get; set; } = string.Empty;
    public string? EntidadId { get; set; }
    public string? Antes { get; set; }
    public string? Despues { get; set; }
    public DateTimeOffset Ts { get; set; }
}

/// <summary>Usuario de Supabase Auth (tabla auth.users). Solo id y correo.</summary>
public class UsuarioAuth
{
    public Guid Id { get; set; }
    public string? Email { get; set; }
}

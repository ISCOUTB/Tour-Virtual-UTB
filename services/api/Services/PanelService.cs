using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using TourVirtualUTB.Api.Data;
using TourVirtualUTB.Api.DTOs;
using TourVirtualUTB.Api.Models;

namespace TourVirtualUTB.Api.Services;

/// <summary>
/// Lo que el panel lee de las tablas de Supabase (eventos, auditoria,
/// perfiles) y el registro de eventos que manda la app.
/// </summary>
public class PanelService(TourDbContext db)
{
    /// <summary>Los tipos de evento que acepta POST /api/eventos.</summary>
    public static readonly IReadOnlySet<string> TiposEvento = new HashSet<string>
    {
        "virtual_map_open", "scene_viewed", "hotspot_tapped", "poi_media_played", "tour_completed"
    };

    public static readonly IReadOnlySet<string> Roles = new HashSet<string>
    {
        "externo", "estudiante", "docente", "admin"
    };

    // Colombia no cambia de hora: los días se cuentan en UTC-5.
    private static readonly TimeSpan HoraColombia = TimeSpan.FromHours(-5);

    public static DateOnly HoyEnColombia() =>
        DateOnly.FromDateTime(DateTimeOffset.UtcNow.ToOffset(HoraColombia).DateTime);

    // ------------------------------------------------------------------
    // POIs, incluidos los inactivos
    // ------------------------------------------------------------------

    public async Task<IReadOnlyList<PoiDto>?> PoisConInactivosAsync(int lugarId)
    {
        if (!await db.Lugares.AnyAsync(l => l.Id == lugarId))
            return null;

        var pois = await db.Pois.AsNoTracking()
            .Where(p => p.LugarId == lugarId)
            .OrderBy(p => p.Id)
            .ToListAsync();
        return pois.Select(Dto.Poi).ToList();
    }

    // ------------------------------------------------------------------
    // Métricas
    // ------------------------------------------------------------------

    private sealed class FilaResumen { public int Visitas { get; set; } public int Eventos { get; set; } }
    private sealed class FilaTipo { public string Tipo { get; set; } = ""; public int Eventos { get; set; } }
    private sealed class FilaDia { public DateOnly Dia { get; set; } public int Visitas { get; set; } public int Eventos { get; set; } }
    private sealed class FilaPoi { public int PoiId { get; set; } public string Nombre { get; set; } = ""; public int Visitas { get; set; } public int Eventos { get; set; } }

    public async Task<MetricasDto> MetricasAsync(DateOnly desde, DateOnly hasta)
    {
        // [desde 00:00, hasta + 1 día 00:00) en hora de Colombia.
        var inicio = new DateTimeOffset(desde.ToDateTime(TimeOnly.MinValue), HoraColombia).ToUniversalTime();
        var fin = new DateTimeOffset(hasta.AddDays(1).ToDateTime(TimeOnly.MinValue), HoraColombia).ToUniversalTime();

        var resumen = await db.Database.SqlQuery<FilaResumen>($"""
            select count(distinct sesion_id)::int as "Visitas", count(*)::int as "Eventos"
            from public.eventos where ts >= {inicio} and ts < {fin}
            """).SingleAsync();

        var porTipo = await db.Database.SqlQuery<FilaTipo>($"""
            select tipo as "Tipo", count(*)::int as "Eventos"
            from public.eventos where ts >= {inicio} and ts < {fin}
            group by tipo order by count(*) desc, tipo
            """).ToListAsync();

        var porDia = await db.Database.SqlQuery<FilaDia>($"""
            select (ts at time zone 'America/Bogota')::date as "Dia",
                   count(distinct sesion_id)::int as "Visitas", count(*)::int as "Eventos"
            from public.eventos where ts >= {inicio} and ts < {fin}
            group by 1 order by 1
            """).ToListAsync();

        // Un evento cuenta para un POI si trae poi_id o si su escena es de ese POI.
        var pois = await db.Database.SqlQuery<FilaPoi>($"""
            select p."Id" as "PoiId", p."Nombre" as "Nombre",
                   count(distinct e.sesion_id)::int as "Visitas", count(*)::int as "Eventos"
            from public.eventos e
            left join public."Escenas" s on s."Id" = e.escena_id
            join public."Pois" p on p."Id" = coalesce(e.poi_id, s."PoiId")
            where e.ts >= {inicio} and e.ts < {fin}
            group by p."Id", p."Nombre"
            order by 3 desc, 4 desc, p."Id"
            limit 10
            """).ToListAsync();

        // Un día sin eventos sale con 0, para que la gráfica no tenga huecos.
        var dias = porDia.ToDictionary(d => d.Dia);
        var serie = new List<VisitasDiaDto>();
        for (var dia = desde; dia <= hasta; dia = dia.AddDays(1))
            serie.Add(dias.TryGetValue(dia, out var d)
                ? new VisitasDiaDto(dia, d.Visitas, d.Eventos)
                : new VisitasDiaDto(dia, 0, 0));

        return new MetricasDto(desde, hasta, resumen.Visitas, resumen.Eventos,
            porTipo.Select(t => new ConteoTipoDto(t.Tipo, t.Eventos)).ToList(),
            serie,
            pois.Select(p => new PoiVistoDto(p.PoiId, p.Nombre, p.Visitas, p.Eventos)).ToList());
    }

    // ------------------------------------------------------------------
    // Actividad
    // ------------------------------------------------------------------

    public async Task<ActividadPaginaDto> ActividadAsync(int pagina, int tamano, string? entidad)
    {
        var consulta = db.Auditoria.AsNoTracking();
        if (!string.IsNullOrWhiteSpace(entidad))
            consulta = consulta.Where(a => a.Entidad == entidad);

        var total = await consulta.CountAsync();
        var filas = await (
                from a in consulta
                join u in db.UsuariosAuth on a.ActorId equals (Guid?)u.Id into usuarios
                from u in usuarios.DefaultIfEmpty()
                orderby a.Ts descending, a.Id descending
                select new { a, Correo = u == null ? null : u.Email })
            .Skip((pagina - 1) * tamano)
            .Take(tamano)
            .ToListAsync();

        var items = filas.Select(f => new ActividadDto(f.a.Id, f.a.Ts, f.a.ActorId, f.Correo,
            f.a.Accion, f.a.Entidad, f.a.EntidadId, Json(f.a.Antes), Json(f.a.Despues))).ToList();
        return new ActividadPaginaDto(pagina, tamano, total, items);
    }

    private static JsonElement? Json(string? texto)
    {
        if (texto is null) return null;
        using var documento = JsonDocument.Parse(texto);
        return documento.RootElement.Clone();
    }

    // ------------------------------------------------------------------
    // Administradores
    // ------------------------------------------------------------------

    private sealed class FilaPerfil
    {
        public Guid UserId { get; set; }
        public string? Correo { get; set; }
        public string Rol { get; set; } = "";
        public bool Verificado { get; set; }
        public DateTimeOffset CreadoEn { get; set; }
    }

    private static PerfilDto Perfil(FilaPerfil f) => new(f.UserId, f.Correo, f.Rol, f.Verificado, f.CreadoEn);

    /// <summary>Solo los admin, o todos los perfiles si <paramref name="todos"/>.</summary>
    public async Task<IReadOnlyList<PerfilDto>> PerfilesAsync(bool todos)
    {
        var filas = await db.Database.SqlQuery<FilaPerfil>($"""
            select p.user_id as "UserId", u.email as "Correo", p.rol::text as "Rol",
                   p.verificado as "Verificado", p.creado_en as "CreadoEn"
            from public.perfiles p
            left join auth.users u on u.id = p.user_id
            where {todos} or p.rol = 'admin'
            order by u.email nulls last, p.user_id
            limit 500
            """).ToListAsync();
        return filas.Select(Perfil).ToList();
    }

    public enum ResultadoCambioRol { Hecho, NoExiste, EsUnoMismo, UltimoAdmin }

    /// <summary>
    /// Cambia el rol de una persona y la marca como verificada. Si quien lo
    /// pide entró con token, la auditoria registra su id como actor.
    /// </summary>
    public async Task<(ResultadoCambioRol resultado, PerfilDto? perfil)> CambiarRolAsync(
        Guid usuario, string rol, Guid? llamante)
    {
        await using var transaccion = await db.Database.BeginTransactionAsync();

        var actual = await db.Database.SqlQuery<string>($"""
            select rol::text as "Value" from public.perfiles where user_id = {usuario} for update
            """).FirstOrDefaultAsync();
        if (actual is null)
            return (ResultadoCambioRol.NoExiste, null);

        if (actual == "admin" && rol != "admin")
        {
            if (llamante == usuario)
                return (ResultadoCambioRol.EsUnoMismo, null);

            var admins = await db.Database.SqlQuery<int>($"""
                select count(*)::int as "Value" from public.perfiles where rol = 'admin'
                """).SingleAsync();
            if (admins <= 1)
                return (ResultadoCambioRol.UltimoAdmin, null);
        }

        // auth.uid() lee este valor; así el trigger de auditoria sabe quién fue.
        var actor = llamante?.ToString() ?? "";
        await db.Database.ExecuteSqlAsync($"select set_config('request.jwt.claim.sub', {actor}, true)");
        await db.Database.ExecuteSqlAsync($"""
            update public.perfiles set rol = {rol}::public.rol_usuario, verificado = true
            where user_id = {usuario}
            """);
        await transaccion.CommitAsync();

        var fila = await db.Database.SqlQuery<FilaPerfil>($"""
            select p.user_id as "UserId", u.email as "Correo", p.rol::text as "Rol",
                   p.verificado as "Verificado", p.creado_en as "CreadoEn"
            from public.perfiles p
            left join auth.users u on u.id = p.user_id
            where p.user_id = {usuario}
            """).SingleAsync();
        return (ResultadoCambioRol.Hecho, Perfil(fila));
    }

    // ------------------------------------------------------------------
    // Registro de eventos
    // ------------------------------------------------------------------

    /// <summary>Null si todo está bien; si no, el motivo del rechazo.</summary>
    public async Task<string?> RegistrarEventoAsync(RegistrarEventoRequest request)
    {
        if (request.SesionId == Guid.Empty)
            return "Falta sesionId.";
        if (request.Tipo is null || !TiposEvento.Contains(request.Tipo))
            return $"tipo debe ser uno de: {string.Join(", ", TiposEvento)}.";

        var payload = "{}";
        if (request.Payload is { } p && p.ValueKind != JsonValueKind.Null)
        {
            if (p.ValueKind != JsonValueKind.Object)
                return "payload debe ser un objeto JSON.";
            payload = p.GetRawText();
            if (payload.Length > 2048)
                return "payload no puede pasar de 2 KB.";
        }

        if (request.PoiId is int poiId && !await db.Pois.AnyAsync(x => x.Id == poiId))
            return "El poiId no existe.";
        if (request.EscenaId is int escenaId && !await db.Escenas.AnyAsync(x => x.Id == escenaId))
            return "El escenaId no existe.";

        // user_id queda vacío: la app no manda sesión de Supabase y no se
        // puede confiar en un id que llegue en el cuerpo.
        db.Eventos.Add(new Evento
        {
            SesionId = request.SesionId,
            Tipo = request.Tipo,
            PoiId = request.PoiId,
            EscenaId = request.EscenaId,
            Payload = payload,
            Ts = DateTimeOffset.UtcNow
        });
        await db.SaveChangesAsync();
        return null;
    }
}

using Microsoft.AspNetCore.Mvc;
using TourVirtualUTB.Api.DTOs;
using TourVirtualUTB.Api.Services;

namespace TourVirtualUTB.Api.Controllers;

/// <summary>
/// Lo que el panel necesita leer: POIs con inactivos, métricas, actividad y
/// administradores. Mismo portero que el resto de /api/admin.
/// </summary>
[ApiController]
[Route("api/admin")]
[RequiereClaveAdmin]
public class AdminPanelController(PanelService panel) : ControllerBase
{
    /// <summary>Todos los POI del lugar, también los inactivos.</summary>
    [HttpGet("lugares/{lugarId:int}/pois")]
    public async Task<ActionResult<IReadOnlyList<PoiDto>>> PoisConInactivos(int lugarId)
    {
        var pois = await panel.PoisConInactivosAsync(lugarId);
        if (pois is null) return NotFound("El lugar no existe.");
        return Ok(pois);
    }

    /// <summary>
    /// Uso del tour entre dos fechas (formato 2026-11-01, hora de Colombia,
    /// ambas incluidas). Sin fechas: los últimos 30 días.
    /// </summary>
    [HttpGet("metricas")]
    public async Task<ActionResult<MetricasDto>> Metricas([FromQuery] DateOnly? desde, [FromQuery] DateOnly? hasta)
    {
        var fin = hasta ?? PanelService.HoyEnColombia();
        var inicio = desde ?? fin.AddDays(-29);
        if (inicio > fin) return BadRequest("desde no puede ser después de hasta.");
        if (fin.DayNumber - inicio.DayNumber > 366) return BadRequest("El rango máximo es de un año.");

        return Ok(await panel.MetricasAsync(inicio, fin));
    }

    /// <summary>Los últimos cambios registrados, del más nuevo al más viejo.</summary>
    [HttpGet("actividad")]
    public async Task<ActionResult<ActividadPaginaDto>> Actividad(
        [FromQuery] int pagina = 1, [FromQuery] int tamano = 20, [FromQuery] string? entidad = null)
    {
        if (pagina < 1) return BadRequest("pagina empieza en 1.");
        if (tamano is < 1 or > 100) return BadRequest("tamano va de 1 a 100.");

        return Ok(await panel.ActividadAsync(pagina, tamano, entidad));
    }

    /// <summary>
    /// Las personas con rol admin. Con todos=true, todos los perfiles, para
    /// buscar a quién darle el rol.
    /// </summary>
    [HttpGet("administradores")]
    public async Task<ActionResult<IReadOnlyList<PerfilDto>>> Administradores([FromQuery] bool todos = false) =>
        Ok(await panel.PerfilesAsync(todos));

    /// <summary>
    /// Da o quita el rol admin (o pone otro rol). No deja quitarse el rol a
    /// uno mismo ni quitar el último admin. La cuenta se crea en Supabase.
    /// </summary>
    [HttpPut("administradores/{userId:guid}")]
    public async Task<ActionResult<PerfilDto>> CambiarRol(Guid userId, [FromBody] CambiarRolRequest request)
    {
        var rol = request.Rol?.Trim().ToLowerInvariant() ?? "";
        if (!PanelService.Roles.Contains(rol))
            return BadRequest($"rol debe ser uno de: {string.Join(", ", PanelService.Roles)}.");

        var (resultado, perfil) = await panel.CambiarRolAsync(userId, rol,
            RequiereClaveAdminAttribute.UsuarioDe(HttpContext));
        return resultado switch
        {
            PanelService.ResultadoCambioRol.NoExiste => NotFound("Esa persona no tiene perfil. Créala primero en Supabase (Authentication > Users)."),
            PanelService.ResultadoCambioRol.EsUnoMismo => Conflict("No puedes quitarte el rol de administrador a ti misma o a ti mismo."),
            PanelService.ResultadoCambioRol.UltimoAdmin => Conflict("Debe quedar al menos un administrador."),
            _ => Ok(perfil)
        };
    }
}

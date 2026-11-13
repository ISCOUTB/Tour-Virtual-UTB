using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using TourVirtualUTB.Api.Data;

namespace TourVirtualUTB.Api.Services;

/// <summary>
/// Protege los endpoints que escriben contenido. Deja pasar una petición si
/// trae cualquiera de estas dos credenciales:
///
/// 1. La clave compartida en la cabecera X-Admin-Key (Admin:ApiKey). Sirve
///    para Swagger y para los scripts, como cargar_narraciones.py.
/// 2. Un token de Supabase Auth (Authorization: Bearer ...) de una persona
///    cuyo rol en la tabla perfiles es admin. Es lo que usa el panel. Solo
///    se revisa si está configurado Supabase:Url.
///
/// Respuestas: 401 si no trae credenciales válidas, 403 si el token es válido
/// pero la persona no es admin, 503 fuera de Development si no hay ninguna de
/// las dos formas configurada. En Development, sin clave configurada, se deja
/// pasar lo que no traiga token, como antes, para no estorbar al equipo.
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public sealed class RequiereClaveAdminAttribute : Attribute, IAsyncAuthorizationFilter
{
    public const string Cabecera = "X-Admin-Key";

    public async Task OnAuthorizationAsync(AuthorizationFilterContext context)
    {
        var http = context.HttpContext;
        var servicios = http.RequestServices;
        var configuracion = servicios.GetRequiredService<IConfiguration>();
        var clave = configuracion["Admin:ApiKey"];
        var conSupabase = AutenticacionSupabase.EstaConfigurada(configuracion);

        // 1. Clave compartida.
        var enviada = http.Request.Headers[Cabecera].ToString();
        if (!string.IsNullOrEmpty(clave) && enviada.Length > 0 &&
            CryptographicOperations.FixedTimeEquals(Encoding.UTF8.GetBytes(enviada), Encoding.UTF8.GetBytes(clave)))
            return;

        // 2. Token de Supabase.
        var traeToken = http.Request.Headers.Authorization.ToString()
            .StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase);
        if (conSupabase && traeToken)
        {
            var resultado = await http.AuthenticateAsync(AutenticacionSupabase.Esquema);
            if (!resultado.Succeeded)
            {
                context.Result = new UnauthorizedObjectResult("El token no es válido o ya venció. Inicia sesión otra vez.");
                return;
            }

            if (!Guid.TryParse(resultado.Principal?.FindFirst("sub")?.Value, out var usuario))
            {
                context.Result = new UnauthorizedObjectResult("El token no identifica a ningún usuario.");
                return;
            }

            var rol = await RolDeAsync(servicios, usuario);
            if (rol != "admin")
                context.Result = new ObjectResult("Tu usuario no tiene rol de administrador.")
                    { StatusCode = StatusCodes.Status403Forbidden };
            return;
        }

        // 3. Sin credenciales válidas.
        if (string.IsNullOrEmpty(clave) && !traeToken)
        {
            if (servicios.GetRequiredService<IHostEnvironment>().IsDevelopment())
                return;

            if (!conSupabase)
            {
                context.Result = new ObjectResult("Los endpoints de administración están deshabilitados: falta configurar Admin:ApiKey o Supabase:Url.")
                    { StatusCode = StatusCodes.Status503ServiceUnavailable };
                return;
            }
        }

        context.Result = new UnauthorizedObjectResult(conSupabase
            ? $"Inicia sesión como administrador o envía la cabecera {Cabecera}."
            : $"Falta la cabecera {Cabecera} o no es correcta.");
    }

    /// <summary>
    /// Rol de la persona en public.perfiles (la tabla de supabase/migrations;
    /// la API no la crea ni la modifica). Null si no tiene perfil.
    /// </summary>
    private static async Task<string?> RolDeAsync(IServiceProvider servicios, Guid usuario)
    {
        var db = servicios.GetRequiredService<TourDbContext>();
        try
        {
            return await db.Database
                .SqlQuery<string>($"select rol::text as \"Value\" from public.perfiles where user_id = {usuario}")
                .FirstOrDefaultAsync();
        }
        catch (PostgresException error) when (error.SqlState == PostgresErrorCodes.UndefinedTable)
        {
            servicios.GetRequiredService<ILogger<RequiereClaveAdminAttribute>>()
                .LogError("No existe la tabla public.perfiles: nadie puede entrar como administrador con token. Aplica supabase/migrations/0002_perfiles_y_auth.sql.");
            return null;
        }
    }
}

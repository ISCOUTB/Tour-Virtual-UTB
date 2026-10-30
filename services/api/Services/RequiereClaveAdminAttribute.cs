using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace TourVirtualUTB.Api.Services;

/// <summary>
/// Protege los endpoints que escriben contenido con una clave compartida en la
/// cabecera X-Admin-Key. Es una barrera mínima hasta que exista login de
/// administradores con Supabase Auth; sin ella cualquiera que conozca la URL
/// podía borrar POIs o reemplazar panorámicas.
///
/// La clave se configura en Admin:ApiKey (user-secrets o variable de entorno
/// Admin__ApiKey). En Development, si no hay clave configurada, se deja pasar
/// para no estorbar al equipo; fuera de Development se rechaza todo.
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public sealed class RequiereClaveAdminAttribute : Attribute, IAuthorizationFilter
{
    public const string Cabecera = "X-Admin-Key";

    public void OnAuthorization(AuthorizationFilterContext context)
    {
        var servicios = context.HttpContext.RequestServices;
        var clave = servicios.GetRequiredService<IConfiguration>()["Admin:ApiKey"];

        if (string.IsNullOrEmpty(clave))
        {
            if (servicios.GetRequiredService<IHostEnvironment>().IsDevelopment())
                return;

            context.Result = new ObjectResult("Los endpoints de administración están deshabilitados: falta configurar Admin:ApiKey.")
                { StatusCode = StatusCodes.Status503ServiceUnavailable };
            return;
        }

        var enviada = context.HttpContext.Request.Headers[Cabecera].ToString();
        if (!CryptographicOperations.FixedTimeEquals(Encoding.UTF8.GetBytes(enviada), Encoding.UTF8.GetBytes(clave)))
            context.Result = new UnauthorizedObjectResult($"Falta la cabecera {Cabecera} o no es correcta.");
    }
}

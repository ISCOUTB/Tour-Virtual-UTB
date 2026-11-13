using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;

namespace TourVirtualUTB.Api.Services;

/// <summary>
/// Lee los tokens (JWT) que entrega Supabase Auth cuando alguien inicia sesión
/// en el panel. Solo se activa si está configurado Supabase:Url.
///
/// Acepta las dos formas en que Supabase firma los tokens:
/// - claves de firma (JWT Signing Keys, las de los proyectos nuevos): se
///   descargan de {Supabase:Url}/auth/v1/.well-known/jwks.json y se renuevan
///   solas; no hay nada secreto que configurar;
/// - el "JWT secret" antiguo (HS256): solo si se configura Supabase:JwtSecret
///   en user-secrets.
///
/// El token solo dice quién es la persona. Si es administradora lo decide
/// <see cref="RequiereClaveAdminAttribute"/>, mirando la tabla perfiles.
/// </summary>
public static class AutenticacionSupabase
{
    public const string Esquema = JwtBearerDefaults.AuthenticationScheme;

    public static bool EstaConfigurada(IConfiguration configuracion) =>
        !string.IsNullOrWhiteSpace(configuracion["Supabase:Url"]);

    public static IServiceCollection AgregarAutenticacionSupabase(
        this IServiceCollection servicios, IConfiguration configuracion, IHostEnvironment entorno)
    {
        var autenticacion = servicios.AddAuthentication();
        if (!EstaConfigurada(configuracion))
            return servicios;

        var url = configuracion["Supabase:Url"]!.TrimEnd('/');
        var emisor = $"{url}/auth/v1";
        var secreto = configuracion["Supabase:JwtSecret"];

        autenticacion.AddJwtBearer(Esquema, opciones =>
        {
            // Deja los nombres de los datos del token tal cual ("sub", "role").
            opciones.MapInboundClaims = false;
            opciones.ConfigurationManager = new ConfigurationManager<OpenIdConnectConfiguration>(
                $"{emisor}/.well-known/jwks.json",
                new RecuperadorJwks(),
                new HttpDocumentRetriever { RequireHttps = !entorno.IsDevelopment() });
            opciones.TokenValidationParameters = new TokenValidationParameters
            {
                ValidIssuer = emisor,
                ValidAudience = "authenticated",
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                IssuerSigningKeys = string.IsNullOrWhiteSpace(secreto)
                    ? Array.Empty<SecurityKey>()
                    : new SecurityKey[] { new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secreto)) },
            };
        });
        return servicios;
    }

    /// <summary>
    /// Supabase publica sus claves públicas como un JWKS suelto, sin el
    /// documento de descubrimiento de OpenID. Esto lo envuelve para que el
    /// lector de tokens lo use, lo guarde en caché y lo renueve.
    /// </summary>
    private sealed class RecuperadorJwks : IConfigurationRetriever<OpenIdConnectConfiguration>
    {
        public async Task<OpenIdConnectConfiguration> GetConfigurationAsync(
            string address, IDocumentRetriever retriever, CancellationToken cancel)
        {
            var json = await retriever.GetDocumentAsync(address, cancel);
            var configuracion = new OpenIdConnectConfiguration();
            foreach (var clave in new JsonWebKeySet(json).GetSigningKeys())
                configuracion.SigningKeys.Add(clave);
            return configuracion;
        }
    }
}

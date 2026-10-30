using System.Text.Json.Serialization;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi;
using TourVirtualUTB.Api.Data;
using TourVirtualUTB.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// 1. Configurar la Base de Datos
// La cadena real va en user-secrets o en la variable de entorno
// ConnectionStrings__DefaultConnection. appsettings.Development.json trae
// una de ejemplo para un Postgres local; fuera de Development no hay valor
// por defecto, y sin cadena la API no arranca en lugar de fallar en la
// primera consulta.
var cadenaConexion = builder.Configuration.GetConnectionString("DefaultConnection");
if (string.IsNullOrWhiteSpace(cadenaConexion))
    throw new InvalidOperationException("Configure ConnectionStrings:DefaultConnection.");

builder.Services.AddDbContext<TourDbContext>(options => options.UseNpgsql(cadenaConexion));

// 2. Agregar Controladores
builder.Services.AddControllers().AddJsonOptions(options =>
    options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter()));
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    // Botón "Authorize" en Swagger para mandar la clave de administración.
    options.AddSecurityDefinition("ClaveAdmin", new OpenApiSecurityScheme
    {
        Type = SecuritySchemeType.ApiKey,
        In = ParameterLocation.Header,
        Name = RequiereClaveAdminAttribute.Cabecera,
        Description = "Clave configurada en Admin:ApiKey. Necesaria para /api/admin/* y para subir mapas."
    });
    options.AddSecurityRequirement(document => new OpenApiSecurityRequirement
    {
        [new OpenApiSecuritySchemeReference("ClaveAdmin", document)] = []
    });
});
builder.Services.AddScoped<IAlmacenamientoService, AlmacenamientoService>();
builder.Services.AddScoped<IContenidoService, ContenidoService>();

// 3. Configurar CORS (Permitir peticiones desde Flutter)
builder.Services.AddCors(options =>
{
    options.AddPolicy("Frontend", policy =>
    {
        var origins = builder.Configuration
            .GetSection("Cors:AllowedOrigins")
            .GetChildren()
            .Select(section => section.Value)
            .OfType<string>()
            .ToArray();

        if (origins.Length == 0)
        {
            if (!builder.Environment.IsDevelopment())
            {
                throw new InvalidOperationException(
                    "Configure Cors:AllowedOrigins fuera de Development.");
            }

            policy.AllowAnyOrigin()
                .AllowAnyMethod()
                .AllowAnyHeader();
            return;
        }

        policy.WithOrigins(origins)
            .AllowAnyMethod()
            .AllowAnyHeader();
    });
});

var app = builder.Build();

if (string.IsNullOrEmpty(app.Configuration["Admin:ApiKey"]))
{
    app.Logger.LogWarning(app.Environment.IsDevelopment()
        ? "Admin:ApiKey no está configurada: los endpoints de administración quedan abiertos (solo en Development)."
        : "Admin:ApiKey no está configurada: los endpoints de administración responderán 503.");
}


// if (app.Environment.IsDevelopment())
// {
//     await using var scope = app.Services.CreateAsyncScope();
//     await ContenidoInicial.InicializarAsync(
//         scope.ServiceProvider.GetRequiredService<TourDbContext>());
// }

// 4. Configurar el entorno HTTP
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseStaticFiles();

app.UseCors("Frontend");

app.UseAuthorization();

app.MapControllers();

app.Run();
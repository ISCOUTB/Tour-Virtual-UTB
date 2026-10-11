using System.Text.Json.Serialization;
using Microsoft.EntityFrameworkCore;
using TourVirtualUTB.Api.Data;
using TourVirtualUTB.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// 1. Configurar la Base de Datos
builder.Services.AddDbContext<TourDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// 2. Agregar Controladores
builder.Services.AddControllers().AddJsonOptions(options =>
    options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter()));
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddScoped<IAlmacenamientoService, AlmacenamientoService>();
builder.Services.AddScoped<IContenidoService, ContenidoService>();
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
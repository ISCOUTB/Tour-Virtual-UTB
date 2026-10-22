namespace TourVirtualUTB.Api.DTOs;

public record CrearPoiRequest(
    int LugarId, 
    string Nombre, 
    string? Categoria, 
    string? Descripcion, 
    double? MapX, 
    double? MapY, 
    string Audiencias, 
    bool Activo,
    int? EscenaPrincipalId);

public record ActualizarPoiRequest(
    string Nombre, 
    string? Categoria, 
    string? Descripcion, 
    double? MapX, 
    double? MapY, 
    string Audiencias, 
    bool Activo,
    int? EscenaPrincipalId);

// --- DTOs de Lugar ---
public record CrearLugarRequest(string Nombre, string Slug);
public record ActualizarLugarRequest(string Nombre, string Slug);

// --- DTOs de Escena ---
// ImagenUrl es opcional: lo normal es crear la escena vacía y luego subir la
// panorámica con POST /api/admin/escenas/{id}/imagen.
public record CrearEscenaRequest(int LugarId, int? PoiId, string? Nombre, string? ImagenUrl, string? ImagenUrlBaja, bool EsEscenaPrincipal, int Orden, double? VistaInicialYaw, double? VistaInicialPitch);
public record ActualizarEscenaRequest(int? PoiId, string? Nombre, string? ImagenUrl, string? ImagenUrlBaja, bool EsEscenaPrincipal, int Orden, double? VistaInicialYaw, double? VistaInicialPitch);

// --- DTOs de Hotspot ---
public record CrearHotspotRequest(int EscenaId, Models.TipoHotspot Tipo, double Pitch, double Yaw, int? EscenaDestinoId, int? PoiId, string? Etiqueta);
public record ActualizarHotspotRequest(Models.TipoHotspot Tipo, double Pitch, double Yaw, int? EscenaDestinoId, int? PoiId, string? Etiqueta);

// --- DTOs de Medio ---
public record CrearMedioRequest(int PoiId, Models.TipoMedio Tipo, string Url, int Orden, int? DuracionSeg, string? TextoAlt, string? SubtitulosUrl);
public record ActualizarMedioRequest(Models.TipoMedio Tipo, string Url, int Orden, int? DuracionSeg, string? TextoAlt, string? SubtitulosUrl);

// --- DTOs de Ruta ---
public record CrearRutaRequest(int LugarId, string Nombre, string? Descripcion, Models.Audiencia Audiencia, bool Activa);
public record ActualizarRutaRequest(string Nombre, string? Descripcion, Models.Audiencia Audiencia, bool Activa);
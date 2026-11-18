namespace TourVirtualUTB.Api.DTOs;

/// <summary>
/// Cuerpo de un 409: por qué no se pudo hacer el cambio y un código estable
/// para que el panel lo reconozca sin leer el mensaje.
/// </summary>
public sealed record ConflictoDto(string Mensaje, string Codigo);

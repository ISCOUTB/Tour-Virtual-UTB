namespace TourVirtualUTB.Api.Services;

/// <summary>Resultado de intentar borrar una escena.</summary>
public enum EliminarEscenaResultado
{
    Eliminada,
    NoExiste,
    /// <summary>
    /// Hay hotspots de otras escenas que apuntan a esta como destino
    /// (FK Restrict en EscenaDestinoId).
    /// </summary>
    EnUsoComoDestino
}

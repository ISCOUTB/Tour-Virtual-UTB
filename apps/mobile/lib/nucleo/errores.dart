import 'dart:async';
import 'dart:io';

/// Fallo con un mensaje que se puede mostrar al usuario.
///
/// Existe porque la version anterior de la app silenciaba los errores de red en
/// `debugPrint` y dejaba una pantalla vacia: quien probaba la aplicacion sin el
/// backend arriba creia que estaba rota.
sealed class FalloApp implements Exception {
  const FalloApp(this.mensaje, {this.detalle});

  /// Texto en espanol, apto para mostrar en pantalla.
  final String mensaje;

  /// Causa tecnica original. Se registra, no se muestra.
  final Object? detalle;

  /// Si reintentar tiene alguna posibilidad de funcionar.
  bool get esReintentable => true;

  @override
  String toString() =>
      '$runtimeType: $mensaje${detalle == null ? '' : ' ($detalle)'}';
}

/// No hubo forma de alcanzar el servidor.
final class FalloDeConexion extends FalloApp {
  const FalloDeConexion({super.detalle})
    : super(
        'No pudimos conectarnos. Revisa tu conexion a internet e intenta de nuevo.',
      );
}

/// El servidor tardo demasiado.
final class FalloDeTiempo extends FalloApp {
  const FalloDeTiempo({super.detalle})
    : super('El servidor tardo demasiado en responder. Intenta de nuevo.');
}

/// La sesion no es valida o expiro.
final class FalloDeSesion extends FalloApp {
  const FalloDeSesion({super.detalle})
    : super('Tu sesion expiro. Vuelve a entrar para continuar.');

  @override
  bool get esReintentable => false;
}

/// El contenido no existe, o el servidor decidio que este usuario no debe verlo.
///
/// Ambos casos se presentan igual a proposito: distinguirlos revelaria la
/// existencia de contenido curado para otro perfil.
final class FalloSinContenido extends FalloApp {
  const FalloSinContenido([String? mensaje, Object? detalle])
    : super(
        mensaje ?? 'Todavia no hay contenido disponible aqui.',
        detalle: detalle,
      );

  @override
  bool get esReintentable => false;
}

/// Cualquier otra cosa.
final class FalloInesperado extends FalloApp {
  const FalloInesperado({super.detalle})
    : super('Algo salio mal. Intenta de nuevo en un momento.');
}

/// Traduce las excepciones de la capa de red a un [FalloApp].
FalloApp traducirFallo(Object error) {
  return switch (error) {
    FalloApp fallo => fallo,
    SocketException _ => FalloDeConexion(detalle: error),
    TimeoutException _ => FalloDeTiempo(detalle: error),
    _ => FalloInesperado(detalle: error),
  };
}

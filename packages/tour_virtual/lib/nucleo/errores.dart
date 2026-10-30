import 'dart:async';
import 'dart:io';

import '../l10n/textos.dart';

/// Fallo que se puede explicar al usuario.
///
/// Existe porque la version anterior de la app silenciaba los errores de red en
/// `debugPrint` y dejaba una pantalla vacia: quien probaba la aplicacion sin el
/// backend arriba creia que estaba rota.
///
/// El fallo no lleva el texto: lo pone la interfaz con [mensaje], en el idioma
/// que el usuario eligió.
sealed class FalloApp implements Exception {
  const FalloApp({this.detalle});

  /// Causa tecnica original. Se registra, no se muestra.
  final Object? detalle;

  /// Texto apto para mostrar en pantalla.
  String mensaje(Textos txt);

  /// Si reintentar tiene alguna posibilidad de funcionar.
  bool get esReintentable => true;

  @override
  String toString() => '$runtimeType${detalle == null ? '' : ' ($detalle)'}';
}

/// No hubo forma de alcanzar el servidor.
final class FalloDeConexion extends FalloApp {
  const FalloDeConexion({super.detalle});

  @override
  String mensaje(Textos txt) => txt.falloConexion;
}

/// El servidor tardo demasiado.
final class FalloDeTiempo extends FalloApp {
  const FalloDeTiempo({super.detalle});

  @override
  String mensaje(Textos txt) => txt.falloTiempo;
}

/// La sesion no es valida o expiro.
final class FalloDeSesion extends FalloApp {
  const FalloDeSesion({super.detalle});

  @override
  String mensaje(Textos txt) => txt.falloSesion;

  @override
  bool get esReintentable => false;
}

/// El contenido no existe, o el servidor decidio que este usuario no debe verlo.
///
/// Ambos casos se presentan igual a proposito: distinguirlos revelaria la
/// existencia de contenido curado para otro perfil.
final class FalloSinContenido extends FalloApp {
  const FalloSinContenido({super.detalle}) : soloConApi = false;

  /// El modo de demostración no tiene panorámicas: explica al equipo por qué
  /// el visor está vacío en vez de decir que no hay contenido.
  const FalloSinContenido.soloConApi() : soloConApi = true, super();

  final bool soloConApi;

  @override
  String mensaje(Textos txt) =>
      soloConApi ? txt.falloPanoramasSoloConApi : txt.falloSinContenido;

  @override
  bool get esReintentable => false;
}

/// Cualquier otra cosa.
final class FalloInesperado extends FalloApp {
  const FalloInesperado({super.detalle});

  @override
  String mensaje(Textos txt) => txt.falloInesperado;
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

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Duraciones y curvas del módulo.
///
/// Un solo vocabulario de movimiento para que el tour se sienta parte de la app
/// UTB y no una colección de efectos sueltos: salidas exponenciales, nada que
/// rebote salvo los marcadores del mapa al caer.
abstract final class Movimiento {
  static const corto = Duration(milliseconds: 180);
  static const medio = Duration(milliseconds: 320);
  static const largo = Duration(milliseconds: 520);

  /// El mapa entrando inclinado y la revelación circular.
  static const escena = Duration(milliseconds: 850);

  static const salida = Curves.easeOutCubic;
  static const salidaFuerte = Curves.easeOutQuart;
  static const vaiven = Curves.easeInOutCubic;

  /// Perspectiva de las transformaciones 3D. Más alto, más profundidad.
  static const perspectiva = 0.0011;
}

/// Si el sistema pide quitar animaciones (WCAG 2.3.3, «Quitar animaciones» en
/// Android). Cada efecto decorativo del módulo lo consulta y se reduce a un
/// fundido o a un corte.
bool sinMovimiento(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Si la plataforma tiene giroscopio que el visor 360 pueda usar.
///
/// `dchs_motion_sensors`, del que depende el visor, solo existe en Android e
/// iOS: en escritorio y web el canal no existe y pedirlo tumba la app.
bool get hayGiroscopio =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

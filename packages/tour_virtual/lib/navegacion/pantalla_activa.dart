import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Mantiene la pantalla encendida mientras una guía o medición está visible.
/// Cada pantalla libera solo su propia solicitud, también al ir al fondo.
class PantallaActiva {
  static var _solicitudes = 0;
  static Future<void> _pendiente = Future<void>.value();
  var _activa = false;

  Future<void> cambiar(bool activa) {
    if (_activa == activa) return _pendiente;
    _activa = activa;
    _solicitudes += activa ? 1 : -1;
    return _pendiente = _pendiente.then((_) async {
      try {
        await WakelockPlus.toggle(enable: _solicitudes > 0);
      } catch (error) {
        // Una plataforma sin plugin sigue permitiendo usar el plano.
        debugPrint('No se pudo mantener la pantalla encendida: $error');
      }
    });
  }
}

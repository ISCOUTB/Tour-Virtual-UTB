import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Puntos de interés que el usuario ya conoció (RF-19).
///
/// Se guarda en el dispositivo y no en la base por dos razones: el visitante
/// externo —el usuario principal— entra sin cuenta, y así el progreso
/// sobrevive a la migración de backend pendiente.
///
/// Un POI cuenta como visitado al abrir su ficha, no al entrar en su escena
/// 360: es el momento en que el usuario conoce el lugar, y funciona aunque la
/// panorámica falle.
class ProgresoRecorrido extends Notifier<Set<int>> {
  static const _clave = 'poisVisitados';

  SharedPreferences? _prefs;

  @override
  Set<int> build() {
    _cargar();
    return const {};
  }

  Future<void> _cargar() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final guardados = _prefs?.getStringList(_clave) ?? const [];
      final ids = guardados.map(int.tryParse).nonNulls.toSet();
      if (ids.isNotEmpty) state = ids;
    } catch (error) {
      // Perder el progreso no debe impedir usar la aplicación.
      debugPrint('No se pudo leer el progreso: $error');
    }
  }

  /// Marca un POI como visitado. Devuelve true si es la primera vez.
  bool marcarVisitado(int poiId) {
    if (state.contains(poiId)) return false;
    state = {...state, poiId};
    _guardar();
    return true;
  }

  void reiniciar() {
    state = const {};
    _guardar();
  }

  Future<void> _guardar() async {
    try {
      await _prefs?.setStringList(
        _clave,
        state.map((id) => id.toString()).toList(),
      );
    } catch (error) {
      debugPrint('No se pudo guardar el progreso: $error');
    }
  }
}

final progresoProvider = NotifierProvider<ProgresoRecorrido, Set<int>>(
  ProgresoRecorrido.new,
);

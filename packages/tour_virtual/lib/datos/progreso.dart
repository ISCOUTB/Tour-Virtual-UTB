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
  static const _clave = 'tourVirtual.poisVisitados';

  late final Future<SharedPreferences?> _prefs;
  late final Future<void> _cargado;

  /// Se completa cuando el progreso guardado ya está en memoria.
  ///
  /// Hay que esperarlo antes de preguntar si un lugar es nuevo. Sin esto, el
  /// primer toque tras arrancar veía el conjunto todavía vacío, lo contaba
  /// como primera visita y, para cuando se cerraba la ficha, la carga había
  /// traído los lugares de sesiones anteriores: el cierre del recorrido
  /// aparecía habiendo visitado uno solo.
  Future<void> get cargado => _cargado;

  @override
  Set<int> build() {
    _prefs = _abrir();
    _cargado = _cargar();
    return const {};
  }

  Future<SharedPreferences?> _abrir() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (error) {
      // Perder el progreso no debe impedir usar la aplicación.
      debugPrint('No se pudo abrir el almacén del progreso: $error');
      return null;
    }
  }

  Future<void> _cargar() async {
    final prefs = await _prefs;
    if (prefs == null) return;
    try {
      final guardados = prefs.getStringList(_clave) ?? const [];
      final ids = guardados.map(int.tryParse).nonNulls.toSet();
      // Unión y no asignación: entre el arranque y esta línea el usuario pudo
      // marcar un lugar, y asignar lo borraría.
      if (ids.isNotEmpty) state = {...state, ...ids};
    } catch (error) {
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
    // Esperar el almacén en vez de saltarse la escritura si todavía no está:
    // antes, las visitas de los primeros segundos se perdían en silencio.
    final prefs = await _prefs;
    if (prefs == null) return;
    try {
      await prefs.setStringList(
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

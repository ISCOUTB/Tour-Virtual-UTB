import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../configuracion_tour.dart';
import 'correcciones.dart';
import 'grafo_campus.dart';

/// Si esta compilación es para probar la guía en el campus
/// (`--dart-define=CAMPO=true`). El visitante nunca la tiene.
final modoCampoProvider = Provider<bool>(
  (ref) => ref.watch(configuracionTourProvider).modoCampo,
);

/// Ensayo del modo campo: la guía camina sola por la ruta con una posición
/// simulada, para practicar las correcciones lejos del campus. Solo en
/// memoria: al cerrar la app vuelve el GPS.
final ensayoCampoProvider = StateProvider<bool>((ref) => false);

/// Las correcciones de la guía guardadas en este teléfono.
class CorreccionesNotifier extends Notifier<CorreccionesCampo> {
  static const _clave = 'tourVirtual.campo.correcciones.v1';
  static const _claveAutor = 'tourVirtual.campo.autor';

  Future<SharedPreferences?>? _prefs;

  /// Quién corrige: va en cada corrección para saber a quién preguntar.
  String? autor;

  @override
  CorreccionesCampo build() {
    if (!ref.watch(modoCampoProvider)) return const CorreccionesCampo();
    _prefs = _abrir();
    _cargar();
    // Lo practicado en un ensayo no se guarda: al apagarlo vuelve lo de
    // antes. Si no, el lunes se mezclaban las pruebas de la casa.
    ref.listen(ensayoCampoProvider, (antes, ahora) {
      if (antes == true && !ahora) {
        state = const CorreccionesCampo();
        _cargar();
      }
    });
    return const CorreccionesCampo();
  }

  Future<SharedPreferences?> _abrir() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (error) {
      debugPrint('Sin almacén para las correcciones: $error');
      return null;
    }
  }

  Future<void> _cargar() async {
    final prefs = await _prefs;
    if (prefs == null) return;
    autor = nuevoAutor(prefs.getString(_claveAutor));
    final texto = prefs.getString(_clave);
    if (texto == null) return;
    final guardadas = CorreccionesCampo.importar(texto);
    // Unión: alguien pudo corregir algo en el segundo que tardó la carga.
    if (guardadas != null) state = guardadas.unir(state);
  }

  /// En un ensayo las correcciones se aplican, pero no se guardan.
  bool get enEnsayo => ref.read(ensayoCampoProvider);

  Future<void> _guardar() async {
    if (enEnsayo) return;
    // El texto se toma ahora: mientras se espera el almacén puede llegar otra
    // corrección (por ejemplo, ya en un ensayo) que no debe guardarse.
    final texto = state.exportar();
    final prefs = await _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_clave, texto);
    } catch (error) {
      debugPrint('No se guardaron las correcciones: $error');
    }
  }

  Future<void> cambiarAutor(String nombre) async {
    autor = nuevoAutor(nombre);
    final prefs = await _prefs;
    if (prefs == null) return;
    if (autor == null) {
      await prefs.remove(_claveAutor);
    } else {
      await prefs.setString(_claveAutor, autor!);
    }
  }

  void agregar(Correccion c) {
    if (!ref.read(modoCampoProvider)) return;
    state = state.agregar(c);
    _guardar();
  }

  void anular(String id) {
    state = state.anular(id);
    _guardar();
  }

  /// Une las de otro teléfono. Devuelve cuántas eran nuevas.
  int importar(CorreccionesCampo otras) {
    final antes = state.lista.length + state.anuladas.length;
    state = state.unir(otras);
    _guardar();
    return state.lista.length + state.anuladas.length - antes;
  }
}

final correccionesCampoProvider =
    NotifierProvider<CorreccionesNotifier, CorreccionesCampo>(
      CorreccionesNotifier.new,
    );

/// El grafo con que guía la app: el empaquetado y, en el modo campo, con las
/// correcciones hechas en el campus encima.
final grafoGuiaProvider = Provider<AsyncValue<GrafoCampus>>((ref) {
  final base = ref.watch(grafoCampusProvider);
  if (!ref.watch(modoCampoProvider)) return base;
  final correcciones = ref.watch(correccionesCampoProvider);
  return base.whenData(correcciones.aplicar);
});

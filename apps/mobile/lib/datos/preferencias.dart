import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../nucleo/idiomas.dart';

/// Aumento del texto que el módulo aplica sobre el del sistema.
///
/// Mucha gente no sabe que el teléfono tiene su propio ajuste, o lo comparte
/// con alguien más. El aumento se multiplica con el del sistema y el total se
/// limita al 200 %, la escala que el módulo garantiza sin cortar contenido
/// (WCAG 1.4.4); si el sistema ya pide más, manda el sistema.
enum TamanoTexto {
  normal(1),
  grande(1.25),
  muyGrande(1.5);

  const TamanoTexto(this.factor);

  final double factor;
}

/// Ajustes de idioma y accesibilidad del módulo.
///
/// Se suman a los del sistema, nunca los anulan: con «quitar animaciones» o
/// «aumentar contraste» activos en el teléfono, apagarlos aquí no los
/// desactiva.
@immutable
class Preferencias {
  const Preferencias({
    this.idioma,
    this.tamanoTexto = TamanoTexto.normal,
    this.altoContraste = false,
    this.reducirMovimiento = false,
    this.movimientoTelefono = true,
    this.subtitulos = true,
  });

  /// Nulo: el idioma del teléfono.
  final Locale? idioma;
  final TamanoTexto tamanoTexto;
  final bool altoContraste;
  final bool reducirMovimiento;

  /// Si el visor 360 sigue al giroscopio. Desactivable por WCAG 2.5.4: quien
  /// no puede sostener el teléfono quieto ve la escena moverse sola.
  final bool movimientoTelefono;

  /// Subtítulos del audio narrado mientras suena.
  final bool subtitulos;

  Preferencias copyWith({
    Locale? Function()? idioma,
    TamanoTexto? tamanoTexto,
    bool? altoContraste,
    bool? reducirMovimiento,
    bool? movimientoTelefono,
    bool? subtitulos,
  }) => Preferencias(
    idioma: idioma == null ? this.idioma : idioma(),
    tamanoTexto: tamanoTexto ?? this.tamanoTexto,
    altoContraste: altoContraste ?? this.altoContraste,
    reducirMovimiento: reducirMovimiento ?? this.reducirMovimiento,
    movimientoTelefono: movimientoTelefono ?? this.movimientoTelefono,
    subtitulos: subtitulos ?? this.subtitulos,
  );

  @override
  bool operator ==(Object other) =>
      other is Preferencias &&
      other.idioma == idioma &&
      other.tamanoTexto == tamanoTexto &&
      other.altoContraste == altoContraste &&
      other.reducirMovimiento == reducirMovimiento &&
      other.movimientoTelefono == movimientoTelefono &&
      other.subtitulos == subtitulos;

  @override
  int get hashCode => Object.hash(
    idioma,
    tamanoTexto,
    altoContraste,
    reducirMovimiento,
    movimientoTelefono,
    subtitulos,
  );
}

abstract final class _Claves {
  static const idioma = 'pref.idioma';
  static const tamanoTexto = 'pref.tamanoTexto';
  static const altoContraste = 'pref.altoContraste';
  static const reducirMovimiento = 'pref.reducirMovimiento';
  static const movimientoTelefono = 'pref.movimientoTelefono';
  static const subtitulos = 'pref.subtitulos';
}

/// Lee las preferencias guardadas. Se llama antes de `runApp` para que la
/// primera pantalla ya salga en el idioma elegido y no cambie a mitad del
/// arranque.
Future<Preferencias> cargarPreferencias() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final idioma = prefs.getString(_Claves.idioma);
    final tamano = prefs.getString(_Claves.tamanoTexto);
    return Preferencias(
      idioma: idioma == null ? null : _localeDe(idioma),
      tamanoTexto:
          TamanoTexto.values.where((t) => t.name == tamano).firstOrNull ??
          TamanoTexto.normal,
      altoContraste: prefs.getBool(_Claves.altoContraste) ?? false,
      reducirMovimiento: prefs.getBool(_Claves.reducirMovimiento) ?? false,
      movimientoTelefono: prefs.getBool(_Claves.movimientoTelefono) ?? true,
      subtitulos: prefs.getBool(_Claves.subtitulos) ?? true,
    );
  } catch (error) {
    // Perder los ajustes no debe impedir usar la aplicación.
    debugPrint('No se pudieron leer las preferencias: $error');
    return const Preferencias();
  }
}

/// Solo acepta idiomas que siguen traducidos: uno retirado de la app no puede
/// dejar la interfaz en un idioma sin textos.
Locale? _localeDe(String etiqueta) {
  final partes = etiqueta.split('-');
  final locale = Locale(partes.first, partes.length > 1 ? partes[1] : null);
  return idiomasUi.any((i) => i.locale == locale) ? locale : null;
}

/// Preferencias leídas al arrancar. `main` lo sobrescribe; sin eso (pruebas,
/// o si el almacén falla) se parte de los valores por defecto.
final preferenciasInicialesProvider = Provider<Preferencias>(
  (ref) => const Preferencias(),
);

class AjustesPreferencias extends Notifier<Preferencias> {
  @override
  Preferencias build() => ref.watch(preferenciasInicialesProvider);

  void cambiarIdioma(Locale? idioma) {
    state = state.copyWith(idioma: () => idioma);
    _guardar(
      (p) => idioma == null
          ? p.remove(_Claves.idioma)
          : p.setString(_Claves.idioma, idioma.toLanguageTag()),
    );
  }

  void cambiarTamanoTexto(TamanoTexto tamano) {
    state = state.copyWith(tamanoTexto: tamano);
    _guardar((p) => p.setString(_Claves.tamanoTexto, tamano.name));
  }

  void cambiarAltoContraste(bool valor) {
    state = state.copyWith(altoContraste: valor);
    _guardar((p) => p.setBool(_Claves.altoContraste, valor));
  }

  void cambiarReducirMovimiento(bool valor) {
    state = state.copyWith(reducirMovimiento: valor);
    _guardar((p) => p.setBool(_Claves.reducirMovimiento, valor));
  }

  void cambiarMovimientoTelefono(bool valor) {
    state = state.copyWith(movimientoTelefono: valor);
    _guardar((p) => p.setBool(_Claves.movimientoTelefono, valor));
  }

  void cambiarSubtitulos(bool valor) {
    state = state.copyWith(subtitulos: valor);
    _guardar((p) => p.setBool(_Claves.subtitulos, valor));
  }

  Future<void> _guardar(
    Future<bool> Function(SharedPreferences prefs) escribir,
  ) async {
    try {
      await escribir(await SharedPreferences.getInstance());
    } catch (error) {
      debugPrint('No se pudo guardar la preferencia: $error');
    }
  }
}

final preferenciasProvider =
    NotifierProvider<AjustesPreferencias, Preferencias>(
      AjustesPreferencias.new,
    );

/// Idiomas del teléfono, en orden de preferencia. La app lo invalida cuando
/// el usuario los cambia en el sistema.
final idiomasDelTelefonoProvider = Provider<List<Locale>>(
  (ref) => WidgetsBinding.instance.platformDispatcher.locales,
);

/// Idioma efectivo de la interfaz: el elegido en el módulo o, si no hay, el
/// mejor de los del teléfono.
final idiomaProvider = Provider<Locale>((ref) {
  final elegido = ref.watch(preferenciasProvider.select((p) => p.idioma));
  return elegido ?? resolverIdioma(ref.watch(idiomasDelTelefonoProvider));
});

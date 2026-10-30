import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Medios empaquetados dentro de la app, para un APK de demostración que
/// funcione sin red ni servidor (`--dart-define=MEDIOS_DEMO=empaquetados`).
///
/// Sus URL llevan el esquema `asset:///` seguido de la clave del asset, el
/// mismo que entiende `just_audio`, así que el audio no necesita nada más.
/// Las imágenes y los subtítulos sí: se resuelven con estas funciones.
abstract final class FuenteMedio {
  /// Valor de `MEDIOS_DEMO` que activa los medios empaquetados.
  static const empaquetados = 'empaquetados';

  /// Carpeta de los medios empaquetados. Sus subcarpetas (`panoramas`,
  /// `audios`, `subtitulos`) están declaradas en pubspec.yaml y vacías en el
  /// repositorio: el material es institucional y lo copia
  /// `scripts/preparar_apk_demo.py` antes de compilar.
  static const carpeta = 'packages/tour_virtual/assets/demo';

  static const _esquema = 'asset:///';

  static bool esEmpaquetado(String url) => url.startsWith(_esquema);

  static String claveDe(String url) => url.substring(_esquema.length);

  /// La imagen de un medio, venga de la red o de la app.
  static ImageProvider imagen(String url) =>
      esEmpaquetado(url) ? AssetImage(claveDe(url)) : NetworkImage(url);

  static Future<Set<String>>? _claves;

  /// Si el medio está empaquetado. Sustituye a la petición HEAD con que el
  /// demo comprueba qué narraciones hay en la carpeta servida.
  static Future<bool> existe(String url) async {
    final claves = await (_claves ??= AssetManifest.loadFromAssetBundle(
      rootBundle,
    ).then((manifiesto) => manifiesto.listAssets().toSet()));
    return claves.contains(claveDe(url));
  }
}

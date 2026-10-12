import 'package:flutter/foundation.dart';

abstract final class Configuracion {
  static const _puertoApiLocal = 5209;

  static String get _hostLocal {
    final esAndroidNativo =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return esAndroidNativo ? '10.0.2.2' : '127.0.0.1';
  }

  static String get apiBaseUrl {
    const definida = String.fromEnvironment('API_BASE_URL');
    if (definida.isNotEmpty) return definida.replaceFirst(RegExp(r'/$'), '');
    return 'http://$_hostLocal:$_puertoApiLocal';
  }

  static const int lugarPorDefecto = int.fromEnvironment(
    'LUGAR_ID',
    defaultValue: 1,
  );

  /// Trabajar el frontend sin backend:
  ///
  /// ```bash
  /// flutter run -d windows --dart-define=DATOS=demo
  /// ```
  ///
  /// Carga el contenido del seed de la API y el mapa empaquetado. Las
  /// panorámicas y el audio viven en S3; para verlos, ver [mediosDemo].
  static const datosDemo = String.fromEnvironment('DATOS') == 'demo';

  /// Carpeta servida por HTTP con las panorámicas y audios del seed, para ver
  /// el visor 360 en modo demo sin acceso a S3:
  ///
  /// ```bash
  /// flutter run -d windows --dart-define=DATOS=demo \
  ///   --dart-define=MEDIOS_DEMO=http://127.0.0.1:8765
  /// ```
  ///
  /// Dentro deben estar `panoramas/<slug>.jpg`, `panoramas/<slug>-baja.jpg` y
  /// `audios/<slug>.mp3`, las mismas claves que usa el seed de la API. Los
  /// genera `scripts/subir_medios.py` a partir del material institucional.
  static const mediosDemo = String.fromEnvironment('MEDIOS_DEMO');
}

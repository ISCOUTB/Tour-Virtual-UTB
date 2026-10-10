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
}

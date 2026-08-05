import 'package:flutter/foundation.dart';

/// Configuracion de entorno, inyectada en tiempo de compilacion.
///
/// Los valores de produccion se pasan con `--dart-define`; los de aqui son los
/// del stack local de Supabase y solo sirven para desarrollo:
///
/// ```bash
/// flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///             --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
/// ```
///
/// La clave publicable no es un secreto: viaja dentro del binario de cualquier
/// aplicacion Supabase y esta pensada para ser publica. Lo que protege los
/// datos es RLS, no el ocultamiento de esta clave.
abstract final class Configuracion {
  /// Puerto de la API local que levanta `supabase start`.
  static const _puertoLocal = 54321;

  /// Desde el emulador de Android, `localhost` es el propio emulador; el equipo
  /// anfitrion es 10.0.2.2.
  static String get _hostLocal {
    final esAndroidNativo =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return esAndroidNativo ? '10.0.2.2' : '127.0.0.1';
  }

  static String get supabaseUrl {
    const definida = String.fromEnvironment('SUPABASE_URL');
    if (definida.isNotEmpty) return definida;
    return 'http://$_hostLocal:$_puertoLocal';
  }

  /// Clave por defecto del stack local. Es identica en toda instalacion de
  /// Supabase CLI y no sirve contra ningun entorno real.
  static const _claveLocal =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9'
      '.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

  static String get supabaseClavePublicable {
    const definida = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    return definida.isNotEmpty ? definida : _claveLocal;
  }

  /// true cuando la app apunta al stack local en lugar de a un proyecto real.
  static bool get esEntornoLocal =>
      const String.fromEnvironment('SUPABASE_URL').isEmpty;

  /// Lugar que se muestra al abrir la app.
  ///
  /// El MVP contempla un unico campus. Cuando existan varias sedes, esto pasa a
  /// ser una seleccion del usuario.
  static const int lugarPorDefecto = int.fromEnvironment(
    'LUGAR_ID',
    defaultValue: 1,
  );
}

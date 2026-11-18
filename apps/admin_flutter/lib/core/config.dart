/// Configuración del panel. Los valores se pueden cambiar al ejecutar con
/// `--dart-define`, sin tocar el código. Ejemplos:
///
///   flutter run -d chrome                                   (datos de ejemplo)
///   flutter run -d chrome --dart-define=USE_MOCK=false      (backend real)
class AppConfig {
  const AppConfig._();

  /// Dirección del backend .NET. El panel de Next.js lo usa en
  /// http://localhost:5209 (ver next.config.ts).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5209',
  );

  /// true = datos de ejemplo en memoria (no necesita backend encendido).
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: true,
  );

  /// El backend ya acepta lat/lng, idioma, subtítulos y texto alternativo
  /// (tareas 1, 4 y 5 de docs/tareas-backend.md, en master desde el
  /// 12/11/2026). Se puede apagar con `--dart-define=BACKEND_CAMPOS_NUEVOS=false`
  /// para probar contra un backend viejo.
  static const bool backendCamposNuevos = bool.fromEnvironment(
    'BACKEND_CAMPOS_NUEVOS',
    defaultValue: true,
  );

  /// Lugar (campus) que administra el panel. El panel de Next.js usa el 1.
  static const int lugarId = int.fromEnvironment('LUGAR_ID', defaultValue: 1);

  /// Proyecto de Supabase del equipo (el mismo de services/api).
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qjnusmpwznaegeburldo.supabase.co',
  );

  /// Clave pública (publishable / anon) de Supabase. No es secreta, pero se
  /// pasa al ejecutar para no dejarla en el repo:
  ///   --dart-define=SUPABASE_ANON_KEY=sb_publishable_...
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Login real con Supabase: solo contra el backend real y con clave.
  static bool get loginReal => !useMockData && supabaseAnonKey.isNotEmpty;
}

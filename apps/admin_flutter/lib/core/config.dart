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

  /// El backend ya acepta lat/lng (y idioma, subtítulos y texto alternativo)
  /// al escribir. Mientras sea false, el panel los muestra pero no los edita
  /// contra la API real. Se activa con `--dart-define=BACKEND_CAMPOS_NUEVOS=true`
  /// cuando backend termine las tareas 1, 4 y 5 de docs/tareas-backend.md.
  static const bool backendCamposNuevos = bool.fromEnvironment(
    'BACKEND_CAMPOS_NUEVOS',
    defaultValue: false,
  );

  /// Lugar (campus) que administra el panel. El panel de Next.js usa el 1.
  static const int lugarId = int.fromEnvironment('LUGAR_ID', defaultValue: 1);
}

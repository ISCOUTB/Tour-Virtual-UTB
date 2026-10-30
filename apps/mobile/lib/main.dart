import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tour_virtual/tour_virtual.dart';

/// App de demostración: abre el módulo a pantalla completa, como lo haría la
/// UTB APP desde su menú. La configuración sale de `--dart-define`:
///
/// ```bash
/// flutter run                                          # API local
/// flutter run --dart-define=API_BASE_URL=https://...   # API en la nube
/// flutter run --dart-define=DATOS=demo                 # contenido local
/// ```
///
/// Ver `ConfiguracionTour.desdeEntorno` y docs/GUIA_DESARROLLO.md.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // De borde a borde, como la app UTB: la cabecera azul pasa por debajo de la
  // barra de estado.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(TourVirtual(configuracion: ConfiguracionTour.desdeEntorno()));
}

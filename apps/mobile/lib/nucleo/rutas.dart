import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../loading_screen.dart';
import '../main.dart';
import '../recorrido_screen.dart';

abstract final class Rutas {
  static const carga = '/';
  static const inicio = '/inicio';
  static const recorrido = '/recorrido';

  /// Enlace al recorrido de un lugar, opcionalmente entrando por una escena.
  static String haciaRecorrido(int lugarId, {int? escenaId}) {
    final base = '$recorrido/$lugarId';
    return escenaId == null ? base : '$base?escena=$escenaId';
  }
}

/// Pantalla por la que arranca la aplicacion.
///
/// Normalmente es la de carga. Se puede cambiar en tiempo de compilacion para
/// abrir una pantalla concreta sin navegar hasta ella, que es lo que permite
/// inspeccionar el visor 360 sin depender de clics sinteticos:
///
/// ```bash
/// flutter run -d windows --dart-define=RUTA_INICIAL=/recorrido/1
/// ```
const _rutaInicialConfigurada = String.fromEnvironment('RUTA_INICIAL');

/// Router de la aplicacion.
///
/// Es una fabrica y no una constante para que cada prueba pueda partir de un
/// historial de navegacion limpio.
GoRouter crearEnrutador({String? ubicacionInicial}) => GoRouter(
  initialLocation:
      ubicacionInicial ??
      (_rutaInicialConfigurada.isEmpty ? Rutas.carga : _rutaInicialConfigurada),
  routes: [
    GoRoute(
      path: Rutas.carga,
      builder: (context, state) => const LoadingScreen(),
    ),
    GoRoute(
      path: Rutas.inicio,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '${Rutas.recorrido}/:lugarId',
      builder: (context, state) {
        // Un identificador ilegible en el enlace no debe tumbar la app: se cae
        // al lugar por defecto.
        final lugarId = int.tryParse(state.pathParameters['lugarId'] ?? '');
        final escenaId = int.tryParse(
          state.uri.queryParameters['escena'] ?? '',
        );

        if (lugarId == null) {
          return const _RutaInvalida();
        }

        return RecorridoScreen(lugarId: lugarId, escenaInicialId: escenaId);
      },
    ),
  ],
);

class _RutaInvalida extends StatelessWidget {
  const _RutaInvalida();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text('Ese enlace no es valido.', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

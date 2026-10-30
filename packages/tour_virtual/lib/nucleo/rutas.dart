import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/textos.dart';
import '../loading_screen.dart';
import '../recorrido_screen.dart';
import '../ui/comunes/transiciones.dart';
import '../ui/inicio/pantalla_tour.dart';
import 'tema.dart';

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
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        transitionDuration: const Duration(milliseconds: 900),
        transitionsBuilder: revelacionCircular,
        child: const HomeScreen(),
      ),
    ),
    GoRoute(
      path: '${Rutas.recorrido}/:lugarId',
      pageBuilder: (context, state) {
        // Un identificador ilegible en el enlace no debe tumbar la app.
        final lugarId = int.tryParse(state.pathParameters['lugarId'] ?? '');
        final escenaId = int.tryParse(
          state.uri.queryParameters['escena'] ?? '',
        );

        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 560),
          reverseTransitionDuration: const Duration(milliseconds: 360),
          transitionsBuilder: entradaInmersiva,
          child: lugarId == null
              ? const _RutaInvalida()
              : RecorridoScreen(lugarId: lugarId, escenaInicialId: escenaId),
        );
      },
    ),
  ],
);

class _RutaInvalida extends StatelessWidget {
  const _RutaInvalida();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: ColoresUtb.fondo),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            Textos.of(context).enlaceInvalido,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

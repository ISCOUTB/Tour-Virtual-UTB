import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tour_virtual/configuracion_tour.dart';
import 'package:tour_virtual/tour_virtual.dart';

/// El módulo como lo abriría la UTB APP: un `TourVirtual` empujado sobre el
/// navegador de una app anfitriona que tiene su propio Riverpod.
///
/// Las animaciones del módulo se repiten sin fin, así que se avanza el reloj a
/// mano en lugar de esperar a que todo se asiente (ver widget_test.dart).
Future<void> avanzar(WidgetTester tester, [int pasos = 60]) async {
  for (var i = 0; i < pasos; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget anfitriona(ConfiguracionTour Function(VoidCallback salir) crear) {
    return ProviderScope(
      // La anfitriona tiene su propia configuración del tour, que el módulo no
      // debe heredar: si la heredara, iría a la red y las pruebas no tienen.
      overrides: [
        configuracionTourProvider.overrideWithValue(
          const ConfiguracionTour(
            fuente: ContenidoRemoto(urlApi: 'http://anfitriona.invalid'),
          ),
        ),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TourVirtual(
                      configuracion: crear(() => Navigator.of(context).pop()),
                    ),
                  ),
                ),
                child: const Text('Abrir tour'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('se abre dentro de otra app con su propia configuración', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      anfitriona((_) => const ConfiguracionTour(fuente: ContenidoLocal())),
    );
    await tester.tap(find.text('Abrir tour'));
    await avanzar(tester);

    // Contenido local: los lugares están sin red ni servidor.
    expect(find.text('Biblioteca'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await avanzar(tester, 10);
  });

  testWidgets('salir desde la pantalla principal lo resuelve la anfitriona', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      anfitriona(
        (salir) =>
            ConfiguracionTour(fuente: const ContenidoLocal(), alSalir: salir),
      ),
    );
    await tester.tap(find.text('Abrir tour'));
    await avanzar(tester);

    // La pantalla principal del módulo no tiene nada debajo en su propio
    // navegador; la flecha aparece porque la anfitriona sabe cerrarlo.
    await tester.tap(find.byTooltip('Back'));
    await avanzar(tester, 10);

    expect(find.byType(TourVirtual), findsNothing);
    expect(find.text('Abrir tour'), findsOneWidget);
  });
}

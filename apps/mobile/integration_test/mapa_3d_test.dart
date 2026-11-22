import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tour_virtual/app_tour.dart';
import 'package:tour_virtual/configuracion_tour.dart';
import 'package:tour_virtual/datos/preferencias.dart';
import 'package:tour_virtual/l10n/textos.dart';
import 'package:tour_virtual/nucleo/tema.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('modelo local, controles, ficha y regreso al plano', (
    tester,
  ) async {
    // Preferencias en memoria: esta comprobación no borra ni modifica las
    // preferencias y las visitas guardadas por la persona en su teléfono.
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_aplicacion(1));
    await _esperar(
      tester,
      () => find.byIcon(Icons.map_rounded).evaluate().isNotEmpty,
    );
    await tester.tap(find.byIcon(Icons.map_rounded));
    await _pausa(tester);
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    await binding.takeScreenshot('phone-mapa-2d');
    expect(find.text(_creditoOsm), findsOneWidget);

    await tester.tap(find.byTooltip('Ver mapa en 3D'));
    await _esperar(
      tester,
      () => find.byTooltip('Girar a la derecha').evaluate().isNotEmpty,
    );
    await _pausa(tester);
    final web = tester
        .widget<WebViewWidget>(find.byType(WebViewWidget))
        .platform
        .params
        .controller;
    expect(
      await web.runJavaScriptReturningResult(
        "document.querySelector('model-viewer').loaded",
      ),
      true,
    );
    final pines = await web.runJavaScriptReturningResult(
      "document.querySelectorAll('[data-tour-poi]').length",
    );
    expect(_numero(pines), greaterThanOrEqualTo(5));
    await _comprobarParadas(web.runJavaScriptReturningResult);
    // Cada vista acredita lo que muestra: la maqueta no es de OSM.
    expect(find.text(_creditoOsm), findsNothing);
    expect(find.text('Modelo 3D: ElMapita UTB'), findsOneWidget);
    await binding.takeScreenshot('phone-mapa-3d');

    final radio = await web.runJavaScriptReturningResult(
      "document.querySelector('model-viewer').getCameraOrbit().radius",
    );
    await tester.tap(find.byTooltip('Acercar'));
    await _pausa(tester);
    final cerca = await web.runJavaScriptReturningResult(
      "document.querySelector('model-viewer').getCameraOrbit().radius",
    );
    expect(_numero(cerca), lessThan(_numero(radio)));
    const theta =
        "document.querySelector('model-viewer').getCameraOrbit().theta";
    final antes = _numero(await web.runJavaScriptReturningResult(theta));
    await tester.tap(find.byTooltip('Girar a la derecha'));
    await _pausa(tester);
    final girado = _numero(await web.runJavaScriptReturningResult(theta));
    expect((girado - antes) * 180 / pi, closeTo(45, 0.5));
    await _comprobarParadas(web.runJavaScriptReturningResult);
    await binding.takeScreenshot('phone-mapa-3d-giro');
    await tester.tap(find.byTooltip('Orientar al norte'));
    await _pausa(tester);
    expect(
      _numero(await web.runJavaScriptReturningResult(theta)),
      closeTo(antes, 0.01),
    );

    await web.runJavaScript(
      "document.querySelector('[data-tour-poi=\"1\"]').click()",
    );
    await _esperar(
      tester,
      () => find.byType(BottomSheet).evaluate().isNotEmpty,
    );
    await _pausa(tester);
    await binding.takeScreenshot('phone-mapa-3d-ficha');
    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await _pausa(tester);
    await tester.tap(find.byTooltip('Volver al mapa 2D'));
    await _pausa(tester);
    expect(find.byTooltip('Ver mapa en 3D'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text(_creditoOsm), findsOneWidget);
    await binding.takeScreenshot('phone-mapa-2d-regreso');

    // Arranque con la escala ya activa, como al abrir el tour con el texto
    // grande del sistema. La cabecera no hereda el scroll de la escala anterior.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(_aplicacion(2));
    await _esperar(
      tester,
      () => find.byIcon(Icons.map_rounded).evaluate().isNotEmpty,
    );
    await tester.tap(find.byIcon(Icons.map_rounded));
    await _pausa(tester);
    await tester.tap(find.byTooltip('Ver mapa en 3D'));
    await _esperar(
      tester,
      () => find.byTooltip('Girar a la derecha').evaluate().isNotEmpty,
    );
    await _pausa(tester);
    final webGrande = tester
        .widget<WebViewWidget>(find.byType(WebViewWidget))
        .platform
        .params
        .controller;
    await _comprobarParadas(webGrande.runJavaScriptReturningResult);
    await binding.takeScreenshot('phone-mapa-3d-texto-grande');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}

const _creditoOsm = '© colaboradores de OpenStreetMap';

Future<void> _comprobarParadas(
  Future<Object> Function(String) consultar,
) async {
  expect(
    await consultar('''
(() => {
  const pines = [...document.querySelectorAll('.parada')];
  const cajas = pines.map(p => p.getBoundingClientRect());
  return cajas.length === 5 && cajas.every((a, i) =>
    a.width >= 48 && a.height >= 48 && cajas.slice(i + 1).every(b =>
      a.right <= b.left || b.right <= a.left || a.bottom <= b.top || b.bottom <= a.top));
})()
'''),
    true,
    reason:
        'Las cinco paradas deben tener objetivos separados de al menos 48 px',
  );
}

double _numero(Object valor) =>
    valor is num ? valor.toDouble() : double.parse('$valor');

Future<void> _pausa(WidgetTester tester) async {
  // El visor nativo y las transiciones encadenadas necesitan cuadros reales
  // durante la espera; un solo salto captura el inicio del siguiente fundido.
  for (var cuadro = 0; cuadro < 15; cuadro++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _esperar(WidgetTester tester, bool Function() condicion) async {
  final limite = DateTime.now().add(const Duration(seconds: 40));
  while (!condicion() && DateTime.now().isBefore(limite)) {
    await tester.pump(const Duration(milliseconds: 150));
  }
  expect(
    condicion(),
    isTrue,
    reason: 'La pantalla no llegó al estado esperado',
  );
}

Widget _aplicacion(double escala) => ProviderScope(
  overrides: [
    configuracionTourProvider.overrideWithValue(
      const ConfiguracionTour(fuente: ContenidoLocal(medios: 'empaquetados')),
    ),
    preferenciasInicialesProvider.overrideWithValue(
      const Preferencias(idioma: Locale('es'), analitica: false),
    ),
  ],
  child: _AppCaptura(escala: escala),
);

class _AppCaptura extends StatelessWidget {
  const _AppCaptura({required this.escala});
  final double escala;

  @override
  Widget build(BuildContext context) => MaterialApp(
    locale: const Locale('es'),
    supportedLocales: Textos.supportedLocales,
    localizationsDelegates: Textos.localizationsDelegates,
    theme: temaUtb(altoContraste: false),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(escala)),
      child: child!,
    ),
    home: const HomeScreen(),
  );
}

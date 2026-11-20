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
    await tester.tap(find.byTooltip('Girar a la derecha'));
    await _pausa(tester);
    await binding.takeScreenshot('phone-mapa-3d-giro');

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
    await binding.takeScreenshot('phone-mapa-2d-regreso');

    await tester.tap(find.byTooltip('Ver mapa en 3D'));
    await _pausa(tester);
    await tester.pumpWidget(_aplicacion(2));
    await _pausa(tester);
    await binding.takeScreenshot('phone-mapa-3d-texto-grande');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}

double _numero(Object valor) =>
    valor is num ? valor.toDouble() : double.parse('$valor');

Future<void> _pausa(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
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

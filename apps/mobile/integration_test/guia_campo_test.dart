import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tour_virtual/configuracion_tour.dart';
import 'package:tour_virtual/datos/preferencias.dart';
import 'package:tour_virtual/l10n/textos.dart';
import 'package:tour_virtual/navegacion/correcciones.dart';
import 'package:tour_virtual/navegacion/grafo_campus.dart';
import 'package:tour_virtual/navegacion/modo_campo.dart';
import 'package:tour_virtual/navegacion/sensores.dart';
import 'package:tour_virtual/nucleo/tema.dart';
import 'package:tour_virtual/ui/navegacion/pantalla_navegacion.dart';

/// La guía en modo campo en un teléfono real: brújula, cámara y GPS del
/// sistema reales, salvo la posición, que es la del ensayo (camina sola por
/// la ruta) para poder probarla lejos del campus.
///
/// ```sh
/// cd apps/mobile
/// flutter drive --driver=test_driver/mapa_3d.dart \
///   --target=integration_test/guia_campo_test.dart -d <serial>
/// ```
///
/// Antes, con el teléfono desbloqueado, dar permiso de cámara y ubicación
/// (`adb shell pm grant co.edu.utb.tour android.permission.CAMERA`). Las
/// capturas quedan en `.impeccable/review/`; las preferencias de la prueba
/// viven en memoria y no tocan las del teléfono. Después hay que reinstalar el
/// APK normal: el comando instala una app de comprobación.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('modo campo con los sensores del teléfono', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final grafo = GrafoCampus.desdeJson(await _leerGrafo());

    // 1. La brújula real, quieta sobre la mesa: intensidad y estabilidad.
    final lecturas = <LecturaRumbo>[];
    final sub = RumboSensores(
      declinacion: grafo.declinacion,
      campoEsperado: grafo.campoMagnetico,
    ).lecturas().listen(lecturas.add);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 4)),
    );
    await sub.cancel();
    expect(lecturas, isNotEmpty, reason: 'La brújula no dio lecturas');
    final intensidades = [for (final l in lecturas) l.intensidad!];
    final media = intensidades.reduce((a, b) => a + b) / intensidades.length;
    final rumbos = [
      for (final l in lecturas.skip(lecturas.length ~/ 2)) l.grados,
    ];
    final dispersion = _dispersionAngular(rumbos);
    // ignore: avoid_print
    print(
      'BRÚJULA: ${lecturas.length} lecturas, campo ${media.toStringAsFixed(1)} '
      'µT (esperado ${grafo.campoMagnetico}), interferida en '
      '${lecturas.where((l) => l.descalibrada).length}, rumbo '
      '${rumbos.last.toStringAsFixed(0)}° ±${dispersion.toStringAsFixed(1)}°',
    );
    expect(dispersion, lessThan(5), reason: 'Quieta, la flecha no debe bailar');

    // 2. La guía en ensayo hacia la Biblioteca.
    await tester.pumpWidget(_app());
    await _esperar(tester, () => _hay('Permitir ubicación'));
    await tester.tap(find.text('Permitir ubicación'));
    await _esperar(tester, () => _hay('Faltan', contiene: true));
    await binding.convertFlutterSurfaceToImage();
    await _pausa(tester);
    expect(find.textContaining('ENSAYO'), findsOneWidget);
    await binding.takeScreenshot('campo-1-guia');

    // 3. La cámara real con la flecha.
    await tester.tap(find.text('Cámara'));
    await _pausa(tester, segundos: 3);
    await binding.takeScreenshot('campo-2-camara');
    await tester.tap(find.text('Plano'));
    await _pausa(tester);

    // 4. «¿Qué está mal?».
    await _abrir(tester);
    await binding.takeScreenshot('campo-3-que-esta-mal');

    // 5. Por aquí no se pasa → se aplica, se ve en naranja, se deshace.
    await tester.tap(find.text('Por aquí no se pasa'));
    await _esperar(tester, () => _hay('cerrado', contiene: true));
    await _pausa(tester, segundos: 1);
    await binding.takeScreenshot('campo-4-tramo-cerrado');
    await tester.tap(find.text('Deshacer'));
    await _pausa(tester);

    // 6. La flecha apunta mal → panel abajo → Listo → Deshacer.
    await _abrir(tester);
    await tester.tap(find.text('La flecha apunta mal'));
    await _esperar(tester, () => _hay('Apunta hacia donde sigue el camino'));
    await _pausa(tester, segundos: 1);
    await binding.takeScreenshot('campo-5-flecha');
    await tester.tap(find.text('Listo'));
    // Con la brújula interferida (junto al computador) no calibra: lo dice.
    await _esperar(
      tester,
      () =>
          _hay('Flecha', contiene: true) ||
          _hay('lo normal es 33', contiene: true),
    );
    await _pausa(tester, segundos: 1);
    if (_hay('Deshacer')) await tester.tap(find.text('Deshacer'));
    await _pausa(tester, segundos: 6);

    // 7. Hay un camino mejor → camina unos segundos → Listo.
    await _abrir(tester);
    await tester.tap(find.text('Hay un camino mejor'));
    await _pausa(tester, segundos: 6);
    expect(find.textContaining('Grabando:'), findsOneWidget);
    await binding.takeScreenshot('campo-6-grabando');
    await tester.tap(find.text('Listo'));
    await _pausa(tester);

    // 8. Llega, y en la puerta: «Estoy en la puerta».
    await _esperar(
      tester,
      () => _hay('Ver la ficha'),
      limite: const Duration(seconds: 90),
    );
    await _pausa(tester);
    await binding.takeScreenshot('campo-7-llegada');
    await _abrir(tester);
    await tester.tap(find.text('Estoy en la puerta'));
    await _pausa(tester, segundos: 12);
    await binding.takeScreenshot('campo-8-puerta');

    // 9. Lo hecho viaja como texto a otro teléfono.
    final contenedor = ProviderScope.containerOf(
      tester.element(find.byType(PantallaNavegacion)),
    );
    final hechas = contenedor.read(correccionesCampoProvider);
    final copia = CorreccionesCampo.importar(hechas.exportar());
    expect(copia, isNotNull);
    expect(copia!.vigentes.map((c) => c.id), hechas.vigentes.map((c) => c.id));
    // ignore: avoid_print
    print(
      'CORRECCIONES: ${[for (final c in hechas.vigentes) c.tipo].join(', ')}',
    );
    expect(hechas.vigentes.whereType<CorreccionPrueba>(), hasLength(1));
    expect(hechas.vigentes.whereType<CorreccionCamino>(), hasLength(1));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pausa(tester, segundos: 7);
  });
}

Future<Map<String, dynamic>> _leerGrafo() async {
  final datos = await rootBundle.load(GrafoCampus.archivo);
  return jsonDecode(
        utf8.decode(
          datos.buffer.asUint8List(datos.offsetInBytes, datos.lengthInBytes),
        ),
      )
      as Map<String, dynamic>;
}

Widget _app() => ProviderScope(
  overrides: [
    configuracionTourProvider.overrideWithValue(
      const ConfiguracionTour(
        fuente: ContenidoLocal(medios: 'empaquetados'),
        modoCampo: true,
      ),
    ),
    preferenciasInicialesProvider.overrideWithValue(
      const Preferencias(idioma: Locale('es'), analitica: false),
    ),
    ensayoCampoProvider.overrideWith((ref) => true),
    // Ensayo más rápido que una persona, para no esperar la ruta entera.
    fuenteUbicacionProvider.overrideWithValue(
      UbicacionSimulada(
        velocidad: 4,
        intervalo: const Duration(milliseconds: 500),
        precision: 4,
      ),
    ),
  ],
  child: MaterialApp(
    locale: const Locale('es'),
    supportedLocales: Textos.supportedLocales,
    localizationsDelegates: Textos.localizationsDelegates,
    theme: temaUtb(altoContraste: false),
    home: const PantallaNavegacion(poiId: 1),
  ),
);

bool _hay(String texto, {bool contiene = false}) =>
    (contiene ? find.textContaining(texto) : find.text(texto))
        .evaluate()
        .isNotEmpty;

Future<void> _abrir(WidgetTester tester) async {
  await tester.tap(find.text('Corregir'));
  await _esperar(tester, () => _hay('¿Qué está mal?'));
  // La hoja sube animada: tocar antes da fuera de la pantalla.
  await _pausa(tester, segundos: 1);
}

Future<void> _pausa(WidgetTester tester, {int segundos = 2}) async {
  for (var i = 0; i < segundos * 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _esperar(
  WidgetTester tester,
  bool Function() condicion, {
  Duration limite = const Duration(seconds: 30),
}) async {
  final fin = DateTime.now().add(limite);
  while (!condicion() && DateTime.now().isBefore(fin)) {
    await tester.pump(const Duration(milliseconds: 150));
  }
  expect(
    condicion(),
    isTrue,
    reason: 'La pantalla no llegó al estado esperado',
  );
}

/// Dispersión de unos rumbos en grados (desviación circular).
double _dispersionAngular(List<double> grados) {
  var s = 0.0, c = 0.0;
  for (final g in grados) {
    s += math.sin(g * math.pi / 180);
    c += math.cos(g * math.pi / 180);
  }
  final r = math.sqrt(s * s + c * c) / grados.length;
  return math.sqrt(-2 * math.log(r.clamp(1e-9, 1.0))) * 180 / math.pi;
}

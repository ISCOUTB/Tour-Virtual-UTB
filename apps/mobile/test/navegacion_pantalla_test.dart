import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tour_virtual/datos/modelos/modelos.dart';
import 'package:tour_virtual/datos/preferencias.dart';
import 'package:tour_virtual/datos/proveedores.dart';
import 'package:tour_virtual/datos/repositorio_contenido.dart';
import 'package:tour_virtual/datos/subtitulos.dart';
import 'package:tour_virtual/datos/analitica.dart';
import 'package:tour_virtual/l10n/textos.dart';
import 'package:tour_virtual/navegacion/seguimiento.dart';
import 'package:tour_virtual/navegacion/sensores.dart';
import 'package:tour_virtual/navegacion/voz_guia.dart';
import 'package:tour_virtual/nucleo/errores.dart';
import 'package:tour_virtual/nucleo/tema.dart';
import 'package:tour_virtual/ui/navegacion/pantalla_navegacion.dart';

/// Biblioteca (parada con entrada en el grafo) y un lugar que no es parada.
const pois = [
  Poi(
    id: 1,
    lugarId: 1,
    nombre: 'Biblioteca',
    lat: 10.3699965,
    lng: -75.4650668,
    escenaPrincipalId: 1,
  ),
];

class RepositorioFalso implements RepositorioContenido {
  @override
  String get idiomaContenido => 'es';
  @override
  Future<List<Poi>> obtenerPois(int lugarId) async => pois;
  @override
  Future<Recorrido> obtenerRecorrido(int lugarId) async =>
      const Recorrido(escenas: [], hotspotsPorEscena: {});
  @override
  Future<PoiDetalle> obtenerPoiDetalle(int poiId) async =>
      PoiDetalle(poi: pois.first);
  @override
  Future<Ruta?> obtenerRutaActual(int lugarId) async => null;
  @override
  Future<Subtitulos> obtenerSubtitulos(String url) async =>
      throw const FalloSinContenido();
  @override
  Future<bool> registrarEvento(EventoAnalitica evento) async => true;
}

/// Una ubicación a la que se le niega el permiso.
class UbicacionSinPermiso extends FuenteUbicacion {
  @override
  bool get simulada => false;
  @override
  Future<PermisoUbicacion> pedirPermiso() async => PermisoUbicacion.denegado;
  @override
  Stream<LecturaPosicion> lecturas() => const Stream.empty();
}

Future<void> montar(
  WidgetTester tester, {
  required FuenteUbicacion ubicacion,
  required VozGuia voz,
}) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferenciasInicialesProvider.overrideWithValue(
          const Preferencias(idioma: Locale('es')),
        ),
        repositorioContenidoProvider.overrideWithValue(RepositorioFalso()),
        fuenteUbicacionProvider.overrideWithValue(ubicacion),
        fuenteRumboProvider.overrideWith((ref, _) => RumboSimulado(90)),
        vozGuiaProvider.overrideWithValue(voz),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        supportedLocales: Textos.supportedLocales,
        localizationsDelegates: Textos.localizationsDelegates,
        theme: temaUtb(altoContraste: false),
        home: const PantallaNavegacion(poiId: 1),
      ),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('pide la ubicación explicando para qué, guía y llega', (
    WidgetTester tester,
  ) async {
    final voz = VozMuda();
    // Rápida, para no esperar el paso de una persona.
    final ubicacion = UbicacionSimulada(
      intervalo: const Duration(milliseconds: 200),
      velocidad: 25,
    );
    await montar(tester, ubicacion: ubicacion, voz: voz);

    expect(find.text('Te guío hasta Biblioteca'), findsOneWidget);
    expect(find.textContaining('no sale del teléfono'), findsOneWidget);

    await tester.tap(find.text('Permitir ubicación'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Guiando: indicación, distancia y los avisos honestos.
    expect(find.textContaining('Faltan'), findsOneWidget);
    expect(find.text('UBICACIÓN SIMULADA'), findsOneWidget);
    expect(
      find.text('LA ENTRADA DE ESTE LUGAR AÚN ES APROXIMADA.'),
      findsOneWidget,
    );
    expect(voz.dichos, isNotEmpty);

    // Camina hasta la puerta.
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.text('Llegaste a Biblioteca').evaluate().isNotEmpty) break;
    }
    expect(find.text('Llegaste a Biblioteca'), findsOneWidget);
    expect(find.text('Ver la ficha'), findsOneWidget);
    expect(voz.dichos.last, 'Llegaste a Biblioteca');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('sin permiso de ubicación ofrece el 360 (modo degradado)', (
    WidgetTester tester,
  ) async {
    await montar(tester, ubicacion: UbicacionSinPermiso(), voz: VozMuda());
    await tester.tap(find.text('Permitir ubicación'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('Sin permiso de ubicación'), findsOneWidget);
    expect(find.text('Ver en 360°'), findsOneWidget);
    // Se puede volver a pedir.
    expect(find.text('Permitir ubicación'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tour_virtual/app_tour.dart';
import 'package:tour_virtual/datos/georreferencia_3d.dart';
import 'package:tour_virtual/datos/preferencias.dart';
import 'package:tour_virtual/datos/proveedores.dart';
import 'package:tour_virtual/ui/inicio/mapa_3d.dart';

import 'widget_test.dart' as base;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('la conversión al modelo conserva las coordenadas al volver', () {
    for (final punto in [
      (10.3699965, -75.4650668),
      (10.37075, -75.46598),
      (10.3691852, -75.4655576),
    ]) {
      final modelo = Georreferencia3d.aModelo(punto.$1, punto.$2);
      final recuperado = Georreferencia3d.aGeografico(modelo.x, modelo.z);
      expect(recuperado.lat, closeTo(punto.$1, 1e-10));
      expect(recuperado.lng, closeTo(punto.$2, 1e-10));
    }
  });

  test('la Biblioteca queda en el modelo, con norte coherente con OSM', () {
    final p = Georreferencia3d.aModelo(10.3699965, -75.4650668);
    expect(p.x, inInclusiveRange(0, 100));
    expect(p.z, inInclusiveRange(-230, -100));
    expect(Georreferencia3d.norteCamara, inInclusiveRange(130, 145));
  });

  Future<void> montar(WidgetTester tester, Future<String> recursos) async {
    base.usarTelefono(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferenciasInicialesProvider.overrideWithValue(base.espanol),
          repositorioContenidoProvider.overrideWithValue(
            base.RepositorioFalso(pois: base.poisDePrueba),
          ),
          recursosMapa3dProvider.overrideWith((ref) => recursos),
        ],
        child: const base.AppDePrueba(hijo: HomeScreen(), sinAnimaciones: true),
      ),
    );
    await base.asentar(tester);
    await base.abrirMapa(tester);
  }

  testWidgets('si falta la maqueta conserva el plano y permite reintentar', (
    tester,
  ) async {
    final recurso = Completer<String>();
    await montar(tester, recurso.future);
    await tester.tap(find.byTooltip('Ver mapa en 3D'));
    await tester.pump();
    expect(find.byTooltip('Volver al mapa 2D'), findsOneWidget);
    recurso.completeError(StateError('Recurso ausente'));
    await base.asentar(tester);
    expect(find.byTooltip('Ver mapa en 3D'), findsOneWidget);
    expect(find.textContaining('No se pudo abrir el mapa 3D'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await base.drenarTemporizadores(tester);
  });

  testWidgets(
    'se puede cancelar el 3D mientras carga, sin perder la selección',
    (tester) async {
      final recurso = Completer<String>();
      await montar(tester, recurso.future);
      final paginas = tester
          .widget<PageView>(find.byType(PageView))
          .controller!;
      paginas.jumpToPage(1);
      await base.asentar(tester);
      expect(paginas.page, 1);
      await tester.tap(find.byTooltip('Ver mapa en 3D'));
      await tester.pump();
      await tester.tap(find.byTooltip('Volver al mapa 2D'));
      await base.asentar(tester);
      expect(find.byTooltip('Ver mapa en 3D'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(paginas.page, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await base.drenarTemporizadores(tester);
    },
  );
}

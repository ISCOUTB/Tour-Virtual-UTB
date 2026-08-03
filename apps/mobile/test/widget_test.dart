import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:utb_tour/loading_screen.dart';
import 'package:utb_tour/main.dart';

// Dos peculiaridades de estas pantallas condicionan como se prueban:
//
// 1. Ninguna se estabiliza nunca. LoadingScreen y los marcadores del mapa
//    ejecutan animaciones en bucle (`controller.repeat()`), asi que
//    `pumpAndSettle` se cuelga hasta agotar el tiempo limite. Hay que avanzar
//    el reloj con `pump(Duration)` explicito.
//
// 2. Quedan temporizadores vivos al final de cada prueba: la espera fija de
//    4 segundos de LoadingScreen y los retardos escalonados de flutter_animate
//    en cada marcador. Si no se drenan, el framework falla con
//    "A Timer is still pending even after the widget tree was disposed".
Future<void> drenarTemporizadores(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pump(const Duration(seconds: 1));
}

/// Busca la anotacion Semantics por su etiqueta.
///
/// Se inspecciona el widget Semantics directamente en lugar de usar
/// `find.bySemanticsLabel`, que exige tener el arbol de semantica construido y
/// depende de como se fusionen los nodos.
Finder etiquetaSemantica(String etiqueta) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == etiqueta,
);

void main() {
  testWidgets('arranca en la pantalla de carga', (WidgetTester tester) async {
    await tester.pumpWidget(const UtbVirtualApp());
    await tester.pump();

    expect(find.byType(LoadingScreen), findsOneWidget);
    expect(find.text('Universidad Tecnológica de Bolívar'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    await drenarTemporizadores(tester);
  });

  testWidgets('pasa al home cuando termina la pantalla de carga', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UtbVirtualApp());

    // LoadingScreen navega tras una espera fija de 4 segundos.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(LoadingScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);

    await drenarTemporizadores(tester);
  });

  testWidgets('el home expone las tres pestanas de navegacion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    // Las etiquetas de la barra inferior son imagenes, no widgets Text. Se
    // buscan por la anotacion Semantics, que es justamente lo que un lector de
    // pantalla anunciaria.
    expect(etiquetaSemantica('Explorar'), findsOneWidget);
    expect(etiquetaSemantica('Recorrido'), findsOneWidget);
    expect(etiquetaSemantica('Perfil'), findsOneWidget);

    await drenarTemporizadores(tester);
  });

  testWidgets('el home dibuja los cinco puntos de interes del MVP', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    expect(find.byIcon(Icons.location_on_rounded), findsNWidgets(5));

    await drenarTemporizadores(tester);
  });
}

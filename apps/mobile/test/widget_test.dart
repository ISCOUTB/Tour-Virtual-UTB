import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:utb_tour/datos/modelos/modelos.dart';
import 'package:utb_tour/datos/proveedores.dart';
import 'package:utb_tour/datos/repositorio_contenido.dart';
import 'package:utb_tour/loading_screen.dart';
import 'package:utb_tour/main.dart';
import 'package:utb_tour/nucleo/errores.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:utb_tour/datos/progreso.dart';
import 'package:utb_tour/nucleo/rutas.dart';
import 'package:utb_tour/ui/recorrido_completado.dart';
import 'package:utb_tour/recorrido_screen.dart';

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
//
//    Ademas, cada widget Animate programa un temporizador de duracion cero al
//    montarse, y esos widgets van apareciendo en frames sucesivos conforme se
//    resuelven los providers. Un `pump()` sin argumento no sirve para
//    vaciarlos: no avanza el reloj, asi que el temporizador de cero nunca
//    vence. Hay que avanzar un instante real, varias veces, para cubrir los
//    montajes encadenados.
Future<void> drenarTemporizadores(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

/// Busca la anotacion Semantics por su etiqueta.
///
/// Se inspecciona el widget Semantics directamente en lugar de usar
/// `find.bySemanticsLabel`, que exige tener el arbol de semantica construido y
/// depende de como se fusionen los nodos.
Finder etiquetaSemantica(String etiqueta) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == etiqueta,
);

/// Desplaza la ficha hasta que el objetivo entre en pantalla.
///
/// La ficha es un ListView, asi que solo construye lo visible: sus secciones
/// inferiores no existen en el arbol hasta que se desplaza hacia ellas.
Future<void> desplazarFichaHasta(WidgetTester tester, Finder objetivo) async {
  await tester.scrollUntilVisible(
    objetivo,
    180,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pump();
}

/// Repositorio de prueba: las pruebas no tocan la red ni Supabase.
class RepositorioFalso implements RepositorioContenido {
  RepositorioFalso({
    this.pois = const [],
    this.recorrido = const Recorrido(escenas: [], hotspotsPorEscena: {}),
    this.fallo,
  });

  final List<Poi> pois;
  final Recorrido recorrido;

  /// Cuando no es nulo, toda consulta falla con este error.
  final FalloApp? fallo;

  int llamadasAPois = 0;

  @override
  Future<List<Poi>> obtenerPois(int lugarId) async {
    llamadasAPois++;
    if (fallo != null) throw fallo!;
    return pois;
  }

  @override
  Future<Recorrido> obtenerRecorrido(int lugarId) async {
    if (fallo != null) throw fallo!;
    return recorrido;
  }

  @override
  Future<PoiDetalle> obtenerPoiDetalle(int poiId) async {
    if (fallo != null) throw fallo!;
    return PoiDetalle(poi: pois.firstWhere((p) => p.id == poiId));
  }

  @override
  Future<Ruta?> obtenerRutaActual(int lugarId) async {
    if (fallo != null) throw fallo!;
    return null;
  }
}

const poisDePrueba = [
  Poi(
    id: 1,
    lugarId: 1,
    nombre: 'Biblioteca',
    mapX: 0.63,
    mapY: 0.30,
    escenaPrincipalId: 3,
  ),
  Poi(id: 2, lugarId: 1, nombre: 'Zona de comidas', mapX: 0.42, mapY: 0.58),
  // Sin calibrar: no debe dibujarse en el mapa.
  Poi(id: 3, lugarId: 1, nombre: 'Murales UTB'),
];

Widget envolver(Widget hijo, {RepositorioContenido? repositorio}) {
  return ProviderScope(
    overrides: [
      if (repositorio != null)
        repositorioContenidoProvider.overrideWithValue(repositorio),
    ],
    child: MaterialApp(home: hijo),
  );
}

void main() {
  // El progreso se guarda en el dispositivo; sin esto el canal nativo no existe
  // en las pruebas y cada lectura cae al manejador de error.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('arranca en la pantalla de carga', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositorioContenidoProvider.overrideWithValue(RepositorioFalso()),
        ],
        child: UtbVirtualApp(enrutador: crearEnrutador()),
      ),
    );
    await tester.pump();

    expect(find.byType(LoadingScreen), findsOneWidget);
    expect(find.text('Universidad Tecnológica de Bolívar'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    await drenarTemporizadores(tester);
  });

  testWidgets('pasa al home cuando termina la pantalla de carga', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositorioContenidoProvider.overrideWithValue(
            RepositorioFalso(pois: poisDePrueba),
          ),
        ],
        child: UtbVirtualApp(enrutador: crearEnrutador()),
      ),
    );

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
    await tester.pumpWidget(
      envolver(const HomeScreen(), repositorio: RepositorioFalso()),
    );
    await tester.pump();

    // Las etiquetas de la barra inferior son imagenes, no widgets Text. Se
    // buscan por la anotacion Semantics, que es justamente lo que un lector de
    // pantalla anunciaria.
    expect(etiquetaSemantica('Explorar'), findsOneWidget);
    expect(etiquetaSemantica('Recorrido'), findsOneWidget);
    expect(etiquetaSemantica('Perfil'), findsOneWidget);

    await drenarTemporizadores(tester);
  });

  testWidgets('solo dibuja marcadores de los POI calibrados', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      envolver(
        const HomeScreen(),
        repositorio: RepositorioFalso(pois: poisDePrueba),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Tres POIs, pero solo dos traen map_x/map_y. El tercero se omite en lugar
    // de inventarle una posicion.
    //
    // Se comprueba por etiqueta y no contando iconos: cada marcador dibuja dos
    // glifos superpuestos para que el reborde blanco lo separe del fondo, asi
    // que contar iconos mide el estilo, no el comportamiento.
    expect(etiquetaSemantica('Biblioteca'), findsOneWidget);
    expect(etiquetaSemantica('Zona de comidas'), findsOneWidget);
    expect(etiquetaSemantica('Murales UTB'), findsNothing);

    await drenarTemporizadores(tester);
  });

  testWidgets('tocar un marcador abre la ficha del POI, no el visor 360', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      envolver(
        const HomeScreen(),
        repositorio: RepositorioFalso(pois: poisDePrueba),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(etiquetaSemantica('Biblioteca'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Antes se saltaba directo a descargar una panoramica a pantalla completa,
    // de modo que un POI sin panoramica no ofrecia nada.
    expect(find.byType(RecorridoScreen), findsNothing);
    expect(find.text('Biblioteca'), findsWidgets);

    await desplazarFichaHasta(tester, find.text('Ver en 360'));
    expect(find.text('Ver en 360'), findsOneWidget);

    await drenarTemporizadores(tester);
  });

  testWidgets('la ficha nombra cada recurso que falta en vez de callarlo', (
    WidgetTester tester,
  ) async {
    // RF-16, prioridad alta. Hoy es el caso corriente y no la excepcion:
    // ningun POI tiene multimedia cargada todavia.
    await tester.pumpWidget(
      envolver(
        const HomeScreen(),
        repositorio: RepositorioFalso(pois: poisDePrueba),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(etiquetaSemantica('Biblioteca'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('no hay descripción'), findsOneWidget);
    expect(find.textContaining('no tiene fotos'), findsOneWidget);

    await desplazarFichaHasta(tester, find.textContaining('no tiene video'));
    expect(find.textContaining('no tiene video'), findsOneWidget);

    await desplazarFichaHasta(
      tester,
      find.textContaining('no tiene audio narrado'),
    );
    expect(find.textContaining('no tiene audio narrado'), findsOneWidget);

    await drenarTemporizadores(tester);
  });

  testWidgets('el marcador responde en toda su caja, no solo en el glifo', (
    WidgetTester tester,
  ) async {
    // El fallo original: el GestureDetector usaba HitTestBehavior.deferToChild,
    // asi que solo el glifo pintado absorbia el toque. Medido en emulador daba
    // 36x36 dp efectivos frente a los 48 que exige Material. Esta prueba toca
    // cerca de la esquina de la caja -fuera del glifo- y exige que abra igual.
    await tester.pumpWidget(
      envolver(
        const HomeScreen(),
        repositorio: RepositorioFalso(pois: poisDePrueba),
      ),
    );
    await tester.pump();
    await tester.pump();

    final marcador = etiquetaSemantica('Biblioteca');
    final caja = tester.getRect(marcador);
    expect(caja.width, greaterThanOrEqualTo(48));
    expect(caja.height, greaterThanOrEqualTo(48));

    // Cuatro pixeles hacia dentro desde la esquina superior izquierda: zona
    // muerta con el comportamiento anterior.
    await tester.tapAt(caja.topLeft + const Offset(4, 4));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Biblioteca'), findsWidgets);

    await drenarTemporizadores(tester);
  });

  testWidgets('la pestana Recorrido lista los lugares y ofrece empezar', (
    WidgetTester tester,
  ) async {
    // Antes era un marcador de posicion, y el unico camino al visor 360 era
    // acertar a un punto sin rotulo en el mapa (RF-21).
    await tester.pumpWidget(
      envolver(
        const HomeScreen(),
        repositorio: RepositorioFalso(pois: poisDePrueba),
      ),
    );
    await tester.pump();

    await tester.tap(etiquetaSemantica('Recorrido'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('0 de 3 lugares'), findsOneWidget);
    expect(find.text('Empezar recorrido'), findsOneWidget);
    // Incluye el POI sin coordenadas: la lista no depende de estar calibrado.
    expect(find.text('Murales UTB'), findsOneWidget);

    await drenarTemporizadores(tester);
  });

  testWidgets('el progreso se refleja en el contador y en cada fila', (
    WidgetTester tester,
  ) async {
    // RF-19: el mapa no sabia decir cuales ya habia visto el usuario.
    late WidgetRef referencia;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositorioContenidoProvider.overrideWithValue(
            RepositorioFalso(pois: poisDePrueba),
          ),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              referencia = ref;
              return const HomeScreen();
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(etiquetaSemantica('Recorrido'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('0 de 3 lugares'), findsOneWidget);

    referencia.read(progresoProvider.notifier).marcarVisitado(1);
    await tester.pump();

    expect(find.text('1 de 3 lugares'), findsOneWidget);
    expect(etiquetaSemantica('Biblioteca, ya visitado'), findsOneWidget);
    expect(find.text('Continuar recorrido'), findsOneWidget);

    await drenarTemporizadores(tester);
  });

  testWidgets('visitar todo cambia el estado del recorrido', (
    WidgetTester tester,
  ) async {
    late WidgetRef referencia;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositorioContenidoProvider.overrideWithValue(
            RepositorioFalso(pois: poisDePrueba),
          ),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              referencia = ref;
              return const HomeScreen();
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(etiquetaSemantica('Recorrido'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    for (final poi in poisDePrueba) {
      referencia.read(progresoProvider.notifier).marcarVisitado(poi.id);
    }
    await tester.pump();

    expect(find.text('3 de 3 lugares'), findsOneWidget);
    expect(find.text('Recorrido completo'), findsOneWidget);
    expect(find.text('Volver a empezar'), findsOneWidget);

    await drenarTemporizadores(tester);
  });

  testWidgets('el cierre del recorrido reconoce el logro', (
    WidgetTester tester,
  ) async {
    // RF-20. El KPI declarado es completar los cinco POI y la aplicacion no
    // reconocia ese momento de ninguna forma.
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => mostrarRecorridoCompletado(context),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Conociste todo el recorrido'), findsOneWidget);
    expect(find.text('Seguir explorando'), findsOneWidget);

    await drenarTemporizadores(tester);
  });

  testWidgets('un fallo de red se muestra y se puede reintentar', (
    WidgetTester tester,
  ) async {
    final repositorio = RepositorioFalso(fallo: const FalloDeConexion());

    await tester.pumpWidget(
      envolver(const HomeScreen(), repositorio: repositorio),
    );
    await tester.pump();
    await tester.pump();

    // La version anterior se tragaba el error en debugPrint y dejaba la
    // pantalla vacia.
    expect(find.textContaining('No pudimos conectarnos'), findsOneWidget);
    expect(repositorio.llamadasAPois, 1);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();

    expect(repositorio.llamadasAPois, 2);

    await drenarTemporizadores(tester);
  });

  testWidgets('una panoramica que no carga muestra el error, no un vacio', (
    WidgetTester tester,
  ) async {
    // PanoramaViewer no dibuja su hijo: lo usa como textura, asi que el
    // errorBuilder de un Image.network entregado ahi nunca aparece. En la app
    // eso se veia como un area gris sin explicacion. La imagen se resuelve
    // antes de construir el visor, y esto lo comprueba.
    //
    // En las pruebas toda peticion HTTP falla, asi que cualquier NetworkImage
    // sirve para provocar el caso.
    await tester.pumpWidget(
      envolver(
        const RecorridoScreen(lugarId: 1),
        repositorio: RepositorioFalso(
          recorrido: const Recorrido(
            escenas: [
              Escena(
                id: 1,
                lugarId: 1,
                nombre: 'Entrada principal',
                imagenUrl: 'https://placeholder.invalid/360/entrada.jpg',
                esEscenaPrincipal: true,
              ),
            ],
            hotspotsPorEscena: {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('No pudimos cargar esta panoramica'), findsOne);
    expect(find.text('Reintentar'), findsOne);

    await drenarTemporizadores(tester);
  });

  testWidgets('un fallo sin contenido no ofrece reintentar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      envolver(
        const HomeScreen(),
        repositorio: RepositorioFalso(fallo: const FalloSinContenido()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Todavia no hay contenido'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);

    await drenarTemporizadores(tester);
  });
}

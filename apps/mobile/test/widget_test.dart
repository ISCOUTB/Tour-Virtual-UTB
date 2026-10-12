import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:utb_tour/datos/modelos/modelos.dart';
import 'package:utb_tour/datos/preferencias.dart';
import 'package:utb_tour/datos/progreso.dart';
import 'package:utb_tour/datos/proveedores.dart';
import 'package:utb_tour/datos/repositorio_contenido.dart';
import 'package:utb_tour/datos/subtitulos.dart';
import 'package:utb_tour/l10n/textos.dart';
import 'package:utb_tour/loading_screen.dart';
import 'package:utb_tour/main.dart';
import 'package:utb_tour/nucleo/errores.dart';
import 'package:utb_tour/nucleo/rutas.dart';
import 'package:utb_tour/nucleo/tema.dart';
import 'package:utb_tour/recorrido_screen.dart';
import 'package:utb_tour/ui/comunes/fondos.dart';
import 'package:utb_tour/ui/recorrido_completado.dart';

// Dos peculiaridades de estas pantallas condicionan como se prueban:
//
// 1. Ninguna se estabiliza nunca. La pantalla de carga hace derivar sus luces,
//    el marcador elegido del mapa y los hotspots laten, y los esqueletos de
//    carga tienen un barrido en bucle (`controller.repeat()`), asi que
//    `pumpAndSettle` se cuelga hasta agotar el tiempo limite. Hay que avanzar
//    el reloj con `pump(Duration)` explicito. La excepcion es el modo sin
//    animaciones, que precisamente por eso se prueba con `pumpAndSettle`.
//
// 2. Quedan temporizadores vivos al final de cada prueba: el tope de la
//    pantalla de carga, la pista del visor 360 y los retardos escalonados de
//    flutter_animate. Si no se drenan, el framework falla con
//    "A Timer is still pending even after the widget tree was disposed".
//
//    Ademas, cada widget Animate programa un temporizador de duracion cero al
//    montarse, y esos widgets van apareciendo en frames sucesivos conforme se
//    resuelven los providers. Un `pump()` sin argumento no sirve para
//    vaciarlos: no avanza el reloj, asi que el temporizador de cero nunca
//    vence. Hay que avanzar un instante real, varias veces, para cubrir los
//    montajes encadenados.
Future<void> drenarTemporizadores(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 7));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

/// Deja correr las entradas animadas: listas escalonadas, el mapa que se
/// endereza y la cabecera que se pliega.
Future<void> asentar(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 100));
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

/// Un marcador del mapa. El carrusel anuncia cada parada igual, así que hay
/// que buscar dentro del lienzo.
Finder marcador(String etiqueta) => find.descendant(
  of: find.byType(InteractiveViewer),
  matching: etiquetaSemantica(etiqueta),
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

/// Proporción de teléfono, 412x915 dp. La superficie de prueba por defecto es
/// apaisada, 800x600, y deja la lista de paradas fuera de la zona construida.
void usarTelefono(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Idiomas del teléfono durante una prueba. Sin esto, las pruebas corren
/// en inglés de Estados Unidos.
void usarIdiomasDelTelefono(WidgetTester tester, List<Locale> idiomas) {
  tester.platformDispatcher.localesTestValue = idiomas;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
}

Future<void> abrirMapa(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.map_rounded));
  await asentar(tester);
}

/// Locale con el que se pintó un widget.
Locale idiomaDe(WidgetTester tester, Finder finder) =>
    Localizations.localeOf(tester.element(finder));

/// Repositorio de prueba: las pruebas no tocan la red.
class RepositorioFalso implements RepositorioContenido {
  RepositorioFalso({
    this.pois = const [],
    this.recorrido = const Recorrido(escenas: [], hotspotsPorEscena: {}),
    this.medios = const [],
    this.fallo,
  });

  final List<Poi> pois;
  final Recorrido recorrido;
  final List<Medio> medios;

  /// Cuando no es nulo, toda consulta falla con este error.
  final FalloApp? fallo;

  int llamadasAPois = 0;

  /// Como el servidor de hoy: todo en español.
  @override
  String get idiomaContenido => 'es';

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
    return PoiDetalle(
      poi: pois.firstWhere((p) => p.id == poiId),
      medios: medios.where((m) => m.poiId == poiId).toList(),
    );
  }

  @override
  Future<Ruta?> obtenerRutaActual(int lugarId) async {
    if (fallo != null) throw fallo!;
    return null;
  }

  @override
  Future<Subtitulos> obtenerSubtitulos(String url) async =>
      throw const FalloSinContenido();

  /// Sin URL: el mapa usa la ilustración empaquetada.
  @override
  Future<String?> obtenerUrlMapa(int lugarId) async => null;
}

const poisDePrueba = [
  Poi(
    id: 1,
    lugarId: 1,
    nombre: 'Biblioteca',
    categoria: 'Recursos',
    mapX: 0.63,
    mapY: 0.30,
    escenaPrincipalId: 3,
  ),
  Poi(id: 2, lugarId: 1, nombre: 'Zona de comidas', mapX: 0.42, mapY: 0.58),
  // Sin calibrar: no debe dibujarse en el mapa.
  Poi(id: 3, lugarId: 1, nombre: 'Murales UTB'),
];

const espanol = Preferencias(idioma: Locale('es'));

/// Recorrido con un salto de la Biblioteca a la Enfermería.
const recorridoConSalto = Recorrido(
  escenas: [
    Escena(
      id: 1,
      lugarId: 1,
      nombre: 'Biblioteca',
      imagenUrl: 'https://placeholder.invalid/360/biblioteca.jpg',
      esEscenaPrincipal: true,
    ),
    Escena(
      id: 3,
      lugarId: 1,
      nombre: 'Enfermeria',
      imagenUrl: 'https://placeholder.invalid/360/enfermeria.jpg',
    ),
  ],
  hotspotsPorEscena: {
    1: [
      Hotspot(
        id: 1,
        escenaId: 1,
        tipo: TipoHotspot.navegacion,
        pitch: 0,
        yaw: 10,
        escenaDestinoId: 3,
        etiqueta: 'Ir a la Enfermería',
      ),
    ],
  },
);

/// La misma configuración de idioma, tema y accesibilidad que
/// [UtbVirtualApp], con una pantalla fija en lugar del enrutador.
class AppDePrueba extends ConsumerWidget {
  const AppDePrueba({
    super.key,
    required this.hijo,
    this.sinAnimaciones = false,
    this.escalaTexto,
  });

  final Widget hijo;
  final bool sinAnimaciones;

  /// Escala del texto del sistema, como el ajuste del teléfono.
  final double? escalaTexto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencias = ref.watch(preferenciasProvider);
    return MaterialApp(
      locale: ref.watch(idiomaProvider),
      supportedLocales: Textos.supportedLocales,
      localizationsDelegates: Textos.localizationsDelegates,
      theme: temaUtb(altoContraste: preferencias.altoContraste),
      home: hijo,
      builder: (context, child) {
        var datos = MediaQuery.of(context);
        if (escalaTexto != null) {
          datos = datos.copyWith(textScaler: TextScaler.linear(escalaTexto!));
        }
        datos = ajustarMediaQuery(datos, preferencias);
        if (sinAnimaciones) datos = datos.copyWith(disableAnimations: true);
        return MediaQuery(data: datos, child: child!);
      },
    );
  }
}

Widget envolver(
  Widget hijo, {
  RepositorioContenido? repositorio,
  bool sinAnimaciones = false,
  Preferencias preferencias = espanol,
  double? escalaTexto,
}) {
  return ProviderScope(
    overrides: [
      preferenciasInicialesProvider.overrideWithValue(preferencias),
      if (repositorio != null)
        repositorioContenidoProvider.overrideWithValue(repositorio),
    ],
    child: AppDePrueba(
      hijo: hijo,
      sinAnimaciones: sinAnimaciones,
      escalaTexto: escalaTexto,
    ),
  );
}

/// Monta el módulo y devuelve una referencia para tocar el progreso.
Future<WidgetRef> montarModulo(
  WidgetTester tester, {
  List<Poi> pois = poisDePrueba,
  Preferencias preferencias = espanol,
  double? escalaTexto,
}) async {
  usarTelefono(tester);
  late WidgetRef referencia;
  await tester.pumpWidget(
    envolver(
      Consumer(
        builder: (context, ref, _) {
          referencia = ref;
          return const HomeScreen();
        },
      ),
      repositorio: RepositorioFalso(pois: pois),
      preferencias: preferencias,
      escalaTexto: escalaTexto,
    ),
  );
  await asentar(tester);
  return referencia;
}

void main() {
  // El progreso se guarda en el dispositivo; sin esto el canal nativo no existe
  // en las pruebas y cada lectura cae al manejador de error.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('arranca en la pantalla de carga', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferenciasInicialesProvider.overrideWithValue(espanol),
          repositorioContenidoProvider.overrideWithValue(RepositorioFalso()),
        ],
        child: UtbVirtualApp(enrutador: crearEnrutador()),
      ),
    );
    await tester.pump();

    expect(find.byType(LoadingScreen), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.semanticLabel == 'Universidad Tecnológica de Bolívar',
      ),
      findsOneWidget,
    );
    expect(find.text('TOUR VIRTUAL'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    await drenarTemporizadores(tester);
  });

  testWidgets('pasa al módulo en cuanto llegan los lugares, no a los 4 s', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferenciasInicialesProvider.overrideWithValue(espanol),
          repositorioContenidoProvider.overrideWithValue(
            RepositorioFalso(pois: poisDePrueba),
          ),
        ],
        child: UtbVirtualApp(enrutador: crearEnrutador()),
      ),
    );

    // Los datos llegan al instante: sale tras el mínimo de 1,5 s, más la
    // revelación circular.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.byType(LoadingScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);

    await drenarTemporizadores(tester);
  });

  testWidgets('el módulo no duplica la barra inferior de la app anfitriona', (
    WidgetTester tester,
  ) async {
    await montarModulo(tester);

    // El módulo se abre desde la app UTB, que ya tiene su barra. Lo que eran
    // pestañas es ahora el selector de Agenda.
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('Recorrido'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    // Sin ruta anterior no hay flecha de volver que no haga nada.
    expect(find.byTooltip('Volver'), findsNothing);

    await drenarTemporizadores(tester);
  });

  testWidgets('ir al mapa pliega la cabecera hasta la barra compacta', (
    WidgetTester tester,
  ) async {
    final cabecera = find.descendant(
      of: find.byType(SliverPersistentHeader),
      matching: find.byType(FondoCabeceraUtb),
    );
    await montarModulo(tester);
    final desplegada = tester.getSize(cabecera).height;

    await abrirMapa(tester);

    final plegada = tester.getSize(cabecera).height;
    expect(desplegada, greaterThan(200));
    expect(plegada, closeTo(64, 1));

    await drenarTemporizadores(tester);
  });

  testWidgets('solo dibuja marcadores de los POI calibrados', (
    WidgetTester tester,
  ) async {
    await montarModulo(tester);
    await abrirMapa(tester);

    // Tres POIs, pero solo dos traen map_x/map_y. El tercero se omite en lugar
    // de inventarle una posicion; el carrusel sí lo lista.
    expect(marcador('Parada 1, Biblioteca, Recursos'), findsOneWidget);
    expect(marcador('Parada 2, Zona de comidas'), findsOneWidget);
    expect(marcador('Parada 3, Murales UTB'), findsNothing);

    await drenarTemporizadores(tester);
  });

  testWidgets('el encuadre inicial del mapa no deja bandas vacias', (
    WidgetTester tester,
  ) async {
    // El lienzo se ajustaba a la caja de los POI aunque eso lo dejara mas bajo
    // que el visor, y encima y debajo del campus quedaba el fondo a la vista.
    //
    // Hace falta proporcion de telefono, que pone montarModulo: en el lienzo
    // de prueba por defecto, apaisado, el ajuste a los POI ya cubre el visor.
    await montarModulo(tester);
    await abrirMapa(tester);

    final visor = find.byType(InteractiveViewer);
    expect(visor, findsOneWidget);

    final hueco = tester.getRect(visor);
    // El hijo del InteractiveViewer es el lienzo: la ilustracion mas los
    // marcadores, ya transformado por la matriz de la camara.
    final lienzo = tester.getRect(
      find.descendant(of: visor, matching: find.byType(Stack)).first,
    );

    expect(
      lienzo.top,
      lessThanOrEqualTo(hueco.top + precisionErrorTolerance),
      reason: 'banda vacia sobre el mapa',
    );
    expect(
      lienzo.bottom,
      greaterThanOrEqualTo(hueco.bottom - precisionErrorTolerance),
      reason: 'banda vacia bajo el mapa',
    );
    expect(
      lienzo.left,
      lessThanOrEqualTo(hueco.left + precisionErrorTolerance),
      reason: 'banda vacia a la izquierda del mapa',
    );
    expect(
      lienzo.right,
      greaterThanOrEqualTo(hueco.right - precisionErrorTolerance),
      reason: 'banda vacia a la derecha del mapa',
    );

    await drenarTemporizadores(tester);
  });

  testWidgets('tocar un marcador abre la ficha del POI, no el visor 360', (
    WidgetTester tester,
  ) async {
    await montarModulo(tester);
    await abrirMapa(tester);

    await tester.tap(marcador('Parada 1, Biblioteca, Recursos'));
    await asentar(tester);

    // Antes se saltaba directo a descargar una panoramica a pantalla completa,
    // de modo que un POI sin panoramica no ofrecia nada.
    expect(find.byType(RecorridoScreen), findsNothing);
    expect(find.text('RECURSOS · PARADA 1 DE 3'), findsOneWidget);
    expect(find.text('Ver en 360°'), findsOneWidget);

    await drenarTemporizadores(tester);
  });

  testWidgets('el marcador responde en toda su caja, no solo en el glifo', (
    WidgetTester tester,
  ) async {
    // El fallo original: el GestureDetector usaba HitTestBehavior.deferToChild,
    // asi que solo el glifo pintado absorbia el toque. Medido en emulador daba
    // 36x36 dp efectivos frente a los 48 que exige Material. Ahora además el
    // marcador escala al revés que el mapa, y la caja tiene que seguir
    // midiendo 48 dp en pantalla.
    await montarModulo(tester);
    await abrirMapa(tester);

    final caja = tester.getRect(marcador('Parada 1, Biblioteca, Recursos'));
    expect(caja.width, greaterThanOrEqualTo(48));
    expect(caja.height, greaterThanOrEqualTo(48));

    // Cuatro pixeles hacia dentro desde la esquina superior izquierda: zona
    // muerta con el comportamiento anterior.
    await tester.tapAt(caja.topLeft + const Offset(4, 4));
    await asentar(tester);

    expect(find.text('Ver en 360°'), findsOneWidget);

    await drenarTemporizadores(tester);
  });

  testWidgets('el mapa se acerca y se aleja sin pellizcar', (
    WidgetTester tester,
  ) async {
    // WCAG 2.5.7: el pellizco no puede ser la única forma de hacer zoom.
    await montarModulo(tester);
    await abrirMapa(tester);

    double escala() => tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!
        .value
        .storage[0];

    final antes = escala();
    await tester.tap(find.byTooltip('Acercar'));
    await asentar(tester);
    expect(escala(), greaterThan(antes));

    await tester.tap(find.byTooltip('Alejar'));
    await asentar(tester);
    expect(escala(), lessThan(antes * 1.5));

    await drenarTemporizadores(tester);
  });

  testWidgets('la ficha nombra cada recurso que falta en vez de callarlo', (
    WidgetTester tester,
  ) async {
    // RF-16, prioridad alta. Hoy es el caso corriente y no la excepcion:
    // ningun POI tiene multimedia cargada todavia.
    await montarModulo(tester);

    await tester.tap(etiquetaSemantica('Parada 1, Biblioteca, Recursos'));
    await asentar(tester);

    expect(find.textContaining('no hay descripción'), findsOneWidget);
    final pendiente = find.text(
      'Todavía no hay: Fotos · Video · Audio narrado',
    );
    await desplazarFichaHasta(tester, pendiente);
    expect(pendiente, findsOneWidget);

    await drenarTemporizadores(tester);
  });

  testWidgets('el audio narrado va antes de lo que falta', (
    WidgetTester tester,
  ) async {
    usarTelefono(tester);
    // Es el unico medio que existe para los cinco lugares. Detras de la
    // seccion de video, vacia en todos, quedaba escondido bajo un hueco.
    await tester.pumpWidget(
      envolver(
        const HomeScreen(),
        repositorio: RepositorioFalso(
          pois: poisDePrueba,
          medios: const [
            Medio(
              id: 1,
              poiId: 1,
              tipo: TipoMedio.audio,
              url: 'https://placeholder.invalid/audio/biblioteca.mp3',
              textoAlt: 'Audio narrado de la Biblioteca',
            ),
          ],
        ),
      ),
    );
    await asentar(tester);

    await tester.tap(etiquetaSemantica('Parada 1, Biblioteca, Recursos'));
    await asentar(tester);

    final pendiente = find.text('Todavía no hay: Fotos · Video');
    await desplazarFichaHasta(tester, pendiente);

    final audio = tester.getTopLeft(find.text('Audio narrado')).dy;
    expect(audio, lessThan(tester.getTopLeft(pendiente).dy));

    await drenarTemporizadores(tester);
  });

  testWidgets('Recorrido lista todos los lugares y ofrece empezar', (
    WidgetTester tester,
  ) async {
    await montarModulo(tester);

    expect(find.text('0 de 3 lugares'), findsOneWidget);
    expect(find.text('Empieza tu recorrido'), findsOneWidget);
    expect(find.text('Empezar recorrido'), findsOneWidget);
    // Incluye el POI sin coordenadas: la lista no depende de estar calibrado.
    await tester.scrollUntilVisible(
      etiquetaSemantica('Parada 3, Murales UTB'),
      200,
    );
    expect(etiquetaSemantica('Parada 3, Murales UTB'), findsOneWidget);

    await drenarTemporizadores(tester);
  });

  testWidgets('el progreso se refleja en el contador y en cada fila', (
    WidgetTester tester,
  ) async {
    // RF-19: el mapa no sabia decir cuales ya habia visto el usuario.
    final referencia = await montarModulo(tester);
    expect(find.text('0 de 3 lugares'), findsOneWidget);

    referencia.read(progresoProvider.notifier).marcarVisitado(1);
    await asentar(tester);

    expect(find.text('1 de 3 lugares'), findsOneWidget);
    expect(find.text('Llevas 1 de 3 lugares'), findsOneWidget);
    // El estado va en la etiqueta: el lector de pantalla no ve la palomita.
    expect(
      etiquetaSemantica('Parada 1, Biblioteca, Recursos, ya visitado'),
      findsOneWidget,
    );
    expect(find.text('Continuar recorrido'), findsOneWidget);
    // La tarjeta destacada pasa al siguiente lugar sin visitar.
    expect(find.text('Siguiente: Zona de comidas'), findsOneWidget);

    await drenarTemporizadores(tester);
  });

  testWidgets('visitar todo cambia el estado del recorrido', (
    WidgetTester tester,
  ) async {
    final referencia = await montarModulo(tester);

    for (final poi in poisDePrueba) {
      referencia.read(progresoProvider.notifier).marcarVisitado(poi.id);
    }
    await asentar(tester);

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
      envolver(
        Builder(
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
    await asentar(tester);

    expect(find.text('Conociste todo el recorrido'), findsOneWidget);
    expect(find.text('Seguir explorando'), findsOneWidget);

    await drenarTemporizadores(tester);
  });

  testWidgets('sin animaciones el módulo queda quieto', (
    WidgetTester tester,
  ) async {
    usarTelefono(tester);
    // WCAG 2.3.3 y el ajuste «Quitar animaciones» de Android. Si algún
    // efecto decorativo ignorara la preferencia, pumpAndSettle no
    // terminaría nunca.
    await tester.pumpWidget(
      envolver(
        const HomeScreen(),
        repositorio: RepositorioFalso(pois: poisDePrueba),
        sinAnimaciones: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Empezar recorrido'), findsOneWidget);

    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();
    expect(marcador('Parada 1, Biblioteca, Recursos'), findsOneWidget);
  });

  testWidgets('«Reducir movimiento» del módulo también deja todo quieto', (
    WidgetTester tester,
  ) async {
    usarTelefono(tester);
    // El mismo efecto que el ajuste del sistema, para quien no lo conoce o
    // no puede cambiarlo en un teléfono prestado.
    await tester.pumpWidget(
      envolver(
        const HomeScreen(),
        repositorio: RepositorioFalso(pois: poisDePrueba),
        preferencias: const Preferencias(
          idioma: Locale('es'),
          reducirMovimiento: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();
    expect(marcador('Parada 1, Biblioteca, Recursos'), findsOneWidget);
  });

  testWidgets('el visor abre la escena que pide la ruta, no la principal', (
    WidgetTester tester,
  ) async {
    // Los cinco POI comparten lugar, y la escena actual vivia en un provider
    // indexado por lugarId que se autoinicializaba a la escena principal del
    // lugar. Como nunca valia null, la escena de la ruta jamas se consultaba
    // y cualquier POI abria la Biblioteca.
    usarTelefono(tester);
    await tester.pumpWidget(
      envolver(
        const RecorridoScreen(lugarId: 1, escenaInicialId: 3),
        repositorio: RepositorioFalso(recorrido: recorridoConSalto),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Enfermeria'), findsOneWidget);
    expect(find.text('ESCENA 2 DE 2'), findsOneWidget);
    expect(find.text('Biblioteca'), findsNothing);

    await drenarTemporizadores(tester);
  });

  testWidgets('el visor ofrece las salidas como botones', (
    WidgetTester tester,
  ) async {
    // Encontrar un hotspot exige mirar alrededor; para un lector de pantalla
    // los que quedan fuera de cuadro no existen. Las salidas están también
    // en el pie, como botones.
    usarTelefono(tester);
    await tester.pumpWidget(
      envolver(
        const RecorridoScreen(lugarId: 1),
        repositorio: RepositorioFalso(recorrido: recorridoConSalto),
      ),
    );
    await asentar(tester);

    expect(find.text('DESDE AQUÍ PUEDES IR A'), findsOneWidget);
    final salida = find.descendant(
      of: find.byType(Wrap),
      matching: find.text('Ir a la Enfermería'),
    );
    expect(salida, findsOneWidget);
    // Girar sin arrastrar.
    expect(find.byTooltip('Girar a la izquierda'), findsOneWidget);
    expect(find.byTooltip('Girar a la derecha'), findsOneWidget);

    await tester.tap(salida);
    await asentar(tester);
    expect(find.text('ESCENA 2 DE 2'), findsOneWidget);

    await drenarTemporizadores(tester);
  });

  testWidgets('en otro idioma, las salidas no repiten la etiqueta en español', (
    WidgetTester tester,
  ) async {
    usarTelefono(tester);
    await tester.pumpWidget(
      envolver(
        const RecorridoScreen(lugarId: 1),
        repositorio: RepositorioFalso(recorrido: recorridoConSalto),
        preferencias: const Preferencias(idioma: Locale('en')),
      ),
    );
    await asentar(tester);

    // «Ir a la Enfermería» llega del servidor; la interfaz compone la suya
    // con el nombre del destino.
    expect(
      find.descendant(
        of: find.byType(Wrap),
        matching: find.text('Go to Enfermeria'),
      ),
      findsOneWidget,
    );
    expect(find.text('Ir a la Enfermería'), findsNothing);

    await drenarTemporizadores(tester);
  });

  testWidgets('ir a una escena ya vista no deja el telón puesto', (
    WidgetTester tester,
  ) async {
    // Con la panorámica en caché, el aviso de «lista» llegaba en el mismo
    // build que creaba el visor: el setState del padre reventaba, se tomaba
    // por una panorámica fallida y «Caminando hacia» no se levantaba nunca.
    // Pasó en un teléfono al volver de la cancha a la Zona T.
    usarTelefono(tester);
    final imagen = await tester.runAsync(
      () => createTestImage(width: 8, height: 4),
    );
    for (final escena in recorridoConSalto.escenas) {
      imageCache.putIfAbsent(
        NetworkImage(escena.imagenUrl),
        () => OneFrameImageStreamCompleter(
          SynchronousFuture(ImageInfo(image: imagen!.clone())),
        ),
      );
    }
    addTearDown(imageCache.clear);

    await tester.pumpWidget(
      envolver(
        const RecorridoScreen(lugarId: 1),
        repositorio: RepositorioFalso(recorrido: recorridoConSalto),
        // Sin giroscopio: el canal de sensores no existe en las pruebas.
        preferencias: const Preferencias(
          idioma: Locale('es'),
          movimientoTelefono: false,
        ),
      ),
    );
    await asentar(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(Wrap),
        matching: find.text('Ir a la Enfermería'),
      ),
    );
    await asentar(tester);

    final telon = find.ancestor(
      of: find.text('CAMINANDO HACIA'),
      matching: find.byType(AnimatedOpacity),
    );
    expect(find.text('ESCENA 2 DE 2'), findsOneWidget);
    expect(tester.widget<AnimatedOpacity>(telon.first).opacity, 0);

    await drenarTemporizadores(tester);
  });

  testWidgets('un fallo de red se muestra y se puede reintentar', (
    WidgetTester tester,
  ) async {
    usarTelefono(tester);
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
    usarTelefono(tester);
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

    expect(find.text('No pudimos cargar esta panorámica.'), findsOne);
    expect(find.text('Reintentar'), findsOne);

    await drenarTemporizadores(tester);
  });

  testWidgets('un fallo sin contenido no ofrece reintentar', (
    WidgetTester tester,
  ) async {
    usarTelefono(tester);
    await tester.pumpWidget(
      envolver(
        const HomeScreen(),
        repositorio: RepositorioFalso(fallo: const FalloSinContenido()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Todavía no hay contenido'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);

    await drenarTemporizadores(tester);
  });

  group('idioma', () {
    testWidgets('sigue el idioma del teléfono', (WidgetTester tester) async {
      usarIdiomasDelTelefono(tester, const [Locale('fr', 'FR')]);
      await montarModulo(tester, preferencias: const Preferencias());

      expect(idiomaDe(tester, find.byType(HomeScreen)), const Locale('fr'));

      await drenarTemporizadores(tester);
    });

    testWidgets('el portugués de Portugal tiene su variante', (
      WidgetTester tester,
    ) async {
      usarIdiomasDelTelefono(tester, const [Locale('pt', 'PT')]);
      await montarModulo(tester, preferencias: const Preferencias());

      expect(
        idiomaDe(tester, find.byType(HomeScreen)),
        const Locale('pt', 'PT'),
      );

      await drenarTemporizadores(tester);
    });

    testWidgets('un idioma sin traducción cae al inglés, no al español', (
      WidgetTester tester,
    ) async {
      // Quien llega con el teléfono en ruso o en árabe entiende antes el
      // inglés que el español.
      usarIdiomasDelTelefono(tester, const [Locale('ru'), Locale('ar')]);
      await montarModulo(tester, preferencias: const Preferencias());

      expect(idiomaDe(tester, find.byType(HomeScreen)), const Locale('en'));
      expect(find.text('Map'), findsOneWidget);

      await drenarTemporizadores(tester);
    });

    testWidgets('elegir otro idioma cambia la interfaz y se recuerda', (
      WidgetTester tester,
    ) async {
      await montarModulo(tester);
      expect(find.text('Mapa'), findsOneWidget);

      await tester.tap(find.byTooltip('Idioma y accesibilidad'));
      await asentar(tester);
      // «English» sale dos veces: el teléfono de prueba también está en
      // inglés y la opción «idioma del teléfono» lo dice.
      await tester.tap(find.text('English').last);
      await asentar(tester);

      expect(idiomaDe(tester, find.byType(HomeScreen)), const Locale('en'));
      expect(find.text('Map'), findsOneWidget);
      final guardadas = await SharedPreferences.getInstance();
      expect(guardadas.getString('pref.idioma'), 'en');

      await drenarTemporizadores(tester);
    });
  });

  group('accesibilidad', () {
    // Con la letra al 200 % (WCAG 1.4.4) nada puede desbordarse. Un
    // desbordamiento es un error del framework y hace fallar la prueba. El
    // alemán es de los idiomas más largos; en las pruebas cada letra mide lo
    // mismo que su tamaño, así que el japonés también sale ancho.
    for (final idioma in const [Locale('es'), Locale('de'), Locale('ja')]) {
      testWidgets(
        'con la letra al 200 % nada se corta (${idioma.languageCode})',
        (WidgetTester tester) async {
          await montarModulo(
            tester,
            preferencias: Preferencias(idioma: idioma),
            escalaTexto: 2,
          );

          // Toda la lista, de arriba abajo.
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -2500),
          );
          await asentar(tester);
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, 2500),
          );
          await asentar(tester);

          // La ficha, desde la tarjeta principal, que con letra grande
          // acaba por debajo del borde.
          await tester.ensureVisible(find.byIcon(Icons.play_arrow_rounded));
          await asentar(tester);
          await tester.tap(find.byIcon(Icons.play_arrow_rounded));
          await asentar(tester);
          await tester.drag(find.byType(ListView).last, const Offset(0, -2500));
          await asentar(tester);
          Navigator.of(tester.element(find.byType(ListView).last)).pop();
          await asentar(tester);

          // Arriba otra vez: el selector solo existe cerca de la vista.
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, 3000),
          );
          await asentar(tester);
          await abrirMapa(tester);

          // Los ajustes, enteros.
          await tester.tap(find.byIcon(Icons.language_rounded));
          await asentar(tester);
          await tester.drag(find.byType(ListView).last, const Offset(0, -3000));
          await asentar(tester);

          await drenarTemporizadores(tester);
        },
      );
    }

    testWidgets('la letra grande se suma a la del sistema hasta el 200 %', (
      WidgetTester tester,
    ) async {
      await montarModulo(
        tester,
        preferencias: const Preferencias(
          idioma: Locale('es'),
          tamanoTexto: TamanoTexto.muyGrande,
        ),
        escalaTexto: 1.6,
      );

      final escala = MediaQuery.textScalerOf(
        tester.element(find.byType(HomeScreen)),
      );
      expect(escala.scale(10), 20);

      await drenarTemporizadores(tester);
    });

    testWidgets('el lector de pantalla puede activar cada botón', (
      WidgetTester tester,
    ) async {
      // Un Semantics con excludeSemantics y sin onTap anuncia «botón» pero
      // el doble toque de TalkBack o VoiceOver no hace nada: la acción del
      // InkWell de dentro queda excluida. `semantics.tap` falla si el nodo
      // no tiene la acción.
      final semantica = tester.ensureSemantics();
      await montarModulo(tester);

      tester.semantics.tap(
        find.semantics.byLabel('Parada 1, Biblioteca, Recursos'),
      );
      await asentar(tester);
      expect(find.text('Ver en 360°'), findsOneWidget);
      Navigator.of(tester.element(find.text('Ver en 360°'))).pop();
      await asentar(tester);

      // Abrir la Biblioteca la marcó como visitada: la tarjeta principal ya
      // propone la siguiente.
      tester.semantics.tap(find.semantics.byLabel(RegExp('^Siguiente parada')));
      await asentar(tester);
      // La Zona de comidas no tiene panorámica, y su ficha lo dice.
      final sin360 = find.text(
        'Este lugar todavía no tiene recorrido en 360°.',
      );
      expect(sin360, findsOneWidget);
      Navigator.of(tester.element(sin360)).pop();
      await asentar(tester);

      tester.semantics.tap(
        find.semantics.byLabel(RegExp('^Idioma y accesibilidad')),
      );
      await asentar(tester);
      final ajustes = find.text('Idioma y accesibilidad');
      expect(ajustes, findsOneWidget);
      Navigator.of(tester.element(ajustes)).pop();
      await asentar(tester);

      await abrirMapa(tester);
      tester.semantics.tap(find.semantics.byLabel('Acercar'));
      await asentar(tester);

      await drenarTemporizadores(tester);
      semantica.dispose();
    });

    testWidgets('cumple las guías de toque y etiquetas de Flutter', (
      WidgetTester tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montarModulo(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      await abrirMapa(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      await drenarTemporizadores(tester);
      semantica.dispose();
    });

    testWidgets('el alto contraste del módulo cambia la paleta', (
      WidgetTester tester,
    ) async {
      await montarModulo(
        tester,
        preferencias: const Preferencias(
          idioma: Locale('es'),
          altoContraste: true,
        ),
      );

      final paleta = PaletaUtb.de(tester.element(find.byType(HomeScreen)));
      expect(paleta.altoContraste, isTrue);
      expect(paleta.textoSecundario, PaletaUtb.contraste.textoSecundario);

      await drenarTemporizadores(tester);
    });

    testWidgets('«aumentar contraste» del sistema también lo activa', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(highContrast: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferenciasInicialesProvider.overrideWithValue(espanol),
            repositorioContenidoProvider.overrideWithValue(RepositorioFalso()),
          ],
          child: UtbVirtualApp(enrutador: crearEnrutador()),
        ),
      );
      await tester.pump();

      final contexto = tester.element(find.byType(LoadingScreen));
      expect(PaletaUtb.de(contexto).altoContraste, isTrue);

      await drenarTemporizadores(tester);
    });
  });
}

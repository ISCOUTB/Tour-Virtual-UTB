// THESIS: El tour no es una app aparte sino un módulo de la app UTB, y tiene
// que leerse como tal desde el primer cuadro: cabecera azul con arcos que
// colapsa, tarjetas grafito y el selector de Agenda. Rechaza la pantalla de
// mapa a sangre con barra inferior propia que el módulo tenía antes.
// OWN-WORLD: Prestado y medido de docs/capturas_utbapp: negro #010406,
// grafito #1B1C1E, azul de acción #2047CD, azul legible #6B9BF7; cabeceras
// azul real a marino con resplandor violeta y arcos finos; radios 26-32;
// Roboto; sobretítulos en versalitas espaciadas; anillos de avance.
// STORY: El visitante ve cuántos lugares hay, cuántos lleva y cuál sigue;
// abre la ficha, se asoma a la panorámica girándola con el dedo y entra en
// 360. El mapa le dice dónde queda cada parada.
// FIRST VIEWPORT: Cabecera de 276 dp con «Tour virtual» arriba y, abajo, la
// ruta, «Empieza tu recorrido» y el anillo 0/N; selector «Recorrido | Mapa»;
// tarjeta azul «Primera parada» con la postal 3D de la panorámica y el botón
// translúcido «Empezar recorrido», que es la acción principal.
// FORM: Dirección fijada por la persona usuaria, exenta de tirada de
// concept-seed: «cambiar TODO el diseño para hacerlo lo más parecido a ellos
// posible» (2026-10-11), registrada como compromiso de marca en PRODUCT.md.
// Estructura elegida por ella: módulo sin barra propia, 3D por código.
// FINISH: unreviewed and undocumented is unfinished; this build ends with the
// finish review, the verdict, DESIGN.md, and every shipping raster carrying
// its provenance

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/modelos/modelos.dart';
import '../../datos/progreso.dart';
import '../../datos/proveedores.dart';
import '../../l10n/textos.dart';
import '../../configuracion_tour.dart';
import '../../nucleo/errores.dart';
import '../../nucleo/idiomas.dart';
import '../../nucleo/movimiento.dart';
import '../../nucleo/tema.dart';
import '../ajustes/hoja_ajustes.dart';
import '../vista_async.dart';
import 'cabecera_tour.dart';
import 'vista_mapa.dart';
import 'vista_recorrido.dart';

enum ModoTour { recorrido, mapa }

/// Pantalla del módulo Tour virtual.
///
/// No tiene barra inferior: el módulo se abre desde la app UTB, que ya tiene
/// la suya. Lo que en la versión anterior eran pestañas aquí es el selector de
/// Agenda («Horario | Eventos»): «Recorrido | Mapa».
///
/// Todo vive en un único `CustomScrollView`. En el mapa la cabecera se
/// colapsa sola y el desplazamiento se bloquea, así los gestos de arrastre son
/// del mapa y no de la página.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _desplazamiento = ScrollController();
  var _modo = ModoTour.recorrido;

  /// Alto del selector con sus márgenes. El mapa ocupa exactamente lo que
  /// queda bajo la cabecera compacta, y para eso este alto no puede depender
  /// del tamaño táctil que Material decida en cada plataforma; solo crece
  /// con el texto, que con letra grande no cabía en los 80 dp de diseño.
  static double _altoSelector(TextScaler escala) =>
      max(80.0, escala.scale(16.5) * 1.3 + 46);

  static const _estiloSistema = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: ColoresUtb.fondo,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  @override
  void dispose() {
    _desplazamiento.dispose();
    super.dispose();
  }

  void _cambiarModo(ModoTour modo, double rangoCabecera) {
    if (modo == _modo) return;
    setState(() => _modo = modo);

    // Tras el cambio de contenido, la cabecera se pliega para dar el alto al
    // mapa o se despliega al volver a la lista.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_desplazamiento.hasClients) return;
      final posicion = _desplazamiento.position;
      final destino = (modo == ModoTour.mapa ? rangoCabecera : 0.0).clamp(
        posicion.minScrollExtent,
        posicion.maxScrollExtent,
      );
      if (sinMovimiento(context)) {
        _desplazamiento.jumpTo(destino);
      } else {
        _desplazamiento.animateTo(
          destino,
          duration: Movimiento.largo,
          curve: Movimiento.vaiven,
        );
      }
    });
  }

  /// El avance se cuenta sobre las paradas: un lugar sin panorámica no es
  /// algo que el recorrido pida visitar.
  ResumenTour? _resumen(
    Textos txt,
    List<Poi>? lugares,
    Set<int> visitados,
    Ruta? ruta,
  ) {
    if (lugares == null) return null;
    final pois = lugares.where((p) => p.esParada).toList();
    final total = pois.length;
    final hechos = pois.where((p) => visitados.contains(p.id)).length;
    final siguiente = pois.where((p) => !visitados.contains(p.id)).firstOrNull;
    // El nombre de la ruta también es contenido: en una interfaz en otro
    // idioma, la cabecera usa el nombre genérico traducido antes que mezclar
    // dos idiomas en una línea.
    final nombreRuta = _contenidoEnIdiomaUi() ? ruta?.nombre : null;

    return (
      sobretitulo:
          '${nombreRuta ?? txt.rutaPorDefecto} · '
          '${txt.cantidadLugares(total)}',
      titular: switch (hechos) {
        _ when total == 0 => txt.titularSinLugares,
        0 => txt.titularEmpieza,
        _ when hechos == total => txt.recorridoCompleto,
        _ => txt.titularAvance(hechos, total),
      },
      detalle: switch (hechos) {
        _ when total == 0 => null,
        // La descripción de la ruta es contenido y llega en español: solo
        // se usa si la interfaz también lo está.
        0 when ruta?.descripcion != null && _contenidoEnIdiomaUi() =>
          ruta!.descripcion,
        0 => txt.detalleEmpieza,
        _ when siguiente == null => txt.detalleCompleto,
        _ => txt.detalleSiguiente(siguiente.nombre),
      },
      hechos: hechos,
      total: total,
    );
  }

  bool _contenidoEnIdiomaUi() => mismoIdioma(
    ref.read(repositorioContenidoProvider).idiomaContenido,
    Localizations.localeOf(context).languageCode,
  );

  @override
  Widget build(BuildContext context) {
    final configuracion = ref.watch(configuracionTourProvider);
    final lugar = configuracion.lugarId;
    final txt = Textos.of(context);
    final escala = MediaQuery.textScalerOf(context);
    final altoSelector = _altoSelector(escala);
    final pois = ref.watch(poisProvider(lugar));
    final visitados = ref.watch(progresoProvider);
    final ruta = ref.watch(rutaProvider(lugar)).valueOrNull;
    // Si hay una pantalla debajo de esta. `Navigator.canPop` también cuenta
    // las hojas modales abiertas encima, y la flecha aparecía al abrir una
    // ficha.
    final puedeVolver = ModalRoute.of(context)?.canPop ?? false;
    // Dentro de la UTB APP, la pantalla principal del módulo no tiene nada
    // debajo en su propio navegador: salir lo resuelve la anfitriona.
    final alSalir = configuracion.alSalir;

    final cabecera = CabeceraTour(
      arriba: MediaQuery.paddingOf(context).top,
      resumen: _resumen(txt, pois.valueOrNull, visitados, ruta),
      alVolver: puedeVolver ? () => Navigator.maybePop(context) : alSalir,
      alAjustes: () => mostrarAjustes(context),
      escala: escala,
    );

    void reintentar() => ref.invalidate(poisProvider(lugar));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _estiloSistema,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, caja) {
            final altoMapa = max(
              360.0,
              caja.maxHeight - cabecera.minExtent - altoSelector,
            );

            return ScrollConfiguration(
              // Sin barra de desplazamiento, como en el teléfono: en el
              // escritorio de desarrollo aparecía una que la app UTB no tiene.
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: CustomScrollView(
                controller: _desplazamiento,
                physics: _modo == ModoTour.mapa
                    ? const NeverScrollableScrollPhysics()
                    : null,
                slivers: [
                  SliverPersistentHeader(pinned: true, delegate: cabecera),
                  SliverToBoxAdapter(
                    child: _Selector(
                      alto: altoSelector,
                      modo: _modo,
                      alCambiar: (m) => _cambiarModo(m, cabecera.rango),
                    ),
                  ),
                  switch (_modo) {
                    ModoTour.recorrido => pois.when(
                      data: (lista) => ListaRecorrido(
                        pois: [...lista.where((p) => p.esParada)],
                        otros: [...lista.where((p) => !p.esParada)],
                        alAbrirMapa: () =>
                            _cambiarModo(ModoTour.mapa, cabecera.rango),
                      ),
                      loading: () => const ListaRecorridoCargando(),
                      error: (error, _) => SliverToBoxAdapter(
                        child: VistaError(
                          fallo: traducirFallo(error),
                          alReintentar: reintentar,
                        ),
                      ),
                    ),
                    ModoTour.mapa => SliverToBoxAdapter(
                      child: SizedBox(
                        height: altoMapa,
                        child: VistaAsync<List<Poi>>(
                          valor: pois,
                          alReintentar: reintentar,
                          enDatos: (lista) => VistaMapa(pois: lista),
                        ),
                      ),
                    ),
                  },
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Selector extends StatelessWidget {
  const _Selector({
    required this.alto,
    required this.modo,
    required this.alCambiar,
  });

  final double alto;
  final ModoTour modo;
  final ValueChanged<ModoTour> alCambiar;

  @override
  Widget build(BuildContext context) {
    final txt = Textos.of(context);
    return SizedBox(
      height: alto,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: MedidasUtb.margen),
        child: Center(
          child: SegmentedButton<ModoTour>(
            segments: [
              ButtonSegment(
                value: ModoTour.recorrido,
                label: Text(txt.modoRecorrido),
                icon: const Icon(Icons.route_rounded),
              ),
              ButtonSegment(
                value: ModoTour.mapa,
                label: Text(txt.modoMapa),
                icon: const Icon(Icons.map_rounded),
              ),
            ],
            selected: {modo},
            onSelectionChanged: (s) => alCambiar(s.first),
            expandedInsets: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}

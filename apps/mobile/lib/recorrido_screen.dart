import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panorama_viewer/panorama_viewer.dart' as pv;

import 'datos/modelos/modelos.dart';
import 'datos/preferencias.dart';
import 'datos/proveedores.dart';
import 'l10n/textos.dart';
import 'nucleo/idiomas.dart';
import 'nucleo/movimiento.dart';
import 'nucleo/tema.dart';
import 'ui/comunes/componentes.dart';
import 'ui/vista_async.dart';

/// Control de camara del visor 360.
///
/// `panorama_viewer` mueve la vista con el giroscopio a traves de
/// `dchs_motion_sensors`, que solo tiene implementacion en Android e iOS. En
/// escritorio y web ese canal no existe y el visor lanza MissingPluginException
/// en bucle hasta tumbar la aplicacion, asi que ahi se navega solo arrastrando.
///
/// Aunque haya giroscopio, el usuario puede apagarlo (WCAG 2.5.4): quien no
/// sostiene el teléfono quieto veía la escena moverse sola.
pv.SensorControl _controlDeSensores({required bool permitido}) =>
    hayGiroscopio && permitido
    ? pv.SensorControl.orientation
    : pv.SensorControl.none;

/// Visor 360 del recorrido de un lugar.
///
/// El recorrido completo se carga una sola vez y los saltos entre escenas se
/// resuelven en memoria, sin volver a la red.
class RecorridoScreen extends ConsumerWidget {
  const RecorridoScreen({
    super.key,
    required this.lugarId,
    this.escenaInicialId,
  });

  final int lugarId;

  /// Escena por la que entrar, cuando se llega desde un POI concreto del mapa.
  /// Si es nula, se arranca por la escena principal del lugar.
  final int? escenaInicialId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recorrido = ref.watch(recorridoProvider(lugarId));
    final txt = Textos.of(context);
    // Si hay una pantalla debajo de esta. `Navigator.canPop` también cuenta
    // las hojas modales abiertas encima, y la flecha aparecía al abrir una
    // ficha.
    final puedeVolver = ModalRoute.of(context)?.canPop ?? false;
    final giroscopio = ref.watch(
      preferenciasProvider.select((p) => p.movimientoTelefono),
    );
    // Descripción de cada POI, para contar la escena a quien no la ve
    // mientras el backend no envíe la de la propia escena.
    final descripciones = <int, String>{
      for (final poi
          in ref.watch(poisProvider(lugarId)).valueOrNull ?? const <Poi>[])
        if (poi.descripcion != null) poi.id: poi.descripcion!,
    };
    final contenidoEnIdiomaUi = mismoIdioma(
      ref.watch(repositorioContenidoProvider).idiomaContenido,
      Localizations.localeOf(context).languageCode,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: VistaAsync<Recorrido>(
                valor: recorrido,
                alReintentar: () => ref.invalidate(recorridoProvider(lugarId)),
                enCarga: const _Cargando(),
                enDatos: (datos) => _Visor(
                  recorrido: datos,
                  escenaInicialId: escenaInicialId,
                  giroscopio: giroscopio,
                  descripciones: descripciones,
                  contenidoEnIdiomaUi: contenidoEnIdiomaUi,
                ),
              ),
            ),
            if (puedeVolver)
              Positioned(
                left: 12,
                top: MediaQuery.paddingOf(context).top + 8,
                child: BotonCircular(
                  icono: Icons.arrow_back_rounded,
                  etiqueta: txt.volver,
                  alTocar: () => Navigator.maybePop(context),
                ),
              ),
            if (hayGiroscopio)
              Positioned(
                right: 12,
                top: MediaQuery.paddingOf(context).top + 8,
                child: BotonCircular(
                  icono: Icons.screen_rotation_alt_rounded,
                  etiqueta: txt.movimientoTelefono,
                  activo: giroscopio,
                  alTocar: () => ref
                      .read(preferenciasProvider.notifier)
                      .cambiarMovimientoTelefono(!giroscopio),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Visor extends StatefulWidget {
  const _Visor({
    required this.recorrido,
    required this.giroscopio,
    required this.descripciones,
    required this.contenidoEnIdiomaUi,
    this.escenaInicialId,
  });

  final Recorrido recorrido;
  final int? escenaInicialId;
  final bool giroscopio;

  /// POI → descripción.
  final Map<int, String> descripciones;

  /// Si las etiquetas que envía el servidor se pueden mostrar tal cual.
  final bool contenidoEnIdiomaUi;

  @override
  State<_Visor> createState() => _VisorState();
}

class _VisorState extends State<_Visor> {
  /// Escena a la que el usuario ha navegado con los hotspots.
  ///
  /// Nula mientras no se mueva, y entonces manda la que pidio la ruta. Vivio
  /// en un provider indexado por lugarId que se autoinicializaba a la escena
  /// principal del lugar: como nunca era nulo, la escena de la ruta no se
  /// llegaba a mirar y todos los POI abrian la Biblioteca.
  int? _elegida;

  /// Telón entre escenas: cubre el salto mientras la siguiente panorámica
  /// carga, con el nombre del destino.
  String? _velo;
  Timer? _limiteVelo;
  var _mostrarPista = true;

  /// Cámara del visor actual, para girar con los botones. Cada visor
  /// necesita la suya: el paquete se suscribe al crearse y no se da de baja
  /// al destruirse, así que reutilizarla avisaría a un visor ya desmontado.
  pv.PanoramaController _camara = pv.PanoramaController();
  Object? _claveCamara;

  /// Escena ya anunciada al lector de pantalla.
  int? _anunciada;

  @override
  void dispose() {
    _limiteVelo?.cancel();
    _camara.dispose();
    super.dispose();
  }

  pv.PanoramaController _camaraPara(Object clave) {
    if (clave == _claveCamara) return _camara;
    final vieja = _camara;
    // Se libera después del cuadro, cuando el visor que la usaba ya se
    // desmontó.
    WidgetsBinding.instance.addPostFrameCallback((_) => vieja.dispose());
    _claveCamara = clave;
    return _camara = pv.PanoramaController();
  }

  void _girar(double grados) =>
      _camara.setView(_camara.getLatitude(), _camara.getLongitude() + grados);

  /// Etiqueta de un hotspot en el idioma de la interfaz.
  ///
  /// La que envía el servidor está en español («Ir a la Zona T»). En otro
  /// idioma se compone a partir del nombre de la escena de destino.
  String _etiqueta(Textos txt, Hotspot hotspot) {
    final destino = hotspot.escenaDestinoId == null
        ? null
        : widget.recorrido.escenaPorId(hotspot.escenaDestinoId!);
    final propia = hotspot.etiqueta;
    if (widget.contenidoEnIdiomaUi && propia != null) return propia;
    return switch (hotspot.tipo) {
      TipoHotspot.navegacion when destino?.nombre != null => txt.irA(
        destino!.nombre!,
      ),
      TipoHotspot.navegacion => txt.avanzarSiguienteEscena,
      _ => txt.verInformacion,
    };
  }

  void _anunciar(Escena escena) {
    if (_anunciada == escena.id || !mounted) return;
    _anunciada = escena.id;
    final nombre = escena.nombre;
    if (nombre == null) return;
    SemanticsService.sendAnnouncement(
      View.of(context),
      Textos.of(context).estasEn(nombre),
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recorrido = widget.recorrido;
    final txt = Textos.of(context);

    // Prioridad: lo que el usuario eligio navegando, luego la entrada que pide
    // la ruta, y por ultimo la escena principal del lugar.
    final escena = switch (_elegida ?? widget.escenaInicialId) {
      final int id => recorrido.escenaPorId(id) ?? recorrido.escenaInicial,
      null => recorrido.escenaInicial,
    };

    if (escena == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: RecuadroInfo(
            icono: Icons.threesixty_rounded,
            texto: txt.sinEscenas,
          ),
        ),
      );
    }

    final hotspots = recorrido
        .hotspotsDe(escena.id)
        .where((h) => h.tipo != TipoHotspot.desconocido)
        .toList();
    final salidas = [
      for (final h in hotspots)
        if (h.tipo == TipoHotspot.navegacion &&
            h.escenaDestinoId != null &&
            recorrido.escenaPorId(h.escenaDestinoId!) != null)
          h,
    ];
    final indice = recorrido.escenas.indexOf(escena);
    final animar = !sinMovimiento(context);
    // El visor se rehace al cambiar de escena y al encender o apagar el
    // giroscopio: el paquete no arranca su bucle de sensores en caliente.
    final clave = (escena.id, widget.giroscopio);
    final camara = _camaraPara(clave);
    final descripcion =
        escena.textoAlt ??
        (escena.poiId == null ? null : widget.descripciones[escena.poiId]);

    Widget panorama = _Panorama(
      // La clave fuerza a reconstruir el visor al cambiar de escena; sin
      // ella conserva la orientacion y la textura de la escena anterior.
      key: ValueKey(clave),
      escena: escena,
      camara: camara,
      giroscopio: widget.giroscopio,
      alResolver: () {
        _levantarVelo();
        _anunciar(escena);
      },
      hotspots: [
        for (final hotspot in hotspots)
          pv.Hotspot(
            latitude: hotspot.pitch,
            longitude: hotspot.yaw,
            width: _BotonHotspot.ancho,
            height: _BotonHotspot.alto,
            widget: _BotonHotspot(
              hotspot: hotspot,
              etiqueta: _etiqueta(txt, hotspot),
              animar: animar,
              alTocar: () => _tocarHotspot(context, hotspot),
            ),
          ),
      ],
    );
    if (animar) {
      // Al llegar, la escena se asienta desde un poco más cerca.
      panorama = panorama
          .animate(key: ValueKey('entrada-${escena.id}'))
          .scale(
            begin: const Offset(1.08, 1.08),
            end: const Offset(1, 1),
            duration: 1100.ms,
            curve: Movimiento.salidaFuerte,
          );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Semantics(
            container: true,
            image: true,
            label: txt.vista360De(escena.nombre ?? txt.esteLugar),
            hint: descripcion,
            child: panorama,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _PieEscena(
            nombre: escena.nombre,
            indice: indice,
            total: recorrido.escenas.length,
            pista: _mostrarPista && _velo == null,
            giroscopio: hayGiroscopio && widget.giroscopio,
            salidas: [
              for (final h in salidas)
                (
                  etiqueta: _etiqueta(txt, h),
                  destino: recorrido.escenaPorId(h.escenaDestinoId!)!,
                  alTocar: () => _tocarHotspot(context, h),
                ),
            ],
            alGirar: _girar,
            alOcultarPista: () {
              if (mounted) setState(() => _mostrarPista = false);
            },
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: _velo == null,
            child: AnimatedOpacity(
              opacity: _velo == null ? 0 : 1,
              duration: _velo == null
                  ? const Duration(milliseconds: 520)
                  : const Duration(milliseconds: 240),
              curve: Movimiento.salida,
              child: _Telon(destino: _velo ?? ''),
            ),
          ),
        ),
      ],
    );
  }

  void _levantarVelo() {
    _limiteVelo?.cancel();
    if (mounted && _velo != null) setState(() => _velo = null);
  }

  Future<void> _tocarHotspot(BuildContext context, Hotspot hotspot) async {
    final txt = Textos.of(context);
    switch (hotspot.tipo) {
      case TipoHotspot.navegacion:
        final destino = hotspot.escenaDestinoId;
        final escena = destino == null
            ? null
            : widget.recorrido.escenaPorId(destino);
        if (escena == null) return;

        if (sinMovimiento(context)) {
          setState(() => _elegida = escena.id);
          return;
        }

        HapticFeedback.selectionClick();
        setState(() => _velo = escena.nombre ?? txt.siguienteEscena);
        await Future<void>.delayed(const Duration(milliseconds: 260));
        if (!mounted) return;
        setState(() => _elegida = escena.id);
        // Si la panorámica tarda, el telón no se queda para siempre: el
        // visor ya muestra su propio estado de carga.
        _limiteVelo = Timer(const Duration(seconds: 4), _levantarVelo);
      case TipoHotspot.info:
        final poiId = hotspot.poiId;
        if (poiId != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  widget.contenidoEnIdiomaUi
                      ? hotspot.etiqueta ?? txt.puntoDeInteres
                      : txt.puntoDeInteres,
                ),
              ),
            );
        }
      case TipoHotspot.desconocido:
        break;
    }
  }
}

class _Telon extends StatelessWidget {
  const _Telon({required this.destino});

  final String destino;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mayusculasDe(context, Textos.of(context).caminandoHacia),
                style: estiloSobretitulo(
                  color: PaletaUtb.de(context).textoSecundario,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              TextoDeContenido(
                destino,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 22),
              const SizedBox(
                width: 120,
                child: LinearProgressIndicator(minHeight: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _Salida = ({String etiqueta, Escena destino, VoidCallback alTocar});

class _PieEscena extends StatefulWidget {
  const _PieEscena({
    required this.nombre,
    required this.indice,
    required this.total,
    required this.pista,
    required this.giroscopio,
    required this.salidas,
    required this.alGirar,
    required this.alOcultarPista,
  });

  final String? nombre;
  final int indice;
  final int total;
  final bool pista;
  final bool giroscopio;
  final List<_Salida> salidas;

  /// Gira la vista los grados indicados, sin arrastrar.
  final ValueChanged<double> alGirar;
  final VoidCallback alOcultarPista;

  @override
  State<_PieEscena> createState() => _PieEscenaState();
}

class _PieEscenaState extends State<_PieEscena> {
  Timer? _ocultar;

  @override
  void initState() {
    super.initState();
    // La pista se lee una vez; después estorbaría sobre la panorámica.
    _ocultar = Timer(const Duration(seconds: 6), widget.alOcultarPista);
  }

  @override
  void dispose() {
    _ocultar?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final txt = Textos.of(context);
    final paleta = PaletaUtb.de(context);
    final abajo = MediaQuery.paddingOf(context).bottom;

    // Solo los botones de salida reciben toques: el degradado y los textos
    // dejan pasar el arrastre a la panorámica.
    final informacion = IgnorePointer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: sinMovimiento(context) ? Duration.zero : Movimiento.medio,
            curve: Movimiento.salida,
            child: widget.pista
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _Pista(giroscopio: widget.giroscopio),
                  )
                : const SizedBox(width: double.infinity),
          ),
          if (widget.total > 1)
            Text(
              mayusculasDe(
                context,
                txt.escenaNDeTotal(widget.indice + 1, widget.total),
              ),
              style: estiloSobretitulo(color: Colors.white),
            ),
          if (widget.nombre != null) ...[
            const SizedBox(height: 6),
            Semantics(
              header: true,
              child: TextoDeContenido(
                widget.nombre!,
                style: textos.headlineMedium,
              ),
            ),
          ],
          if (widget.total > 1) ...[
            const SizedBox(height: 14),
            ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < widget.total; i++)
                    AnimatedContainer(
                      duration: sinMovimiento(context)
                          ? Duration.zero
                          : Movimiento.medio,
                      curve: Movimiento.salida,
                      margin: const EdgeInsets.only(right: 6),
                      width: i == widget.indice ? 22 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == widget.indice
                            ? ColoresUtb.azulClaro
                            : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              // El velo llega oscuro a la altura del texto: sobre los
              // interiores blancos de las panorámicas, un degradado tardío
              // dejaba la etiqueta de escena por debajo de 3:1.
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: paleta.altoContraste
                      ? const [
                          Color(0x00000000),
                          Color(0xE6000000),
                          Color(0xF2000000),
                        ]
                      : const [
                          Color(0x00000000),
                          Color(0xB3000000),
                          Color(0xD9000000),
                        ],
                  stops: const [0, 0.25, 1],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            MedidasUtb.margen,
            64,
            MedidasUtb.margen,
            20 + abajo,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Girar sin arrastrar (WCAG 2.5.7): con una mano, un puntero o
              // el acceso con interruptores el arrastre no siempre es
              // posible. Van aquí y no a media pantalla, donde tapaban los
              // hotspots, que casi siempre están a la altura del horizonte.
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: informacion),
                  const SizedBox(width: 12),
                  BotonCircular(
                    icono: Icons.chevron_left_rounded,
                    etiqueta: txt.girarIzquierda,
                    alTocar: () => widget.alGirar(-45),
                  ),
                  const SizedBox(width: 8),
                  BotonCircular(
                    icono: Icons.chevron_right_rounded,
                    etiqueta: txt.girarDerecha,
                    alTocar: () => widget.alGirar(45),
                  ),
                ],
              ),
              // Las salidas también como botones: encontrar un hotspot
              // exige mirar alrededor, y para un lector de pantalla los que
              // quedan fuera de cuadro no existen.
              if (widget.salidas.isNotEmpty) ...[
                const SizedBox(height: 16),
                IgnorePointer(
                  child: Semantics(
                    header: true,
                    child: Text(
                      mayusculasDe(context, txt.desdeAquiPuedesIr),
                      style: estiloSobretitulo(
                        color: Colors.white.withValues(alpha: 0.8),
                      ).copyWith(fontSize: 11.5),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final salida in widget.salidas)
                      _BotonSalida(salida: salida),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BotonSalida extends StatelessWidget {
  const _BotonSalida({required this.salida});

  final _Salida salida;

  @override
  Widget build(BuildContext context) {
    final paleta = PaletaUtb.de(context);
    return SemanticaConContenido(
      etiqueta: salida.etiqueta,
      contenido: salida.destino.nombre ?? '',
      boton: true,
      alTocar: salida.alTocar,
      child: Material(
        color: Colors.white.withValues(
          alpha: paleta.altoContraste ? 0.2 : 0.12,
        ),
        shape: StadiumBorder(
          side: BorderSide(
            color: Colors.white.withValues(
              alpha: paleta.altoContraste ? 0.85 : 0.3,
            ),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: salida.alTocar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: MedidasUtb.toque),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_walk_rounded,
                    size: 20,
                    color: ColoresUtb.texto,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      salida.etiqueta,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pista extends StatelessWidget {
  const _Pista({required this.giroscopio});

  final bool giroscopio;

  @override
  Widget build(BuildContext context) {
    final txt = Textos.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: PaletaUtb.de(context).veloOscuro,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              giroscopio
                  ? Icons.screen_rotation_alt_rounded
                  : Icons.swipe_rounded,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                giroscopio ? txt.pistaGiroscopio : txt.pistaArrastre,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            Textos.of(context).preparando360,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: PaletaUtb.de(context).textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}

/// Visor 360 de una escena, con la carga de la panoramica resuelta aparte.
///
/// `PanoramaViewer` no dibuja su hijo en el arbol de widgets: lo usa como
/// fuente de textura y le pide el ImageProvider. Por eso `loadingBuilder` y
/// `errorBuilder` de un `Image.network` entregado ahi nunca se muestran, y una
/// panoramica que falla deja el area vacia sin explicacion alguna. La imagen se
/// resuelve aqui primero y el visor solo se construye cuando hay algo que
/// mostrar.
class _Panorama extends StatefulWidget {
  const _Panorama({
    super.key,
    required this.escena,
    required this.hotspots,
    required this.camara,
    required this.giroscopio,
    required this.alResolver,
  });

  final Escena escena;
  final List<pv.Hotspot> hotspots;
  final pv.PanoramaController camara;
  final bool giroscopio;

  /// Avisa cuando hay algo que ver o cuando falló del todo, para levantar el
  /// telón entre escenas.
  final VoidCallback alResolver;

  @override
  State<_Panorama> createState() => _PanoramaState();
}

enum _EstadoPanorama { cargando, lista, fallida }

class _PanoramaState extends State<_Panorama> {
  ImageProvider? _proveedor;
  ImageStream? _flujo;
  ImageStreamListener? _oyente;
  var _estado = _EstadoPanorama.cargando;

  @override
  void initState() {
    super.initState();
    _resolver();
  }

  @override
  void dispose() {
    _desuscribir();
    super.dispose();
  }

  void _desuscribir() {
    if (_flujo != null && _oyente != null) {
      _flujo!.removeListener(_oyente!);
    }
    _flujo = null;
    _oyente = null;
  }

  /// Carga primero la version ligera y luego la completa.
  ///
  /// Una equirectangular de 4096 px tarda en llegar por una wifi compartida, y
  /// hasta ahora el usuario solo veia un indicador de progreso sin tamano. La
  /// ligera pesa unas veinte veces menos y deja ver la escena de inmediato.
  Future<void> _resolver() async {
    _desuscribir();
    setState(() => _estado = _EstadoPanorama.cargando);

    final baja = widget.escena.imagenUrlBaja;
    var hayAlgo = false;
    if (baja != null && baja.isNotEmpty) {
      hayAlgo = await _intentar(NetworkImage(baja));
    }

    final completa = await _intentar(NetworkImage(widget.escena.imagenUrl));

    // Solo es un fallo si no se pudo mostrar ninguna de las dos.
    if (!completa && !hayAlgo && mounted) {
      setState(() => _estado = _EstadoPanorama.fallida);
      widget.alResolver();
    }
  }

  /// Resuelve un proveedor y lo adopta si carga. Devuelve si lo consiguio.
  Future<bool> _intentar(ImageProvider proveedor) {
    final listo = Completer<bool>();
    late final ImageStreamListener oyente;

    void terminar(bool exito) {
      if (!listo.isCompleted) listo.complete(exito);
    }

    oyente = ImageStreamListener(
      (_, _) {
        if (mounted) {
          setState(() {
            _proveedor = proveedor;
            _estado = _EstadoPanorama.lista;
          });
          // Después del cuadro, nunca aquí. Al volver a una escena ya vista,
          // la imagen está en caché y este aviso llega en el mismo build que
          // crea el visor: el setState del padre reventaba, el error se tomaba
          // por una panorámica fallida y el telón «Caminando hacia» se quedaba
          // puesto para siempre.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.alResolver();
          });
        }
        terminar(true);
      },
      onError: (error, pila) {
        // Sin esto la excepcion sube al manejador global y el usuario solo ve
        // un area en blanco.
        debugPrint('Panoramica fallo: $error');
        terminar(false);
      },
    );

    final flujo = proveedor.resolve(const ImageConfiguration())
      ..addListener(oyente);

    return listo.future.whenComplete(() => flujo.removeListener(oyente));
  }

  @override
  Widget build(BuildContext context) {
    final proveedor = _proveedor;
    final txt = Textos.of(context);

    return switch (_estado) {
      _EstadoPanorama.cargando => const ColoredBox(
        color: Colors.black,
        child: _Cargando(),
      ),
      _EstadoPanorama.fallida => ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: ColoresUtb.fondoInfo,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: ColoresUtb.azulInfo,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  txt.panoramaNoCargo,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _resolver,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(txt.reintentar),
                ),
              ],
            ),
          ),
        ),
      ),
      _EstadoPanorama.lista when proveedor != null => pv.PanoramaViewer(
        // Sin `animSpeed` el visor se queda quieto, que es el valor por
        // defecto del paquete. Antes se le pasaba 1.0 y la escena giraba sola
        // sin parar: arrastraba los hotspots fuera de cuadro, dejaba el
        // AnimationController en repeat() para siempre y era justo el
        // movimiento continuo que WCAG 2.2 pide no imponer. Ya no se pasa.
        longitude: widget.escena.vistaInicialYaw ?? 0,
        latitude: widget.escena.vistaInicialPitch ?? 0,
        sensorControl: _controlDeSensores(permitido: widget.giroscopio),
        panoramaController: widget.camara,
        hotspots: widget.hotspots,
        child: Image(image: proveedor, fit: BoxFit.cover),
      ),
      _ => const ColoredBox(color: Colors.black),
    };
  }
}

/// Salida hacia otra escena: círculo azul con pulso y su destino debajo.
///
/// La caja es simétrica en vertical para que el centro del círculo caiga
/// exactamente sobre el ángulo calibrado; solo el círculo y la etiqueta
/// reciben toques, el resto deja pasar el arrastre al panorama.
class _BotonHotspot extends StatelessWidget {
  const _BotonHotspot({
    required this.hotspot,
    required this.etiqueta,
    required this.animar,
    required this.alTocar,
  });

  static const ancho = 176.0;
  static const alto = 136.0;
  static const _circulo = 56.0;

  final Hotspot hotspot;
  final String etiqueta;
  final bool animar;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final esNavegacion = hotspot.tipo == TipoHotspot.navegacion;
    const margen = (alto - _circulo) / 2;

    Widget pulso = Container(
      width: _circulo,
      height: _circulo,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
    if (animar) {
      pulso = pulso
          .animate(onPlay: (c) => c.repeat())
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.7, 1.7),
            duration: 1600.ms,
            curve: Curves.easeOut,
          )
          .fadeOut(begin: 0.7, duration: 1600.ms);
    }

    return Semantics(
      button: true,
      label: etiqueta,
      onTap: alTocar,
      excludeSemantics: true,
      child: SizedBox(
        width: ancho,
        height: alto,
        child: Column(
          children: [
            const SizedBox(height: margen),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: alTocar,
              child: SizedBox.square(
                dimension: _circulo,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    IgnorePointer(child: pulso),
                    Container(
                      width: _circulo,
                      height: _circulo,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF4F6BFF), ColoresUtb.azul],
                        ),
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x80000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        esNavegacion
                            ? Icons.keyboard_double_arrow_up_rounded
                            : Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: alTocar,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  // La caja del hotspot es fija; con letra grande la etiqueta
                  // se recorta, y el texto completo queda en los botones de
                  // salida del pie.
                  child: Text(
                    etiqueta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

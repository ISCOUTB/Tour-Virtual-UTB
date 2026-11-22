import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/modelos/modelos.dart';
import '../../datos/georreferencia_3d.dart';
import '../../datos/plano_campus.dart';
import '../../datos/progreso.dart';
import '../../l10n/textos.dart';
import '../../nucleo/movimiento.dart';
import '../../nucleo/tema.dart';
import '../../navegacion/geo.dart';
import '../comunes/componentes.dart';
import '../ficha_poi.dart';
import 'pintor_plano.dart';
import 'mapa_3d.dart';

/// Plano del campus con los lugares de la UTB.
///
/// El plano sale de OpenStreetMap (ver [PlanoCampus]) y cada lugar se ubica
/// por su lat/lng. Las paradas del recorrido llevan un pin numerado y entran
/// en el carrusel de abajo; deslizarlo lleva la cámara hasta cada una. Los
/// demás lugares son puntos que se vuelven tocables al acercarse.
///
/// Entra tumbado en perspectiva y se endereza: el campus aparece como una
/// maqueta que se levanta hacia el usuario.
class VistaMapa extends ConsumerStatefulWidget {
  const VistaMapa({super.key, required this.pois});

  /// Todos los lugares, paradas o no.
  final List<Poi> pois;

  @override
  ConsumerState<VistaMapa> createState() => _VistaMapaState();
}

class _VistaMapaState extends ConsumerState<VistaMapa>
    with TickerProviderStateMixin {
  static const double _amplitud = 1.9;

  /// El plano es vectorial y sigue nítido de cerca; la ilustración, en mapa
  /// de bits, no pasaba de 2,6.
  static const double _escalaMaxima = 6;

  /// Desde esta escala los lugares que no son parada se pueden tocar. Antes
  /// son puntos mudos: con el campus entero en pantalla, veinte objetivos de
  /// 48 dp se pisaban. Quien no ve el mapa los tiene todos en «Más lugares».
  static const double _escalaLugares = 1.8;

  /// Desde esta escala los lugares muestran su nombre sin solaparse.
  static const double _escalaNombres = 3.2;

  final _controlador = TransformationController();
  late final _camara = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  late final _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final _paginas = PageController(viewportFraction: 0.84);

  Animation<Matrix4>? _vuelo;
  Matrix4? _encuadre;
  var _ventana = Size.zero;
  var _lienzo = Size.zero;
  PlanoCampus? _plano;
  var _actual = 0;
  var _paginaProgramada = false;
  var _entradaIniciada = false;
  final _control3d = ControladorMapa3d();
  var _crear3d = false;
  var _listo3d = false;
  var _desea3d = false;
  var _mostrar3d = false;
  var _cambioDimension = 0;
  Timer? _volverAlPlano;
  PuntoGeo? _ultimoCentro3d;
  var _ultimoAlto3d = 0.0;

  /// Cuánto gira el norte en pantalla, en grados y en sentido horario.
  var _rumbo3d = 0.0;

  // Lo que Flutter pinta encima del visor 3D. El visor no pone nombres
  // debajo: se transparentaban por los botones.
  final _claveMapa = GlobalKey();
  final _claveLeyenda = GlobalKey();
  final _claveDimension = GlobalKey();
  final _claveControles = GlobalKey();
  final _claveOrientacion = GlobalKey();
  final _claveCredito = GlobalKey();
  final _claveCarrusel = GlobalKey();
  String? _ultimasZonas;

  List<Poi> get _paradas => widget.pois.where((p) => p.esParada).toList();

  @override
  void initState() {
    super.initState();
    _camara.addListener(() {
      final vuelo = _vuelo;
      if (vuelo != null) _controlador.value = vuelo.value;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entradaIniciada) return;
    _entradaIniciada = true;
    if (sinMovimiento(context)) {
      _entrada.value = 1;
    } else {
      _entrada.forward();
    }
  }

  @override
  void dispose() {
    _volverAlPlano?.cancel();
    _controlador.dispose();
    _camara.dispose();
    _entrada.dispose();
    _paginas.dispose();
    super.dispose();
  }

  /// Punto del lienzo donde cae [poi], o nulo si no tiene posición o queda
  /// fuera del plano.
  Offset? _enLienzo(Poi poi) {
    final plano = _plano;
    if (plano == null || !poi.tienePosicionEnMapa) return null;
    final n = plano.normalizar(poi.lat!, poi.lng!);
    if (n == null) return null;
    return Offset(n.dx * _lienzo.width, n.dy * _lienzo.height);
  }

  static double _escalaDeCobertura(Size ventana, Size lienzo) {
    if (lienzo.width <= 0 || lienzo.height <= 0) return 1;
    final cobertura = max(
      ventana.width / lienzo.width,
      ventana.height / lienzo.height,
    );
    return cobertura.isFinite && cobertura > 0 ? cobertura : 1;
  }

  /// Matriz que muestra el punto (x, y) del lienzo a escala [escala], con la
  /// traslación acotada para que el lienzo cubra siempre la ventana.
  ///
  /// `InteractiveViewer` solo corrige los gestos posteriores, nunca una matriz
  /// asignada a mano: sin este acotado quedaban bandas vacías.
  Matrix4 _matriz(double x, double y, double escala, {double alturaFoco = .5}) {
    final s = escala.clamp(
      _escalaDeCobertura(_ventana, _lienzo),
      _escalaMaxima,
    );
    final dx = (_ventana.width / 2 - x * s).clamp(
      _ventana.width - _lienzo.width * s,
      0.0,
    );
    final dy = (_ventana.height * alturaFoco - y * s).clamp(
      _ventana.height - _lienzo.height * s,
      0.0,
    );
    return Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
  }

  /// Encuadre inicial desde la caja de los lugares, no desde el centro del
  /// plano: el plano abarca todo el polígono del campus y sus calles, y los
  /// lugares ocupan un rincón.
  ///
  /// La cobertura manda sobre el ajuste. Ajustar la caja de los lugares puede
  /// pedir menos zoom del que hace falta para llenar la ventana, y esa
  /// diferencia se veía como bandas muertas.
  void _encuadrar(Size ventana, Size lienzo, PlanoCampus plano) {
    _ventana = ventana;
    _lienzo = lienzo;
    _plano = plano;
    if (_encuadre != null || ventana.isEmpty) return;

    final puntos = widget.pois.map(_enLienzo).nonNulls.toList();

    var izq = 0.0, arr = 0.0;
    var der = lienzo.width, aba = lienzo.height;
    if (puntos.isNotEmpty) {
      const holgura = 60.0;
      izq = puntos.map((p) => p.dx).reduce(min) - holgura;
      der = puntos.map((p) => p.dx).reduce(max) + holgura;
      arr = puntos.map((p) => p.dy).reduce(min) - holgura;
      // Hueco extra abajo: ahí flota el carrusel.
      aba = puntos.map((p) => p.dy).reduce(max) + holgura + 120;
    }

    final escala = min(
      ventana.width / max(der - izq, 1.0),
      ventana.height / max(aba - arr, 1.0),
    );
    final encuadre = _matriz((izq + der) / 2, (arr + aba) / 2, escala);
    _encuadre = encuadre;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controlador.value = encuadre;
    });
  }

  /// Escala real de la cámara.
  ///
  /// `getMaxScaleOnAxis` incluye el eje z, que siempre vale 1: con zoom menor
  /// que 1 devolvía 1, y los marcadores se encogían por debajo de 48 dp.
  static double _escalaDe(Matrix4 m) {
    final s = m.storage;
    return sqrt(s[0] * s[0] + s[1] * s[1] + s[2] * s[2]);
  }

  void _volarA(Matrix4 destino) {
    if (sinMovimiento(context)) {
      _controlador.value = destino;
      return;
    }
    _vuelo = Matrix4Tween(
      begin: _controlador.value.clone(),
      end: destino,
    ).animate(CurvedAnimation(parent: _camara, curve: Movimiento.vaiven));
    _camara.forward(from: 0);
  }

  void _verTodo() {
    if (_mostrar3d) {
      _control3d.verTodo();
      return;
    }
    final encuadre = _encuadre;
    if (encuadre != null) _volarA(encuadre);
  }

  /// Acerca o aleja sobre el centro de la ventana.
  ///
  /// Es la alternativa al pellizco (WCAG 2.5.7): quien usa una sola mano, un
  /// puntero o el acceso con interruptores no puede hacer el gesto de dos
  /// dedos.
  void _zoom(double factor) {
    if (_mostrar3d) {
      _control3d.zoom(factor);
      return;
    }
    final m = _controlador.value;
    final s = _escalaDe(m);
    final x = (_ventana.width / 2 - m.storage[12]) / s;
    final y = (_ventana.height / 2 - m.storage[13]) / s;
    _volarA(_matriz(x, y, s * factor));
  }

  void _seleccionar(int indice, {bool moverCarrusel = true}) {
    setState(() => _actual = indice);
    if (_mostrar3d) unawaited(_control3d.centrar(_paradas[indice]));
    final punto = _enLienzo(_paradas[indice]);
    if (punto != null) {
      final escala = max(_escalaDe(_controlador.value), 2.0);
      _volarA(_matriz(punto.dx, punto.dy, escala, alturaFoco: .38));
    }
    if (moverCarrusel && _paginas.hasClients) {
      _paginaProgramada = true;
      _paginas
          .animateToPage(
            indice,
            duration: Movimiento.largo,
            curve: Movimiento.vaiven,
          )
          .whenComplete(() => _paginaProgramada = false);
    }
  }

  /// Las paradas numeran y cuentan; el resto de los lugares abre su ficha
  /// sin número de parada.
  void _abrir(Poi poi) => abrirPoi(context, ref, poi: poi, pois: _paradas);

  /// Centro del plano y metros del modelo que caben en vertical.
  ///
  /// El visor 3D llena la misma caja que el plano: con el mismo centro y la
  /// misma altura en metros, la vista cenital coincide con el plano y el
  /// fundido no da un salto de escala.
  ({PuntoGeo centro, double alto})? _camaraDelPlano() {
    final p = _plano;
    if (p == null || _ventana.isEmpty || _lienzo.isEmpty) return null;
    final punto = _controlador.toScene(_ventana.center(Offset.zero));
    final centro = PuntoGeo(
      p.norte - punto.dy / _lienzo.height * (p.norte - p.sur),
      p.oeste + punto.dx / _lienzo.width * (p.este - p.oeste),
    );
    final metrosPorPixel =
        p.anchoMetros / (_lienzo.width * _escalaDe(_controlador.value));
    final alto = _ventana.height * metrosPorPixel * Georreferencia3d.escala;
    return (centro: centro, alto: alto);
  }

  Future<void> _entrar3d() async {
    final cambio = _cambioDimension;
    final camara = _camaraDelPlano();
    if (!_desea3d || camara == null) return;
    final quieto = sinMovimiento(context);
    _ultimoCentro3d = camara.centro;
    _ultimoAlto3d = camara.alto;
    await _control3d.vista(
      false,
      camara.centro,
      camara.alto,
      quieto: true,
      instantaneo: true,
    );
    if (!mounted || !_desea3d || cambio != _cambioDimension) return;
    setState(() => _mostrar3d = true);
    if (!quieto) {
      // El primer cuadro inicia el fundido. El último se pinta antes de
      // inclinar la cámara; cancelar o salir invalida esta continuación.
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(Movimiento.medio);
      if (!mounted || !_desea3d || cambio != _cambioDimension) return;
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!mounted || !_desea3d || cambio != _cambioDimension) return;
    // Al inclinarse se acerca un poco: tumbado, el mismo encuadre dejaba
    // media vista de horizonte.
    await _control3d.vista(
      true,
      camara.centro,
      camara.alto * 0.82,
      quieto: sinMovimiento(context),
    );
  }

  void _alternarDimension() {
    _cambioDimension++;
    _volverAlPlano?.cancel();
    if (!_desea3d) {
      setState(() {
        _desea3d = true;
        _crear3d = true;
      });
      if (_listo3d) unawaited(_entrar3d());
      return;
    }
    setState(() => _desea3d = false);
    final centro = _ultimoCentro3d;
    final alto = _ultimoAlto3d;
    if (_mostrar3d && centro != null && alto > 0) {
      // Se endereza y mira al norte antes del fundido: así llega al plano
      // con el mismo encuadre que tendrá el plano.
      unawaited(
        _control3d.vista(
          false,
          centro,
          alto,
          quieto: sinMovimiento(context),
          duracion: Vuelo3d.enderezar,
        ),
      );
    }
    _volverAlPlano = Timer(
      sinMovimiento(context) || !_mostrar3d ? Duration.zero : Vuelo3d.enderezar,
      () {
        if (!mounted || _desea3d) return;
        final plano = _plano;
        if (centro != null && alto > 0 && plano != null && !_lienzo.isEmpty) {
          final n = plano.normalizar(centro.lat, centro.lng);
          if (n != null) {
            final s =
                _ventana.height *
                plano.anchoMetros *
                Georreferencia3d.escala /
                (alto * _lienzo.width);
            _controlador.value = _matriz(
              n.dx * _lienzo.width,
              n.dy * _lienzo.height,
              s,
            );
          }
        }
        setState(() => _mostrar3d = false);
      },
    );
  }

  /// Mide los controles sobre el mapa y se los pasa al visor 3D.
  void _reservarZonas() {
    if (!mounted || !_listo3d || !_mostrar3d) return;
    final mapa = _claveMapa.currentContext?.findRenderObject();
    if (mapa is! RenderBox || !mapa.hasSize) return;
    final zonas = <Rect>[
      for (final clave in [
        _claveLeyenda,
        _claveDimension,
        _claveControles,
        _claveOrientacion,
        _claveCredito,
        _claveCarrusel,
      ])
        if (clave.currentContext?.findRenderObject() case final RenderBox caja
            when caja.hasSize && caja.attached)
          MatrixUtils.transformRect(
            caja.getTransformTo(mapa),
            Offset.zero & caja.size,
          ).inflate(4),
    ];
    final firma = zonas.map((z) => z.toString()).join();
    if (firma == _ultimasZonas) return;
    _ultimasZonas = firma;
    unawaited(_control3d.reservar(zonas));
  }

  void _alFallar3d() {
    if (!mounted) return;
    _ultimasZonas = null;
    _cambioDimension++;
    final avisar = _desea3d || _mostrar3d;
    _volverAlPlano?.cancel();
    setState(() {
      _desea3d = false;
      _mostrar3d = false;
      _crear3d = false;
      _listo3d = false;
    });
    if (avisar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Textos.of(context).mapa3dNoDisponible)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visitados = ref.watch(progresoProvider);
    final plano = ref.watch(planoCampusProvider);
    final paradas = _paradas;
    final abajo = MediaQuery.paddingOf(context).bottom;
    final hechos = paradas.where((p) => visitados.contains(p.id)).length;
    final txt = Textos.of(context);
    final escala = MediaQuery.textScalerOf(context);
    // El carrusel crece con el texto: el nombre y la categoría no cabían en
    // 84 dp con la letra al 200 %.
    final altoCarrusel = max(
      84.0,
      24 + escala.scale(17) * 1.3 + 2 + escala.scale(13) * 1.4 + 6,
    );

    if (_mostrar3d && _listo3d) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reservarZonas());
    }
    final tarjeta = ClipRRect(
      borderRadius: BorderRadius.circular(MedidasUtb.radioTarjeta + 2),
      child: ColoredBox(
        // El color de la tierra del plano: mientras carga, o si se aleja más
        // allá del borde, no se ve una costura.
        color: ColoresPlano.tierra,
        child: Stack(
          key: _claveMapa,
          children: [
            Positioned.fill(
              key: const ValueKey('plano-campus'),
              child: IgnorePointer(
                ignoring: _mostrar3d,
                child: ExcludeSemantics(
                  excluding: _mostrar3d,
                  child: plano.when(
                    data: (p) => _lienzoInteractivo(p, paradas, visitados),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const _MapaAusente(),
                  ),
                ),
              ),
            ),
            if (_crear3d)
              Positioned.fill(
                key: const ValueKey('maqueta-campus'),
                child: IgnorePointer(
                  ignoring: !_mostrar3d,
                  child: ExcludeSemantics(
                    excluding: !_mostrar3d,
                    child: AnimatedOpacity(
                      opacity: _mostrar3d ? 1 : 0,
                      duration: sinMovimiento(context)
                          ? Duration.zero
                          : Movimiento.medio,
                      curve: Movimiento.salida,
                      child: MapaCampus3d(
                        pois: widget.pois,
                        visitados: visitados,
                        seleccion: paradas.elementAtOrNull(_actual)?.id,
                        controlador: _control3d,
                        alCargar: () {
                          _listo3d = true;
                          unawaited(_entrar3d());
                        },
                        alFallar: _alFallar3d,
                        alMoverCamara: (camara) {
                          if (!_mostrar3d || !_desea3d) return;
                          _ultimoCentro3d = camara.centro;
                          _ultimoAlto3d = camara.alto;
                          // Solo se redibuja la brújula cuando se nota.
                          if ((camara.rumbo - _rumbo3d).abs() > 0.5) {
                            setState(() => _rumbo3d = camara.rumbo);
                          }
                        },
                        alTocarPoi: (poi) {
                          final i = _paradas.indexWhere((p) => p.id == poi.id);
                          if (i >= 0) _seleccionar(i);
                          _abrir(poi);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            if (admiteMapa3d)
              Positioned(
                key: const ValueKey('dimension-campus'),
                left: 12,
                top: 60,
                child: Tooltip(
                  key: _claveDimension,
                  message: _desea3d ? txt.verMapa2d : txt.verMapa3d,
                  child: Semantics(
                    button: true,
                    toggled: _desea3d,
                    label: _desea3d && !_listo3d
                        ? '${txt.mapa3dCargando}. ${txt.verMapa2d}'
                        : _desea3d
                        ? txt.verMapa2d
                        : txt.verMapa3d,
                    liveRegion: _desea3d && !_listo3d,
                    onTap: _alternarDimension,
                    excludeSemantics: true,
                    child: FilledButton.tonalIcon(
                      onPressed: _alternarDimension,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(80, 48),
                        backgroundColor: ColoresUtb.superficie,
                        foregroundColor: ColoresUtb.texto,
                      ),
                      icon: _desea3d && !_listo3d
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _desea3d
                                  ? Icons.map_outlined
                                  : Icons.view_in_ar_rounded,
                              size: 20,
                            ),
                      label: Text(_desea3d ? '2D' : '3D'),
                    ),
                  ),
                ),
              ),
            Positioned(
              key: const ValueKey('leyenda-campus'),
              left: 12,
              right: 12 + MedidasUtb.toque + 8,
              top: 12,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _Leyenda(
                  key: _claveLeyenda,
                  hechos: hechos,
                  total: paradas.length,
                ),
              ),
            ),
            Positioned(
              key: const ValueKey('controles-campus'),
              right: 12,
              top: 12,
              child: Column(
                key: _claveControles,
                children: [
                  BotonCircular(
                    solido: true,
                    icono: Icons.zoom_out_map_rounded,
                    etiqueta: txt.verTodoCampus,
                    alTocar: _verTodo,
                  ),
                  const SizedBox(height: 8),
                  BotonCircular(
                    solido: true,
                    icono: Icons.add_rounded,
                    etiqueta: txt.acercar,
                    alTocar: () => _zoom(1.5),
                  ),
                  const SizedBox(height: 8),
                  BotonCircular(
                    solido: true,
                    icono: Icons.remove_rounded,
                    etiqueta: txt.alejar,
                    alTocar: () => _zoom(1 / 1.5),
                  ),
                ],
              ),
            ),
            // Giro y brújula, solo en 3D. Van en fila bajo el botón 2D/3D y
            // no en la columna del zoom: seis botones apilados pisaban el
            // carrusel en un teléfono pequeño o con el texto grande.
            if (_mostrar3d)
              Positioned(
                key: const ValueKey('orientacion-campus'),
                left: 12,
                top: 116,
                child: Row(
                  key: _claveOrientacion,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BotonCircular(
                      solido: true,
                      icono: Icons.rotate_left_rounded,
                      etiqueta: txt.girarIzquierda,
                      alTocar: () => _control3d.girar(-45),
                    ),
                    const SizedBox(width: 8),
                    _Brujula(
                      rumbo: _rumbo3d,
                      etiqueta: txt.orientarNorte,
                      alTocar: _control3d.orientarNorte,
                    ),
                    const SizedBox(width: 8),
                    BotonCircular(
                      solido: true,
                      icono: Icons.rotate_right_rounded,
                      etiqueta: txt.girarDerecha,
                      alTocar: () => _control3d.girar(45),
                    ),
                  ],
                ),
              ),
            // ODbL: los datos de OSM se usan con la atribución a la vista.
            Positioned(
              key: const ValueKey('credito-campus'),
              left: 12,
              right: 12,
              bottom: 12 + (paradas.isEmpty ? 0 : altoCarrusel + 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                // El plano es de OSM; la maqueta, de ElMapita. Cada vista
                // acredita lo que muestra.
                child: AnimatedSwitcher(
                  key: _claveCredito,
                  duration: sinMovimiento(context)
                      ? Duration.zero
                      : Movimiento.medio,
                  child: _Credito(
                    key: ValueKey(_mostrar3d),
                    texto: _mostrar3d ? txt.creditoModelo3d : txt.creditoOsm,
                  ),
                ),
              ),
            ),
            if (paradas.isNotEmpty)
              Positioned(
                key: const ValueKey('carrusel-campus'),
                left: 0,
                right: 0,
                bottom: 12,
                height: altoCarrusel,
                child: KeyedSubtree(
                  key: _claveCarrusel,
                  child: _carrusel(paradas, visitados),
                ),
              ),
          ],
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + abajo),
      child: AnimatedBuilder(
        animation: _entrada,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MedidasUtb.radioTarjeta + 2),
            border: Border.all(color: ColoresUtb.borde),
          ),
          child: tarjeta,
        ),
        // La estructura no cambia al terminar la entrada: devolver el hijo
        // pelado al final recreaba el mapa entero, y por un cuadro convivían
        // dos carruseles colgados del mismo PageController.
        builder: (context, hijo) {
          final v = _entrada.value;
          final t = Movimiento.salidaFuerte.transform(v);
          final escala = lerpDouble(0.9, 1, t)!;
          return Opacity(
            opacity: (v * 2.2).clamp(0.0, 1.0),
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, Movimiento.perspectiva)
                ..rotateX(-(1 - t) * 0.9)
                ..scaleByDouble(escala, escala, 1, 1),
              child: hijo,
            ),
          );
        },
      ),
    );
  }

  Widget _lienzoInteractivo(
    PlanoCampus plano,
    List<Poi> paradas,
    Set<int> visitados,
  ) {
    final altoContraste = PaletaUtb.de(context).altoContraste;
    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = max(
          restricciones.maxWidth * _amplitud,
          restricciones.maxHeight * plano.proporcion,
        );
        final lienzo = Size(ancho, ancho / plano.proporcion);
        _encuadrar(restricciones.biggest, lienzo, plano);

        return InteractiveViewer(
          transformationController: _controlador,
          constrained: false,
          minScale: _escalaDeCobertura(restricciones.biggest, lienzo),
          maxScale: _escalaMaxima,
          boundaryMargin: EdgeInsets.zero,
          onInteractionStart: (_) => _camara.stop(),
          child: SizedBox(
            width: lienzo.width,
            height: lienzo.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Semantics(
                    image: true,
                    label: Textos.of(context).mapaDescripcion,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: PintorPlano(
                          plano: plano,
                          altoContraste: altoContraste,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(child: _marcadores(paradas, visitados)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Los marcadores escalan al revés que el mapa: en pantalla miden siempre lo
  /// mismo, así que acercarse no los vuelve enormes ni alejarse los esconde.
  Widget _marcadores(List<Poi> paradas, Set<int> visitados) {
    final animar = !sinMovimiento(context);
    final lugares = widget.pois.where((p) => !p.esParada);

    return ValueListenableBuilder<Matrix4>(
      valueListenable: _controlador,
      builder: (context, matriz, _) {
        final escala = _escalaDe(matriz);
        final k = 1 / escala.clamp(0.2, 10.0);
        final tocables = escala >= _escalaLugares;
        final conNombre = escala >= _escalaNombres;
        final apartes = _repartirParadas(paradas, escala);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Los lugares van debajo: donde se cruzan con una parada, manda
            // la parada.
            for (final poi in lugares)
              if (_enLienzo(poi) case final punto?)
                Positioned(
                  left: punto.dx - _PuntoLugar.lado / 2,
                  top: punto.dy - _PuntoLugar.lado / 2,
                  child: Transform.scale(
                    scale: k,
                    child: tocables
                        ? _PuntoLugar(
                            poi: poi,
                            conNombre: conNombre,
                            alTocar: () => _abrir(poi),
                          )
                        : const _PuntoMudo(),
                  ),
                ),
            // Tallos de las paradas apartadas, bajo todos los pines.
            for (final (i, poi) in paradas.indexed)
              if ((_enLienzo(poi), apartes[i]) case (
                final punto?,
                final aparte?,
              ))
                Positioned(
                  left: punto.dx,
                  top: punto.dy,
                  child: Transform.scale(
                    scale: k,
                    alignment: Alignment.topLeft,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _PintorTallo(
                          aparte: aparte,
                          color: visitados.contains(poi.id)
                              ? ColoresUtb.verde
                              : ColoresUtb.azul,
                        ),
                      ),
                    ),
                  ),
                ),
            for (final (i, poi) in paradas.indexed)
              if (_enLienzo(poi) case final punto?)
                Positioned(
                  left:
                      punto.dx -
                      _Marcador.ancho / 2 +
                      (apartes[i]?.dx ?? 0) / escala,
                  top:
                      punto.dy -
                      _Marcador.punta +
                      (apartes[i]?.dy ?? 0) / escala,
                  child: Transform.scale(
                    scale: k,
                    alignment: const Alignment(
                      0,
                      2 * _Marcador.punta / _Marcador.alto - 1,
                    ),
                    child: _Marcador(
                      numero: i + 1,
                      nombre: poi.nombre,
                      categoria: poi.categoria,
                      visitado: visitados.contains(poi.id),
                      elegido: i == _actual,
                      animar: animar,
                      orden: i,
                      alTocar: () {
                        _seleccionar(i);
                        _abrir(poi);
                      },
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  /// Paradas que, en pantalla, caen encima de otra: suben (o se apartan)
  /// lo justo y un tallo las une a su punto real. Mismos desplazamientos que
  /// el visor 3D (`CANDIDATOS` en visor.js). La elegida no se mueve.
  ///
  /// Devuelve el desplazamiento en píxeles de pantalla de cada parada
  /// apartada, por su índice.
  Map<int, Offset> _repartirParadas(List<Poi> paradas, double escala) {
    Rect caja(Offset punta) => Rect.fromLTWH(
      punta.dx - _Marcador.ancho / 2,
      punta.dy - _Marcador.punta,
      _Marcador.ancho,
      _Marcador.alto,
    );
    final orden = [
      if (_actual < paradas.length) _actual,
      for (var i = 0; i < paradas.length; i++)
        if (i != _actual) i,
    ];
    final ocupadas = <Rect>[];
    final apartes = <int, Offset>{};
    for (final i in orden) {
      final punto = _enLienzo(paradas[i]);
      if (punto == null) continue;
      final base = punto * escala;
      for (final d in _candidatos) {
        final c = caja(base + d);
        if (ocupadas.any((o) => o.overlaps(c))) continue;
        ocupadas.add(c);
        if (d != Offset.zero) apartes[i] = d;
        break;
      }
    }
    return apartes;
  }

  static final _candidatos = () {
    final lista = <(Offset, double)>[];
    for (final dx in const [0.0, -20.0, 20.0, -40.0, 40.0, -64.0, 64.0]) {
      for (final dy in const [
        0.0,
        -20.0,
        -40.0,
        -60.0,
        -80.0,
        -100.0,
        24.0,
        48.0,
      ]) {
        lista.add((Offset(dx, dy), dx.abs() * 1.6 + (dy < 0 ? -dy : dy * 2.5)));
      }
    }
    lista.sort((a, b) => a.$2.compareTo(b.$2));
    return [for (final (d, _) in lista) d];
  }();

  Widget _carrusel(List<Poi> paradas, Set<int> visitados) {
    return PageView.builder(
      controller: _paginas,
      itemCount: paradas.length,
      onPageChanged: (i) {
        if (!_paginaProgramada) _seleccionar(i, moverCarrusel: false);
      },
      itemBuilder: (context, i) {
        final poi = paradas[i];
        return AnimatedBuilder(
          animation: _paginas,
          builder: (context, hijo) {
            final pagina =
                _paginas.hasClients && _paginas.position.haveDimensions
                ? _paginas.page ?? _actual.toDouble()
                : _actual.toDouble();
            final d = (pagina - i).abs().clamp(0.0, 1.0);
            return Opacity(
              opacity: 1 - d * 0.3,
              child: Transform.scale(scale: 1 - d * 0.06, child: hijo),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            // Solo la tarjeta centrada es un botón. Las vecinas asoman unos
            // 30 dp por el borde: tocarlas trae el carrusel hasta ellas, y
            // el lector de pantalla no las anuncia como un objetivo que no
            // cabe en pantalla.
            child: ExcludeSemantics(
              excluding: i != _actual,
              child: _TarjetaCarrusel(
                poi: poi,
                numero: i + 1,
                visitado: visitados.contains(poi.id),
                alTocar: () => i == _actual ? _abrir(poi) : _seleccionar(i),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MapaAusente extends StatelessWidget {
  const _MapaAusente();

  @override
  Widget build(BuildContext context) {
    const gris = Color(0xFF5B5E66);
    return ColoredBox(
      color: const Color(0xFFF1F3F6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 40, color: gris),
            const SizedBox(height: 10),
            Text(
              Textos.of(context).mapaNoCargo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: familiaLetra,
                fontSize: 15,
                color: gris,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «© colaboradores de OpenStreetMap» sobre el plano, o el autor de la
/// maqueta sobre el 3D.
class _Credito extends StatelessWidget {
  const _Credito({super.key, required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          texto,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            // Gris de OSM sobre blanco: 10:1.
            color: const Color(0xFF333333),
          ),
        ),
      ),
    );
  }
}

/// Brújula del mapa 3D: la aguja marca dónde queda el norte y tocarla lo
/// vuelve a poner arriba.
class _Brujula extends StatelessWidget {
  const _Brujula({
    required this.rumbo,
    required this.etiqueta,
    required this.alTocar,
  });

  /// Giro del norte en pantalla, en grados y en sentido horario.
  final double rumbo;
  final String etiqueta;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final paleta = PaletaUtb.de(context);
    return Tooltip(
      message: etiqueta,
      child: Semantics(
        button: true,
        label: etiqueta,
        onTap: alTocar,
        excludeSemantics: true,
        child: Material(
          // Como los BotonCircular sólidos de al lado.
          color: ColoresUtb.superficie,
          shape: CircleBorder(
            side: BorderSide(
              color: Colors.white.withValues(
                alpha: paleta.altoContraste ? 0.85 : 0.2,
              ),
              width: paleta.altoContraste ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: alTocar,
            child: SizedBox.square(
              dimension: MedidasUtb.toque,
              child: Transform.rotate(
                angle: rumbo * pi / 180,
                child: const CustomPaint(painter: _PintorAguja()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PintorAguja extends CustomPainter {
  const _PintorAguja();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const largo = 14.0, ancho = 5.5;
    Path mitad(double signo) => Path()
      ..moveTo(c.dx, c.dy + signo * largo)
      ..lineTo(c.dx + ancho, c.dy)
      ..lineTo(c.dx - ancho, c.dy)
      ..close();
    canvas.drawPath(mitad(-1), Paint()..color = ColoresUtb.rojo);
    canvas.drawPath(mitad(1), Paint()..color = ColoresUtb.texto);
    canvas.drawCircle(c, 1.8, Paint()..color = ColoresUtb.superficie);
  }

  @override
  bool shouldRepaint(_PintorAguja old) => false;
}

/// Lugar del campus que no es parada: un círculo con el icono de su
/// categoría. Tocarlo abre su ficha.
class _PuntoLugar extends StatelessWidget {
  const _PuntoLugar({
    required this.poi,
    required this.conNombre,
    required this.alTocar,
  });

  /// Caja táctil, centrada en el punto del mapa. Material pide 48 dp.
  static const double lado = 48;

  final Poi poi;
  final bool conNombre;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final txt = Textos.of(context);
    final estilo = EstiloCategoria.de(poi.categoria);
    final categoria = poi.categoria == null
        ? null
        : EstiloCategoria.nombre(txt, poi.categoria!);

    return SemanticaConContenido(
      etiqueta: categoria == null ? poi.nombre : '${poi.nombre}, $categoria',
      contenido: poi.nombre,
      boton: true,
      alTocar: alTocar,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: alTocar,
        child: SizedBox(
          width: lado,
          height: lado,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Grafito con el color de la categoría: se separa igual del
              // techo claro de un edificio que del verde de una cancha.
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: ColoresUtb.superficie,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(estilo.icono, size: 16, color: estilo.color),
              ),
              if (conNombre)
                Positioned(
                  top: lado - 6,
                  left: -60,
                  right: -60,
                  child: IgnorePointer(
                    child: Center(child: _EtiquetaPin(texto: poi.nombre)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El mismo lugar visto desde lejos: un punto que no se toca ni se anuncia.
class _PuntoMudo extends StatelessWidget {
  const _PuntoMudo();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: SizedBox(
          width: _PuntoLugar.lado,
          height: _PuntoLugar.lado,
          child: Center(
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: ColoresUtb.superficie,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Marcador extends StatelessWidget {
  const _Marcador({
    required this.numero,
    required this.nombre,
    required this.categoria,
    required this.visitado,
    required this.elegido,
    required this.animar,
    required this.orden,
    required this.alTocar,
  });

  /// Caja táctil. Material exige 48 dp como mínimo en ambos ejes.
  static const double ancho = 56;
  static const double alto = 60;

  /// Altura de la punta del pin dentro de la caja: el punto exacto del mapa.
  static const double punta = 48;

  final int numero;
  final String nombre;
  final String? categoria;
  final bool visitado;
  final bool elegido;
  final bool animar;
  final int orden;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final color = visitado ? ColoresUtb.verde : ColoresUtb.azul;
    final txt = Textos.of(context);

    Widget pin = SizedBox(
      width: ancho,
      height: alto,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          if (elegido && animar)
            Positioned(
              top: 5,
              child: IgnorePointer(
                child:
                    Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 3),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.9, 1.9),
                          duration: 1400.ms,
                          curve: Curves.easeOut,
                        )
                        .fadeOut(begin: 0.9, duration: 1400.ms),
              ),
            ),
          AnimatedScale(
            scale: elegido ? 1.14 : 1,
            alignment: Alignment(0, 2 * punta / alto - 1),
            duration: Movimiento.corto,
            curve: Movimiento.salida,
            child: CustomPaint(
              size: const Size(ancho, alto),
              painter: _PintorPin(color: color),
              child: SizedBox(
                width: ancho,
                height: alto,
                child: Align(
                  // Centro del círculo del pin, no de la caja.
                  alignment: const Alignment(0, 2 * 23 / alto - 1),
                  child: visitado
                      ? const Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: Colors.white,
                        )
                      // La cifra vive dentro de un pin de 34 dp: no crece con
                      // el texto del sistema, y el lector de pantalla la
                      // recibe por la etiqueta del marcador.
                      : Text(
                          '$numero',
                          textScaler: TextScaler.noScaling,
                          style: const TextStyle(
                            fontFamily: familiaLetra,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                ),
              ),
            ),
          ),
          if (elegido)
            Positioned(
              left: -70,
              right: -70,
              bottom: alto + 2,
              child: IgnorePointer(
                child: Center(child: _EtiquetaPin(texto: nombre)),
              ),
            ),
        ],
      ),
    );

    if (animar) {
      pin = pin
          .animate(delay: (200 + orden * 90).ms)
          .fadeIn(duration: 220.ms)
          .moveY(
            begin: -22,
            end: 0,
            duration: 560.ms,
            curve: Curves.easeOutBack,
          );
    }

    final parada = txt.paradaSemantica(numero, nombre);
    final conCategoria = categoria == null
        ? parada
        : '$parada, ${EstiloCategoria.nombre(txt, categoria!)}';
    return SemanticaConContenido(
      etiqueta: visitado ? txt.yaVisitado(conCategoria) : conCategoria,
      contenido: nombre,
      boton: true,
      alTocar: alTocar,
      child: GestureDetector(
        // Toda la caja responde, no solo el glifo pintado: con
        // deferToChild el área efectiva medía 36 dp.
        behavior: HitTestBehavior.opaque,
        onTap: alTocar,
        child: pin,
      ),
    );
  }
}

/// Tallo blanco desde el punto real de una parada hasta la punta de su pin
/// apartado, con un punto del color de la parada en el extremo.
class _PintorTallo extends CustomPainter {
  const _PintorTallo({required this.aparte, required this.color});

  /// De la punta real a la punta del pin, en píxeles de pantalla.
  final Offset aparte;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset.zero,
      aparte,
      Paint()
        ..color = const Color(0x8C000000)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset.zero,
      aparte,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset.zero, 5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset.zero, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PintorTallo old) =>
      old.aparte != aparte || old.color != color;
}

class _PintorPin extends CustomPainter {
  const _PintorPin({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const cy = 23.0;
    const r = 17.0;
    final forma = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r))
      ..moveTo(cx - 8, cy + r - 3)
      ..lineTo(cx, _Marcador.punta)
      ..lineTo(cx + 8, cy + r - 3)
      ..close();

    canvas.drawShadow(forma, Colors.black, 4, false);
    canvas.drawPath(
      forma,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.22)!, color],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );
    // El reborde blanco separa el pin del fondo sea cual sea: techos claros,
    // césped o asfalto.
    canvas.drawPath(
      forma,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_PintorPin old) => old.color != color;
}

class _EtiquetaPin extends StatelessWidget {
  const _EtiquetaPin({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColoresUtb.superficie,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          texto,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({super.key, required this.hechos, required this.total});

  final int hechos;
  final int total;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: ColoresUtb.verde,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                Textos.of(context).visitadosDeTotal(hechos, total),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaCarrusel extends StatelessWidget {
  const _TarjetaCarrusel({
    required this.poi,
    required this.numero,
    required this.visitado,
    required this.alTocar,
  });

  final Poi poi;
  final int numero;
  final bool visitado;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final txt = Textos.of(context);
    final paleta = PaletaUtb.de(context);
    final estilo = EstiloCategoria.de(poi.categoria);
    final categoria = poi.categoria == null
        ? null
        : EstiloCategoria.nombre(txt, poi.categoria!);
    final detalle = !poi.tienePosicionEnMapa
        ? txt.sinUbicacionMapa
        : visitado
        ? '${txt.visitado} · ${categoria ?? txt.campus}'
        : categoria ?? txt.lugarDelCampus;
    final parada = txt.paradaSemantica(numero, poi.nombre);
    final conCategoria = categoria == null ? parada : '$parada, $categoria';

    return SemanticaConContenido(
      etiqueta: visitado ? txt.yaVisitado(conCategoria) : conCategoria,
      contenido: poi.nombre,
      boton: true,
      alTocar: alTocar,
      child: TarjetaUtb(
        radio: 22,
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        colorBorde: paleta.bordeFuerte,
        alTocar: alTocar,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: visitado
                      ? [const Color(0xFF6FD585), ColoresUtb.verde]
                      : [const Color(0xFF4F6BFF), ColoresUtb.azul],
                ),
              ),
              alignment: Alignment.center,
              child: visitado
                  ? const Icon(Icons.check_rounded, color: Colors.white)
                  : Text(
                      numeroParada(numero),
                      style: textos.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    poi.nombre,
                    style: textos.titleMedium?.copyWith(fontSize: 17),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        estilo.icono,
                        size: 14,
                        color: paleta.textoSecundario,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          detalle,
                          style: textos.bodySmall?.copyWith(
                            color: paleta.textoSecundario,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: paleta.textoTerciario),
          ],
        ),
      ),
    );
  }
}

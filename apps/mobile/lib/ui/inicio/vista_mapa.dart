import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/modelos/modelos.dart';
import '../../datos/progreso.dart';
import '../../datos/proveedores.dart';
import '../../l10n/textos.dart';
import '../../nucleo/configuracion.dart';
import '../../nucleo/movimiento.dart';
import '../../nucleo/tema.dart';
import '../comunes/componentes.dart';
import '../ficha_poi.dart';

/// Mapa isométrico del campus con los puntos de interés.
///
/// Entra tumbado en perspectiva y se endereza: el campus aparece como una
/// maqueta que se levanta hacia el usuario. Debajo, un carrusel con todas las
/// paradas; deslizarlo lleva la cámara hasta cada una.
///
/// El render entregado por la universidad mide 4096x2304. El lienzo tiene que
/// respetar esa proporción: mientras fue cuadrado, toda coordenada normalizada
/// caía desplazada en vertical.
class VistaMapa extends ConsumerStatefulWidget {
  const VistaMapa({super.key, required this.pois});

  final List<Poi> pois;

  @override
  ConsumerState<VistaMapa> createState() => _VistaMapaState();
}

class _VistaMapaState extends ConsumerState<VistaMapa>
    with TickerProviderStateMixin {
  static const double _relacion = 4096 / 2304;
  static const double _amplitud = 1.9;
  static const double _escalaMaxima = 2.6;
  static const _rutaMapa = 'android/app/src/assets/mapa_campus.webp';

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
  var _actual = 0;
  var _paginaProgramada = false;
  var _entradaIniciada = false;

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
    _controlador.dispose();
    _camara.dispose();
    _entrada.dispose();
    _paginas.dispose();
    super.dispose();
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

  /// Encuadre inicial desde la caja de los POI, no desde el centro de la
  /// imagen: así los márgenes propios de la ilustración quedan fuera.
  ///
  /// La cobertura manda sobre el ajuste. Ajustar la caja de los POI puede
  /// pedir menos zoom del que hace falta para llenar la ventana, y esa
  /// diferencia se veía como bandas muertas.
  void _encuadrar(Size ventana, Size lienzo) {
    _ventana = ventana;
    _lienzo = lienzo;
    if (_encuadre != null || ventana.isEmpty) return;

    final ubicables = widget.pois.where((p) => p.tienePosicionEnMapa).toList();

    var izq = 0.0, arr = 0.0;
    var der = lienzo.width, aba = lienzo.height;
    if (ubicables.isNotEmpty) {
      final xs = ubicables.map((p) => p.mapX! * lienzo.width);
      final ys = ubicables.map((p) => p.mapY! * lienzo.height);
      const holgura = 90.0;
      izq = xs.reduce(min) - holgura;
      der = xs.reduce(max) + holgura;
      arr = ys.reduce(min) - holgura;
      // Hueco extra abajo: ahí flota el carrusel.
      aba = ys.reduce(max) + holgura + 120;
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
    final encuadre = _encuadre;
    if (encuadre != null) _volarA(encuadre);
  }

  /// Acerca o aleja sobre el centro de la ventana.
  ///
  /// Es la alternativa al pellizco (WCAG 2.5.7): quien usa una sola mano, un
  /// puntero o el acceso con interruptores no puede hacer el gesto de dos
  /// dedos.
  void _zoom(double factor) {
    final m = _controlador.value;
    final s = _escalaDe(m);
    final x = (_ventana.width / 2 - m.storage[12]) / s;
    final y = (_ventana.height / 2 - m.storage[13]) / s;
    _volarA(_matriz(x, y, s * factor));
  }

  void _seleccionar(int indice, {bool moverCarrusel = true}) {
    setState(() => _actual = indice);
    final poi = widget.pois[indice];
    if (poi.tienePosicionEnMapa) {
      final escala = max(_escalaDe(_controlador.value), 1.5);
      _volarA(
        _matriz(
          poi.mapX! * _lienzo.width,
          poi.mapY! * _lienzo.height,
          escala,
          alturaFoco: .38,
        ),
      );
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

  void _abrir(Poi poi) => abrirPoi(context, ref, poi: poi, pois: widget.pois);

  @override
  Widget build(BuildContext context) {
    final visitados = ref.watch(progresoProvider);
    final abajo = MediaQuery.paddingOf(context).bottom;
    final hechos = widget.pois.where((p) => visitados.contains(p.id)).length;
    final txt = Textos.of(context);
    final escala = MediaQuery.textScalerOf(context);
    // El carrusel crece con el texto: el nombre y la categoría no cabían en
    // 84 dp con la letra al 200 %.
    final altoCarrusel = max(
      84.0,
      24 + escala.scale(17) * 1.3 + 2 + escala.scale(13) * 1.4 + 6,
    );

    final tarjeta = ClipRRect(
      borderRadius: BorderRadius.circular(MedidasUtb.radioTarjeta + 2),
      child: ColoredBox(
        // El render trae su propio fondo blanco hasta los bordes; cualquier
        // otro color dibujaría una costura alrededor del campus.
        color: Colors.white,
        child: Stack(
          children: [
            Positioned.fill(child: _lienzoInteractivo(visitados)),
            Positioned(
              left: 12,
              right: 12 + MedidasUtb.toque + 8,
              top: 12,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _Leyenda(hechos: hechos, total: widget.pois.length),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Column(
                children: [
                  BotonCircular(
                    icono: Icons.zoom_out_map_rounded,
                    etiqueta: txt.verTodoCampus,
                    alTocar: _verTodo,
                  ),
                  const SizedBox(height: 8),
                  BotonCircular(
                    icono: Icons.add_rounded,
                    etiqueta: txt.acercar,
                    alTocar: () => _zoom(1.5),
                  ),
                  const SizedBox(height: 8),
                  BotonCircular(
                    icono: Icons.remove_rounded,
                    etiqueta: txt.alejar,
                    alTocar: () => _zoom(1 / 1.5),
                  ),
                ],
              ),
            ),
            if (widget.pois.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                height: altoCarrusel,
                child: _carrusel(visitados),
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

  Widget _lienzoInteractivo(Set<int> visitados) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = max(
          restricciones.maxWidth * _amplitud,
          restricciones.maxHeight * _relacion,
        );
        final lienzo = Size(ancho, ancho / _relacion);
        _encuadrar(restricciones.biggest, lienzo);

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
                    child: const _ImagenMapa(ruta: _rutaMapa),
                  ),
                ),
                Positioned.fill(child: _marcadores(lienzo, visitados)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Los marcadores escalan al revés que el mapa: en pantalla miden siempre lo
  /// mismo, así que acercarse no los vuelve enormes ni alejarse los esconde.
  Widget _marcadores(Size lienzo, Set<int> visitados) {
    final animar = !sinMovimiento(context);

    return ValueListenableBuilder<Matrix4>(
      valueListenable: _controlador,
      builder: (context, matriz, _) {
        final k = 1 / _escalaDe(matriz).clamp(0.2, 10.0);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final (i, poi) in widget.pois.indexed)
              if (poi.tienePosicionEnMapa)
                Positioned(
                  left: poi.mapX! * lienzo.width - _Marcador.ancho / 2,
                  top: poi.mapY! * lienzo.height - _Marcador.punta,
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

  Widget _carrusel(Set<int> visitados) {
    return PageView.builder(
      controller: _paginas,
      itemCount: widget.pois.length,
      onPageChanged: (i) {
        if (!_paginaProgramada) _seleccionar(i, moverCarrusel: false);
      },
      itemBuilder: (context, i) {
        final poi = widget.pois[i];
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

class _ImagenMapa extends ConsumerWidget {
  const _ImagenMapa({required this.ruta});

  final String ruta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Decodificar a 4096 cuesta unos 38 MB: más de lo que aguanta un
    // teléfono de gama baja. A 2560 sigue nítido con el zoom máximo.
    final local = Image.asset(
      ruta,
      cacheWidth: 2560,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
      // La ilustración es material institucional y no se versiona: en una
      // copia sin ella, el mapa lo dice en vez de quedar en blanco.
      errorBuilder: (context, error, pila) => const _MapaAusente(),
    );
    const blanco = ColoredBox(color: Colors.white);

    // El backend sirve el mapa desde S3 para que el panel pueda cambiarlo.
    // Si no hay URL o falla, se usa la ilustración empaquetada, que es la
    // misma sobre la que se calibraron las coordenadas.
    return ref
        .watch(mapaUrlProvider(Configuracion.lugarPorDefecto))
        .when(
          data: (url) => url == null
              ? local
              : CachedNetworkImage(
                  imageUrl: url,
                  // La URL firmada cambia en cada consulta; el nombre del
                  // objeto en S3 no, salvo que el panel suba otro mapa.
                  cacheKey: Uri.parse(url).replace(query: '').toString(),
                  fit: BoxFit.fill,
                  memCacheWidth: 2560,
                  filterQuality: FilterQuality.medium,
                  placeholder: (_, _) => blanco,
                  errorWidget: (_, _, _) => local,
                ),
          loading: () => blanco,
          error: (_, _) => local,
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
                fontFamily: 'Roboto',
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
                            fontFamily: 'Roboto',
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
  const _Leyenda({required this.hechos, required this.total});

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

import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/poi.dart';
import '../../data/plano_campus.dart';

/// Colores del plano (los mismos de la app móvil, `ColoresPlano`).
abstract final class _C {
  static const tierra = Color(0xFFF2EFE9);
  static const zona = Color(0xFFE0DFDF);
  static const campus = Color(0xFFFFFFE5);
  static const bordeCampus = Color(0xFFD4C59C);
  static const verde = Color(0xFFCDEBB0);
  static const arboles = Color(0xFFADD19E);
  static const agua = Color(0xFFAAD3DF);
  static const parqueadero = Color(0xFFEEEEEE);
  static const bordeParqueadero = Color(0xFFCCCCCC);
  static const cancha = Color(0xFFAAE0CB);
  static const bordeCancha = Color(0xFF88C9AE);
  static const plazoleta = Color(0xFFDDDDE8);
  static const edificio = Color(0xFFD9D0C9);
  static const bordeEdificio = Color(0xFFC4B6AB);
  static const via = Color(0xFFFFFFFF);
  static const bordeVia = Color(0xFFBBBBBB);
  static const viaPrincipal = Color(0xFFFCD6A4);
  static const bordeViaPrincipal = Color(0xFFC99E64);
  static const sendero = Color(0xFFFA8072);
}

/// Mapa del campus con los POI como pines.
///
/// - [pois]: los que se dibujan (solo los que tienen lat/lng dentro del plano).
/// - [seleccionado]: id del POI resaltado.
/// - [alColocar]: si no es nulo, tocar o arrastrar sobre el mapa devuelve la
///   posición (lat, lng) elegida. Con nulo el mapa es de solo lectura.
/// - [alTocarPoi]: se llama al tocar un pin.
class MapaCampus extends StatefulWidget {
  const MapaCampus({
    super.key,
    required this.pois,
    this.seleccionado,
    this.pinNuevo,
    this.alColocar,
    this.alTocarPoi,
    this.alto = 340,
  });

  final List<Poi> pois;
  final int? seleccionado;

  /// Pin extra (por ejemplo el del POI que se está creando), en (lat, lng).
  final (double, double)? pinNuevo;
  final void Function(double lat, double lng)? alColocar;
  final ValueChanged<Poi>? alTocarPoi;
  final double alto;

  @override
  State<MapaCampus> createState() => _MapaCampusState();
}

class _MapaCampusState extends State<MapaCampus> {
  late final Future<PlanoCampus> _plano = PlanoCampus.cargar();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<PlanoCampus>(
          future: _plano,
          builder: (context, snap) {
            if (snap.hasError) {
              return SizedBox(
                height: widget.alto,
                child: const Center(
                  child: Text(
                    'No se pudo cargar el plano del campus '
                    '(assets/campus_osm.geojson).',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }
            if (!snap.hasData) {
              return SizedBox(
                height: widget.alto,
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            return _lienzo(snap.data!);
          },
        ),
        const SizedBox(height: 6),
        const Text(
          '© colaboradores de OpenStreetMap (ODbL)',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _lienzo(PlanoCampus plano) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // El lienzo respeta la proporción del plano; se centra en el espacio.
        var ancho = constraints.maxWidth;
        var alto = ancho / plano.proporcion;
        if (alto > widget.alto) {
          alto = widget.alto;
          ancho = alto * plano.proporcion;
        }

        void colocar(Offset p) {
          final f = widget.alColocar;
          if (f == null) return;
          final n = Offset(
            (p.dx / ancho).clamp(0.0, 1.0).toDouble(),
            (p.dy / alto).clamp(0.0, 1.0).toDouble(),
          );
          final (lat, lng) = plano.aLatLng(n);
          f(lat, lng);
        }

        final pines = _pinesDelMapa(
          plano: plano,
          pois: widget.pois,
          seleccionado: widget.seleccionado,
          pin: widget.pinNuevo,
          ancho: ancho,
          alto: alto,
          alTocarPoi: widget.alTocarPoi,
        );

        return Center(
          child: SizedBox(
            width: ancho,
            height: alto,
            child: Stack(
              children: [
                GestureDetector(
                  onTapDown: widget.alColocar == null
                      ? null
                      : (d) => colocar(d.localPosition),
                  onPanUpdate: widget.alColocar == null
                      ? null
                      : (d) => colocar(d.localPosition),
                  child: MouseRegion(
                    cursor: widget.alColocar == null
                        ? MouseCursor.defer
                        : SystemMouseCursors.precise,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: ancho,
                        height: alto,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(painter: _PintorPlano(plano)),
                            ),
                            ...pines,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _BotonAmpliar(onPressed: () => _ampliar(plano)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Abre el mapa en grande, con zoom y desplazamiento. Mover o acercar la
  /// vista no cambia las coordenadas: solo un clic coloca el pin.
  void _ampliar(PlanoCampus plano) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar mapa ampliado',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) => _MapaAmpliado(
        plano: plano,
        pois: widget.pois,
        seleccionado: widget.seleccionado,
        pinInicial: widget.pinNuevo,
        alColocar: widget.alColocar,
        alTocarPoi: widget.alTocarPoi,
      ),
      // Aparece con un fundido y un leve acercamiento; al cerrar, al revés.
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curva = CurveTween(curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: animation.drive(curva),
          child: ScaleTransition(
            scale: animation.drive(
              Tween<double>(begin: 0.96, end: 1).chain(curva),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Pines del mapa (los POI y el pin nuevo). [escala] es el zoom actual de la
/// vista: se usa para que los pines mantengan su tamaño en pantalla al acercar.
List<Widget> _pinesDelMapa({
  required PlanoCampus plano,
  required List<Poi> pois,
  required int? seleccionado,
  required (double, double)? pin,
  required double ancho,
  required double alto,
  double escala = 1,
  ValueChanged<Poi>? alTocarPoi,
  Object? claveAparicion,
}) {
  final pines = <Widget>[];
  for (final poi in pois) {
    if (poi.lat == null || poi.lng == null) continue;
    final n = plano.normalizar(poi.lat!, poi.lng!);
    if (n == null) continue;
    final activo = poi.id == seleccionado;
    final color = AppColors.categoria(poi.categoria);
    final tam = (activo ? 18.0 : 12.0) / escala;
    pines.add(
      Positioned(
        left: n.dx * ancho - tam / 2,
        top: n.dy * alto - tam / 2,
        child: Tooltip(
          message: poi.nombre,
          child: GestureDetector(
            onTap: alTocarPoi == null ? null : () => alTocarPoi(poi),
            child: Container(
              width: tam,
              height: tam,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: (activo ? 3.0 : 2.0) / escala,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x66000000),
                    blurRadius: 3 / escala,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  final nuevo = pin;
  if (nuevo != null) {
    final n = plano.normalizar(nuevo.$1, nuevo.$2);
    if (n != null) {
      // La punta del glifo `location_on` queda a 22/24 de su alto, no en el
      // borde inferior: anclar el borde dejaba la punta ~3 px (unos 4 m
      // del campus) al norte de la coordenada.
      final tamPin = 32.0 / escala;
      Widget icono = Icon(
        Icons.location_on,
        size: tamPin,
        color: AppColors.danger,
      );
      if (claveAparicion != null) {
        // Al colocar el pin, aparece con un pequeño rebote desde la punta.
        icono = TweenAnimationBuilder<double>(
          key: ValueKey(claveAparicion),
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          child: icono,
          builder: (context, v, hijo) => Opacity(
            opacity: v.clamp(0.0, 1.0).toDouble(),
            child: Transform.scale(
              scale: 0.5 + 0.5 * v,
              alignment: const Alignment(0, 0.8333),
              child: hijo,
            ),
          ),
        );
      }
      pines.add(
        Positioned(
          left: n.dx * ancho - tamPin / 2,
          top: n.dy * alto - tamPin * 22 / 24,
          child: icono,
        ),
      );
    }
  }
  return pines;
}

/// Fondo y borde de los controles que flotan sobre el mapa.
BoxDecoration _decoracionFlotante() => BoxDecoration(
  color: AppColors.card.withValues(alpha: 0.94),
  borderRadius: BorderRadius.circular(10),
  border: Border.all(color: AppColors.border),
  boxShadow: const [
    BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2)),
  ],
);

/// Botón «Ampliar» que va sobre una esquina del mapa pequeño.
class _BotonAmpliar extends StatelessWidget {
  const _BotonAmpliar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ampliar mapa',
      child: DecoratedBox(
        decoration: _decoracionFlotante(),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onPressed,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_full, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Ampliar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

/// Píldora con una pista de uso («Rueda: acercar»).
class _Pista extends StatelessWidget {
  const _Pista(this.icono, this.texto);

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Caja de solo lectura con una coordenada, al estilo de los campos del panel.
class _CampoCoordenada extends StatelessWidget {
  const _CampoCoordenada(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Nivel de zoom actual («×2.5»), arriba a la izquierda del mapa ampliado.
class _NivelZoom extends StatelessWidget {
  const _NivelZoom({required this.escala});

  final double escala;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _decoracionFlotante(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.zoom_in, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              '×${escala.toStringAsFixed(1)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Acercar, alejar, centrar en el pin y restablecer, abajo a la derecha.
class _ControlesZoom extends StatelessWidget {
  const _ControlesZoom({
    required this.puedeAcercar,
    required this.puedeAlejar,
    required this.puedeCentrar,
    required this.onAcercar,
    required this.onAlejar,
    required this.onCentrar,
    required this.onRestablecer,
  });

  final bool puedeAcercar;
  final bool puedeAlejar;
  final bool puedeCentrar;
  final VoidCallback onAcercar;
  final VoidCallback onAlejar;
  final VoidCallback onCentrar;
  final VoidCallback onRestablecer;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _decoracionFlotante(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Material(
          type: MaterialType.transparency,
          child: SizedBox(
            width: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BotonControl(
                  icono: Icons.add,
                  mensaje: 'Acercar',
                  onTap: puedeAcercar ? onAcercar : null,
                ),
                const Divider(),
                _BotonControl(
                  icono: Icons.remove,
                  mensaje: 'Alejar',
                  onTap: puedeAlejar ? onAlejar : null,
                ),
                const Divider(),
                _BotonControl(
                  icono: Icons.my_location,
                  mensaje: 'Centrar en el pin',
                  onTap: puedeCentrar ? onCentrar : null,
                ),
                const Divider(),
                _BotonControl(
                  icono: Icons.zoom_out_map,
                  mensaje: 'Restablecer vista',
                  onTap: onRestablecer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BotonControl extends StatelessWidget {
  const _BotonControl({
    required this.icono,
    required this.mensaje,
    required this.onTap,
  });

  final IconData icono;
  final String mensaje;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: mensaje,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(
              end: onTap == null ? Colors.white30 : Colors.white,
            ),
            duration: const Duration(milliseconds: 160),
            builder: (context, color, _) => Icon(icono, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}

/// Mapa en grande: rueda del ratón o pellizco para acercar, arrastrar para
/// mover la vista y un clic para colocar el pin. Mover la vista nunca cambia
/// las coordenadas.
class _MapaAmpliado extends StatefulWidget {
  const _MapaAmpliado({
    required this.plano,
    required this.pois,
    required this.seleccionado,
    required this.pinInicial,
    required this.alColocar,
    required this.alTocarPoi,
  });

  final PlanoCampus plano;
  final List<Poi> pois;
  final int? seleccionado;
  final (double, double)? pinInicial;
  final void Function(double lat, double lng)? alColocar;
  final ValueChanged<Poi>? alTocarPoi;

  @override
  State<_MapaAmpliado> createState() => _MapaAmpliadoState();
}

class _MapaAmpliadoState extends State<_MapaAmpliado>
    with SingleTickerProviderStateMixin {
  static const _escalaMaxima = 12.0;

  final _controlador = TransformationController();
  late final AnimationController _anim = AnimationController(vsync: this);
  CurvedAnimation? _curvaActual;
  VoidCallback? _escuchaActual;

  /// Zoom al que llega la animación en curso (para encadenar pulsaciones o
  /// giros de la rueda sin que la vista se frene entre una y otra).
  double _escalaObjetivo = 1;

  (double, double)? _pin;
  // Cuántas veces se ha colocado el pin; hace que el pin rebote solo al
  // colocarlo y no al acercar o mover la vista.
  int _colocaciones = 0;
  Size _area = Size.zero;

  @override
  void initState() {
    super.initState();
    _pin = widget.pinInicial;
  }

  @override
  void dispose() {
    _detenerAnimacion();
    _anim.dispose();
    _controlador.dispose();
    super.dispose();
  }

  void _colocar(Offset p) {
    final f = widget.alColocar;
    if (f == null || _area.isEmpty) return;
    final n = Offset(
      (p.dx / _area.width).clamp(0.0, 1.0).toDouble(),
      (p.dy / _area.height).clamp(0.0, 1.0).toDouble(),
    );
    final (lat, lng) = widget.plano.aLatLng(n);
    setState(() {
      _pin = (lat, lng);
      _colocaciones++;
    });
    f(lat, lng);
  }

  /// Matriz de zoom [s] con la traslación (tx, ty) sin salirse del plano.
  Matrix4 _matriz(double s, double tx, double ty) {
    final x = tx.clamp(-_area.width * (s - 1), 0.0).toDouble();
    final y = ty.clamp(-_area.height * (s - 1), 0.0).toDouble();
    return Matrix4.translationValues(x, y, 0) *
        Matrix4.diagonal3Values(s, s, 1);
  }

  void _detenerAnimacion() {
    _anim.stop();
    final curva = _curvaActual;
    final escucha = _escuchaActual;
    if (curva != null) {
      if (escucha != null) curva.removeListener(escucha);
      curva.dispose();
    }
    _curvaActual = null;
    _escuchaActual = null;
  }

  /// Anima la vista hasta el zoom [s1], dejando el punto [p] del plano (en
  /// coordenadas del lienzo) en la posición de pantalla [q1].
  ///
  /// El zoom avanza de forma geométrica, que es como se percibe uniforme, y
  /// el punto se desliza en línea recta: acercar desde la rueda mantiene el
  /// punto bajo el cursor, y centrar lo lleva suavemente al medio.
  void _animarVista({
    required double s1,
    required Offset p,
    required Offset q1,
    required Duration duracion,
    required Curve curva,
  }) {
    final m0 = _controlador.value;
    final s0 = m0.getMaxScaleOnAxis();
    final q0 = Offset(s0 * p.dx + m0.storage[12], s0 * p.dy + m0.storage[13]);
    _detenerAnimacion();
    _escalaObjetivo = s1;
    final curvada = CurvedAnimation(parent: _anim, curve: curva);
    void escuchar() {
      final k = curvada.value;
      final s = s0 * pow(s1 / s0, k).toDouble();
      final q = Offset.lerp(q0, q1, k)!;
      _controlador.value = _matriz(s, q.dx - s * p.dx, q.dy - s * p.dy);
    }

    _curvaActual = curvada;
    _escuchaActual = escuchar;
    curvada.addListener(escuchar);
    _anim.duration = duracion;
    _anim.forward(from: 0);
  }

  /// Acerca o aleja desde el centro de la vista (botones + y −).
  void _zoomBotones(double factor) {
    final m = _controlador.value;
    final actual = m.getMaxScaleOnAxis();
    final base = _anim.isAnimating ? _escalaObjetivo : actual;
    final s1 = (base * factor).clamp(1.0, _escalaMaxima).toDouble();
    if ((s1 - base).abs() < 0.001) return;
    final c = Offset(_area.width / 2, _area.height / 2);
    final p = Offset(
      (c.dx - m.storage[12]) / actual,
      (c.dy - m.storage[13]) / actual,
    );
    _animarVista(
      s1: s1,
      p: p,
      q1: c,
      duracion: const Duration(milliseconds: 220),
      curva: Curves.easeOutCubic,
    );
  }

  /// Rueda del ratón: acerca suavemente, manteniendo bajo el cursor el punto
  /// que se está mirando.
  void _rueda(PointerScrollEvent evento) {
    final m = _controlador.value;
    final actual = m.getMaxScaleOnAxis();
    final base = _anim.isAnimating ? _escalaObjetivo : actual;
    final factor = exp(-evento.scrollDelta.dy / 500).clamp(0.5, 2.0).toDouble();
    final s1 = (base * factor).clamp(1.0, _escalaMaxima).toDouble();
    if ((s1 - base).abs() < 0.001) return;
    final p = evento.localPosition;
    final q = Offset(
      actual * p.dx + m.storage[12],
      actual * p.dy + m.storage[13],
    );
    _animarVista(
      s1: s1,
      p: p,
      q1: q,
      duracion: const Duration(milliseconds: 180),
      curva: Curves.easeOutCubic,
    );
  }

  /// Acerca la vista y lleva el pin al centro.
  void _centrarEnPin() {
    final pin = _pin;
    if (pin == null) return;
    final n = widget.plano.normalizar(pin.$1, pin.$2);
    if (n == null) return;
    final actual = _controlador.value.getMaxScaleOnAxis();
    final base = _anim.isAnimating ? _escalaObjetivo : actual;
    _animarVista(
      s1: base < 4 ? 4.0 : base,
      p: Offset(n.dx * _area.width, n.dy * _area.height),
      q1: Offset(_area.width / 2, _area.height / 2),
      duracion: const Duration(milliseconds: 380),
      curva: Curves.easeInOutCubic,
    );
  }

  /// Vuelve a la vista completa del plano.
  void _restablecer() {
    final m = _controlador.value;
    final actual = m.getMaxScaleOnAxis();
    final c = Offset(_area.width / 2, _area.height / 2);
    final p = Offset(
      (c.dx - m.storage[12]) / actual,
      (c.dy - m.storage[13]) / actual,
    );
    _animarVista(
      s1: 1,
      p: p,
      q1: p,
      duracion: const Duration(milliseconds: 340),
      curva: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final editable = widget.alColocar != null;
    final pin = _pin;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_location_alt_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ubicación en el mapa',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          editable
                              ? 'Acerca el mapa para ubicar el pin con más '
                                    'precisión.'
                              : 'Acerca el mapa para recorrer el campus.',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const _Pista(Icons.mouse_outlined, 'Rueda: acercar'),
                  const _Pista(Icons.pan_tool_alt_outlined, 'Arrastrar: mover'),
                  if (editable)
                    const _Pista(Icons.touch_app_outlined, 'Clic: colocar pin'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      var ancho = c.maxWidth;
                      var alto = ancho / widget.plano.proporcion;
                      if (alto > c.maxHeight) {
                        alto = c.maxHeight;
                        ancho = alto * widget.plano.proporcion;
                      }
                      _area = Size(ancho, alto);
                      return Center(
                        child: SizedBox(
                          width: ancho,
                          height: alto,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: InteractiveViewer(
                                    transformationController: _controlador,
                                    minScale: 1,
                                    maxScale: _escalaMaxima,
                                    // Si el usuario toma el control, la
                                    // animación en curso se detiene.
                                    onInteractionStart: (_) =>
                                        _detenerAnimacion(),
                                    child: _lienzo(ancho, alto),
                                  ),
                                ),
                                Positioned(
                                  left: 10,
                                  top: 10,
                                  child: AnimatedBuilder(
                                    animation: _controlador,
                                    builder: (context, _) => _NivelZoom(
                                      escala: _controlador.value
                                          .getMaxScaleOnAxis(),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 10,
                                  bottom: 10,
                                  child: AnimatedBuilder(
                                    animation: _controlador,
                                    builder: (context, _) {
                                      final s = _controlador.value
                                          .getMaxScaleOnAxis();
                                      return _ControlesZoom(
                                        puedeAcercar: s < _escalaMaxima - 0.01,
                                        puedeAlejar: s > 1.01,
                                        puedeCentrar: pin != null,
                                        onAcercar: () => _zoomBotones(1.5),
                                        onAlejar: () => _zoomBotones(1 / 1.5),
                                        onCentrar: _centrarEnPin,
                                        onRestablecer: _restablecer,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _CampoCoordenada(
                      'Latitud',
                      pin == null ? '—' : pin.$1.toStringAsFixed(7),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CampoCoordenada(
                      'Longitud',
                      pin == null ? '—' : pin.$2.toStringAsFixed(7),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Listo'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '© colaboradores de OpenStreetMap (ODbL)',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lienzo(double ancho, double alto) {
    return Listener(
      // La rueda se atiende aquí (en vez de en el InteractiveViewer) para que
      // el zoom sea gradual y no salte en pasos grandes.
      onPointerSignal: (evento) {
        if (evento is PointerScrollEvent) {
          GestureBinding.instance.pointerSignalResolver.register(
            evento,
            (e) => _rueda(e as PointerScrollEvent),
          );
        }
      },
      child: GestureDetector(
        // Solo un toque coloca el pin; arrastrar mueve la vista.
        onTapUp: widget.alColocar == null
            ? null
            : (d) => _colocar(d.localPosition),
        child: MouseRegion(
          cursor: widget.alColocar == null
              ? SystemMouseCursors.grab
              : SystemMouseCursors.precise,
          child: SizedBox(
            width: ancho,
            height: alto,
            child: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(painter: _PintorPlano(widget.plano)),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _controlador,
                    builder: (context, _) => Stack(
                      children: _pinesDelMapa(
                        plano: widget.plano,
                        pois: widget.pois,
                        seleccionado: widget.seleccionado,
                        pin: _pin,
                        ancho: ancho,
                        alto: alto,
                        escala: _controlador.value.getMaxScaleOnAxis(),
                        alTocarPoi: widget.alTocarPoi,
                        claveAparicion: _colocaciones == 0
                            ? null
                            : _colocaciones,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PintorPlano extends CustomPainter {
  const _PintorPlano(this.plano);

  final PlanoCampus plano;

  @override
  void paint(Canvas canvas, Size size) {
    final pxPorMetro = size.width / plano.anchoMetros;
    double ancho(double metros, {double minimo = 1}) =>
        max(metros * pxPorMetro, minimo);

    Path trazo(RasgoPlano r) => Path()
      ..addPolygon([
        for (final p in r.puntos) Offset(p.dx * size.width, p.dy * size.height),
      ], r.esArea);

    void areas(
      ClaseRasgo clase,
      Color relleno, {
      Color? borde,
      double grosor = 1,
    }) {
      final pintura = Paint()..color = relleno;
      final contorno = borde == null
          ? null
          : (Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = grosor
              ..strokeJoin = StrokeJoin.round
              ..color = borde);
      for (final r in plano.rasgos[clase]!) {
        if (!r.esArea) continue;
        final camino = trazo(r);
        canvas.drawPath(camino, pintura);
        if (contorno != null) canvas.drawPath(camino, contorno);
      }
    }

    void lineas(
      ClaseRasgo clase,
      Color color,
      double grosor, {
      double? trazoDe,
      double? huecoDe,
      StrokeCap punta = StrokeCap.round,
    }) {
      final pintura = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor
        ..strokeCap = punta
        ..strokeJoin = StrokeJoin.round
        ..color = color;
      for (final r in plano.rasgos[clase]!) {
        if (r.esArea) continue;
        final camino = trazo(r);
        if (trazoDe == null || huecoDe == null) {
          canvas.drawPath(camino, pintura);
          continue;
        }
        for (final m in camino.computeMetrics()) {
          for (var d = 0.0; d < m.length; d += trazoDe + huecoDe) {
            canvas.drawPath(m.extractPath(d, d + trazoDe), pintura);
          }
        }
      }
    }

    canvas.drawRect(Offset.zero & size, Paint()..color = _C.tierra);
    areas(ClaseRasgo.zona, _C.zona);
    areas(
      ClaseRasgo.campus,
      _C.campus,
      borde: _C.bordeCampus,
      grosor: ancho(1.5),
    );
    areas(ClaseRasgo.verde, _C.verde);
    areas(ClaseRasgo.arboles, _C.arboles);
    areas(ClaseRasgo.agua, _C.agua);
    areas(ClaseRasgo.parqueadero, _C.parqueadero, borde: _C.bordeParqueadero);
    areas(ClaseRasgo.cancha, _C.cancha, borde: _C.bordeCancha);
    areas(ClaseRasgo.plazoleta, _C.plazoleta);

    lineas(
      ClaseRasgo.viaPrincipal,
      _C.bordeViaPrincipal,
      ancho(8 + 2 * 1.2, minimo: 3),
    );
    lineas(ClaseRasgo.via, _C.bordeVia, ancho(5 + 2 * 1.2, minimo: 3));
    lineas(ClaseRasgo.viaPrincipal, _C.viaPrincipal, ancho(8, minimo: 2));
    lineas(ClaseRasgo.via, _C.via, ancho(5, minimo: 2));
    lineas(
      ClaseRasgo.sendero,
      _C.sendero,
      ancho(1.4),
      trazoDe: ancho(2.5, minimo: 3),
      huecoDe: ancho(1.5, minimo: 2),
    );
    lineas(
      ClaseRasgo.escalera,
      _C.sendero,
      ancho(2.6, minimo: 3),
      trazoDe: ancho(0.6),
      huecoDe: ancho(0.5),
      punta: StrokeCap.butt,
    );
    areas(ClaseRasgo.edificio, _C.edificio, borde: _C.bordeEdificio);
  }

  @override
  bool shouldRepaint(_PintorPlano old) => old.plano != plano;
}

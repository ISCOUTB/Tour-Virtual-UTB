import 'dart:math';

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
    return LayoutBuilder(builder: (context, constraints) {
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
        final n = Offset((p.dx / ancho).clamp(0.0, 1.0).toDouble(),
            (p.dy / alto).clamp(0.0, 1.0).toDouble());
        final (lat, lng) = plano.aLatLng(n);
        f(lat, lng);
      }

      final pines = <Widget>[];
      for (final poi in widget.pois) {
        if (poi.lat == null || poi.lng == null) continue;
        final n = plano.normalizar(poi.lat!, poi.lng!);
        if (n == null) continue;
        final activo = poi.id == widget.seleccionado;
        final color = AppColors.categoria(poi.categoria);
        final tam = activo ? 18.0 : 12.0;
        pines.add(Positioned(
          left: n.dx * ancho - tam / 2,
          top: n.dy * alto - tam / 2,
          child: Tooltip(
            message: poi.nombre,
            child: GestureDetector(
              onTap: widget.alTocarPoi == null
                  ? null
                  : () => widget.alTocarPoi!(poi),
              child: Container(
                width: tam,
                height: tam,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white, width: activo ? 3 : 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x66000000), blurRadius: 3),
                  ],
                ),
              ),
            ),
          ),
        ));
      }
      final nuevo = widget.pinNuevo;
      if (nuevo != null) {
        final n = plano.normalizar(nuevo.$1, nuevo.$2);
        if (n != null) {
          pines.add(Positioned(
            left: n.dx * ancho - 16,
            top: n.dy * alto - 32,
            child: const Icon(Icons.location_on,
                size: 32, color: AppColors.danger),
          ));
        }
      }

      return Center(
        child: GestureDetector(
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
      );
    });
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

    void areas(ClaseRasgo clase, Color relleno,
        {Color? borde, double grosor = 1}) {
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

    void lineas(ClaseRasgo clase, Color color, double grosor,
        {double? trazoDe, double? huecoDe, StrokeCap punta = StrokeCap.round}) {
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
    areas(ClaseRasgo.campus, _C.campus,
        borde: _C.bordeCampus, grosor: ancho(1.5));
    areas(ClaseRasgo.verde, _C.verde);
    areas(ClaseRasgo.arboles, _C.arboles);
    areas(ClaseRasgo.agua, _C.agua);
    areas(ClaseRasgo.parqueadero, _C.parqueadero, borde: _C.bordeParqueadero);
    areas(ClaseRasgo.cancha, _C.cancha, borde: _C.bordeCancha);
    areas(ClaseRasgo.plazoleta, _C.plazoleta);

    lineas(ClaseRasgo.viaPrincipal, _C.bordeViaPrincipal,
        ancho(8 + 2 * 1.2, minimo: 3));
    lineas(ClaseRasgo.via, _C.bordeVia, ancho(5 + 2 * 1.2, minimo: 3));
    lineas(ClaseRasgo.viaPrincipal, _C.viaPrincipal, ancho(8, minimo: 2));
    lineas(ClaseRasgo.via, _C.via, ancho(5, minimo: 2));
    lineas(ClaseRasgo.sendero, _C.sendero, ancho(1.4),
        trazoDe: ancho(2.5, minimo: 3), huecoDe: ancho(1.5, minimo: 2));
    lineas(ClaseRasgo.escalera, _C.sendero, ancho(2.6, minimo: 3),
        trazoDe: ancho(0.6),
        huecoDe: ancho(0.5),
        punta: StrokeCap.butt);
    areas(ClaseRasgo.edificio, _C.edificio, borde: _C.bordeEdificio);
  }

  @override
  bool shouldRepaint(_PintorPlano old) => old.plano != plano;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../datos/plano_campus.dart';
import '../../navegacion/geo.dart';
import '../../nucleo/tema.dart';
import '../inicio/pintor_plano.dart';

/// El plano del campus encuadrado en lo que queda de ruta y en la persona:
/// se acerca solo a medida que se llega.
///
/// Dibuja la ruta pendiente, la puerta de destino y «estás aquí»: un punto
/// azul con su círculo de precisión y un cono hacia donde mira el teléfono
/// (fase 1 del plan de realidad aumentada).
class PlanoRuta extends StatelessWidget {
  const PlanoRuta({
    super.key,
    required this.plano,
    required this.ruta,
    required this.destino,
    this.posicion,
    this.precision,
    this.rumbo,
  });

  final PlanoCampus plano;

  /// Lo que falta de la ruta, de la persona a la puerta.
  final List<PuntoGeo> ruta;
  final PuntoGeo destino;
  final PuntoGeo? posicion;

  /// Radio de confianza del GPS, en metros.
  final double? precision;

  /// Hacia dónde mira el teléfono (grados desde el norte geográfico).
  final double? rumbo;

  @override
  Widget build(BuildContext context) {
    final altoContraste = PaletaUtb.de(context).altoContraste;
    return ClipRRect(
      borderRadius: BorderRadius.circular(MedidasUtb.radioTarjeta),
      child: ColoredBox(
        color: ColoresPlano.tierra,
        child: CustomPaint(
          size: Size.infinite,
          painter: _PintorRuta(
            plano: plano,
            pintorPlano: PintorPlano(
              plano: plano,
              altoContraste: altoContraste,
            ),
            ruta: ruta,
            destino: destino,
            posicion: posicion,
            precision: precision,
            rumbo: rumbo,
          ),
        ),
      ),
    );
  }
}

class _PintorRuta extends CustomPainter {
  _PintorRuta({
    required this.plano,
    required this.pintorPlano,
    required this.ruta,
    required this.destino,
    required this.posicion,
    required this.precision,
    required this.rumbo,
  });

  final PlanoCampus plano;
  final PintorPlano pintorPlano;
  final List<PuntoGeo> ruta;
  final PuntoGeo destino;
  final PuntoGeo? posicion;
  final double? precision;
  final double? rumbo;

  /// Lado del lienzo del plano, antes de encuadrar.
  static const _anchoBase = 1000.0;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Size(_anchoBase, _anchoBase / plano.proporcion);
    Offset aLienzo(PuntoGeo p) {
      // Sin recortar a la caja: un punto fuera del plano igual se dibuja.
      final x = (p.lng - plano.oeste) / (plano.este - plano.oeste);
      final y = (plano.norte - p.lat) / (plano.norte - plano.sur);
      return Offset(x * base.width, y * base.height);
    }

    final pxPorMetro = base.width / plano.anchoMetros;
    final puntos = [
      if (posicion != null) aLienzo(posicion!),
      for (final p in ruta) aLienzo(p),
      aLienzo(destino),
    ];

    // Encuadre: la ruta pendiente y la persona, con 25 m de margen y al menos
    // 90 m de lado, para no acercarse tanto que se pierda el contexto.
    var izq = puntos.map((p) => p.dx).reduce(math.min);
    var der = puntos.map((p) => p.dx).reduce(math.max);
    var arr = puntos.map((p) => p.dy).reduce(math.min);
    var aba = puntos.map((p) => p.dy).reduce(math.max);
    final margen = 25 * pxPorMetro;
    final minimo = 90 * pxPorMetro;
    final cx = (izq + der) / 2, cy = (arr + aba) / 2;
    final ancho = math.max(der - izq + 2 * margen, minimo);
    final alto = math.max(aba - arr + 2 * margen, minimo);
    izq = cx - ancho / 2;
    arr = cy - alto / 2;
    final escala = math.min(size.width / ancho, size.height / alto);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(escala);
    canvas.translate(-cx, -cy);
    pintorPlano.paint(canvas, base);

    // Grosores constantes en pantalla, sin importar el encuadre.
    double dp(double valor) => valor / escala;

    // Ruta: contorno oscuro y trazo azul, para que se lea sobre cualquier
    // fondo del plano.
    if (ruta.length >= 2 || posicion != null) {
      final camino = Path();
      final inicio = posicion != null
          ? aLienzo(posicion!)
          : aLienzo(ruta.first);
      camino.moveTo(inicio.dx, inicio.dy);
      for (final p in ruta) {
        final o = aLienzo(p);
        camino.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        camino,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = dp(9)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = ColoresUtb.cabeceraAbajo,
      );
      canvas.drawPath(
        camino,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = dp(5.5)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = ColoresUtb.azul,
      );
    }

    // Puerta de destino.
    final puerta = aLienzo(destino);
    canvas.drawCircle(puerta, dp(11), Paint()..color = Colors.white);
    canvas.drawCircle(puerta, dp(8), Paint()..color = ColoresUtb.verde);

    // Estás aquí: precisión, cono y punto.
    if (posicion != null) {
      final yo = aLienzo(posicion!);
      final radio = (precision ?? 0) * pxPorMetro;
      if (radio > 0) {
        canvas.drawCircle(
          yo,
          radio,
          Paint()..color = ColoresUtb.azul.withValues(alpha: 0.16),
        );
        canvas.drawCircle(
          yo,
          radio,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = dp(1.2)
            ..color = ColoresUtb.azul.withValues(alpha: 0.5),
        );
      }
      if (rumbo != null) {
        // El norte del plano es arriba: el rumbo se dibuja tal cual.
        final angulo = (rumbo! - 90) * math.pi / 180;
        const abertura = 0.55;
        final largo = dp(46);
        final cono = Path()
          ..moveTo(yo.dx, yo.dy)
          ..arcTo(
            Rect.fromCircle(center: yo, radius: largo),
            angulo - abertura / 2,
            abertura,
            false,
          )
          ..close();
        canvas.drawPath(
          cono,
          Paint()
            ..shader = RadialGradient(
              colors: [
                ColoresUtb.azul.withValues(alpha: 0.55),
                ColoresUtb.azul.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: yo, radius: largo)),
        );
      }
      canvas.drawCircle(yo, dp(10), Paint()..color = Colors.white);
      canvas.drawCircle(yo, dp(7), Paint()..color = ColoresUtb.azul);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PintorRuta old) =>
      old.posicion != posicion ||
      old.rumbo != rumbo ||
      old.precision != precision ||
      old.ruta != ruta ||
      old.destino != destino ||
      old.plano != plano;
}

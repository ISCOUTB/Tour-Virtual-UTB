import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../nucleo/movimiento.dart';
import '../../nucleo/tema.dart';

/// Anillo de avance de la app UTB («Promedio acumulado», «Avance del
/// programa»): trazo grueso de puntas redondas sobre una pista del mismo tono.
///
/// Se llena desde cero al aparecer y anima cada cambio de valor.
class AnilloProgreso extends StatelessWidget {
  const AnilloProgreso({
    super.key,
    required this.valor,
    this.tamano = 76,
    this.grosor = 8,
    this.color = ColoresUtb.azulClaro,
    this.colorPista,
    this.child,
  });

  /// Entre 0 y 1.
  final double valor;
  final double tamano;
  final double grosor;
  final Color color;
  final Color? colorPista;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final destino = valor.isFinite ? valor.clamp(0.0, 1.0) : 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: destino),
      duration: sinMovimiento(context) ? Duration.zero : Movimiento.escena,
      curve: Movimiento.salidaFuerte,
      builder: (context, v, hijo) => CustomPaint(
        painter: _PintorAnillo(
          valor: v,
          grosor: grosor,
          color: color,
          pista: colorPista ?? color.withValues(alpha: 0.18),
        ),
        child: hijo,
      ),
      child: SizedBox.square(
        dimension: tamano,
        child: Center(child: child),
      ),
    );
  }
}

class _PintorAnillo extends CustomPainter {
  const _PintorAnillo({
    required this.valor,
    required this.grosor,
    required this.color,
    required this.pista,
  });

  final double valor;
  final double grosor;
  final Color color;
  final Color pista;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - grosor) / 2,
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, base..color = pista);
    if (valor <= 0) return;

    // El arranque del trazo es más claro, como en los anillos de la Agenda.
    final claro = Color.lerp(color, Colors.white, 0.28)!;
    base
      ..color = color
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [claro, color, color],
        stops: const [0, 0.55, 1],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * valor, false, base);
  }

  @override
  bool shouldRepaint(_PintorAnillo old) =>
      old.valor != valor ||
      old.color != color ||
      old.grosor != grosor ||
      old.pista != pista;
}

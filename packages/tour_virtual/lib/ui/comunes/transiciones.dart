import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../nucleo/movimiento.dart';

/// Revelación circular del arranque al módulo, la de la app UTB: un círculo
/// con aro de luz crece desde el centro y deja ver la pantalla nueva, que se
/// aleja un poco mientras aparece.
Widget revelacionCircular(
  BuildContext context,
  Animation<double> animacion,
  Animation<double> secundaria,
  Widget hijo,
) {
  if (sinMovimiento(context)) {
    return FadeTransition(opacity: animacion, child: hijo);
  }
  return _Revelacion(animacion: animacion, child: hijo);
}

class _Revelacion extends AnimatedWidget {
  const _Revelacion({required Animation<double> animacion, required this.child})
    : super(listenable: animacion);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final v = (listenable as Animation<double>).value;
    if (v >= 1) return child;
    final t = Curves.easeInOutCubic.transform(v);

    return LayoutBuilder(
      builder: (context, caja) {
        final tamano = caja.biggest;
        final centro = tamano.center(Offset.zero);
        final maximo =
            math.sqrt(
                  tamano.width * tamano.width + tamano.height * tamano.height,
                ) /
                2 +
            8;
        final radio = maximo * t;

        return Stack(
          fit: StackFit.expand,
          children: [
            ClipPath(
              clipper: _Circulo(centro, radio),
              child: Transform.scale(
                scale: lerpDouble(1.22, 1, t)!,
                child: child,
              ),
            ),
            IgnorePointer(
              child: CustomPaint(
                // Pleno casi todo el recorrido; se apaga en el último cuarto.
                painter: _Aro(centro, radio, ((1 - t) / 0.25).clamp(0.0, 1.0)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Circulo extends CustomClipper<Path> {
  const _Circulo(this.centro, this.radio);

  final Offset centro;
  final double radio;

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: centro, radius: radio));

  @override
  bool shouldReclip(_Circulo old) => old.radio != radio || old.centro != centro;
}

class _Aro extends CustomPainter {
  const _Aro(this.centro, this.radio, this.intensidad);

  final Offset centro;
  final double radio;
  final double intensidad;

  @override
  void paint(Canvas canvas, Size size) {
    if (radio <= 0 || intensidad <= 0) return;
    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..color = const Color(0xFF9FC0FF).withValues(alpha: 0.6 * intensidad)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: intensidad),
    );
  }

  @override
  bool shouldRepaint(_Aro old) =>
      old.radio != radio || old.intensidad != intensidad;
}

/// Entrada al visor 360: la escena llega desde un poco más cerca y se asienta,
/// como dar un paso hacia dentro.
Widget entradaInmersiva(
  BuildContext context,
  Animation<double> animacion,
  Animation<double> secundaria,
  Widget hijo,
) {
  final curva = CurvedAnimation(
    parent: animacion,
    curve: Movimiento.salida,
    reverseCurve: Curves.easeIn,
  );
  if (sinMovimiento(context)) {
    return FadeTransition(opacity: curva, child: hijo);
  }
  return FadeTransition(
    opacity: curva,
    child: ScaleTransition(
      scale: Tween<double>(begin: 1.1, end: 1).animate(curva),
      child: hijo,
    ),
  );
}

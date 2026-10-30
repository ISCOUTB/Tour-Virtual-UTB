import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../nucleo/movimiento.dart';
import '../../nucleo/tema.dart';

/// Superficie azul de las cabeceras de la app UTB.
///
/// Azul real arriba, marino abajo a la izquierda, un resplandor violeta abajo a
/// la derecha y los arcos concéntricos finos que cruzan todas las cabeceras de
/// la anfitriona. Las esquinas inferiores van redondeadas y el radio se puede
/// interpolar mientras la cabecera colapsa.
class FondoCabeceraUtb extends StatelessWidget {
  const FondoCabeceraUtb({
    super.key,
    this.radioInferior = MedidasUtb.radioCabecera,
    this.child,
  });

  final double radioInferior;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PintorCabecera(radioInferior: radioInferior),
      child: child,
    );
  }
}

class _PintorCabecera extends CustomPainter {
  const _PintorCabecera({required this.radioInferior});

  final double radioInferior;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final forma = RRect.fromRectAndCorners(
      rect,
      bottomLeft: Radius.circular(radioInferior),
      bottomRight: Radius.circular(radioInferior),
    );
    canvas.save();
    canvas.clipRRect(forma);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColoresUtb.cabeceraArriba,
            ColoresUtb.cabeceraMedio,
            ColoresUtb.cabeceraAbajo,
          ],
          stops: [0, 0.62, 1],
        ).createShader(rect),
    );

    // El resplandor se ancla al ancho y no al alto: así conserva la misma
    // forma mientras la cabecera se encoge al desplazar.
    final brillo = Rect.fromCircle(
      center: Offset(size.width * 1.02, size.height * 1.05),
      radius: size.width * 0.95,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            ColoresUtb.cabeceraBrillo.withValues(alpha: 0.9),
            ColoresUtb.cabeceraBrillo.withValues(alpha: 0),
          ],
        ).createShader(brillo),
    );

    final luz = Rect.fromCircle(
      center: Offset(size.width * 0.05, -size.width * 0.1),
      radius: size.width * 0.7,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(luz),
    );

    pintarArcos(canvas, size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PintorCabecera old) => old.radioInferior != radioInferior;
}

/// Arcos concéntricos de las cabeceras UTB.
///
/// El centro queda fuera de la pantalla, arriba a la derecha, así que sobre la
/// cabecera solo se ven trazos curvos que bajan hacia la izquierda.
void pintarArcos(
  Canvas canvas,
  Size size, {
  double opacidad = 1,
  Offset? centro,
}) {
  final c = centro ?? Offset(size.width * 1.08, -size.width * 0.22);
  // Medido en Agenda: unos 30 dp entre arcos en un teléfono de 411 dp.
  final separacion = math.max(28.0, size.width * 0.075);
  final alcance = size.longestSide * 1.9;
  final pincel = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  var i = 0;
  for (var r = size.width * 0.3; r < alcance; r += separacion, i++) {
    // Más tenues cuanto más lejos del centro, como en la anfitriona.
    final alfa = (0.085 - i * 0.0018).clamp(0.03, 0.085) * opacidad;
    pincel.color = Colors.white.withValues(alpha: alfa);
    canvas.drawCircle(c, r, pincel);
  }
}

/// Fondo de la pantalla de arranque: marino profundo con luces desenfocadas.
///
/// Las luces derivan despacio, como en el arranque de la app UTB. Con
/// «quitar animaciones» activo se quedan quietas.
class FondoArranque extends StatefulWidget {
  const FondoArranque({super.key, this.child});

  final Widget? child;

  @override
  State<FondoArranque> createState() => _FondoArranqueState();
}

class _FondoArranqueState extends State<FondoArranque>
    with SingleTickerProviderStateMixin {
  late final AnimationController _deriva = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (sinMovimiento(context)) {
      _deriva.stop();
    } else if (!_deriva.isAnimating) {
      _deriva.repeat();
    }
  }

  @override
  void dispose() {
    _deriva.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _PintorArranque(_deriva),
        child: widget.child,
      ),
    );
  }
}

class _Luz {
  const _Luz(this.x, this.y, this.radio, this.alfa, this.fase, this.velocidad);

  final double x, y, radio, alfa, fase, velocidad;
}

class _PintorArranque extends CustomPainter {
  _PintorArranque(this.tiempo) : super(repaint: tiempo);

  final Animation<double> tiempo;

  // Semilla fija: las luces caen siempre en el mismo sitio, y una captura de
  // la pantalla de carga es reproducible.
  static final List<_Luz> _luces = () {
    final azar = math.Random(11);
    return List.generate(16, (_) {
      return _Luz(
        azar.nextDouble(),
        azar.nextDouble(),
        4 + azar.nextDouble() * 9,
        0.05 + azar.nextDouble() * 0.11,
        azar.nextDouble() * math.pi * 2,
        0.4 + azar.nextDouble() * 0.8,
      );
    });
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, 0.02),
          radius: 0.95,
          colors: [ColoresUtb.arranqueCentro, ColoresUtb.arranqueBorde],
        ).createShader(rect),
    );

    final brillo = Rect.fromCircle(
      center: Offset(size.width * 0.95, size.height * 0.04),
      radius: size.width * 0.75,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            ColoresUtb.arranqueBrillo.withValues(alpha: 0.85),
            ColoresUtb.arranqueBrillo.withValues(alpha: 0),
          ],
        ).createShader(brillo),
    );

    final halo = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide * 0.42,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(halo),
    );

    final t = tiempo.value * math.pi * 2;
    for (final luz in _luces) {
      final dx = math.sin(t * luz.velocidad + luz.fase) * 14;
      final dy = math.cos(t * luz.velocidad * 0.7 + luz.fase) * 18;
      final destello = 0.65 + 0.35 * math.sin(t * 2 * luz.velocidad + luz.fase);
      canvas.drawCircle(
        Offset(luz.x * size.width + dx, luz.y * size.height + dy),
        luz.radio,
        Paint()
          ..color = Colors.white.withValues(alpha: luz.alfa * destello)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, luz.radio * 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(_PintorArranque old) => false;
}

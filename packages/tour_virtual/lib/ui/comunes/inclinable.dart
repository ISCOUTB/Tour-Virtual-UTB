import 'package:flutter/material.dart';

import '../../nucleo/movimiento.dart';

/// Pose 3D en radianes.
class Pose3D {
  const Pose3D({this.x = 0, this.y = 0, this.z = 0});

  final double x, y, z;
}

/// Tarjeta que se inclina en 3D hacia el dedo, como el carnet de la app UTB.
///
/// Reposa en [reposo] y, al tocarla o pasar el puntero, gira hasta [maximo]
/// radianes hacia ese punto; un reflejo blanco recorre la superficie según el
/// ángulo. Al soltar vuelve con un pequeño rebote. Usa `Listener`, así que no
/// compite con los toques ni con el desplazamiento de la lista que la contiene.
class Inclinable extends StatefulWidget {
  const Inclinable({
    super.key,
    required this.child,
    this.reposo = const Pose3D(),
    this.maximo = 0.2,
    this.radio,
    this.reflejo = true,
  });

  final Widget child;
  final Pose3D reposo;
  final double maximo;

  /// Recorte del reflejo. Debe coincidir con las esquinas del hijo.
  final BorderRadius? radio;
  final bool reflejo;

  @override
  State<Inclinable> createState() => _InclinableState();
}

class _InclinableState extends State<Inclinable> {
  var _objetivo = Offset.zero;
  var _activa = false;

  void _apuntar(Offset local) {
    final caja = context.size;
    if (caja == null || caja.isEmpty) return;
    final x = (local.dx / caja.width * 2 - 1).clamp(-1.0, 1.0);
    final y = (local.dy / caja.height * 2 - 1).clamp(-1.0, 1.0);
    setState(() {
      _objetivo = Offset(x, y);
      _activa = true;
    });
  }

  void _soltar() => setState(() {
    _objetivo = Offset.zero;
    _activa = false;
  });

  @override
  Widget build(BuildContext context) {
    final quieta = sinMovimiento(context);

    final cuerpo = TweenAnimationBuilder<Offset>(
      tween: Tween(end: quieta ? Offset.zero : _objetivo),
      duration: _activa
          ? const Duration(milliseconds: 140)
          : const Duration(milliseconds: 700),
      curve: _activa ? Curves.easeOut : Curves.elasticOut,
      builder: (context, p, hijo) {
        final r = widget.reposo;
        final matriz = Matrix4.identity()
          ..setEntry(3, 2, Movimiento.perspectiva)
          ..rotateX(r.x - p.dy * widget.maximo)
          ..rotateY(r.y + p.dx * widget.maximo)
          ..rotateZ(r.z);

        return Transform(
          alignment: Alignment.center,
          transform: matriz,
          child: widget.reflejo
              ? Stack(
                  fit: StackFit.passthrough,
                  children: [
                    hijo!,
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: widget.radio ?? BorderRadius.zero,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(-1.2 - p.dx, -1.2 - p.dy),
                                end: Alignment(1.2 - p.dx, 1.2 - p.dy),
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(
                                    alpha: _activa ? 0.22 : 0.1,
                                  ),
                                  Colors.white.withValues(alpha: 0),
                                ],
                                stops: const [0.3, 0.5, 0.7],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : hijo,
        );
      },
      child: widget.child,
    );

    if (quieta) return cuerpo;

    return MouseRegion(
      onHover: (e) => _apuntar(e.localPosition),
      onExit: (_) => _soltar(),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) => _apuntar(e.localPosition),
        onPointerMove: (e) => _apuntar(e.localPosition),
        onPointerUp: (_) => _soltar(),
        onPointerCancel: (_) => _soltar(),
        child: cuerpo,
      ),
    );
  }
}

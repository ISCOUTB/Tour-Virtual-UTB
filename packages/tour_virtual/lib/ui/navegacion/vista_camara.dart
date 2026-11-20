import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../l10n/textos.dart';
import '../../nucleo/tema.dart';

/// La flecha sobre la imagen de la cámara (RF-28, AD-01): `CameraPreview` con
/// un dibujo encima, sin ARCore ni ARKit.
///
/// La flecha apunta según el rumbo al próximo punto de la ruta menos el rumbo
/// del teléfono, y se acuesta sobre el suelo según cuánto se inclina la
/// cámara. Si la cámara no abre (sin permiso, sin cámara, escritorio), avisa
/// con [alFallar] para que la guía siga en el plano sin perder la ruta
/// (RF-33).
class VistaCamara extends StatefulWidget {
  const VistaCamara({
    super.key,
    required this.giro,
    required this.inclinacion,
    required this.metros,
    required this.alFallar,
  });

  /// Cuánto girar para mirar hacia el próximo punto: grados, positivo a la
  /// derecha. Nulo mientras no hay rumbo.
  final double? giro;

  /// Inclinación de la cámara: 0 al frente, -90 al suelo.
  final double inclinacion;
  final int? metros;
  final VoidCallback alFallar;

  @override
  State<VistaCamara> createState() => _VistaCamaraState();
}

class _VistaCamaraState extends State<VistaCamara> with WidgetsBindingObserver {
  CameraController? _control;
  var _fallo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _abrir();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _control?.dispose();
    super.dispose();
  }

  /// La cámara se suelta al salir de la app y se vuelve a abrir al volver: si
  /// no, Android la deja tomada y otra app no la puede usar.
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    final control = _control;
    if (estado == AppLifecycleState.inactive && control != null) {
      _control = null;
      control.dispose();
      if (mounted) setState(() {});
    } else if (estado == AppLifecycleState.resumed && _control == null) {
      _abrir();
    }
  }

  Future<void> _abrir() async {
    try {
      final camaras = await availableCameras();
      final trasera = camaras
          .where((c) => c.lensDirection == CameraLensDirection.back)
          .firstOrNull;
      if (trasera == null) throw StateError('sin cámara trasera');
      // Media resolución: es para orientarse, no para fotografiar, y la gama
      // baja tiene que mantener 24 fps con la flecha encima.
      final control = CameraController(
        trasera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await control.initialize();
      if (!mounted) {
        await control.dispose();
        return;
      }
      setState(() => _control = control);
    } catch (error) {
      debugPrint('Cámara no disponible: $error');
      if (!mounted) return;
      setState(() => _fallo = true);
      widget.alFallar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final txt = Textos.of(context);
    final control = _control;
    if (_fallo) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(MedidasUtb.radioTarjeta),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (control != null && control.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: control.value.previewSize?.height ?? 1,
                height: control.value.previewSize?.width ?? 1,
                child: CameraPreview(control),
              ),
            )
          else
            const ColoredBox(color: Colors.black),
          if (widget.giro != null)
            ExcludeSemantics(
              child: _Flecha(
                giro: widget.giro!,
                inclinacion: widget.inclinacion,
                metros: widget.metros,
              ),
            ),
          // Aviso de seguridad: nunca tapa el centro, donde va el camino.
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Align(
              alignment: Alignment.topCenter,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.visibility_rounded,
                        size: 18,
                        color: ColoresUtb.amarillo,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          txt.navCamaraAviso,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Flecha acostada sobre el suelo: gira con el rumbo y se inclina en
/// perspectiva según hacia dónde mira la cámara.
class _Flecha extends StatelessWidget {
  const _Flecha({required this.giro, required this.inclinacion, this.metros});

  final double giro;
  final double inclinacion;
  final int? metros;

  @override
  Widget build(BuildContext context) {
    // Con la cámara al suelo (-90) la flecha se ve de frente; al frente (0),
    // casi de canto. Hasta 70° para que siga leyéndose.
    final acostada = ((90 + inclinacion).clamp(0.0, 70.0)) * math.pi / 180;
    return Align(
      alignment: const Alignment(0, 0.45),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateX(acostada)
              ..rotateZ(giro * math.pi / 180),
            child: const CustomPaint(
              size: Size(150, 150),
              painter: _PintorFlecha(),
            ),
          ),
          if (metros != null) ...[
            const SizedBox(height: 4),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: Text(
                  '$metros m',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PintorFlecha extends CustomPainter {
  const _PintorFlecha();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Chevrón ancho apuntando hacia arriba (hacia adelante sobre el suelo).
    final flecha = Path()
      ..moveTo(w * 0.5, h * 0.06)
      ..lineTo(w * 0.94, h * 0.62)
      ..lineTo(w * 0.66, h * 0.62)
      ..lineTo(w * 0.66, h * 0.94)
      ..lineTo(w * 0.34, h * 0.94)
      ..lineTo(w * 0.34, h * 0.62)
      ..lineTo(w * 0.06, h * 0.62)
      ..close();
    canvas.drawShadow(flecha, Colors.black, 10, true);
    canvas.drawPath(flecha, Paint()..color = ColoresUtb.azul);
    canvas.drawPath(
      flecha,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_PintorFlecha old) => false;
}

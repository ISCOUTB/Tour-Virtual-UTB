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
    this.destino,
  });

  /// Cuánto girar para mirar hacia el próximo punto: grados, positivo a la
  /// derecha. Nulo mientras no hay rumbo.
  final double? giro;

  /// Inclinación de la cámara: 0 al frente, -90 al suelo.
  final double inclinacion;
  final int? metros;
  final VoidCallback alFallar;

  /// La puerta del destino vista desde la cámara: cuántos grados a la derecha
  /// (negativo, a la izquierda) de hacia donde apunta, a cuántos metros y su
  /// nombre. Nulo mientras no hay rumbo.
  final ({double giro, int metros, String nombre})? destino;

  /// Mitad del campo de visión horizontal de la cámara trasera en vertical.
  /// En los teléfonos va de 25° a 30° (lente principal, sensor 4:3); un error
  /// de unos grados solo corre el marcador unos píxeles.
  static const medioCampo = 27.0;

  @override
  State<VistaCamara> createState() => _VistaCamaraState();
}

class _VistaCamaraState extends State<VistaCamara> with WidgetsBindingObserver {
  CameraController? _control;
  var _fallo = false;
  var _activa = true;
  var _sesion = 0;
  Future<void> _transicion = Future<void>.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _programarApertura();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cerrar();
    super.dispose();
  }

  /// La cámara se suelta al salir de la app y se vuelve a abrir al volver: si
  /// no, Android la deja tomada y otra app no la puede usar.
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    _activa = estado == AppLifecycleState.resumed;
    if (!_activa) {
      _cerrar();
      if (mounted) setState(() {});
    } else {
      _programarApertura();
    }
  }

  void _programarApertura() {
    final sesion = ++_sesion;
    // No abrir dos cámaras si la app vuelve antes de terminar initialize().
    _transicion = _transicion.then((_) => _abrir(sesion));
  }

  void _cerrar() {
    _sesion++;
    final control = _control;
    _control = null;
    _transicion = _transicion.then((_) => _liberar(control));
  }

  Future<void> _liberar(CameraController? control) async {
    try {
      await control?.dispose();
    } catch (error) {
      debugPrint('No se pudo liberar la cámara: $error');
    }
  }

  Future<void> _abrir(int sesion) async {
    if (!mounted || !_activa || sesion != _sesion) return;
    CameraController? control;
    try {
      final camaras = await availableCameras();
      if (!mounted || !_activa || sesion != _sesion) return;
      final trasera = camaras
          .where((c) => c.lensDirection == CameraLensDirection.back)
          .firstOrNull;
      if (trasera == null) throw StateError('sin cámara trasera');
      // Media resolución: es para orientarse, no para fotografiar, y la gama
      // baja tiene que mantener 24 fps con la flecha encima.
      control = CameraController(
        trasera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await control.initialize();
      if (!mounted || !_activa || sesion != _sesion) {
        await _liberar(control);
        return;
      }
      setState(() => _control = control);
    } catch (error) {
      await _liberar(control);
      debugPrint('Cámara no disponible: $error');
      if (!mounted || !_activa || sesion != _sesion) return;
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
          // El destino anclado donde está de verdad, si entra en la imagen.
          // La flecha dice por dónde ir; el marcador, dónde queda.
          if (widget.destino case final d?
              when d.giro.abs() < VistaCamara.medioCampo)
            ExcludeSemantics(
              child: LayoutBuilder(
                builder: (context, caja) => _MarcadorDestino(
                  caja: caja.biggest,
                  giro: d.giro,
                  inclinacion: widget.inclinacion,
                  metros: d.metros,
                  nombre: d.nombre,
                ),
              ),
            ),
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
    // Se encoge si no cabe: en un teléfono con los avisos de la guía y la
    // barra del modo campo, a la cámara le quedaban 184 px y la flecha con su
    // distancia se desbordaba.
    return Align(
      alignment: const Alignment(0, 0.45),
      child: FittedBox(
        fit: BoxFit.scaleDown,
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
      ),
    );
  }
}

/// Un pin sobre la línea del horizonte, a la altura de la puerta del
/// destino: se mueve con el teléfono como si estuviera en la calle.
class _MarcadorDestino extends StatelessWidget {
  const _MarcadorDestino({
    required this.caja,
    required this.giro,
    required this.inclinacion,
    required this.metros,
    required this.nombre,
  });

  final Size caja;
  final double giro;
  final double inclinacion;
  final int metros;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    final esquina = posicionMarcadorDestino(caja, giro, inclinacion);
    if (esquina == null) return const SizedBox.shrink();
    final textos = Theme.of(context).textTheme;
    return Stack(
      children: [
        Positioned(
          left: esquina.dx,
          top: esquina.dy,
          width: anchoMarcadorDestino,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: ColoresUtb.amarillo, width: 1.4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    '$nombre · $metros m',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textos.labelLarge?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              const Icon(
                Icons.location_on_rounded,
                size: 30,
                color: ColoresUtb.amarillo,
                shadows: [Shadow(blurRadius: 6)],
              ),
            ],
          ),
        ),
      ],
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

/// Ancho del marcador del destino en la vista de cámara.
const anchoMarcadorDestino = 180.0;

/// Esquina superior izquierda del marcador del destino en una vista de cámara
/// de tamaño [caja], para un destino [giro] grados a la derecha de hacia donde
/// apunta y con la cámara inclinada [inclinacion] grados (0 al frente). Nulo si
/// la vista es demasiado chica para mostrarlo sin tapar la flecha: con el
/// panel del modo campo abierto puede quedar de menos de 150 px, y un
/// `clamp` con el mínimo por encima del máximo lanzaba un error en cada cuadro.
Offset? posicionMarcadorDestino(Size caja, double giro, double inclinacion) {
  if (caja.width < anchoMarcadorDestino + 16 || caja.height < 220) return null;
  // Proyección de cámara estenopeica: la distancia focal en píxeles sale del
  // campo de visión horizontal.
  final focal =
      (caja.width / 2) / math.tan(VistaCamara.medioCampo * math.pi / 180);
  final x =
      caja.width / 2 +
      focal * math.tan(giro.clamp(-80.0, 80.0) * math.pi / 180);
  // El horizonte sube cuando la cámara mira al suelo (inclinación negativa).
  final horizonte =
      caja.height / 2 +
      focal * math.tan(inclinacion.clamp(-80.0, 80.0) * math.pi / 180);
  // Sin tapar la flecha (va en la mitad de abajo) ni el aviso de arriba.
  final y = horizonte.clamp(64.0, caja.height * 0.42);
  return Offset(
    (x - anchoMarcadorDestino / 2).clamp(
      8.0,
      caja.width - anchoMarcadorDestino - 8,
    ),
    y - 58,
  );
}

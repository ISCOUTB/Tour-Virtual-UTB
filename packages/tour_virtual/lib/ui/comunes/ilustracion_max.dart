import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../nucleo/movimiento.dart';

/// Ilustraciones de Max, la mascota de la UTB.
///
/// Son renders 2D (WebP con transparencia) en `assets/max/`, generados a partir
/// de la hoja de referencia del personaje y limpiados a mano. Max acompaña: da
/// la bienvenida, señala por dónde empezar, celebra el cierre y da la cara
/// cuando algo falla. No es un asistente ni conversa: ese papel es del robot de
/// la app anfitriona (DESIGN.md), y dos personajes que ayudan competirían.
enum PoseMax {
  /// Cuerpo entero, saludando: la bienvenida.
  saludo('max_saludo', 548 / 1000, parpadea: true),

  /// Torso, señalando hacia su derecha y abajo: la cabecera, hacia el texto.
  senalando('max_senalando', 499 / 760, parpadea: true, torso: true),

  /// Cuerpo entero, saltando con los brazos arriba: el cierre del recorrido.
  celebrando('max_celebrando', 689 / 1000, parpadea: true),

  /// Torso, mano en la barbilla: lo que aún no hay.
  pensativo('max_pensativo', 424 / 760, parpadea: true, torso: true),

  /// Torso, rascándose la cabeza: un fallo de conexión.
  apenado('max_apenado', 500 / 760, parpadea: true, torso: true),

  /// Cuerpo entero, con un mapa del campus: invita a abrir el mapa.
  mapa('max_mapa', 522 / 1000, parpadea: true),

  /// Torso, mostrando un teléfono: reservada para la realidad aumentada.
  telefono('max_telefono', 497 / 760, torso: true),

  /// Torso, escuchando con los ojos cerrados: reservada para el audio.
  escuchando('max_escuchando', 510 / 760, torso: true),

  /// Torso, pulgar arriba y guiño.
  pulgar('max_pulgar', 481 / 760, torso: true),

  /// Cuerpo entero, mostrando el camino con la mano.
  invitando('max_invitando', 592 / 1000);

  const PoseMax(
    this._archivo,
    this.proporcion, {
    this.parpadea = false,
    this.torso = false,
  });

  final String _archivo;

  /// Ancho / alto del render.
  final double proporcion;

  /// Si tiene la versión con los ojos cerrados para parpadear. Las que ya
  /// tienen los ojos cerrados o un guiño no la necesitan.
  final bool parpadea;

  /// Termina en la cintura con un corte recto.
  final bool torso;

  String get ruta => 'assets/max/$_archivo.webp';
  String get rutaOjos => 'assets/max/${_archivo}_ojos.webp';
}

/// Max a un alto fijo, con vida: respira, se balancea apenas y parpadea.
///
/// El movimiento es una sola animación de 12 s de la que salen tres ritmos que
/// no coinciden (respiración cada 3 s, balanceo de 6 s y 4 s) y parpadeos a
/// destiempo, uno de ellos doble: así no se nota el bucle. Todo es sutil (un
/// 1 % de escala, menos de un grado de giro) y anclado en los pies. Con
/// «Reducir movimiento», del sistema o del módulo, Max se queda quieto: es el
/// mecanismo para detener el movimiento que pide WCAG 2.2.2.
///
/// Es decorativo: el texto que lo acompaña lleva el mensaje, así que el lector
/// de pantalla no lo anuncia.
class IlustracionMax extends StatefulWidget {
  const IlustracionMax({
    super.key,
    required this.pose,
    required this.alto,
    this.sombra = false,
    this.difuminarBase = false,
  });

  final PoseMax pose;
  final double alto;

  /// Sombra difusa sacada de la propia silueta. Va sobre las superficies
  /// azules: sin ella la camiseta azul se funde con el fondo.
  final bool sombra;

  /// Desvanece el corte recto de la cintura de las poses de torso, para cuando
  /// Max no se apoya en un borde.
  final bool difuminarBase;

  @override
  State<IlustracionMax> createState() => _IlustracionMaxState();
}

class _IlustracionMaxState extends State<IlustracionMax>
    with TickerProviderStateMixin {
  static const _ciclo = Duration(seconds: 12);

  /// Momentos del ciclo (en segundos) en que parpadea; 6,25 hace el doble.
  static const _parpadeos = [1.6, 5.9, 6.25, 10.3];
  static const _duracionParpadeo = 0.13;

  late final AnimationController _reloj = AnimationController(
    vsync: this,
    duration: _ciclo,
  );
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: Movimiento.largo,
  );
  late final AnimationController _salto = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  /// Desfase propio de cada pose: si hay dos Max a la vez, no van al compás.
  double get _desfase => widget.pose.index * 1.37;

  bool? _animando;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animar = !sinMovimiento(context);
    if (animar == _animando) return;
    _animando = animar;
    if (animar) {
      if (_entrada.value == 0) _entrada.forward();
      _reloj.repeat();
    } else {
      _reloj.stop();
      _entrada.value = 1;
      _salto.value = 0;
    }
  }

  @override
  void dispose() {
    _reloj.dispose();
    _entrada.dispose();
    _salto.dispose();
    super.dispose();
  }

  void _tocar() {
    if (_animando != true) return;
    _salto.forward(from: 0);
  }

  bool _parpadeando(double t) {
    final s = (t + _desfase) % 12;
    return _parpadeos.any((p) => s >= p && s < p + _duracionParpadeo);
  }

  @override
  Widget build(BuildContext context) {
    final pose = widget.pose;
    final alto = widget.alto;
    final ancho = alto * pose.proporcion;
    final cache = (alto * MediaQuery.devicePixelRatioOf(context)).round();

    Image capa(String ruta, {Color? color}) => Image.asset(
      ruta,
      package: 'tour_virtual',
      excludeFromSemantics: true,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      // Decodificada al tamaño en que se ve: en gama baja la memoria de
      // imágenes es lo primero que se acaba.
      cacheHeight: color == null ? cache : cache ~/ 2,
      gaplessPlayback: true,
      color: color,
      colorBlendMode: color == null ? null : BlendMode.srcIn,
    );

    Widget figura = AnimatedBuilder(
      animation: _reloj,
      builder: (context, _) {
        final ojosCerrados =
            _animando == true &&
            pose.parpadea &&
            _parpadeando(_reloj.value * 12);
        return Stack(
          fit: StackFit.expand,
          children: [
            capa(pose.ruta),
            // Siempre construida, para que esté decodificada antes del primer
            // parpadeo y no aparezca tarde.
            if (pose.parpadea)
              Opacity(
                opacity: ojosCerrados ? 1 : 0,
                child: capa(pose.rutaOjos),
              ),
          ],
        );
      },
    );

    if (pose.torso && widget.difuminarBase) {
      figura = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0, 0.8, 1],
        ).createShader(rect),
        child: figura,
      );
    }

    if (widget.sombra) {
      figura = Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          Transform.translate(
            offset: Offset(0, alto * 0.025),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
              child: capa(pose.ruta, color: const Color(0x8C000A2E)),
            ),
          ),
          figura,
        ],
      );
    }

    return GestureDetector(
      onTap: _tocar,
      // El saltito es un guiño, no una acción: el lector de pantalla no debe
      // anunciar un botón que no hace nada.
      excludeFromSemantics: true,
      child: SizedBox(
        width: ancho,
        height: alto,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_reloj, _entrada, _salto]),
            child: figura,
            builder: (context, hijo) {
              if (_animando != true) return hijo!;
              final t = _reloj.value * 12 + _desfase;
              final respira = math.sin(2 * math.pi * t / 3);
              final giro =
                  0.011 * math.sin(2 * math.pi * t / 6) +
                  0.005 * math.sin(2 * math.pi * t / 4 + 1);
              final entrada = Movimiento.salida.transform(_entrada.value);
              final salto = math.sin(math.pi * _salto.value);
              return Opacity(
                opacity: entrada,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    (1 - entrada) * 14 - (respira + 1) * 0.6 - salto * 9,
                  ),
                  child: Transform.rotate(
                    angle: giro,
                    alignment: Alignment.bottomCenter,
                    child: Transform.scale(
                      scaleX: 1 - 0.004 * respira,
                      scaleY: 1 + 0.010 * respira + salto * 0.02,
                      alignment: Alignment.bottomCenter,
                      child: hijo,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

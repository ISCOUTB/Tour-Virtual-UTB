import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../nucleo/movimiento.dart';

/// Ilustraciones de Max, la mascota de la UTB.
///
/// Son recortes 2D (WebP con transparencia) en `assets/max/`. Max acompaña:
/// da la bienvenida, asoma en la cabecera y celebra el cierre. No es un
/// asistente ni habla con el usuario: ese papel es del robot de la app
/// anfitriona (DESIGN.md), y dos personajes que ayudan competirían.
enum PoseMax {
  /// Cuerpo entero, de frente.
  frente('assets/max/max_frente.webp', 392 / 911),

  /// De la gorra a la cintura, para asomar en la cabecera.
  busto('assets/max/max_busto.webp', 392 / 546);

  const PoseMax(this.ruta, this.proporcion);

  final String ruta;

  /// Ancho / alto del recorte.
  final double proporcion;
}

/// Max a un alto fijo. Es decorativo: el texto que lo acompaña lleva el
/// mensaje, así que el lector de pantalla no lo anuncia.
class IlustracionMax extends StatelessWidget {
  const IlustracionMax({
    super.key,
    required this.pose,
    required this.alto,
    this.alineacion = Alignment.bottomCenter,
    this.sombra = false,
  });

  final PoseMax pose;
  final double alto;
  final Alignment alineacion;

  /// Sombra difusa sacada de la propia silueta de Max. Va sobre las
  /// superficies azules: sin ella la camiseta azul se funde con el fondo.
  final bool sombra;

  @override
  Widget build(BuildContext context) {
    final ancho = alto * pose.proporcion;
    final pixeles = MediaQuery.devicePixelRatioOf(context);
    final animar = !sinMovimiento(context);
    final imagen = Image.asset(
      pose.ruta,
      package: 'tour_virtual',
      excludeFromSemantics: true,
      fit: BoxFit.contain,
      alignment: alineacion,
      // Decodificada al tamaño en que se ve: en gama baja la memoria de
      // imágenes es lo primero que se acaba.
      cacheHeight: (alto * pixeles).round(),
      gaplessPlayback: true,
      frameBuilder: (context, hijo, cuadro, sincronico) {
        if (sincronico || !animar) return hijo;
        return AnimatedOpacity(
          opacity: cuadro == null ? 0 : 1,
          duration: Movimiento.medio,
          curve: Movimiento.salida,
          child: hijo,
        );
      },
    );
    if (!sombra) return SizedBox(width: ancho, height: alto, child: imagen);
    return SizedBox(
      width: ancho,
      height: alto,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, alto * 0.025),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                child: Image.asset(
                  pose.ruta,
                  package: 'tour_virtual',
                  excludeFromSemantics: true,
                  fit: BoxFit.contain,
                  alignment: alineacion,
                  cacheHeight: (alto * pixeles / 2).round(),
                  color: const Color(0x8C000A2E),
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
          ),
          Positioned.fill(child: imagen),
        ],
      ),
    );
  }
}

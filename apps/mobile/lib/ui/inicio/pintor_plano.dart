import 'dart:math';

import 'package:flutter/material.dart';

import '../../datos/plano_campus.dart';
import '../../nucleo/tema.dart';

/// Dibuja el plano del campus con la cartografía de OpenStreetMap.
///
/// Los anchos van en metros y se pasan a píxeles con la escala del lienzo,
/// así una vía mide lo mismo que en el terreno a cualquier tamaño de
/// pantalla. El `InteractiveViewer` escala el dibujo entero al acercarse:
/// como es vectorial, sigue nítido hasta el zoom máximo, que la ilustración
/// en mapa de bits no permitía.
class PintorPlano extends CustomPainter {
  const PintorPlano({required this.plano, required this.altoContraste});

  final PlanoCampus plano;
  final bool altoContraste;

  // Anchos en metros, a ojo de lo que se ve en una foto aérea del campus.
  static const _anchoVia = 5.0;
  static const _anchoViaPrincipal = 8.0;
  static const _anchoBordeVia = 1.2;
  static const _anchoSendero = 1.4;
  static const _anchoEscalera = 2.6;

  @override
  void paint(Canvas canvas, Size size) {
    final pxPorMetro = size.width / plano.anchoMetros;
    double ancho(double metros, {double minimo = 1}) =>
        max(metros * pxPorMetro, minimo);

    Path trazo(RasgoPlano rasgo) => Path()
      ..addPolygon([
        for (final p in rasgo.puntos)
          Offset(p.dx * size.width, p.dy * size.height),
      ], rasgo.esArea);

    void areas(
      ClaseRasgo clase,
      Color relleno, {
      Color? borde,
      double grosorBorde = 1,
    }) {
      final pintura = Paint()..color = relleno;
      final contorno = borde == null
          ? null
          : (Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = grosorBorde
              ..strokeJoin = StrokeJoin.round
              ..color = borde);
      for (final rasgo in plano.rasgos[clase]!) {
        if (!rasgo.esArea) continue;
        final camino = trazo(rasgo);
        canvas.drawPath(camino, pintura);
        if (contorno != null) canvas.drawPath(camino, contorno);
      }
    }

    void lineas(
      ClaseRasgo clase,
      Color color,
      double grosor, {
      double? trazoDe,
      double? huecoDe,
      StrokeCap punta = StrokeCap.round,
    }) {
      final pintura = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor
        ..strokeCap = punta
        ..strokeJoin = StrokeJoin.round
        ..color = color;
      for (final rasgo in plano.rasgos[clase]!) {
        if (rasgo.esArea) continue;
        final camino = trazo(rasgo);
        if (trazoDe == null || huecoDe == null) {
          canvas.drawPath(camino, pintura);
          continue;
        }
        for (final metrica in camino.computeMetrics()) {
          for (var d = 0.0; d < metrica.length; d += trazoDe + huecoDe) {
            canvas.drawPath(metrica.extractPath(d, d + trazoDe), pintura);
          }
        }
      }
    }

    canvas.drawRect(Offset.zero & size, Paint()..color = ColoresPlano.tierra);

    areas(ClaseRasgo.zona, ColoresPlano.zona);
    areas(
      ClaseRasgo.campus,
      ColoresPlano.campus,
      borde: altoContraste
          ? ColoresPlano.bordeCampusFuerte
          : ColoresPlano.bordeCampus,
      grosorBorde: ancho(1.5),
    );
    areas(ClaseRasgo.verde, ColoresPlano.verde);
    areas(ClaseRasgo.arboles, ColoresPlano.arboles);
    areas(ClaseRasgo.agua, ColoresPlano.agua);
    areas(
      ClaseRasgo.parqueadero,
      ColoresPlano.parqueadero,
      borde: ColoresPlano.bordeParqueadero,
    );
    areas(
      ClaseRasgo.cancha,
      ColoresPlano.cancha,
      borde: ColoresPlano.bordeCancha,
    );
    areas(ClaseRasgo.plazoleta, ColoresPlano.plazoleta);

    // Vías: primero el borde de todas y luego el relleno, para que los cruces
    // se vean continuos y no como dos tiras superpuestas.
    final bordeVia = altoContraste
        ? ColoresPlano.bordeViaFuerte
        : ColoresPlano.bordeVia;
    lineas(
      ClaseRasgo.viaPrincipal,
      altoContraste ? bordeVia : ColoresPlano.bordeViaPrincipal,
      ancho(_anchoViaPrincipal + 2 * _anchoBordeVia, minimo: 3),
    );
    lineas(
      ClaseRasgo.via,
      bordeVia,
      ancho(_anchoVia + 2 * _anchoBordeVia, minimo: 3),
    );
    lineas(
      ClaseRasgo.viaPrincipal,
      ColoresPlano.viaPrincipal,
      ancho(_anchoViaPrincipal, minimo: 2),
    );
    lineas(ClaseRasgo.via, ColoresPlano.via, ancho(_anchoVia, minimo: 2));

    final sendero = altoContraste
        ? ColoresPlano.senderoFuerte
        : ColoresPlano.sendero;
    lineas(
      ClaseRasgo.sendero,
      sendero,
      ancho(_anchoSendero),
      trazoDe: ancho(2.5, minimo: 3),
      huecoDe: ancho(1.5, minimo: 2),
    );
    // Las escaleras, en peldaños: trazos cortos y gruesos, como en OSM.
    lineas(
      ClaseRasgo.escalera,
      sendero,
      ancho(_anchoEscalera, minimo: 3),
      trazoDe: ancho(0.6),
      huecoDe: ancho(0.5),
      punta: StrokeCap.butt,
    );

    areas(
      ClaseRasgo.edificio,
      ColoresPlano.edificio,
      borde: altoContraste
          ? ColoresPlano.bordeEdificioFuerte
          : ColoresPlano.bordeEdificio,
      grosorBorde: altoContraste ? 1.5 : 1,
    );
  }

  @override
  bool shouldRepaint(PintorPlano old) =>
      old.plano != plano || old.altoContraste != altoContraste;
}

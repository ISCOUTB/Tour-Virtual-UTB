import 'dart:convert';
import 'dart:math';
import 'dart:ui' show Offset;

import 'package:flutter/services.dart';

/// Tipo de elemento del plano, tal como lo clasifica `scripts/mapa_campus.py`
/// de la app móvil.
enum ClaseRasgo {
  campus,
  zona,
  verde,
  arboles,
  agua,
  parqueadero,
  cancha,
  plazoleta,
  edificio,
  via,
  viaPrincipal,
  sendero,
  escalera,
  desconocida;

  static ClaseRasgo leer(String? valor) => switch (valor) {
        'campus' => campus,
        'zona' => zona,
        'verde' => verde,
        'arboles' => arboles,
        'agua' => agua,
        'parqueadero' => parqueadero,
        'cancha' => cancha,
        'plazoleta' => plazoleta,
        'edificio' => edificio,
        'via' => via,
        'via_principal' => viaPrincipal,
        'sendero' => sendero,
        'escalera' => escalera,
        _ => desconocida,
      };
}

/// Un polígono o una línea del plano, normalizado a la caja (x al este,
/// y al sur, ambos en [0, 1]).
class RasgoPlano {
  const RasgoPlano({
    required this.clase,
    required this.esArea,
    required this.puntos,
  });

  final ClaseRasgo clase;
  final bool esArea;
  final List<Offset> puntos;
}

/// Plano del campus a partir de OpenStreetMap (`campus_osm.geojson`, el mismo
/// archivo que usa la app móvil). Los datos son ODbL: junto al mapa debe verse
/// «© colaboradores de OpenStreetMap».
class PlanoCampus {
  PlanoCampus({
    required this.oeste,
    required this.sur,
    required this.este,
    required this.norte,
    required List<RasgoPlano> rasgos,
  }) : rasgos = {
          for (final clase in ClaseRasgo.values)
            clase: rasgos.where((r) => r.clase == clase).toList(),
        };

  static const ruta = 'assets/campus_osm.geojson';

  factory PlanoCampus.desdeGeoJson(Map<String, dynamic> json) {
    final caja = (json['bbox'] as List).cast<num>();
    final oeste = caja[0].toDouble(), sur = caja[1].toDouble();
    final este = caja[2].toDouble(), norte = caja[3].toDouble();

    Offset normal(List<dynamic> par) => Offset(
          ((par[0] as num) - oeste) / (este - oeste),
          (norte - (par[1] as num)) / (norte - sur),
        );

    final rasgos = <RasgoPlano>[];
    for (final rasgo in json['features'] as List) {
      final propiedades = rasgo['properties'] as Map<String, dynamic>;
      final geometria = rasgo['geometry'] as Map<String, dynamic>;
      final clase = ClaseRasgo.leer(propiedades['clase'] as String?);
      if (clase == ClaseRasgo.desconocida) continue;
      final esArea = geometria['type'] == 'Polygon';
      final coords = esArea
          ? (geometria['coordinates'] as List).first as List
          : geometria['coordinates'] as List;
      rasgos.add(RasgoPlano(
        clase: clase,
        esArea: esArea,
        puntos: [for (final par in coords) normal(par as List)],
      ));
    }
    return PlanoCampus(
        oeste: oeste, sur: sur, este: este, norte: norte, rasgos: rasgos);
  }

  final double oeste, sur, este, norte;
  final Map<ClaseRasgo, List<RasgoPlano>> rasgos;

  double get _latMedia => (sur + norte) / 2;
  double get anchoMetros => (este - oeste) * 111320 * cos(_latMedia * pi / 180);
  double get altoMetros => (norte - sur) * 110574;

  /// Ancho entre alto: el lienzo debe respetarla o cada lat/lng se desplaza.
  double get proporcion => anchoMetros / altoMetros;

  /// Posición normalizada [0, 1] de un punto. Nula si cae fuera de la caja.
  Offset? normalizar(double lat, double lng) {
    final x = (lng - oeste) / (este - oeste);
    final y = (norte - lat) / (norte - sur);
    if (x < 0 || x > 1 || y < 0 || y > 1) return null;
    return Offset(x, y);
  }

  /// Operación inversa: de posición normalizada a (lat, lng).
  (double, double) aLatLng(Offset p) =>
      (norte - p.dy * (norte - sur), oeste + p.dx * (este - oeste));

  static Future<PlanoCampus>? _cache;

  /// Carga el plano una sola vez. Se usa `load` y no `loadString` porque con
  /// más de 50 KB este último decodifica en otro isolate.
  static Future<PlanoCampus> cargar() => _cache ??= () async {
        final datos = await rootBundle.load(ruta);
        final texto = utf8.decode(
            datos.buffer.asUint8List(datos.offsetInBytes, datos.lengthInBytes));
        return PlanoCampus.desdeGeoJson(
            jsonDecode(texto) as Map<String, dynamic>);
      }();
}

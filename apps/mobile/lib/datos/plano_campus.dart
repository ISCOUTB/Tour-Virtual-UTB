import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tipo de elemento del plano, tal como lo clasifica `scripts/mapa_campus.py`.
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

  /// Una clase que esta versión de la app no conoce. Se ignora en lugar de
  /// dejar el mapa en blanco.
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

/// Un polígono o una línea del plano, en coordenadas normalizadas a la caja.
class RasgoPlano {
  const RasgoPlano({
    required this.clase,
    required this.esArea,
    required this.puntos,
  });

  final ClaseRasgo clase;
  final bool esArea;

  /// x hacia el este e y hacia el sur, ambas en [0, 1] dentro de la caja.
  final List<Offset> puntos;
}

/// Plano del campus a partir de OpenStreetMap.
///
/// Lo genera `scripts/mapa_campus.py` en `campus_osm.geojson`, con los
/// nombres de A3 y A4 ya corregidos. Los datos son ODbL: la app tiene que
/// mostrar «© colaboradores de OpenStreetMap» junto al mapa.
///
/// La proyección es equirectangular local. A la escala del campus, unos
/// 700 m, se aleja de la real por centímetros, y así lat/lng se pasan al
/// lienzo con una regla de tres.
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

  /// Lee el GeoJSON del script. Las coordenadas vienen como [lng, lat].
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
      rasgos.add(
        RasgoPlano(
          clase: clase,
          esArea: esArea,
          puntos: [for (final par in coords) normal(par as List)],
        ),
      );
    }
    return PlanoCampus(
      oeste: oeste,
      sur: sur,
      este: este,
      norte: norte,
      rasgos: rasgos,
    );
  }

  static const ruta = 'android/app/src/assets/campus_osm.geojson';

  final double oeste, sur, este, norte;

  /// Rasgos agrupados por clase, para pintarlos capa por capa.
  final Map<ClaseRasgo, List<RasgoPlano>> rasgos;

  double get _latMedia => (sur + norte) / 2;

  double get anchoMetros => (este - oeste) * 111320 * cos(_latMedia * pi / 180);

  double get altoMetros => (norte - sur) * 110574;

  /// Ancho entre alto. El lienzo tiene que respetarla, o cada lat/lng caería
  /// desplazada.
  double get proporcion => anchoMetros / altoMetros;

  /// Posición de un punto en el plano, normalizada a [0, 1]. Nula si cae
  /// fuera de la caja.
  Offset? normalizar(double lat, double lng) {
    final x = (lng - oeste) / (este - oeste);
    final y = (norte - lat) / (norte - sur);
    if (x < 0 || x > 1 || y < 0 || y > 1) return null;
    return Offset(x, y);
  }
}

/// El plano empaquetado.
///
/// Se lee con `load` y no con `loadString`: con más de 50 KB este decodifica
/// en otro isolate, y en las pruebas de widgets ese isolate no termina nunca.
final planoCampusProvider = FutureProvider<PlanoCampus>((ref) async {
  final datos = await rootBundle.load(PlanoCampus.ruta);
  final texto = utf8.decode(
    datos.buffer.asUint8List(datos.offsetInBytes, datos.lengthInBytes),
  );
  return PlanoCampus.desdeGeoJson(jsonDecode(texto) as Map<String, dynamic>);
});

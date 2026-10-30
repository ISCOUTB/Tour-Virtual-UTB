import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tour_virtual/datos/plano_campus.dart';
import 'package:tour_virtual/datos/repositorio_demo.dart';

/// El plano lo genera `scripts/mapa_campus.py` desde OpenStreetMap. Estas
/// pruebas leen el archivo empaquetado tal cual, así que fallan si alguien lo
/// regenera roto o con otra caja.
void main() {
  final json =
      jsonDecode(
            File(
              '../../packages/tour_virtual/assets/campus_osm.geojson',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final plano = PlanoCampus.desdeGeoJson(json);

  test('trae el campus y lo que se dibuja encima', () {
    expect(plano.rasgos[ClaseRasgo.campus], hasLength(1));
    expect(plano.rasgos[ClaseRasgo.edificio], isNotEmpty);
    expect(plano.rasgos[ClaseRasgo.sendero], isNotEmpty);
    expect(plano.rasgos[ClaseRasgo.cancha], isNotEmpty);
    // La caja mide unos 740 x 510 m. El lienzo toma esta proporción: si se
    // desviara, cada lat/lng caería corrida.
    expect(plano.proporcion, closeTo(1.45, 0.03));
  });

  test('todo lugar con lat/lng cae dentro del plano', () async {
    final pois = await const RepositorioDemo().obtenerPois(1);
    final ubicados = pois.where((p) => p.tienePosicionEnMapa).toList();

    expect(ubicados.length, greaterThan(20));
    for (final poi in ubicados) {
      expect(
        plano.normalizar(poi.lat!, poi.lng!),
        isNotNull,
        reason: poi.nombre,
      );
    }
  });

  test('A3 y A4 llevan el nombre de la leyenda, no el de OSM', () {
    String? nombreDe(String osm) =>
        (json['features'] as List).cast<Map<String, dynamic>>().firstWhere(
              (f) => f['properties']['osm'] == osm,
            )['properties']['nombre']
            as String?;

    expect(nombreDe('way/238258177'), 'Edificio A3');
    expect(nombreDe('way/1563809309'), 'Edificio A4');
  });
}

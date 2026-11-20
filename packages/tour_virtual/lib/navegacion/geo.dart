import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Radio medio de la Tierra (WGS84), en metros.
const radioTierra = 6371008.8;

/// Un punto en coordenadas geográficas (grados, WGS84).
@immutable
class PuntoGeo {
  const PuntoGeo(this.lat, this.lng);

  final double lat;
  final double lng;

  @override
  bool operator ==(Object other) =>
      other is PuntoGeo && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'PuntoGeo($lat, $lng)';
}

double _rad(double grados) => grados * math.pi / 180;
double _grados(double rad) => rad * 180 / math.pi;

/// Distancia Haversine entre dos puntos, en metros (AD-03).
double distanciaMetros(PuntoGeo a, PuntoGeo b) {
  final p1 = _rad(a.lat), p2 = _rad(b.lat);
  final dp = p2 - p1, dl = _rad(b.lng - a.lng);
  final h =
      math.pow(math.sin(dp / 2), 2) +
      math.cos(p1) * math.cos(p2) * math.pow(math.sin(dl / 2), 2);
  return 2 * radioTierra * math.asin(math.min(1, math.sqrt(h)));
}

/// Rumbo inicial de [desde] hacia [hacia], en grados desde el norte
/// geográfico, en sentido horario: 0 norte, 90 este. Entre 0 y 360.
double rumboGrados(PuntoGeo desde, PuntoGeo hacia) {
  final p1 = _rad(desde.lat), p2 = _rad(hacia.lat);
  final dl = _rad(hacia.lng - desde.lng);
  final y = math.sin(dl) * math.cos(p2);
  final x =
      math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl);
  return normalizarGrados(_grados(math.atan2(y, x)));
}

/// Un ángulo en grados llevado a [0, 360).
double normalizarGrados(double grados) {
  final r = grados % 360;
  return r < 0 ? r + 360 : r;
}

/// Cuánto hay que girar desde [desde] para mirar hacia [hacia], en grados:
/// positivo a la derecha, negativo a la izquierda, en (-180, 180].
double diferenciaAngular(double desde, double hacia) {
  final d = normalizarGrados(hacia - desde);
  return d > 180 ? d - 360 : d;
}

/// Punto más cercano a [p] dentro del tramo [a]–[b], con la fracción del tramo
/// en que cae (0 en [a], 1 en [b]) y la distancia en metros.
///
/// Usa un plano local tangente: a la escala del campus (cientos de metros) el
/// error frente a la geodesia es de milímetros.
({PuntoGeo punto, double fraccion, double metros}) proyectarEnTramo(
  PuntoGeo p,
  PuntoGeo a,
  PuntoGeo b,
) {
  final escalaX = math.cos(_rad(p.lat)) * radioTierra;
  double x(PuntoGeo q) => _rad(q.lng) * escalaX;
  double y(PuntoGeo q) => _rad(q.lat) * radioTierra;
  final ax = x(a), ay = y(a), bx = x(b), by = y(b), px = x(p), py = y(p);
  final dx = bx - ax, dy = by - ay;
  final largo2 = dx * dx + dy * dy;
  final t = largo2 == 0
      ? 0.0
      : (((px - ax) * dx + (py - ay) * dy) / largo2).clamp(0.0, 1.0);
  final punto = PuntoGeo(
    a.lat + t * (b.lat - a.lat),
    a.lng + t * (b.lng - a.lng),
  );
  return (punto: punto, fraccion: t, metros: distanciaMetros(p, punto));
}

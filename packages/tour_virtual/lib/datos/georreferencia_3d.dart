import 'dart:math' as math;

import '../navegacion/geo.dart';

/// Ajuste de similitud de ElMapita entre OSM y la maqueta de Ternera.
/// Fuente y autores: assets/mapa3d/origen.json. Precisión provisional ~9 m;
/// solo se usa para dibujar, nunca para calcular llegadas ni rutas AR.
abstract final class Georreferencia3d {
  static const origenLat = 10.3687;
  static const origenLng = -75.4645;
  static const ar = 0.7037688010352227;
  static const ai = 0.6475444290808399;
  static const tx = 87.46136076530392;
  static const tz = -304.17586844832044;
  static const metrosLat = 110574.0;
  static final metrosLng = 111320 * math.cos(origenLat * math.pi / 180);
  static final escala = math.sqrt(ar * ar + ai * ai);

  /// La cámara mira al norte en la vista cenital, igual que el plano OSM.
  static final norteCamara = math.atan2(ai, -ar) * 180 / math.pi;

  static ({double x, double z}) aModelo(double lat, double lng) {
    final u = -(lng - origenLng) * metrosLng;
    final v = (lat - origenLat) * metrosLat;
    return (x: ar * u - ai * v + tx, z: ai * u + ar * v + tz);
  }

  static PuntoGeo aGeografico(double x, double z) {
    final dx = x - tx, dz = z - tz;
    const norma = ar * ar + ai * ai;
    final u = (ar * dx + ai * dz) / norma;
    final v = (-ai * dx + ar * dz) / norma;
    return PuntoGeo(origenLat + v / metrosLat, origenLng - u / metrosLng);
  }
}

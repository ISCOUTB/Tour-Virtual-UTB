import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tour_virtual/navegacion/geo.dart';
import 'package:tour_virtual/navegacion/grafo_campus.dart';
import 'package:tour_virtual/navegacion/seguimiento.dart';
import 'package:tour_virtual/navegacion/sensores.dart';

/// Un punto a [norte] y [este] metros de [origen].
PuntoGeo desplazar(PuntoGeo origen, {double norte = 0, double este = 0}) =>
    PuntoGeo(
      origen.lat + norte / 111195,
      origen.lng + este / (111195 * 0.98358),
    );

const origen = PuntoGeo(10.37, -75.465);

/// Grafo de prueba en forma de L, con un atajo por escaleras:
///
///   n2 ---- n3 (acceso del lugar 9)
///   |      /
///   n1 --s/    (escalera n1-n3, más corta)
GrafoCampus grafoEnL() {
  final n1 = origen;
  final n2 = desplazar(origen, norte: 100);
  final n3 = desplazar(origen, norte: 100, este: 100);
  return GrafoCampus(
    version: 'prueba',
    declinacion: 0,
    nodos: {'n1': n1, 'n2': n2, 'n3': n3},
    tramos: [
      TramoCampus(
        a: 'n1',
        b: 'n2',
        metros: 100,
        tipo: TipoTramo.sendero,
        escalones: false,
        techado: false,
      ),
      TramoCampus(
        a: 'n2',
        b: 'n3',
        metros: 100,
        tipo: TipoTramo.sendero,
        escalones: false,
        techado: false,
      ),
      TramoCampus(
        a: 'n1',
        b: 'n3',
        metros: 141,
        tipo: TipoTramo.escalera,
        escalones: true,
        techado: false,
      ),
    ],
    accesos: [
      AccesoLugar(
        poiId: 9,
        nombre: 'Lugar',
        punto: n3,
        nodo: 'n3',
        principal: true,
        verificado: true,
      ),
    ],
  );
}

LecturaPosicion lectura(PuntoGeo p, {double precision = 5}) =>
    LecturaPosicion(punto: p, precision: precision);

void main() {
  test('elige un rumbo fiable sin orientar la flecha con una brújula mala', () {
    const brujula = LecturaRumbo(grados: 90, inclinacion: 0);
    const mala = LecturaRumbo(grados: 180, inclinacion: 0, descalibrada: true);
    const caminando = LecturaPosicion(
      punto: origen,
      precision: 5,
      velocidad: 1.2,
      rumbo: 40,
    );
    expect(rumboNavegacion(caminando, brujula), 40);
    expect(rumboNavegacion(caminando, mala), 40);
    expect(rumboNavegacion(lectura(origen), brujula), 90);
    expect(rumboNavegacion(lectura(origen), mala), isNull);
    expect(rumboNavegacion(null, null), isNull);
    const imprecisa = LecturaPosicion(
      punto: origen,
      precision: 80,
      velocidad: 1.2,
      rumbo: 40,
    );
    expect(rumboNavegacion(imprecisa, mala), isNull);
  });
  group('geometría', () {
    test('distancia y rumbo', () {
      final norte = desplazar(origen, norte: 100);
      final este = desplazar(origen, este: 100);
      expect(distanciaMetros(origen, norte), closeTo(100, 0.5));
      expect(distanciaMetros(origen, este), closeTo(100, 0.5));
      expect(rumboGrados(origen, norte), closeTo(0, 0.5));
      expect(rumboGrados(origen, este), closeTo(90, 0.5));
      expect(diferenciaAngular(350, 10), 20);
      expect(diferenciaAngular(10, 350), -20);
    });
  });

  group('rumbo con acelerómetro y magnetómetro', () {
    // Campo en el campus: ~30 µT horizontal al norte y ~15 µT hacia abajo.
    const bh = 30.0, bv = 15.0;

    test('acostado, con la parte de arriba al norte o al este', () {
      final norte = rumboDesdeSensores([0, 0, 9.8], [0, bh, -bv])!;
      expect(norte.grados, closeTo(0, 0.5));
      expect(norte.inclinacion, closeTo(-90, 0.5));
      final este = rumboDesdeSensores([0, 0, 9.8], [-bh, 0, -bv])!;
      expect(este.grados, closeTo(90, 0.5));
    });

    test('vertical, con la cámara al norte (modo cámara)', () {
      final r = rumboDesdeSensores([0, 9.8, 0], [0, -bv, -bh])!;
      expect(r.grados, closeTo(0, 0.5));
      expect(r.inclinacion, closeTo(0, 0.5));
      expect(r.descalibrada, isFalse);
    });

    test('la declinación pasa del norte magnético al geográfico', () {
      final r = rumboDesdeSensores(
        [0, 0, 9.8],
        [0, bh, -bv],
        declinacion: -7.7,
      )!;
      expect(r.grados, closeTo(352.3, 0.5));
    });

    test('un campo que no es el de la Tierra pide calibrar', () {
      final r = rumboDesdeSensores([0, 0, 9.8], [0, 300, -bv])!;
      expect(r.descalibrada, isTrue);
    });
  });

  group('ruta con A*', () {
    test('fuera del campus no inventa una ruta desde la casa', () {
      final lejos = desplazar(origen, norte: 2000, este: 2000);
      expect(grafoEnL().ruta(lejos, 9), isNull);
    });
    test('toma el camino más corto y evita escaleras si se pide', () {
      final grafo = grafoEnL();
      final corta = grafo.ruta(origen, 9)!;
      expect(corta.usaEscaleras, isTrue);
      expect(corta.metros, closeTo(141, 1));

      final sinEscaleras = grafo.ruta(origen, 9, sinEscaleras: true)!;
      expect(sinEscaleras.usaEscaleras, isFalse);
      expect(sinEscaleras.metros, closeTo(200, 1));
      expect(
        sinEscaleras.puntos.last,
        desplazar(origen, norte: 100, este: 100),
      );
    });

    test('entra al camino por el punto más cercano, no por un nodo', () {
      final grafo = grafoEnL();
      // A 50 m al norte sobre el tramo n1-n2: le quedan 50 + 100 sin escaleras.
      final r = grafo.ruta(
        desplazar(origen, norte: 50, este: 3),
        9,
        sinEscaleras: true,
      )!;
      expect(r.metros, closeTo(150, 1));
    });

    test('un lugar sin acceso no tiene ruta', () {
      expect(grafoEnL().ruta(origen, 1), isNull);
    });

    test('en el grafo del campus, las cinco paradas tienen ruta', () {
      final archivo = File(
        '../../packages/tour_virtual/assets/navegacion/grafo_campus.json',
      );
      final grafo = GrafoCampus.desdeJson(
        jsonDecode(archivo.readAsStringSync()) as Map<String, dynamic>,
      );
      for (final poi in [1, 2, 3, 4, 5]) {
        final r = grafo.ruta(UbicacionSimulada.puntoDePartida, poi);
        expect(r, isNotNull, reason: 'parada $poi');
        expect(r!.destino.poiId, poi);
        // El campus mide unos 400 m de punta a punta.
        expect(r.metros, inInclusiveRange(20, 900), reason: 'parada $poi');
        final sin = grafo.ruta(
          UbicacionSimulada.puntoDePartida,
          poi,
          sinEscaleras: true,
        );
        expect(sin?.usaEscaleras ?? false, isFalse, reason: 'parada $poi');
      }
    });
  });

  group('seguimiento', () {
    RutaCampus rutaEnL() => grafoEnL().ruta(origen, 9, sinEscaleras: true)!;

    test('avanza por los puntos y llega', () {
      final s = SeguimientoRuta(rutaEnL());
      s.actualizar(lectura(origen));
      expect(s.estado, EstadoSeguimiento.guiando);
      expect(s.metrosRestantes, closeTo(200, 2));

      s.actualizar(lectura(desplazar(origen, norte: 95)));
      expect(s.puntoObjetivo, desplazar(origen, norte: 100, este: 100));
      expect(s.rumboAlObjetivo, closeTo(87, 4));

      s.actualizar(lectura(desplazar(origen, norte: 100, este: 95)));
      expect(s.estado, EstadoSeguimiento.llegada);
      expect(s.proximaManiobra()!.llegada, isTrue);
    });

    test('con poca precisión, la llegada pide dos lecturas', () {
      final s = SeguimientoRuta(rutaEnL());
      s.actualizar(lectura(origen));
      final cerca = desplazar(origen, norte: 100, este: 95);
      s.actualizar(lectura(desplazar(origen, norte: 95)));
      s.actualizar(lectura(cerca, precision: 20));
      expect(s.estado, isNot(EstadoSeguimiento.llegada));
      s.actualizar(lectura(cerca, precision: 20));
      expect(s.estado, EstadoSeguimiento.llegada);
    });

    test('una lectura muy imprecisa no guía: señal débil', () {
      final s = SeguimientoRuta(rutaEnL());
      s.actualizar(lectura(origen, precision: 80));
      expect(s.estado, EstadoSeguimiento.senalDebil);
    });

    test('alejarse de la ruta en dos lecturas pide recalcular', () {
      final s = SeguimientoRuta(rutaEnL());
      s.actualizar(lectura(origen));
      final lejos = desplazar(origen, norte: 40, este: -60);
      s.actualizar(lectura(lejos));
      expect(s.estado, EstadoSeguimiento.guiando);
      s.actualizar(lectura(lejos));
      expect(s.estado, EstadoSeguimiento.fueraDeRuta);
    });

    test('anuncia el giro de la esquina, no cada vértice', () {
      final s = SeguimientoRuta(rutaEnL());
      s.actualizar(lectura(desplazar(origen, norte: 30)));
      final m = s.proximaManiobra()!;
      expect(m.giro, Giro.derecha);
      expect(m.metros, closeTo(70, 2));
      expect(m.llegada, isFalse);
    });
  });
}

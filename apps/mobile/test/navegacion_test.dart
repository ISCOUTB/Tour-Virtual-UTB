import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_virtual/datos/modelos/modelos.dart';
import 'package:tour_virtual/navegacion/espacios.dart';
import 'package:tour_virtual/navegacion/geo.dart';
import 'package:tour_virtual/navegacion/grafo_campus.dart';
import 'package:tour_virtual/navegacion/seguimiento.dart';
import 'package:tour_virtual/navegacion/sensores.dart';
import 'package:tour_virtual/ui/navegacion/vista_camara.dart';

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
    // RF-29: la brújula manda aunque se camine. Es lo único que sabe hacia
    // dónde apunta la cámara, y así la flecha no salta al pararse.
    expect(rumboNavegacion(caminando, brujula), 90);
    // Con la brújula interferida, el rumbo del GPS al caminar.
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
  group('filtro de la brújula con el giroscopio', () {
    const arriba = [0.0, 0.0, 9.8];

    test('sigue a la brújula y arranca con ella', () {
      final f = FiltroRumbo();
      expect(f.corregir(120, 0.05), 120);
      // Un salto de más de 60° (teléfono de acostado a vertical) se toma tal cual.
      expect(f.corregir(250, 0.05), 250);
    });

    test(
      'un giro del teléfono se ve al instante, sin esperar a la brújula',
      () {
        final f = FiltroRumbo()..corregir(0, 0.05);
        // 90°/s hacia la derecha (horario visto desde arriba) durante 0,2 s.
        for (var i = 0; i < 20; i++) {
          f.girar([0, 0, -math.pi / 2], arriba, 0.01);
        }
        expect(f.rumbo, closeTo(18, 0.5));
      },
    );

    test('la brújula que tiembla ±12° apenas mueve la flecha', () {
      final f = FiltroRumbo()..corregir(90, 0.05);
      final azar = math.Random(3);
      var maximo = 0.0;
      for (var i = 0; i < 400; i++) {
        f.girar([0, 0, 0], arriba, 0.05);
        final r = f.corregir(90 + (azar.nextDouble() - 0.5) * 24, 0.05);
        maximo = math.max(maximo, diferenciaAngular(90, r).abs());
      }
      // Sin el filtro, el ruido llegaba entero a la flecha (hasta 12°).
      expect(maximo, lessThan(4));
    });

    test('corrige la deriva del giroscopio hacia la brújula', () {
      final f = FiltroRumbo()..corregir(0, 0.05);
      for (var i = 0; i < 200; i++) {
        f.girar([0, 0, 0.01], arriba, 0.05);
        f.corregir(0, 0.05);
      }
      expect(diferenciaAngular(0, f.rumbo!).abs(), lessThan(2));
    });
  });

  group('marcador del destino en la cámara', () {
    test('se ancla donde está la puerta', () {
      const caja = Size(400, 700);
      final centro = posicionMarcadorDestino(caja, 0, 0)!;
      expect(centro.dx + anchoMarcadorDestino / 2, closeTo(200, 0.5));
      final derecha = posicionMarcadorDestino(caja, 15, 0)!;
      expect(derecha.dx, greaterThan(centro.dx));
      // Mirando al suelo, el horizonte (y el pin) suben.
      final abajo = posicionMarcadorDestino(caja, 0, -30)!;
      expect(abajo.dy, lessThan(centro.dy));
    });

    test('en una vista chica no se dibuja ni falla', () {
      for (final caja in const [
        Size(400, 140),
        Size(400, 0),
        Size(120, 700),
        Size.zero,
      ]) {
        expect(posicionMarcadorDestino(caja, 0, -20), isNull);
      }
    });
  });

  group('lecturas del GPS (filtro de MAPSUTB)', () {
    final ahora = DateTime(2026, 11, 23, 10);

    test(
      'una lectura vieja no se usa; una imprecisa solo dice que hay señal',
      () {
        LecturaPosicion l(double precision, Duration edad) => LecturaPosicion(
          punto: origen,
          precision: precision,
          momento: ahora.subtract(edad),
        );
        expect(
          usoDeLectura(l(5, const Duration(seconds: 2)), ahora),
          UsoLectura.guiar,
        );
        expect(
          usoDeLectura(l(5, const Duration(seconds: 30)), ahora),
          UsoLectura.vieja,
        );
        expect(usoDeLectura(l(80, Duration.zero), ahora), UsoLectura.debil);
        // Sin marca de tiempo se toma como reciente.
        expect(usoDeLectura(lectura(origen), ahora), UsoLectura.guiar);
      },
    );

    test('fuera del campus solo con certeza, aun con el peor error', () {
      final grafo = grafoEnL();
      final lejos = desplazar(origen, este: -400);
      expect(fueraDelCampusCon(lectura(lejos, precision: 10), grafo), isTrue);
      expect(fueraDelCampusCon(lectura(lejos, precision: 500), grafo), isFalse);
    });
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

    test(
      'en el grafo del campus, los 26 lugares tienen ruta desde la portería',
      () {
        final grafo = grafoDelCampus();
        final lugares = {for (final a in grafo.accesos) a.poiId};
        expect(lugares, hasLength(26));
        for (final poi in lugares) {
          final r = grafo.ruta(UbicacionSimulada.puntoDePartida, poi);
          expect(r, isNotNull, reason: 'lugar $poi');
          expect(r!.metros, inInclusiveRange(10, 900), reason: 'lugar $poi');
        }
      },
    );

    test('los cruces sin nodo de OSM ya no obligan a rodear el campus', () {
      final grafo = grafoDelCampus();
      // Al final del andén del sur, donde cruza la vía de servicio sin un nodo
      // en OSM: la ruta al A5 daba 600 m de rodeo (también en MAPSUTB).
      final r = grafo.ruta(const PuntoGeo(10.3686027, -75.4649653), 10)!;
      expect(r.metros, lessThan(220));
    });

    test('100 rutas en el grafo del campus en menos de un segundo', () {
      // El escenario 2 de MAPSUTB pide la ruta en menos de 5 s.
      final grafo = grafoDelCampus();
      final azar = math.Random(5);
      final reloj = Stopwatch()..start();
      for (var i = 0; i < 100; i++) {
        final desde = desplazar(
          const PuntoGeo(10.3690, -75.4665),
          norte: azar.nextDouble() * 220,
          este: azar.nextDouble() * 200,
        );
        grafo.ruta(desde, 1 + azar.nextInt(26));
      }
      expect(reloj.elapsedMilliseconds, lessThan(1000));
    });

    test('en el grafo del campus, las cinco paradas tienen ruta', () {
      final grafo = grafoDelCampus();
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

    test('la flecha mira adelante sobre la ruta y no salta con el GPS', () {
      final s = SeguimientoRuta(rutaEnL());
      final azar = math.Random(11);
      final viejo = <double>[], nuevo = <double>[];
      // Camina hacia el norte por el primer tramo con ±4 m de ruido lateral.
      for (var metros = 10.0; metros < 70; metros += 3) {
        s.actualizar(
          lectura(
            desplazar(
              origen,
              norte: metros,
              este: (azar.nextDouble() - 0.5) * 8,
            ),
          ),
        );
        viejo.add(s.rumboAlObjetivo!);
        nuevo.add(s.rumboGuia!);
      }
      double saltoMaximo(List<double> r) {
        var m = 0.0;
        for (var i = 1; i < r.length; i++) {
          m = math.max(m, diferenciaAngular(r[i - 1], r[i]).abs());
        }
        return m;
      }

      expect(saltoMaximo(nuevo), lessThan(saltoMaximo(viejo)));
      for (final r in nuevo) {
        expect(diferenciaAngular(0, r).abs(), lessThan(20));
      }
    });

    test('los pasos de la ruta completa, para verla sin GPS', () {
      final pasos = pasosDeRuta(rutaEnL().puntos);
      expect(pasos, hasLength(2));
      expect(pasos.first.giro, Giro.derecha);
      expect(pasos.first.metros, closeTo(100, 2));
      expect(pasos.last.llegada, isTrue);
      expect(pasos.last.metros, closeTo(100, 2));
    });

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

  group('catálogo de espacios (de MAPSUTB)', () {
    final catalogo = CatalogoEspacios.desdeJson(
      jsonDecode(
            File(
              '../../packages/tour_virtual/assets/navegacion/espacios_campus.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>,
    );
    const lugares = [
      Poi(id: 7, lugarId: 1, nombre: 'Edificio A2'),
      Poi(id: 25, lugarId: 1, nombre: 'La Placita'),
      Poi(id: 3, lugarId: 1, nombre: 'Enfermería'),
    ];
    final indice = IndiceBusqueda(lugares: lugares, catalogo: catalogo);

    test('cada edificio lleva a un lugar con entrada en la guía', () {
      final grafo = grafoDelCampus();
      for (final e in catalogo.edificios) {
        expect(grafo.tieneAcceso(e.poiId), isTrue, reason: e.nombre);
        for (final x in e.espacios) {
          if (x.poiId != null) expect(grafo.tieneAcceso(x.poiId!), isTrue);
        }
      }
      expect(catalogo.edificios.length, 10);
    });

    test('«a2 401» encuentra el salón del A2 y dice el piso', () {
      final r = indice.buscar('a2 401').first;
      expect(r.titulo, 'Salón 401');
      expect(r.poiId, 7);
      expect(r.donde, 'Edificio A2 · Cuarto Piso');
      // Sin el edificio salen los dos 401 (A1 y A2).
      expect(
        indice.buscar('401').where((d) => d.titulo == 'Salón 401'),
        hasLength(2),
      );
    });

    test('sin tildes ni mayúsculas, y un lugar del tour no se repite', () {
      expect(indice.buscar('ENFERMERIA').first.lugar?.id, 3);
      final placita = indice.buscar('placita');
      expect(placita.first.lugar?.id, 25);
      expect(placita.where((d) => d.titulo == 'La Placita'), hasLength(1));
      // Sus puestos sí: llevan a La Placita.
      expect(indice.buscar('punto fit').first.poiId, 25);
    });

    test('un espacio se abre por su id desde el enlace', () {
      final d = catalogo.destino('biblioteca-esp-makerspace')!;
      expect(
        (d.titulo, d.poiId, d.piso?.nombre),
        ('Maker Space', 1, 'Tercer Piso'),
      );
      expect(catalogo.destino('no-existe'), isNull);
    });
  });
}

GrafoCampus grafoDelCampus() => GrafoCampus.desdeJson(
  jsonDecode(
        File(
          '../../packages/tour_virtual/assets/navegacion/grafo_campus.json',
        ).readAsStringSync(),
      )
      as Map<String, dynamic>,
);

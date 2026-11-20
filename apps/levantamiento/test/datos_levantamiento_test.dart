import 'package:flutter_test/flutter_test.dart';
import 'package:tour_virtual/navegacion/geo.dart';
import 'package:tour_virtual/navegacion/grafo_campus.dart';
import 'package:tour_virtual/navegacion/seguimiento.dart';
import 'package:utb_levantamiento/datos_levantamiento.dart';

/// Un grafo en L: 55 m al norte y 55 m al este, con la puerta al final.
GrafoCampus _grafoL() => GrafoCampus.desdeJson({
  'version': 'prueba',
  'declinacion': -7.7,
  'nodos': [
    {'id': 'n0', 'lat': 10.3700, 'lng': -75.4650},
    {'id': 'n1', 'lat': 10.3705, 'lng': -75.4650},
    {'id': 'n2', 'lat': 10.3705, 'lng': -75.4645},
  ],
  'aristas': [
    {'a': 'n0', 'b': 'n1', 'metros': 55.6, 'tipo': 'sendero'},
    {'a': 'n1', 'b': 'n2', 'metros': 54.7, 'tipo': 'sendero'},
  ],
  'accesos': [
    {
      'poi_id': 1,
      'nombre': 'Prueba',
      'lat': 10.3705,
      'lng': -75.4645,
      'nodo': 'n2',
      'principal': true,
    },
  ],
});

LecturaPosicion _en(double lat, double lng, {double precision = 3}) =>
    LecturaPosicion(punto: PuntoGeo(lat, lng), precision: precision);

/// Lecturas cada [paso] metros de [a] a [b].
List<LecturaPosicion> _caminar(PuntoGeo a, PuntoGeo b, {double paso = 4}) {
  final n = (distanciaMetros(a, b) / paso).ceil();
  return [
    for (var i = 1; i <= n; i++)
      _en(a.lat + (b.lat - a.lat) * i / n, a.lng + (b.lng - a.lng) * i / n),
  ];
}

Json _medida(double lat, double lng, double precision, String fecha) => {
  'poi_id': 1,
  'nombre': 'Prueba',
  'lat': lat,
  'lng': lng,
  'precision': precision,
  'fecha': fecha,
};

void main() {
  group('evaluarAcceso (criterio de la fase 0)', () {
    test('sin medidas', () {
      expect(evaluarAcceso(const []).estado, EstadoAcceso.sinMedir);
    });

    test('una sola medida buena: falta otro día', () {
      final r = evaluarAcceso([
        _medida(10.37, -75.465, 4, '2026-11-23T09:00:00'),
      ]);
      expect(r.estado, EstadoAcceso.sinConfirmar);
      expect(r.motivo, contains('otro día'));
      expect(r.punto, isNotNull);
    });

    test('dos medidas el mismo día no bastan', () {
      final r = evaluarAcceso([
        _medida(10.37, -75.465, 4, '2026-11-23T09:00:00'),
        _medida(10.37, -75.465, 4, '2026-11-23T15:00:00'),
      ]);
      expect(r.estado, EstadoAcceso.sinConfirmar);
    });

    test('dos días a menos de 5 m: aceptada, en medio de las dos', () {
      final r = evaluarAcceso([
        _medida(10.37000, -75.465, 4, '2026-11-23T09:00:00'),
        _medida(10.37002, -75.465, 4, '2026-11-25T09:00:00'),
      ]);
      expect(r.estado, EstadoAcceso.aceptado);
      expect(r.punto!.lat, closeTo(10.37001, 1e-7));
    });

    test('dos días a más de 5 m: medir otra vez', () {
      final r = evaluarAcceso([
        _medida(10.3700, -75.465, 4, '2026-11-23T09:00:00'),
        _medida(10.3701, -75.465, 4, '2026-11-25T09:00:00'),
      ]);
      expect(r.estado, EstadoAcceso.sinConfirmar);
      expect(r.motivo, contains('medir otra vez'));
    });

    test('precisión peor que 5 m no cuenta para aceptar', () {
      final r = evaluarAcceso([
        _medida(10.37, -75.465, 9, '2026-11-23T09:00:00'),
        _medida(10.37, -75.465, 9, '2026-11-25T09:00:00'),
      ]);
      expect(r.estado, EstadoAcceso.sinConfirmar);
      expect(r.punto, isNotNull);
    });

    test('todas peores que 15 m: inútiles', () {
      final r = evaluarAcceso([
        _medida(10.37, -75.465, 30, '2026-11-23T09:00:00'),
      ]);
      expect(r.estado, EstadoAcceso.sinUtiles);
      expect(r.punto, isNull);
    });
  });

  test('promedioLecturas descarta las malas y pesa las buenas', () {
    final r = promedioLecturas([
      _en(10.3700, -75.465, precision: 2),
      _en(10.3702, -75.465, precision: 8),
      _en(10.3800, -75.465, precision: 40),
    ])!;
    expect(r.usadas, 2);
    expect(r.descartadas, 1);
    // La de ±2 m pesa 16 veces más que la de ±8 m.
    expect(r.punto.lat, closeTo(10.3700 + 0.0002 / 17, 1e-7));
  });

  group('brújula', () {
    test('recalibrar no vuelve a restar el sesgo anterior', () {
      final medidas = <Json>[
        {
          'rumbo_tramo': 85,
          'rumbo_magnetico': 90,
          'declinacion': -7.7,
          'error': -2.7,
        },
      ];
      expect(erroresDeBrujula(medidas, -7.7).single, closeTo(-2.7, 1e-9));
      expect(erroresDeBrujula(medidas, -5).single, closeTo(0, 1e-9));
    });
    test('dos comprobaciones no bastan para cumplir RNF-27', () {
      expect(resumirBrujula([1, 1])!.cumple, isFalse);
    });
    test('la media circular de 359° y 1° es 0°', () {
      expect(
        diferenciaAngular(0, mediaCircular([359, 1])).abs(),
        lessThan(1e-9),
      );
    });

    test('el error se mide contra el sentido del camino más cercano', () {
      expect(errorBrujula(10, 15), closeTo(5, 1e-9));
      expect(errorBrujula(10, 195), closeTo(5, 1e-9));
      expect(errorBrujula(350, 5), closeTo(15, 1e-9));
      expect(errorBrujula(90, 80), closeTo(-10, 1e-9));
    });

    test('el resumen coincide con el del script', () {
      final r = resumirBrujula([3, 5, -1, 4, 6, 2, 8, 1])!;
      expect(r.sesgo, closeTo(3.5, 1e-9));
      expect(r.p95, closeTo(4.5, 1e-9));
      expect(r.cumple, isTrue);
      expect(resumirBrujula([3]), isNull);
    });
  });

  test('tramoCercano encuentra el tramo y su rumbo', () {
    final t = tramoCercano(_grafoL(), const PuntoGeo(10.37052, -75.4647))!;
    expect((t.tramo.a, t.tramo.b), ('n1', 'n2'));
    expect(t.metros, lessThan(3));
    expect(t.rumbo, closeTo(90, 0.5));
  });

  test('normalizarDatos lee el formato 1', () {
    final d = normalizarDatos({
      'accesos': [
        {'poi_id': 1},
      ],
    });
    expect(d['formato'], 2);
    expect(d['accesos'], hasLength(1));
    for (final clave in clavesDatos) {
      expect(d[clave], isA<List>());
    }
  });

  group('RegistroPrueba', () {
    const n0 = PuntoGeo(10.3700, -75.4650);
    const n1 = PuntoGeo(10.3705, -75.4650);
    const n2 = PuntoGeo(10.3705, -75.4645);

    test('una puerta con GPS impreciso no aprueba la prueba', () {
      final prueba = RegistroPrueba.iniciar(_grafoL(), 1, _en(n0.lat, n0.lng))!;
      for (final l in [..._caminar(n0, n1), ..._caminar(n1, n2)]) {
        prueba.lectura(l);
      }
      prueba.marcarPuerta(_en(n2.lat, n2.lng, precision: 30));
      expect(prueba.errorLlegada, lessThanOrEqualTo(radioLlegada));
      expect(prueba.paso, isFalse);
    });

    test('caminando la ruta da la llegada y la prueba pasa', () {
      final grafo = _grafoL();
      final prueba = RegistroPrueba.iniciar(grafo, 1, _en(n0.lat, n0.lng))!;
      expect(prueba.maniobra?.giro, Giro.derecha);
      for (final l in [..._caminar(n0, n1), ..._caminar(n1, n2)]) {
        prueba.lectura(l);
      }
      expect(prueba.seguimiento.estado, EstadoSeguimiento.llegada);
      expect(prueba.llegadaApp, isNotNull);
      prueba.marcarPuerta(_en(n2.lat, n2.lng));
      expect(prueba.errorLlegada, lessThanOrEqualTo(radioLlegada));
      expect(prueba.paso, isTrue);
      final tipos = prueba.eventos.map((e) => e['tipo']).toSet();
      expect(
        tipos,
        containsAll(['inicio', 'indicacion', 'llegada_app', 'puerta_real']),
      );
      final json = prueba.toJson();
      expect(json['paso'], isTrue);
      expect(json['destino'], 'Prueba');
    });

    test('alejarse de la ruta cuenta un recálculo', () {
      final prueba = RegistroPrueba.iniciar(_grafoL(), 1, _en(n0.lat, n0.lng))!;
      prueba.lectura(_en(10.3702, -75.4640));
      prueba.lectura(_en(10.3702, -75.4640));
      expect(prueba.recalculos, 1);
      expect(prueba.eventos.map((e) => e['tipo']), contains('fuera_de_ruta'));
    });

    test('una indicación marcada como equivocada hace que no pase', () {
      final prueba = RegistroPrueba.iniciar(_grafoL(), 1, _en(n0.lat, n0.lng))!;
      prueba.marcarIndicacionMala(_en(n0.lat, n0.lng), nota: 'no hay camino');
      for (final l in [..._caminar(n0, n1), ..._caminar(n1, n2)]) {
        prueba.lectura(l);
      }
      prueba.marcarPuerta(_en(n2.lat, n2.lng));
      expect(prueba.indicacionesMalas, 1);
      expect(prueba.paso, isFalse);
    });

    test('sin llegada de la app no pasa', () {
      final prueba = RegistroPrueba.iniciar(_grafoL(), 1, _en(n0.lat, n0.lng))!;
      prueba.marcarPuerta(_en(n2.lat, n2.lng));
      expect(prueba.errorLlegada, isNull);
      expect(prueba.paso, isFalse);
      // Terminada: no se anota nada más.
      prueba.lectura(_en(n1.lat, n1.lng));
      expect(prueba.eventos.last['tipo'], 'puerta_real');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tour_virtual/navegacion/correcciones.dart';
import 'package:tour_virtual/navegacion/geo.dart';
import 'package:tour_virtual/navegacion/grafo_campus.dart';
import 'package:tour_virtual/navegacion/sensores.dart';

import 'navegacion_test.dart' show desplazar, grafoEnL, origen;

/// Correcciones de campo: lo que el equipo arregla en el campus el día de la
/// prueba tiene que cambiar la ruta al momento, viajar a otros teléfonos y
/// sobrevivir a que otra corrección parta el mismo tramo.
void main() {
  final fecha = DateTime(2026, 11, 23, 9);
  var n = 0;
  String id() => 'c${n++}';

  final n1 = origen;
  final n2 = desplazar(origen, norte: 100);
  final n3 = desplazar(origen, norte: 100, este: 100);

  CorreccionesCampo con(List<Correccion> lista) =>
      lista.fold(const CorreccionesCampo(), (c, x) => c.agregar(x));

  test('sin correcciones el grafo es el mismo objeto', () {
    final base = grafoEnL();
    expect(const CorreccionesCampo().aplicar(base), same(base));
  });

  test('la ruta lleva cada segmento con su tramo', () {
    final ruta = grafoEnL().ruta(desplazar(n1, norte: 30), 9)!;
    expect(ruta.tramos, hasLength(ruta.puntos.length - 1));
  });

  test('mover la entrada cambia el destino y lo da por verificado', () {
    // La puerta real está a mitad del tramo n2-n3, no en n3.
    final puerta = desplazar(n2, este: 40, norte: 3);
    final grafo = con([
      CorreccionEntrada(
        id: id(),
        fecha: fecha,
        poiId: 9,
        nombre: 'Lugar',
        punto: puerta,
      ),
    ]).aplicar(grafoEnL());

    final ruta = grafo.ruta(desplazar(n1, norte: 10), 9, sinEscaleras: true)!;
    expect(distanciaMetros(ruta.destino.punto, puerta), lessThan(0.01));
    expect(ruta.destino.verificado, isTrue);
    expect(distanciaMetros(ruta.puntos.last, puerta), lessThan(0.01));
    // Por el sendero: 90 m hasta n2, 40 por n2-n3 y 3 hasta la puerta.
    expect(ruta.metros, closeTo(133, 1));
    expect(grafo.accesosDe(9), hasLength(1));
  });

  test('una entrada con nombre nuevo se agrega a las que había', () {
    final grafo = con([
      CorreccionEntrada(
        id: id(),
        fecha: fecha,
        poiId: 9,
        nombre: 'Puerta de atrás',
        punto: desplazar(n2, norte: 2),
      ),
    ]).aplicar(grafoEnL());
    expect(grafo.accesosDe(9).map((a) => a.nombre), [
      'Lugar',
      'Puerta de atrás',
    ]);
    expect(grafo.accesosDe(9).last.principal, isFalse);
  });

  test('un tramo cerrado deja de usarse', () {
    final grafo = con([
      CorreccionTramo(
        id: id(),
        fecha: fecha,
        desde: n2,
        hasta: n3,
        bloqueado: true,
      ),
    ]).aplicar(grafoEnL());
    // Sin el sendero n2-n3 solo queda la escalera.
    final ruta = grafo.ruta(desplazar(n1, norte: 10), 9)!;
    expect(ruta.usaEscaleras, isTrue);
    expect(grafo.ruta(desplazar(n1, norte: 10), 9, sinEscaleras: true), isNull);
  });

  test('cerrar un tramo alcanza también a sus pedazos ya partidos', () {
    // Primero se mueve la puerta a mitad de n2-n3, lo que parte el tramo;
    // después otro teléfono cierra n2-n3 con los extremos de siempre.
    final grafo = con([
      CorreccionEntrada(
        id: id(),
        fecha: fecha,
        poiId: 9,
        nombre: 'Lugar',
        punto: desplazar(n2, este: 40),
      ),
      CorreccionTramo(
        id: id(),
        fecha: fecha.add(const Duration(minutes: 1)),
        desde: n2,
        hasta: n3,
        bloqueado: true,
      ),
    ]).aplicar(grafoEnL());
    final ruta = grafo.ruta(desplazar(n1, norte: 10), 9, sinEscaleras: true);
    expect(ruta, isNull);
  });

  test('quitar los escalones abre la ruta sin escaleras por ese tramo', () {
    final grafo = con([
      CorreccionTramo(
        id: id(),
        fecha: fecha,
        desde: n3,
        hasta: n1,
        escalones: false,
      ),
    ]).aplicar(grafoEnL());
    final ruta = grafo.ruta(desplazar(n1, norte: 1), 9, sinEscaleras: true)!;
    expect(ruta.usaEscaleras, isFalse);
    expect(ruta.metros, lessThan(150));
  });

  test('un camino grabado se une por sus puntas y acorta la ruta', () {
    // Atajo por dentro de la L, de junto al sendero n1-n2 hasta junto al
    // sendero n2-n3 (lejos de la escalera, que no sirve sin escaleras).
    final atajo = [
      desplazar(n1, norte: 20, este: -3),
      desplazar(n1, norte: 50, este: 50),
      desplazar(n3, norte: 3, este: -3),
    ];
    final base = grafoEnL();
    final antes = base.ruta(desplazar(n1, norte: 1), 9, sinEscaleras: true)!;
    final grafo = con([
      CorreccionCamino(id: id(), fecha: fecha, puntos: atajo),
    ]).aplicar(base);
    final ruta = grafo.ruta(desplazar(n1, norte: 1), 9, sinEscaleras: true)!;
    expect(ruta.metros, lessThan(antes.metros - 25));
  });

  test('la brújula suma el último ajuste a la declinación', () {
    final grafo = con([
      CorreccionBrujula(id: id(), fecha: fecha, grados: 4),
      CorreccionBrujula(
        id: id(),
        fecha: fecha.add(const Duration(minutes: 1)),
        grados: -3,
      ),
      CorreccionTramo(
        id: id(),
        fecha: fecha,
        desde: n1,
        hasta: n2,
        escalones: true,
      ),
    ]).aplicar(grafoEnL());
    expect(grafo.declinacion, -3);
  });

  test('el detector de metal se amplía o se apaga desde el campo', () {
    GrafoCampus conCampo() => GrafoCampus(
      version: 'x',
      declinacion: -8.5,
      campoMagnetico: 33,
      nodos: grafoEnL().nodos,
      tramos: grafoEnL().tramos,
      accesos: grafoEnL().accesos,
    );
    final amplio = con([
      CorreccionMagnetico(id: id(), fecha: fecha, tolerancia: 0.6),
      // Cualquier otra, para que aplicar no devuelva la base.
      CorreccionNota(id: id(), fecha: fecha, texto: 'x'),
    ]).aplicar(conCampo());
    expect(amplio.campoMagnetico, 33);
    expect(amplio.toleranciaCampo, 0.6);
    // Un teléfono sin calibrar que mide 49 µT: estricto lo da por
    // interferido, amplio no.
    expect(campoAnomalo(49, 33), isTrue);
    expect(campoAnomalo(49, 33, amplio.toleranciaCampo), isFalse);

    final apagado = con([
      CorreccionMagnetico(id: id(), fecha: fecha, tolerancia: null),
    ]).aplicar(conCampo());
    expect(apagado.campoMagnetico, isNull);
  });

  test('un ajuste nuevo reemplaza al anterior del mismo tipo', () {
    final c = con([
      CorreccionRadio(id: 'r1', fecha: fecha, metros: 12),
      CorreccionRadio(
        id: 'r2',
        fecha: fecha.add(const Duration(seconds: 1)),
        metros: 14,
      ),
      CorreccionNota(id: 'n', fecha: fecha, texto: 'x'),
    ]);
    expect(c.vigentes.map((x) => x.id), ['n', 'r2']);
    expect(c.radioLlegada, 14);
  });

  test('deshacer quita la corrección del grafo', () {
    final cerrar = CorreccionTramo(
      id: id(),
      fecha: fecha,
      desde: n2,
      hasta: n3,
      bloqueado: true,
    );
    final correcciones = con([cerrar]).anular(cerrar.id);
    expect(correcciones.isEmpty, isTrue);
    expect(
      correcciones.aplicar(grafoEnL()).ruta(n1, 9, sinEscaleras: true),
      isNotNull,
    );
  });

  group('entre teléfonos', () {
    final entrada = CorreccionEntrada(
      id: 'a',
      fecha: fecha,
      autor: 'José',
      poiId: 9,
      nombre: 'Lugar',
      punto: n2,
      precision: 4.2,
    );
    final nota = CorreccionNota(
      id: 'b',
      fecha: fecha,
      texto: 'Reja cerrada los domingos',
      punto: n1,
      poiId: 9,
    );

    test('ida y vuelta por el portapapeles, con texto alrededor', () {
      final texto = con([entrada, nota]).anular('b').exportar();
      final leidas = CorreccionesCampo.importar(
        'Correcciones de Kevin:\n$texto\nenviado desde WhatsApp',
      )!;
      expect(leidas.lista.map((c) => c.id), ['a', 'b']);
      expect(leidas.anuladas, {'b'});
      final otra = leidas.lista.first as CorreccionEntrada;
      expect(otra.autor, 'José');
      expect(otra.precision, 4.2);
      expect(distanciaMetros(otra.punto, n2), lessThan(0.05));
    });

    test('unir no duplica y respeta lo deshecho en cualquiera', () {
      final mio = con([entrada]);
      final suyo = con([entrada, nota]).anular('a');
      final juntas = mio.unir(suyo);
      expect(juntas.lista.map((c) => c.id), ['a', 'b']);
      expect(juntas.vigentes.map((c) => c.id), ['b']);
    });

    test('un tipo desconocido se ignora sin romper la importación', () {
      final leidas = CorreccionesCampo.importar(
        '{"formato":"correcciones-guia-1","correcciones":['
        '{"id":"x","tipo":"teletransporte","fecha":"2026-11-23T09:00:00"},'
        '{"id":"n","tipo":"nota","fecha":"2026-11-23T09:00:00","texto":"hola"}'
        ']}',
      )!;
      expect(leidas.lista.map((c) => c.id), ['n']);
    });

    test('un texto que no son correcciones da nulo', () {
      expect(CorreccionesCampo.importar('hola'), isNull);
      expect(CorreccionesCampo.importar('{"formato":"otro"}'), isNull);
    });
  });

  test('el camino grabado pierde el ruido y conserva las esquinas', () {
    final esquina = desplazar(n1, norte: 50);
    final trazo = [
      n1,
      desplazar(n1, norte: 10, este: 0.5),
      desplazar(n1, norte: 25, este: -0.6),
      esquina,
      desplazar(esquina, este: 20, norte: 0.4),
      desplazar(esquina, este: 50),
    ];
    final limpio = simplificarTrazo(trazo, 2);
    expect(limpio, hasLength(3));
    expect(distanciaMetros(limpio[1], esquina), lessThan(0.01));
  });

  test('normaliza el ajuste de la brújula entre -180 y 180', () {
    expect(normalizarAjuste(350), -10);
    expect(normalizarAjuste(-190), 170);
    expect(normalizarAjuste(12.5), 12.5);
  });

  group('metal cerca', () {
    test('con el campo de Cartagena, 60 µT ya es una reja', () {
      expect(campoAnomalo(33, 33), isFalse);
      expect(campoAnomalo(40, 33), isFalse);
      expect(campoAnomalo(60, 33), isTrue);
      expect(campoAnomalo(18, 33), isTrue);
    });

    test('sin el campo del lugar se usa el rango mundial', () {
      expect(campoAnomalo(60, null), isFalse);
      expect(campoAnomalo(80, null), isTrue);
    });
  });

  test('el grafo del campus trae declinación y campo del WMM', () {
    // Se comprueba en grafo_test con el archivo real; aquí, que se lean.
    final grafo = GrafoCampus.desdeJson({
      'version': 'x',
      'declinacion': -8.5,
      'campo_magnetico_ut': 33.0,
      'nodos': <Object>[],
      'aristas': <Object>[],
      'accesos': <Object>[],
    });
    expect(grafo.campoMagnetico, 33);
    expect(grafo.declinacion, -8.5);
  });
}

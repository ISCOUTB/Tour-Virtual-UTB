import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tour_virtual/datos/analitica.dart';
import 'package:tour_virtual/nucleo/errores.dart';

/// Deja correr las microtareas y los reintentos de 1 ms de la cola.
Future<void> dejarCorrer() =>
    Future<void>.delayed(const Duration(milliseconds: 30));

/// «API» de prueba: guarda lo que recibe y responde lo que se le pida.
class ApiFalsa {
  final recibidos = <EventoAnalitica>[];

  /// Respuestas por llamada, en orden. Vacía: acepta.
  final respuestas = <Object>[];
  var llamadas = 0;

  Future<bool> enviar(EventoAnalitica evento) async {
    llamadas++;
    final respuesta = respuestas.isEmpty ? true : respuestas.removeAt(0);
    if (respuesta is bool) {
      if (respuesta) recibidos.add(evento);
      return respuesta;
    }
    throw respuesta;
  }
}

ColaAnalitica nuevaCola(ApiFalsa api) => ColaAnalitica(
  enviar: api.enviar,
  espera: (_) => const Duration(milliseconds: 1),
);

void main() {
  group('sesión anónima', () {
    test('es un UUID v4 al azar', () {
      final formato = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      for (var semilla = 0; semilla < 50; semilla++) {
        expect(nuevaSesionId(Random(semilla)), matches(formato));
      }
      expect(nuevaSesionId(), isNot(nuevaSesionId()));
    });

    test('todos los eventos de una apertura comparten sesión', () async {
      final api = ApiFalsa();
      final cola = nuevaCola(api)..consentimiento = true;
      cola.registrar(TipoEvento.mapaAbierto);
      cola.registrar(TipoEvento.escenaVista, escenaId: 1);
      await dejarCorrer();

      expect(api.recibidos.map((e) => e.sesionId).toSet(), {cola.sesionId});
      expect(nuevaCola(ApiFalsa()).sesionId, isNot(cola.sesionId));
    });
  });

  test('el cuerpo usa los nombres camelCase de RegistrarEventoRequest', () {
    const evento = EventoAnalitica(
      sesionId: 'ses',
      tipo: TipoEvento.hotspotTocado,
      escenaId: 1,
      datos: {'destino': 3},
    );
    expect(evento.toJson(), {
      'sesionId': 'ses',
      'tipo': 'hotspot_tapped',
      'escenaId': 1,
      'payload': {'destino': 3},
    });
    // Los nulos y el payload vacío no viajan.
    expect(
      const EventoAnalitica(
        sesionId: 'ses',
        tipo: TipoEvento.mapaAbierto,
      ).toJson().keys,
      ['sesionId', 'tipo'],
    );
  });

  test('los tipos son los que acepta la API', () {
    expect(TipoEvento.values.map((t) => t.clave).toSet(), {
      'virtual_map_open',
      'scene_viewed',
      'hotspot_tapped',
      'poi_media_played',
      'tour_completed',
    });
  });

  group('consentimiento', () {
    test(
      'sin respuesta nada sale del teléfono; al aceptar, sale en orden',
      () async {
        final api = ApiFalsa();
        final cola = nuevaCola(api);
        cola.registrar(TipoEvento.mapaAbierto);
        cola.registrar(TipoEvento.escenaVista, escenaId: 7);
        await dejarCorrer();
        expect(api.llamadas, 0);
        expect(cola.pendientes, 2);

        cola.consentimiento = true;
        await dejarCorrer();
        expect(api.recibidos.map((e) => e.tipo), [
          TipoEvento.mapaAbierto,
          TipoEvento.escenaVista,
        ]);
        expect(cola.pendientes, 0);
      },
    );

    test('al rechazar se descarta lo pendiente y lo siguiente', () async {
      final api = ApiFalsa();
      final cola = nuevaCola(api);
      cola.registrar(TipoEvento.mapaAbierto);
      cola.consentimiento = false;
      cola.registrar(TipoEvento.escenaVista);
      await dejarCorrer();

      expect(api.llamadas, 0);
      expect(cola.pendientes, 0);
    });

    test('retirarlo a mitad de un envío no reenvía ni rompe la cola', () async {
      final api = ApiFalsa();
      final cola = nuevaCola(api)..consentimiento = true;
      cola.registrar(TipoEvento.mapaAbierto);
      cola.registrar(TipoEvento.escenaVista);
      cola.consentimiento = false;
      await dejarCorrer();

      expect(cola.pendientes, 0);
      expect(api.llamadas, lessThanOrEqualTo(1));
    });
  });

  group('envío', () {
    test('un fallo de red deja el evento en la cola y se reintenta', () async {
      final api = ApiFalsa()
        ..respuestas.addAll([const FalloDeConexion(), const FalloDeTiempo()]);
      final cola = nuevaCola(api)..consentimiento = true;
      cola.registrar(TipoEvento.mapaAbierto);
      cola.registrar(TipoEvento.escenaVista);
      await dejarCorrer();

      expect(api.llamadas, 4);
      expect(api.recibidos.map((e) => e.tipo), [
        TipoEvento.mapaAbierto,
        TipoEvento.escenaVista,
      ]);
    });

    test('lo que la API rechaza se descarta y se sigue con lo demás', () async {
      final api = ApiFalsa()..respuestas.add(false);
      final cola = nuevaCola(api)..consentimiento = true;
      cola.registrar(TipoEvento.mapaAbierto);
      cola.registrar(TipoEvento.escenaVista);
      await dejarCorrer();

      expect(api.llamadas, 2);
      expect(api.recibidos.single.tipo, TipoEvento.escenaVista);
    });

    test('registrar nunca lanza, aunque el envío explote (RF-24)', () async {
      final api = ApiFalsa()
        ..respuestas.add(StateError('fallo de programación'));
      final cola = nuevaCola(api)..consentimiento = true;
      expect(() => cola.registrar(TipoEvento.mapaAbierto), returnsNormally);
      cola.registrar(TipoEvento.escenaVista);
      await dejarCorrer();

      // El evento que explotó se descarta; reintentarlo no lo arreglaría.
      expect(api.recibidos.single.tipo, TipoEvento.escenaVista);
    });

    test('sin red mucho rato, la cola no crece sin límite', () async {
      final cola = nuevaCola(ApiFalsa());
      for (var i = 0; i < ColaAnalitica.maxPendientes + 20; i++) {
        cola.registrar(TipoEvento.escenaVista, escenaId: i);
      }
      expect(cola.pendientes, ColaAnalitica.maxPendientes);
    });

    test('al cerrar deja de reintentar', () async {
      final api = ApiFalsa()
        ..respuestas.addAll(List.filled(50, const FalloDeConexion()));
      final cola = ColaAnalitica(
        enviar: api.enviar,
        espera: (_) => const Duration(milliseconds: 5),
      )..consentimiento = true;
      cola.registrar(TipoEvento.mapaAbierto);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      cola.cerrar();
      final llamadas = api.llamadas;
      await dejarCorrer();

      expect(api.llamadas, llamadas);
      expect(cola.pendientes, 0);
      cola.registrar(TipoEvento.escenaVista);
      expect(cola.pendientes, 0);
    });

    test('la espera crece hasta dos minutos', () {
      expect(
        [for (var f = 1; f <= 7; f++) esperaPorDefecto(f).inSeconds],
        [5, 10, 20, 40, 80, 120, 120],
      );
    });
  });
}

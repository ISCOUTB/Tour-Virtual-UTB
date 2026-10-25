import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:utb_tour/datos/repositorio_contenido.dart';
import 'package:utb_tour/datos/repositorio_demo.dart';
import 'package:utb_tour/datos/subtitulos.dart';
import 'package:utb_tour/nucleo/errores.dart';

void main() {
  test(
    'RepositorioContenido consume el contrato HTTP y resuelve medios',
    () async {
      final cliente = MockClient((request) async {
        expect(request.headers['accept'], 'application/json');
        if (request.url.path == '/api/lugares/1/pois') {
          return http.Response(
            jsonEncode([
              {
                'id': 1,
                'lugar_id': 1,
                'nombre': 'Biblioteca',
                'audiencias': ['externo'],
                'activo': true,
              },
            ]),
            200,
          );
        }
        if (request.url.path == '/api/pois/1') {
          return http.Response(
            jsonEncode({
              'poi': {
                'id': 1,
                'lugar_id': 1,
                'nombre': 'Biblioteca',
                'audiencias': ['externo'],
                'activo': true,
              },
              'medios': [
                {
                  'id': 1,
                  'poi_id': 1,
                  'tipo': 'audio',
                  'url': 'audios/biblioteca.mp3',
                },
              ],
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });
      final repositorio = RepositorioContenido(
        baseUrl: 'http://127.0.0.1:5209',
        cliente: cliente,
      );

      expect((await repositorio.obtenerPois(1)).single.nombre, 'Biblioteca');
      expect(
        (await repositorio.obtenerPoiDetalle(1)).audios.single.url,
        'http://127.0.0.1:5209/audios/biblioteca.mp3',
      );
    },
  );

  test('RepositorioContenido traduce un 404 a contenido ausente', () async {
    final repositorio = RepositorioContenido(
      baseUrl: 'http://127.0.0.1:5209',
      cliente: MockClient((_) async => http.Response('{}', 404)),
    );

    expect(() => repositorio.obtenerPois(1), throwsA(isA<FalloSinContenido>()));
  });

  test('el modo demo replica la base compartida', () async {
    const demo = RepositorioDemo();
    final pois = await demo.obtenerPois(1);

    // Las cinco paradas: el puente A3-A5 es visible para todos desde el
    // 2026-10-11.
    final paradas = pois.where((p) => p.esParada).toList();
    expect(paradas.map((p) => p.nombre), contains('Puente A3 - A5'));
    expect(paradas, hasLength(5));
    expect(paradas.every((p) => p.tienePosicionEnMapa), isTrue);

    // Los demás lugares del campus, sin panorámica, incluidas las estaciones
    // del guion que el equipo marcó sobre el mapa.
    final otros = pois.where((p) => !p.esParada).toList();
    expect(
      otros.map((p) => p.nombre),
      containsAll(['Edificio A1', 'QuantaLab']),
    );
    expect(otros.every((p) => p.tienePosicionEnMapa), isTrue);

    // Las panorámicas viven en S3: el demo lo dice en vez de fingirlas.
    expect(() => demo.obtenerRecorrido(1), throwsA(isA<FalloSinContenido>()));
  });

  test(
    'cada panorámica del demo se describe para el lector de pantalla',
    () async {
      // Copia de scripts/datos/escenas_texto_alt.json: si una cambia y la otra
      // no, esto lo dice.
      final datos =
          jsonDecode(
                File(
                  '../../scripts/datos/escenas_texto_alt.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      const demo = RepositorioDemo(medios: 'http://medios.invalid');
      final recorrido = await demo.obtenerRecorrido(1);

      expect(recorrido.escenas, hasLength(5));
      for (final escena in recorrido.escenas) {
        final slug = Uri.parse(
          escena.imagenUrl,
        ).pathSegments.last.replaceFirst('.jpg', '');
        expect(escena.textoAlt, datos[slug], reason: slug);
      }
    },
  );

  test(
    'el demo encuentra las narraciones por idioma de la carpeta local',
    () async {
      // Lo que hay en la carpeta: el original, una narración en inglés con sus
      // subtítulos y los del original. Nada más.
      const hay = {
        '/audios/biblioteca.en.mp3',
        '/subtitulos/biblioteca.vtt',
        '/subtitulos/biblioteca.en.vtt',
      };
      final demo = RepositorioDemo(
        medios: 'http://127.0.0.1:8765',
        cliente: MockClient(
          (peticion) async => http.Response(
            'WEBVTT\n\n00:00.000 --> 00:02.000\nHola',
            hay.contains(peticion.url.path) ? 200 : 404,
          ),
        ),
      );

      final detalle = await demo.obtenerPoiDetalle(1);
      final original = detalle.audioPara('es')!;
      final ingles = detalle.audioPara('en')!;

      expect(detalle.audios, hasLength(2));
      expect(
        original.subtitulosUrl,
        'http://127.0.0.1:8765/subtitulos/biblioteca.vtt',
      );
      expect(ingles.url, 'http://127.0.0.1:8765/audios/biblioteca.en.mp3');
      expect(ingles.idioma, 'en');
      expect(
        (await demo.obtenerSubtitulos(ingles.subtitulosUrl!)).texto,
        'Hola',
      );
    },
  );

  test('un 204 sin cuerpo es «no hay», no un error', () async {
    // Así responde la API real cuando no hay ruta para la audiencia.
    final repositorio = RepositorioContenido(
      baseUrl: 'http://127.0.0.1:5209',
      cliente: MockClient((_) async => http.Response('', 204)),
    );

    expect(await repositorio.obtenerRutaActual(1), isNull);
  });

  group('Subtitulos', () {
    const vtt =
        'WEBVTT\n'
        '\n'
        'NOTE generado por el equipo de contenido\n'
        '\n'
        '1\n'
        '00:00:00.000 --> 00:00:04.000\n'
        'Más que una <i>biblioteca</i>:\n'
        '\n'
        '2\n'
        '00:00:04.500 --> 00:00:09.500 align:start\n'
        'concentración y disciplina.\n';

    test('un WebVTT da la transcripción en texto plano', () {
      final subtitulos = Subtitulos.leer(vtt);
      expect(
        subtitulos.texto,
        'Más que una biblioteca: concentración y disciplina.',
      );
      expect(subtitulos.sincronizados, isTrue);
    });

    test('cada momento muestra su frase, y los silencios ninguna', () {
      final subtitulos = Subtitulos.leer(vtt);
      expect(
        subtitulos.en(const Duration(seconds: 1))?.texto,
        'Más que una biblioteca:',
      );
      expect(subtitulos.en(const Duration(milliseconds: 4200)), isNull);
      expect(
        subtitulos.en(const Duration(seconds: 6))?.texto,
        'concentración y disciplina.',
      );
      expect(subtitulos.en(const Duration(seconds: 12)), isNull);
    });

    test('un SRT también se lee, con la coma de los milisegundos', () {
      final srt = Subtitulos.leer(
        '1\r\n00:00:01,000 --> 00:00:03,250\r\nHola &amp; bienvenida\r\n',
      );
      expect(srt.lineas.single.inicio, const Duration(seconds: 1));
      expect(srt.lineas.single.fin, const Duration(milliseconds: 3250));
      expect(srt.texto, 'Hola & bienvenida');
    });

    test('un texto plano es transcripción sin subtítulos en vivo', () {
      final plano = Subtitulos.leer('Texto plano.\n\nSegundo párrafo.');
      expect(plano.texto, 'Texto plano. Segundo párrafo.');
      expect(plano.sincronizados, isFalse);
      expect(plano.en(const Duration(seconds: 1)), isNull);
    });
  });

  test('pide el contenido en el idioma de la interfaz', () async {
    final cabeceras = <String, String>{};
    final repositorio = RepositorioContenido(
      baseUrl: 'http://127.0.0.1:5209',
      idioma: 'pt-BR',
      cliente: MockClient((peticion) async {
        cabeceras.addAll(peticion.headers);
        return http.Response('[]', 200);
      }),
    );

    await repositorio.obtenerPois(1);
    // Con el español como respaldo: el servidor aún no traduce, y así sabe
    // que el original también sirve.
    expect(cabeceras['Accept-Language'], 'pt-BR, es;q=0.5');
    expect(repositorio.idiomaContenido, 'es');
  });

  test('toma el idioma del contenido de la respuesta', () async {
    final repositorio = RepositorioContenido(
      baseUrl: 'http://127.0.0.1:5209',
      idioma: 'en',
      cliente: MockClient(
        (_) async =>
            http.Response('[]', 200, headers: {'content-language': 'en'}),
      ),
    );

    await repositorio.obtenerPois(1);
    expect(repositorio.idiomaContenido, 'en');
  });
}

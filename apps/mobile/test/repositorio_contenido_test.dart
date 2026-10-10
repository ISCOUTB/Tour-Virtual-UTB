import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:utb_tour/datos/repositorio_contenido.dart';
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
        (await repositorio.obtenerPoiDetalle(1)).audio!.url,
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
}

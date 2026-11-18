// Contrato contra una API viva: el código real de la app (repositorio,
// modelos, selección de narración, lector de subtítulos) sobre las respuestas
// reales de `services/api` y del Storage de Supabase.
//
// Se salta salvo que se pida, porque necesita red y la API levantada:
//
//   flutter test test/api_real_test.dart --dart-define=API_REAL=http://127.0.0.1:5209
//
// Escribe en la base: registra un evento de cada tipo, marcado con
// `payload.prueba = "contrato"`. Para borrarlos:
//
//   delete from public.eventos where payload->>'prueba' = 'contrato';
//
// Las descargas van una tras otra (88 narraciones y sus subtítulos): los 30 s
// por defecto no alcanzan.
@TestOn('vm')
@Timeout(Duration(minutes: 3))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tour_virtual/datos/analitica.dart';
import 'package:tour_virtual/datos/modelos/modelos.dart';
import 'package:tour_virtual/datos/repositorio_contenido.dart';
import 'package:tour_virtual/nucleo/idiomas.dart';

const api = String.fromEnvironment('API_REAL');
const lugar = 1;

void main() {
  final saltar = api.isEmpty
      ? 'Sin API viva. Ver la cabecera del archivo: --dart-define=API_REAL=...'
      : null;

  late RepositorioContenido repositorio;
  late List<Poi> pois;
  late Recorrido recorrido;
  final detalles = <int, PoiDetalle>{};

  setUpAll(() async {
    if (api.isEmpty) return;
    repositorio = RepositorioContenido(baseUrl: api);
    pois = await repositorio.obtenerPois(lugar);
    recorrido = await repositorio.obtenerRecorrido(lugar);
    for (final poi in pois) {
      detalles[poi.id] = await repositorio.obtenerPoiDetalle(poi.id);
    }
  });

  group('contenido publicado', skip: saltar, () {
    test('todos los lugares tienen posición en el plano', () {
      expect(pois, isNotEmpty);
      expect([
        for (final p in pois)
          if (p.lat == null || p.lng == null) p.nombre,
      ], isEmpty);
    });

    test('cada parada abre una escena con panorámica y texto alternativo', () {
      final paradas = pois.where((p) => p.esParada).toList();
      expect(paradas, isNotEmpty);
      for (final parada in paradas) {
        final escena = recorrido.escenaPorId(parada.escenaPrincipalId!);
        expect(escena, isNotNull, reason: parada.nombre);
        expect(
          escena!.imagenUrl,
          startsWith('https://'),
          reason: parada.nombre,
        );
        // WCAG 1.1.1: lo que dice el lector de pantalla en el visor 360.
        expect(escena.textoAlt, isNotNull, reason: parada.nombre);
      }
    });

    test('ningún hotspot lleva a una escena que no existe', () {
      for (final hotspots in recorrido.hotspotsPorEscena.values) {
        for (final h in hotspots) {
          if (h.escenaDestinoId == null) continue;
          expect(
            recorrido.escenaPorId(h.escenaDestinoId!),
            isNotNull,
            reason: 'hotspot ${h.id}',
          );
        }
      }
    });

    test('las panorámicas se descargan', () async {
      for (final escena in recorrido.escenas) {
        for (final url in [escena.imagenUrlBaja, escena.imagenUrl]) {
          if (url == null) continue;
          final respuesta = await http.get(Uri.parse(url));
          expect(respuesta.statusCode, 200, reason: escena.nombre);
          expect(
            respuesta.headers['content-type'],
            startsWith('image/'),
            reason: escena.nombre,
          );
        }
      }
    });

    test('cada idioma de la interfaz oye la narración en su idioma', () {
      final narrados = detalles.values.where((d) => d.audios.isNotEmpty);
      expect(narrados, isNotEmpty);
      for (final detalle in narrados) {
        for (final idioma in idiomasUi) {
          final etiqueta = idioma.locale.toLanguageTag();
          final audio = detalle.audioPara(etiqueta)!;
          expect(
            audio.idiomaEfectivo.toLowerCase(),
            etiqueta.toLowerCase(),
            reason: '${detalle.poi.nombre} en $etiqueta',
          );
        }
      }
    });

    test('cada narración se descarga y tiene subtítulos legibles', () async {
      for (final detalle in detalles.values) {
        for (final audio in detalle.audios) {
          final nombre = '${detalle.poi.nombre} (${audio.idiomaEfectivo})';
          final mp3 = await http.get(
            Uri.parse(audio.url),
            headers: const {'Range': 'bytes=0-1023'},
          );
          expect(mp3.statusCode, anyOf(200, 206), reason: nombre);
          expect(mp3.headers['content-type'], 'audio/mpeg', reason: nombre);

          // WCAG 1.2.1: sin subtítulos no se puede publicar.
          expect(audio.subtitulosUrl, isNotNull, reason: nombre);
          final subtitulos = await repositorio.obtenerSubtitulos(
            audio.subtitulosUrl!,
          );
          expect(subtitulos.lineas, isNotEmpty, reason: nombre);
        }
      }
    });
  });

  group('analítica', skip: saltar, () {
    test('la API acepta un evento de cada tipo', () async {
      final sesion = nuevaSesionId();
      final parada = pois.firstWhere((p) => p.esParada);
      final escena = recorrido.escenaPorId(parada.escenaPrincipalId!)!;
      final audio = detalles.values.expand((d) => d.audios).first;
      const marca = {'prueba': 'contrato'};

      final eventos = [
        EventoAnalitica(
          sesionId: sesion,
          tipo: TipoEvento.mapaAbierto,
          datos: marca,
        ),
        EventoAnalitica(
          sesionId: sesion,
          tipo: TipoEvento.escenaVista,
          escenaId: escena.id,
          poiId: escena.poiId,
          datos: marca,
        ),
        EventoAnalitica(
          sesionId: sesion,
          tipo: TipoEvento.hotspotTocado,
          escenaId: escena.id,
          datos: {...marca, 'tipo': 'navegacion'},
        ),
        EventoAnalitica(
          sesionId: sesion,
          tipo: TipoEvento.medioReproducido,
          poiId: audio.poiId,
          datos: {...marca, 'medio': audio.id, 'tipo': 'audio'},
        ),
        EventoAnalitica(
          sesionId: sesion,
          tipo: TipoEvento.recorridoCompletado,
          datos: {...marca, 'paradas': 5},
        ),
      ];
      for (final evento in eventos) {
        expect(
          await repositorio.registrarEvento(evento),
          isTrue,
          reason: '$evento',
        );
      }
    });

    test('rechaza un evento con un POI que no existe', () async {
      final aceptado = await repositorio.registrarEvento(
        EventoAnalitica(
          sesionId: nuevaSesionId(),
          tipo: TipoEvento.escenaVista,
          poiId: 999999999,
          datos: const {'prueba': 'contrato'},
        ),
      );
      expect(aceptado, isFalse);
    });
  });
}

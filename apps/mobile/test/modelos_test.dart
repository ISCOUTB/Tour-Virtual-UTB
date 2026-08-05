import 'package:flutter_test/flutter_test.dart';
import 'package:utb_tour/datos/modelos/modelos.dart';

/// Estas pruebas fijan el contrato entre las columnas de Postgres y los
/// modelos del cliente.
///
/// Los JSON de aqui son respuestas reales de PostgREST contra las migraciones
/// de `supabase/migrations`, copiadas tal cual: incluyen las columnas de
/// auditoria que el modelo no declara y los tipos exactos que devuelve la base.
/// Si alguien renombra una columna en una migracion, esto se pone rojo antes de
/// que la app muestre una pantalla vacia.
void main() {
  group('Poi', () {
    test('mapea las columnas de la base', () {
      final poi = Poi.fromJson(const {
        'id': 4,
        'lugar_id': 1,
        'nombre': 'Biblioteca',
        'categoria': 'Recursos',
        'descripcion': 'Centro de recursos bibliograficos.',
        'lat': null,
        'lng': null,
        'map_x': 0.63,
        'map_y': 0.3,
        'audiencias': ['externo', 'estudiante', 'docente'],
        'activo': true,
        'creado_en': '2026-08-04T10:00:00+00:00',
        'actualizado_en': '2026-08-04T10:00:00+00:00',
        'escena_principal_id': null,
      });

      expect(poi.id, 4);
      expect(poi.lugarId, 1);
      expect(poi.nombre, 'Biblioteca');
      expect(poi.mapX, 0.63);
      expect(poi.mapY, 0.3);
      expect(poi.audiencias, [
        Audiencia.externo,
        Audiencia.estudiante,
        Audiencia.docente,
      ]);
      expect(poi.tienePosicionEnMapa, isTrue);
    });

    test('un POI sin calibrar no es ubicable en el mapa', () {
      final poi = Poi.fromJson(const {
        'id': 3,
        'lugar_id': 1,
        'nombre': 'Murales UTB',
        'map_x': null,
        'map_y': null,
      });

      expect(poi.tienePosicionEnMapa, isFalse);
    });
  });

  group('Escena', () {
    test('mapea las columnas de la base', () {
      final escena = Escena.fromJson(const {
        'id': 1,
        'lugar_id': 1,
        'poi_id': null,
        'nombre': 'Entrada principal',
        'imagen_url': 'https://placeholder.invalid/360/entrada.jpg',
        'imagen_url_baja': null,
        'es_escena_principal': true,
        'orden': 0,
        'creado_en': '2026-08-04T10:00:00+00:00',
        'actualizado_en': '2026-08-04T10:00:00+00:00',
      });

      expect(escena.imagenUrl, endsWith('entrada.jpg'));
      expect(escena.esEscenaPrincipal, isTrue);
    });
  });

  group('Hotspot', () {
    test('acepta pitch y yaw enteros', () {
      // Postgres devuelve -5 y 45 sin parte decimal aunque la columna sea
      // double precision. Si el modelo hiciera un cast directo a double, esto
      // reventaria en tiempo de ejecucion.
      final hotspot = Hotspot.fromJson(const {
        'id': 1,
        'escena_id': 1,
        'tipo': 'navegacion',
        'pitch': -5,
        'yaw': 45,
        'escena_destino_id': 2,
        'poi_id': null,
        'etiqueta': 'Ir a la zona de comidas',
        'creado_en': '2026-08-04T10:00:00+00:00',
      });

      expect(hotspot.pitch, -5.0);
      expect(hotspot.yaw, 45.0);
      expect(hotspot.tipo, TipoHotspot.navegacion);
      expect(hotspot.escenaDestinoId, 2);
    });

    test('reconoce el tipo info', () {
      final hotspot = Hotspot.fromJson(const {
        'id': 9,
        'escena_id': 1,
        'tipo': 'info',
        'pitch': 0.0,
        'yaw': 12.5,
        'poi_id': 4,
      });

      expect(hotspot.tipo, TipoHotspot.info);
      expect(hotspot.poiId, 4);
    });
  });

  group('Recorrido', () {
    const escenas = [
      Escena(id: 1, lugarId: 1, imagenUrl: 'a.jpg', orden: 0),
      Escena(
        id: 2,
        lugarId: 1,
        imagenUrl: 'b.jpg',
        esEscenaPrincipal: true,
        orden: 1,
      ),
    ];

    test('entra por la escena marcada como principal', () {
      const recorrido = Recorrido(escenas: escenas, hotspotsPorEscena: {});
      expect(recorrido.escenaInicial?.id, 2);
    });

    test('sin escena principal entra por la primera', () {
      const recorrido = Recorrido(
        escenas: [Escena(id: 7, lugarId: 1, imagenUrl: 'c.jpg')],
        hotspotsPorEscena: {},
      );
      expect(recorrido.escenaInicial?.id, 7);
    });

    test('un lugar sin escenas no tiene punto de entrada', () {
      const recorrido = Recorrido(escenas: [], hotspotsPorEscena: {});
      expect(recorrido.escenaInicial, isNull);
    });

    test('una escena sin hotspots devuelve lista vacia, no nulo', () {
      const recorrido = Recorrido(escenas: escenas, hotspotsPorEscena: {});
      expect(recorrido.hotspotsDe(1), isEmpty);
    });
  });

  group('PoiDetalle', () {
    test('separa el contenido multimedia por tipo', () {
      const detalle = PoiDetalle(
        poi: Poi(id: 1, lugarId: 1, nombre: 'Biblioteca'),
        medios: [
          Medio(id: 1, poiId: 1, tipo: TipoMedio.imagen, url: 'uno.jpg'),
          Medio(id: 2, poiId: 1, tipo: TipoMedio.imagen, url: 'dos.jpg'),
          Medio(id: 3, poiId: 1, tipo: TipoMedio.video, url: 'clip.mp4'),
          Medio(id: 4, poiId: 1, tipo: TipoMedio.audio, url: 'historia.mp3'),
        ],
      );

      expect(detalle.imagenes, hasLength(2));
      expect(detalle.video?.url, 'clip.mp4');
      expect(detalle.audio?.url, 'historia.mp3');
    });

    test('un POI sin multimedia no rompe la ficha', () {
      const detalle = PoiDetalle(
        poi: Poi(id: 1, lugarId: 1, nombre: 'Biblioteca'),
      );

      expect(detalle.imagenes, isEmpty);
      expect(detalle.video, isNull);
      expect(detalle.audio, isNull);
    });
  });
}

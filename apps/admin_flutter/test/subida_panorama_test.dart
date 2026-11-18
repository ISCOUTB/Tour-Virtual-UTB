import 'dart:typed_data';

import 'package:admin_flutter/data/api/api_client.dart';
import 'package:admin_flutter/data/models/escena.dart';
import 'package:admin_flutter/data/models/poi.dart';
import 'package:admin_flutter/data/repositories/escena_repository.dart';
import 'package:admin_flutter/data/repositories/poi_repository.dart';
import 'package:admin_flutter/data/subida_panorama.dart';
import 'package:flutter_test/flutter_test.dart';

/// Escenas como las devuelve la API: `listar` es el endpoint público, que
/// esconde las escenas sin imagen y las de lugares inactivos.
class EscenasFalsas implements EscenaRepository {
  EscenasFalsas({this.visibles = const []});

  final List<Escena> visibles;
  final creadas = <Escena>[];
  final actualizadas = <Escena>[];
  final subidas = <int>[];

  /// Si no es nulo, la próxima subida lo lanza.
  Object? falloSubida;
  String? advertencia;
  var _siguienteId = 100;

  @override
  Future<List<Escena>> listar() async => visibles;

  @override
  Future<Escena> crear(Escena e) async {
    final creada = Escena(
      id: _siguienteId++,
      lugarId: e.lugarId,
      poiId: e.poiId,
      nombre: e.nombre,
      esEscenaPrincipal: e.esEscenaPrincipal,
      orden: e.orden,
      textoAlt: e.textoAlt,
    );
    creadas.add(creada);
    return creada;
  }

  @override
  Future<Escena> actualizar(Escena e) async {
    actualizadas.add(e);
    return e;
  }

  @override
  Future<void> eliminar(int id) => throw UnimplementedError();

  @override
  Future<PanoramaSubida> subirImagen(
    int escenaId, {
    required Uint8List bytes,
    required String filename,
    bool bajaResolucion = false,
    String? carpeta,
  }) async {
    subidas.add(escenaId);
    final fallo = falloSubida;
    if (fallo != null) {
      falloSubida = null;
      throw fallo;
    }
    return PanoramaSubida(
      imagenUrl: 'panoramas/$filename',
      imagenUrlBaja: 'panoramas/baja-$filename',
      advertencia: advertencia,
    );
  }
}

class PoisFalsos extends PoiRepository {
  final actualizados = <Poi>[];

  @override
  Future<Poi> actualizar(Poi poi) async {
    actualizados.add(poi);
    return poi;
  }

  @override
  Future<List<Poi>> listar() => throw UnimplementedError();
  @override
  Future<PoiDetalle> detalle(int id) => throw UnimplementedError();
  @override
  Future<Poi> crear(Poi poi) => throw UnimplementedError();
  @override
  Future<void> eliminar(int id) => throw UnimplementedError();
}

/// La escena de la Biblioteca, la principal del lugar: el recorrido de la
/// app arranca por ella.
const biblioteca = Escena(
  id: 1,
  lugarId: 1,
  poiId: 1,
  nombre: 'Biblioteca',
  esEscenaPrincipal: true,
  orden: 0,
);

/// Una parada con encuadre calibrado.
const zonaT = Escena(
  id: 4,
  lugarId: 1,
  poiId: 4,
  nombre: 'Zona T',
  imagenUrl: 'https://firmada.example/zona-t.jpg?X-Amz-Signature=abc',
  orden: 3,
  vistaInicialYaw: -10,
  vistaInicialPitch: -4,
  textoAlt: 'Mesas al aire libre bajo los árboles.',
);

const lugarNuevo = Poi(id: 30, lugarId: 1, nombre: 'Granja Solar');
const poiZonaT = Poi(id: 4, lugarId: 1, nombre: 'Zona T', escenaPrincipalId: 4);

void main() {
  late EscenasFalsas escenas;
  late PoisFalsos pois;
  late SubidaPanorama subida;

  SubidaPanorama nueva(EscenasFalsas e) =>
      SubidaPanorama(escenas: e, pois: pois);

  setUp(() {
    escenas = EscenasFalsas(visibles: const [biblioteca, zonaT]);
    pois = PoisFalsos();
    subida = nueva(escenas);
  });

  Future<String?> subir(
    Poi poi, {
    Escena? escena,
    String alt = 'Paneles solares en hileras.',
  }) => subida.subir(
    poi: poi,
    escena: escena,
    bytes: Uint8List(4),
    nombreArchivo: 'granja.jpg',
    textoAlt: alt,
  );

  group('un lugar sin escena', () {
    test('crea una escena que no es la principal del lugar', () async {
      await subir(lugarNuevo);

      final creada = escenas.creadas.single;
      // La principal del lugar decide dónde arranca el recorrido de la app.
      expect(creada.esEscenaPrincipal, isFalse);
      expect(creada.orden, 4, reason: 'después de la última visible');
      expect(creada.textoAlt, 'Paneles solares en hileras.');
      expect(pois.actualizados.single.escenaPrincipalId, creada.id);
      expect(escenas.subidas, [creada.id]);
      // El texto alternativo ya va en la creación: no hace falta un PUT.
      expect(escenas.actualizadas, isEmpty);
    });

    test('si la imagen falla, el reintento reutiliza la escena', () async {
      escenas.falloSubida = ApiException('No es una imagen', statusCode: 400);
      await expectLater(subir(lugarNuevo), throwsA(isA<ApiException>()));

      // La pantalla reintenta con el mismo POI, que sigue sin escena.
      await subir(lugarNuevo);

      expect(escenas.creadas, hasLength(1));
      expect(escenas.subidas, [100, 100]);
    });

    test('sin escenas visibles, el orden es 0', () async {
      escenas = EscenasFalsas();
      subida = nueva(escenas);
      await subir(lugarNuevo);

      expect(escenas.creadas.single.orden, 0);
      expect(escenas.creadas.single.esEscenaPrincipal, isFalse);
    });
  });

  group('un lugar con escena', () {
    test('no crea otra escena y sube a la suya', () async {
      await subir(poiZonaT, escena: zonaT, alt: zonaT.textoAlt!);

      expect(escenas.creadas, isEmpty);
      expect(escenas.subidas, [4]);
      expect(escenas.actualizadas, isEmpty, reason: 'el texto no cambió');
    });

    test('al cambiar el texto conserva todo lo demás de la escena', () async {
      await subir(poiZonaT, escena: zonaT, alt: 'Terraza con mesas.');

      final puesta = escenas.actualizadas.single;
      expect(puesta.textoAlt, 'Terraza con mesas.');
      expect(puesta.esEscenaPrincipal, isFalse);
      expect(puesta.orden, 3);
      expect(puesta.vistaInicialYaw, -10);
      expect(puesta.vistaInicialPitch, -4);
      // Las rutas que devolvió la subida, nunca la URL firmada que se leyó.
      expect(puesta.imagenUrl, 'panoramas/granja.jpg');
      expect(puesta.imagenUrlBaja, 'panoramas/baja-granja.jpg');
    });

    test('si no se pudo leer la escena, no la reescribe y lo avisa', () async {
      // Lugar inactivo: la API pública no deja ver su escena.
      final aviso = await subir(poiZonaT, alt: 'Terraza con mesas.');

      expect(escenas.subidas, [4]);
      expect(escenas.actualizadas, isEmpty);
      expect(aviso, SubidaPanorama.avisoSinEscena);
    });
  });

  test('pasa la advertencia del servidor', () async {
    escenas.advertencia = 'La imagen no tiene proporción 2:1.';
    expect(await subir(lugarNuevo), 'La imagen no tiene proporción 2:1.');
  });
}

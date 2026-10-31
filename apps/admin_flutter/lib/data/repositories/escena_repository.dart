import 'dart:typed_data';

import '../../core/config.dart';
import '../api/api_client.dart';
import '../models/escena.dart';

abstract class EscenaRepository {
  /// Escenas 360° del lugar configurado (GET /api/lugares/{id}/recorrido).
  Future<List<Escena>> listar();

  Future<Escena> crear(Escena escena);

  Future<Escena> actualizar(Escena escena);

  Future<void> eliminar(int id);

  /// POST /api/admin/escenas/{id}/imagen (multipart: Archivo, Carpeta).
  /// [bajaResolucion] sube la versión liviana de la imagen.
  Future<void> subirImagen(
    int escenaId, {
    required Uint8List bytes,
    required String filename,
    bool bajaResolucion = false,
    String? carpeta,
  });
}

class HttpEscenaRepository implements EscenaRepository {
  HttpEscenaRepository(this._api, {int? lugarId})
      : _lugarId = lugarId ?? AppConfig.lugarId;

  final ApiClient _api;
  final int _lugarId;

  Escena _fromJson(Object? data) =>
      Escena.fromJson((data as Map).cast<String, dynamic>());

  @override
  Future<List<Escena>> listar() async {
    final data = await _api.get('/api/lugares/$_lugarId/recorrido') as Map;
    final escenas = (data['escenas'] as List?) ?? const [];
    return escenas.map(_fromJson).toList();
  }

  @override
  Future<Escena> crear(Escena escena) async =>
      _fromJson(await _api.post('/api/admin/escenas', escena.toCreateJson()));

  @override
  Future<Escena> actualizar(Escena escena) async => _fromJson(
      await _api.put('/api/admin/escenas/${escena.id}', escena.toUpdateJson()));

  @override
  Future<void> eliminar(int id) => _api.delete('/api/admin/escenas/$id');

  @override
  Future<void> subirImagen(
    int escenaId, {
    required Uint8List bytes,
    required String filename,
    bool bajaResolucion = false,
    String? carpeta,
  }) =>
      _api.uploadFile(
        '/api/admin/escenas/$escenaId/imagen',
        bytes: bytes,
        filename: filename,
        carpeta: carpeta,
        query: {'esBajaResolucion': bajaResolucion.toString()},
      );
}

/// Versión en memoria para maquetar sin backend.
class MockEscenaRepository implements EscenaRepository {
  MockEscenaRepository() {
    // Las cinco escenas reales de la app (ContenidoInicial.cs), con su vista
    // inicial. Las panorámicas son material institucional y no se incluyen.
    _escenas = const [
      Escena(
          id: 1,
          lugarId: 1,
          poiId: 1,
          nombre: 'Biblioteca',
          esEscenaPrincipal: true,
          orden: 0,
          vistaInicialYaw: 152,
          vistaInicialPitch: -5,
          textoAlt:
              'Vestíbulo amplio y luminoso de la biblioteca, de techo alto y piso claro. En el centro hay un mostrador de atención curvo. A la izquierda se abre un pasillo largo con estanterías y mesas de lectura; a la derecha, mesas junto a ventanales que dan a un jardín con palmeras. Al fondo a la derecha, una escalera con el letrero de salida.'),
      Escena(
          id: 2,
          lugarId: 1,
          poiId: 2,
          nombre: 'Puente A3 - A5',
          esEscenaPrincipal: false,
          orden: 1,
          vistaInicialYaw: -58,
          vistaInicialPitch: -5,
          textoAlt:
              'Pasarela elevada y techada, con barandas metálicas a los dos lados, que une dos edificios de aulas de tres pisos. Desde ella se ven, abajo, árboles frondosos, senderos y un jardín con letras formadas por arbustos, y arriba, un cielo azul con nubes.'),
      Escena(
          id: 3,
          lugarId: 1,
          poiId: 3,
          nombre: 'Enfermeria',
          esEscenaPrincipal: false,
          orden: 2,
          vistaInicialYaw: -158,
          vistaInicialPitch: -6,
          textoAlt:
              'Sala de atención de la enfermería, blanca y bien iluminada. A la izquierda hay un escritorio con computador y, junto a la puerta de entrada, una pequeña sala de espera con sillas verdes. Al centro y a la derecha, cubículos separados por cortinas, uno de ellos con biombos azules, y equipos como un tanque de oxígeno.'),
      Escena(
          id: 4,
          lugarId: 1,
          poiId: 4,
          nombre: 'Zona T',
          esEscenaPrincipal: false,
          orden: 3,
          vistaInicialYaw: -55,
          vistaInicialPitch: -6,
          textoAlt:
              'Plazoleta al aire libre a la sombra de árboles grandes y palmeras, con mesas metálicas y sillas de colores. A un lado se abre una explanada de césped; al otro, un edificio con columnas y una escalera exterior de peldaños amarillos.'),
      Escena(
          id: 5,
          lugarId: 1,
          poiId: 5,
          nombre: 'Cancha de softbol',
          esEscenaPrincipal: false,
          orden: 4,
          vistaInicialYaw: -40,
          vistaInicialPitch: -3,
          textoAlt:
              'Campo abierto de césped seco bajo un cielo azul con nubes, rodeado de árboles. Al fondo se ve el edificio deportivo de dos pisos, con una torre de luz.'),
    ];
  }

  late List<Escena> _escenas;
  int _nextId = 6;

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 350));

  @override
  Future<List<Escena>> listar() async {
    await _delay();
    return List.unmodifiable(_escenas);
  }

  @override
  Future<Escena> crear(Escena escena) async {
    await _delay();
    final nueva = Escena(
      id: _nextId++,
      lugarId: escena.lugarId,
      poiId: escena.poiId,
      nombre: escena.nombre,
      imagenUrl: escena.imagenUrl,
      imagenUrlBaja: escena.imagenUrlBaja,
      esEscenaPrincipal: escena.esEscenaPrincipal,
      orden: escena.orden,
      vistaInicialYaw: escena.vistaInicialYaw,
      vistaInicialPitch: escena.vistaInicialPitch,
    );
    _escenas = [..._escenas, nueva];
    return nueva;
  }

  @override
  Future<Escena> actualizar(Escena escena) async {
    await _delay();
    _escenas = [for (final e in _escenas) e.id == escena.id ? escena : e];
    return escena;
  }

  @override
  Future<void> eliminar(int id) async {
    await _delay();
    _escenas = _escenas.where((e) => e.id != id).toList();
  }

  @override
  Future<void> subirImagen(
    int escenaId, {
    required Uint8List bytes,
    required String filename,
    bool bajaResolucion = false,
    String? carpeta,
  }) =>
      _delay();
}

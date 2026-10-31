import 'dart:typed_data';

import '../api/api_client.dart';
import '../models/medio.dart';

abstract class MedioRepository {
  /// Crea el registro del medio. Después se sube el archivo con [subirArchivo].
  Future<Medio> crear(Medio medio);

  Future<Medio> actualizar(Medio medio);

  Future<void> eliminar(int id);

  /// POST /api/admin/medios/{id}/archivo (multipart: Archivo, Carpeta).
  Future<void> subirArchivo(
    int medioId, {
    required Uint8List bytes,
    required String filename,
    String? carpeta,
  });
}

class HttpMedioRepository implements MedioRepository {
  HttpMedioRepository(this._api);

  final ApiClient _api;

  Medio _fromJson(Object? data) =>
      Medio.fromJson((data as Map).cast<String, dynamic>());

  @override
  Future<Medio> crear(Medio medio) async =>
      _fromJson(await _api.post('/api/admin/medios', medio.toCreateJson()));

  @override
  Future<Medio> actualizar(Medio medio) async => _fromJson(
      await _api.put('/api/admin/medios/${medio.id}', medio.toUpdateJson()));

  @override
  Future<void> eliminar(int id) => _api.delete('/api/admin/medios/$id');

  @override
  Future<void> subirArchivo(
    int medioId, {
    required Uint8List bytes,
    required String filename,
    String? carpeta,
  }) =>
      _api.uploadFile(
        '/api/admin/medios/$medioId/archivo',
        bytes: bytes,
        filename: filename,
        carpeta: carpeta,
      );
}

/// Versión en memoria para maquetar sin backend.
class MockMedioRepository implements MedioRepository {
  final List<Medio> _medios = [];
  int _nextId = 1;

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 350));

  @override
  Future<Medio> crear(Medio medio) async {
    await _delay();
    final nuevo = Medio(
      id: _nextId++,
      poiId: medio.poiId,
      tipo: medio.tipo,
      url: medio.url,
      orden: medio.orden,
      duracionSeg: medio.duracionSeg,
      textoAlt: medio.textoAlt,
      subtitulosUrl: medio.subtitulosUrl,
      idioma: medio.idioma,
    );
    _medios.add(nuevo);
    return nuevo;
  }

  @override
  Future<Medio> actualizar(Medio medio) async {
    await _delay();
    final i = _medios.indexWhere((m) => m.id == medio.id);
    if (i >= 0) _medios[i] = medio;
    return medio;
  }

  @override
  Future<void> eliminar(int id) async {
    await _delay();
    _medios.removeWhere((m) => m.id == id);
  }

  @override
  Future<void> subirArchivo(
    int medioId, {
    required Uint8List bytes,
    required String filename,
    String? carpeta,
  }) =>
      _delay();
}

import 'dart:typed_data';

import '../api/api_client.dart';
import '../models/enums.dart';
import '../models/medio.dart';

abstract class MedioRepository {
  /// Sube el archivo y crea el medio en un solo paso
  /// (POST /api/admin/pois/{poiId}/medios). Las imágenes exigen [textoAlt];
  /// audio y video pueden llevar [idioma] (BCP 47) y subtítulos .vtt.
  Future<Medio> subir({
    required int poiId,
    required TipoMedio tipo,
    required ArchivoSubida archivo,
    int orden = 0,
    String? textoAlt,
    String? idioma,
    ArchivoSubida? subtitulos,
  });

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
  Future<Medio> subir({
    required int poiId,
    required TipoMedio tipo,
    required ArchivoSubida archivo,
    int orden = 0,
    String? textoAlt,
    String? idioma,
    ArchivoSubida? subtitulos,
  }) async =>
      _fromJson(await _api.postMultipart(
        '/api/admin/pois/$poiId/medios',
        fields: {
          'Tipo': tipo.name,
          'Orden': '$orden',
          if (textoAlt != null && textoAlt.trim().isNotEmpty)
            'TextoAlt': textoAlt.trim(),
          if (idioma != null && idioma.isNotEmpty) 'Idioma': idioma,
        },
        files: [archivo, ?subtitulos],
      ));

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
  Future<Medio> subir({
    required int poiId,
    required TipoMedio tipo,
    required ArchivoSubida archivo,
    int orden = 0,
    String? textoAlt,
    String? idioma,
    ArchivoSubida? subtitulos,
  }) =>
      crear(Medio(
        id: 0,
        poiId: poiId,
        tipo: tipo,
        url: archivo.nombre,
        orden: orden,
        textoAlt: textoAlt,
        idioma: idioma,
        subtitulosUrl: subtitulos?.nombre,
      ));

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

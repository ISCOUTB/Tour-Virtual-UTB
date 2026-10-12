import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../nucleo/errores.dart';
import '../nucleo/idiomas.dart';
import 'modelos/modelos.dart';
import 'subtitulos.dart';

class RepositorioContenido {
  RepositorioContenido({
    required String baseUrl,
    String idioma = 'es',
    http.Client? cliente,
  }) : _baseUrl = baseUrl,
       _idioma = idioma,
       _cliente = cliente ?? http.Client();

  final String _baseUrl;
  final http.Client _cliente;
  static const _tiempoLimite = Duration(seconds: 15);

  /// Idioma de la interfaz, como etiqueta BCP 47.
  final String _idioma;

  String _idiomaContenido = idiomaOriginal.languageCode;

  /// Idioma en que el servidor respondió, según su `Content-Language`.
  ///
  /// El servidor todavía no traduce y no envía la cabecera, así que hoy es
  /// siempre el español. La interfaz lo usa para avisar de que un texto no
  /// está en el idioma elegido y para que el lector de pantalla lo pronuncie
  /// con la voz correcta (WCAG 3.1.2).
  String get idiomaContenido => _idiomaContenido;

  /// Pide el contenido en el idioma de la interfaz y, si no lo hay, en el
  /// original. El contrato está en docs/ACCESIBILIDAD.md.
  Map<String, String> get _cabeceras => {
    'Accept': 'application/json',
    'Accept-Language': mismoIdioma(_idioma, idiomaOriginal.languageCode)
        ? _idioma
        : '$_idioma, ${idiomaOriginal.languageCode};q=0.5',
  };

  Future<dynamic> _get(String path) async {
    try {
      final response = await _cliente
          .get(Uri.parse('$_baseUrl$path'), headers: _cabeceras)
          .timeout(_tiempoLimite);
      if (response.statusCode == 404) throw const FalloSinContenido();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FalloInesperado(detalle: 'HTTP ${response.statusCode}');
      }
      final idioma = response.headers['content-language']?.split(',').first;
      if (idioma != null && idioma.trim().isNotEmpty) {
        _idiomaContenido = idioma.trim();
      }
      return jsonDecode(response.body);
    } on FalloApp {
      rethrow;
    } on TimeoutException catch (error) {
      throw FalloDeTiempo(detalle: error);
    } on http.ClientException catch (error) {
      throw FalloDeConexion(detalle: error);
    } on FormatException catch (error) {
      throw FalloInesperado(detalle: error);
    }
  }

  String _resolverMedio(String valor) =>
      valor.startsWith('http://') || valor.startsWith('https://')
      ? valor
      : '$_baseUrl/${valor.replaceFirst(RegExp(r'^/'), '')}';

  Future<List<Poi>> obtenerPois(int lugarId) async {
    final json = await _get('/api/lugares/$lugarId/pois') as List<dynamic>;
    return json
        .map((fila) => Poi.fromJson(fila as Map<String, dynamic>))
        .toList();
  }

  Future<String?> obtenerUrlMapa(int lugarId) async {
    try {
      final json =
          await _get('/api/lugares/$lugarId/mapa') as Map<String, dynamic>;
      return json['urlMapa'] as String?;
    } catch (error) {
      // Si el backend devuelve 404 (el lugar no tiene mapa aún), retornamos nulo
      if (error is FalloSinContenido) return null;
      rethrow;
    }
  }

  Future<Recorrido> obtenerRecorrido(int lugarId) async {
    final json =
        await _get('/api/lugares/$lugarId/recorrido') as Map<String, dynamic>;
    final escenas = (json['escenas'] as List<dynamic>)
        .map(
          (fila) => Escena.fromJson(
            _conMedios(fila as Map<String, dynamic>, const [
              'imagen_url',
              'imagen_url_baja',
            ]),
          ),
        )
        .toList();
    final hotspots = (json['hotspots'] as List<dynamic>)
        .map((fila) => Hotspot.fromJson(fila as Map<String, dynamic>))
        .toList();
    return Recorrido(
      escenas: escenas,
      hotspotsPorEscena: {
        for (final escena in escenas)
          escena.id: hotspots
              .where((hotspot) => hotspot.escenaId == escena.id)
              .toList(),
      },
    );
  }

  Future<PoiDetalle> obtenerPoiDetalle(int poiId) async {
    final json = await _get('/api/pois/$poiId') as Map<String, dynamic>;
    final medios = (json['medios'] as List<dynamic>)
        .map(
          (fila) => Medio.fromJson(
            _conMedios(fila as Map<String, dynamic>, const ['url']),
          ),
        )
        .toList();
    return PoiDetalle(
      poi: Poi.fromJson(json['poi'] as Map<String, dynamic>),
      medios: medios,
    );
  }

  /// Subtítulos de un audio o video (WebVTT, SRT o texto plano): la
  /// alternativa en texto de la narración (WCAG 1.2.1 y 1.2.2).
  ///
  /// La URL viene ya resuelta o firmada en `Medio.subtitulosUrl`.
  Future<Subtitulos> obtenerSubtitulos(String url) async {
    try {
      final response = await _cliente
          .get(Uri.parse(_resolverMedio(url)))
          .timeout(_tiempoLimite);
      if (response.statusCode == 404) throw const FalloSinContenido();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FalloInesperado(detalle: 'HTTP ${response.statusCode}');
      }
      return Subtitulos.leer(utf8.decode(response.bodyBytes));
    } on FalloApp {
      rethrow;
    } on TimeoutException catch (error) {
      throw FalloDeTiempo(detalle: error);
    } on http.ClientException catch (error) {
      throw FalloDeConexion(detalle: error);
    }
  }

  Future<Ruta?> obtenerRutaActual(int lugarId) async {
    final json = await _get('/api/lugares/$lugarId/ruta');
    return json == null ? null : Ruta.fromJson(json as Map<String, dynamic>);
  }

  Map<String, dynamic> _conMedios(
    Map<String, dynamic> fila,
    List<String> campos,
  ) {
    final copia = Map<String, dynamic>.from(fila);
    for (final campo in campos) {
      final valor = copia[campo];
      if (valor is String && valor.isNotEmpty) {
        copia[campo] = _resolverMedio(valor);
      }
    }
    return copia;
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../nucleo/errores.dart';
import 'modelos/modelos.dart';

class RepositorioContenido {
  RepositorioContenido({required String baseUrl, http.Client? cliente})
    : _baseUrl = baseUrl,
      _cliente = cliente ?? http.Client();

  final String _baseUrl;
  final http.Client _cliente;
  static const _tiempoLimite = Duration(seconds: 15);

  Future<dynamic> _get(String path) async {
    try {
      final response = await _cliente
          .get(
            Uri.parse('$_baseUrl$path'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(_tiempoLimite);
      if (response.statusCode == 404) throw const FalloSinContenido();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FalloInesperado(detalle: 'HTTP ${response.statusCode}');
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

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => statusCode == null ? message : '$statusCode: $message';
}

/// Devuelve el token de sesión (por ejemplo de Firebase Auth) o null.
typedef TokenProvider = Future<String?> Function();

/// Cliente HTTP mínimo para el backend .NET.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl, this.tokenProvider})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  /// Si se asigna, se envía como `Authorization: Bearer <token>`.
  final TokenProvider? tokenProvider;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  Future<Map<String, String>> _headers({bool json = true}) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json';
    final token = await tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> _send(Future<http.Response> Function() call) async {
    try {
      final res = await call();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException(_errorMessage(res), statusCode: res.statusCode);
      }
      if (res.body.isEmpty) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    } on ApiException {
      rethrow;
    } on http.ClientException catch (e) {
      // En Flutter web, un bloqueo por CORS aparece como "Failed to fetch".
      throw ApiException(
        'No se pudo conectar con el servidor. Verifica que el backend esté '
        'encendido y que permita CORS para este origen. (${e.message})',
      );
    }
  }

  String _errorMessage(http.Response res) {
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is Map) {
        final msg = body['detail'] ?? body['title'] ?? body['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    } catch (_) {
      // El cuerpo no es JSON; se usa el texto estándar.
    }
    return res.reasonPhrase ?? 'Error ${res.statusCode}';
  }

  Future<dynamic> get(String path) =>
      _send(() async => _client.get(_uri(path), headers: await _headers()));

  Future<dynamic> post(String path, Object? body) => _send(() async =>
      _client.post(_uri(path),
          headers: await _headers(), body: jsonEncode(body)));

  Future<dynamic> put(String path, Object? body) => _send(() async =>
      _client.put(_uri(path),
          headers: await _headers(), body: jsonEncode(body)));

  Future<void> delete(String path) async {
    await _send(
        () async => _client.delete(_uri(path), headers: await _headers()));
  }

  /// Sube un archivo como multipart/form-data con los campos que define la
  /// API: `Archivo` (binario) y `Carpeta` (opcional).
  Future<void> uploadFile(
    String path, {
    required Uint8List bytes,
    required String filename,
    String? carpeta,
    Map<String, String>? query,
  }) async {
    await _send(() async {
      final req = http.MultipartRequest('POST', _uri(path, query));
      req.headers.addAll(await _headers(json: false));
      req.files.add(
        http.MultipartFile.fromBytes('Archivo', bytes, filename: filename),
      );
      if (carpeta != null && carpeta.isNotEmpty) {
        req.fields['Carpeta'] = carpeta;
      }
      return http.Response.fromStream(await _client.send(req));
    });
  }
}

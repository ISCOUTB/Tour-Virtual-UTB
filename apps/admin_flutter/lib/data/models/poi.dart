import 'enums.dart';
import 'medio.dart';

double? _toDouble(Object? v) => (v as num?)?.toDouble();
int? _toInt(Object? v) => (v as num?)?.toInt();

/// Punto de interés. Respuestas de la API: snake_case (PoiDto).
/// Peticiones de crear/editar: camelCase (CrearPoiRequest / ActualizarPoiRequest).
class Poi {
  const Poi({
    required this.id,
    required this.lugarId,
    required this.nombre,
    this.categoria,
    this.descripcion,
    this.lat,
    this.lng,
    this.mapX,
    this.mapY,
    this.escenaPrincipalId,
    this.audiencias = const [],
    this.activo = true,
  });

  final int id;
  final int lugarId;
  final String nombre;
  final String? categoria;
  final String? descripcion;

  /// Solo lectura: la API no permite escribir lat/lng, solo mapX/mapY.
  final double? lat;
  final double? lng;

  /// Posición del pin sobre la imagen del mapa del lugar.
  final double? mapX;
  final double? mapY;

  final int? escenaPrincipalId;
  final List<Audiencia> audiencias;
  final bool activo;

  factory Poi.fromJson(Map<String, dynamic> j) => Poi(
        id: _toInt(j['id']) ?? 0,
        lugarId: _toInt(j['lugar_id']) ?? 0,
        nombre: (j['nombre'] as String?) ?? '',
        categoria: j['categoria'] as String?,
        descripcion: j['descripcion'] as String?,
        lat: _toDouble(j['lat']),
        lng: _toDouble(j['lng']),
        mapX: _toDouble(j['map_x']),
        mapY: _toDouble(j['map_y']),
        escenaPrincipalId: _toInt(j['escena_principal_id']),
        audiencias: ((j['audiencias'] as List?) ?? const [])
            .map(Audiencia.tryParse)
            .whereType<Audiencia>()
            .toList(),
        activo: (j['activo'] as bool?) ?? true,
      );

  /// Nota: este copyWith no permite poner un campo opcional en null.
  Poi copyWith({
    int? id,
    int? lugarId,
    String? nombre,
    String? categoria,
    String? descripcion,
    double? lat,
    double? lng,
    double? mapX,
    double? mapY,
    int? escenaPrincipalId,
    List<Audiencia>? audiencias,
    bool? activo,
  }) =>
      Poi(
        id: id ?? this.id,
        lugarId: lugarId ?? this.lugarId,
        nombre: nombre ?? this.nombre,
        categoria: categoria ?? this.categoria,
        descripcion: descripcion ?? this.descripcion,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        mapX: mapX ?? this.mapX,
        mapY: mapY ?? this.mapY,
        escenaPrincipalId: escenaPrincipalId ?? this.escenaPrincipalId,
        audiencias: audiencias ?? this.audiencias,
        activo: activo ?? this.activo,
      );

  Map<String, dynamic> _body() => {
        'nombre': nombre,
        'categoria': categoria,
        'descripcion': descripcion,
        'mapX': mapX,
        'mapY': mapY,
        // Backend tarea 1: hoy la API ignora lat/lng al escribir.
        'lat': lat,
        'lng': lng,
        // VERIFICAR con el backend: la API recibe `audiencias` como texto.
        // Se asume lista separada por comas, p. ej. "externo,estudiante".
        'audiencias': audiencias.map((a) => a.name).join(','),
        'activo': activo,
        'escenaPrincipalId': escenaPrincipalId,
      };

  /// Cuerpo de POST /api/admin/pois (CrearPoiRequest).
  Map<String, dynamic> toCreateJson() => {'lugarId': lugarId, ..._body()};

  /// Cuerpo de PUT /api/admin/pois/{id} (ActualizarPoiRequest).
  Map<String, dynamic> toUpdateJson() => _body();
}

/// Respuesta de GET /api/pois/{id} (PoiDetalleDto).
class PoiDetalle {
  const PoiDetalle({required this.poi, this.medios = const []});

  final Poi poi;
  final List<Medio> medios;

  factory PoiDetalle.fromJson(Map<String, dynamic> j) => PoiDetalle(
        poi: Poi.fromJson((j['poi'] as Map).cast<String, dynamic>()),
        medios: ((j['medios'] as List?) ?? const [])
            .map((e) => Medio.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

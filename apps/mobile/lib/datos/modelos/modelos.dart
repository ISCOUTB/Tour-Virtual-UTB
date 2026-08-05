import 'package:freezed_annotation/freezed_annotation.dart';

part 'modelos.freezed.dart';
part 'modelos.g.dart';

/// Publico al que se dirige una pieza de contenido.
///
/// El filtrado real lo hace RLS en Postgres mediante `audiencia_actual()`. Este
/// enum solo sirve para leer lo que la base ya decidio devolver: nunca debe
/// usarse para filtrar en el cliente.
enum Audiencia {
  @JsonValue('externo')
  externo,
  @JsonValue('estudiante')
  estudiante,
  @JsonValue('docente')
  docente,
}

enum RolUsuario {
  @JsonValue('externo')
  externo,
  @JsonValue('estudiante')
  estudiante,
  @JsonValue('docente')
  docente,
  @JsonValue('admin')
  admin,
}

enum TipoHotspot {
  /// Salta a otra escena del recorrido.
  @JsonValue('navegacion')
  navegacion,

  /// Abre la ficha multimedia de un POI.
  @JsonValue('info')
  info,
}

enum TipoMedio {
  @JsonValue('imagen')
  imagen,
  @JsonValue('video')
  video,
  @JsonValue('audio')
  audio,
}

@freezed
abstract class Lugar with _$Lugar {
  const factory Lugar({
    required int id,
    required String nombre,
    required String slug,
  }) = _Lugar;

  factory Lugar.fromJson(Map<String, dynamic> json) => _$LugarFromJson(json);
}

@freezed
abstract class Poi with _$Poi {
  const factory Poi({
    required int id,
    @JsonKey(name: 'lugar_id') required int lugarId,
    required String nombre,
    String? categoria,
    String? descripcion,
    double? lat,
    double? lng,

    /// Posicion del marcador sobre el render ilustrado, normalizada a [0,1].
    /// Puede venir nula mientras el POI no se haya calibrado desde el panel.
    @JsonKey(name: 'map_x') double? mapX,
    @JsonKey(name: 'map_y') double? mapY,

    @JsonKey(name: 'escena_principal_id') int? escenaPrincipalId,
    @Default(<Audiencia>[]) List<Audiencia> audiencias,
    @Default(true) bool activo,
  }) = _Poi;

  const Poi._();

  factory Poi.fromJson(Map<String, dynamic> json) => _$PoiFromJson(json);

  /// Solo los POI calibrados pueden dibujarse en el mapa.
  bool get tienePosicionEnMapa => mapX != null && mapY != null;
}

@freezed
abstract class Escena with _$Escena {
  const factory Escena({
    required int id,
    @JsonKey(name: 'lugar_id') required int lugarId,
    @JsonKey(name: 'poi_id') int? poiId,
    String? nombre,
    @JsonKey(name: 'imagen_url') required String imagenUrl,
    @JsonKey(name: 'imagen_url_baja') String? imagenUrlBaja,
    @JsonKey(name: 'es_escena_principal')
    @Default(false)
    bool esEscenaPrincipal,
    @Default(0) int orden,
  }) = _Escena;

  factory Escena.fromJson(Map<String, dynamic> json) => _$EscenaFromJson(json);
}

@freezed
abstract class Hotspot with _$Hotspot {
  const factory Hotspot({
    required int id,
    @JsonKey(name: 'escena_id') required int escenaId,
    required TipoHotspot tipo,

    /// Grados. El visor lo consume como `Hotspot.latitude`.
    required double pitch,

    /// Grados. El visor lo consume como `Hotspot.longitude`.
    required double yaw,

    @JsonKey(name: 'escena_destino_id') int? escenaDestinoId,
    @JsonKey(name: 'poi_id') int? poiId,
    String? etiqueta,
  }) = _Hotspot;

  factory Hotspot.fromJson(Map<String, dynamic> json) =>
      _$HotspotFromJson(json);
}

@freezed
abstract class Medio with _$Medio {
  const factory Medio({
    required int id,
    @JsonKey(name: 'poi_id') required int poiId,
    required TipoMedio tipo,
    required String url,
    @Default(0) int orden,
    @JsonKey(name: 'duracion_seg') int? duracionSeg,
    @JsonKey(name: 'texto_alt') String? textoAlt,
    @JsonKey(name: 'subtitulos_url') String? subtitulosUrl,
  }) = _Medio;

  factory Medio.fromJson(Map<String, dynamic> json) => _$MedioFromJson(json);
}

@freezed
abstract class Ruta with _$Ruta {
  const factory Ruta({
    required int id,
    @JsonKey(name: 'lugar_id') required int lugarId,
    required String nombre,
    String? descripcion,
    required Audiencia audiencia,
    @Default(true) bool activa,
  }) = _Ruta;

  factory Ruta.fromJson(Map<String, dynamic> json) => _$RutaFromJson(json);
}

@freezed
abstract class Perfil with _$Perfil {
  const factory Perfil({
    @JsonKey(name: 'user_id') required String userId,
    required RolUsuario rol,

    /// Solo un administrador lo pone en true. Un rol declarado por el propio
    /// usuario llega siempre sin verificar.
    @Default(false) bool verificado,
  }) = _Perfil;

  factory Perfil.fromJson(Map<String, dynamic> json) => _$PerfilFromJson(json);
}

/// Un POI junto con el contenido que muestra su ficha.
@freezed
abstract class PoiDetalle with _$PoiDetalle {
  const factory PoiDetalle({
    required Poi poi,
    @Default(<Medio>[]) List<Medio> medios,
  }) = _PoiDetalle;

  const PoiDetalle._();

  List<Medio> get imagenes =>
      medios.where((m) => m.tipo == TipoMedio.imagen).toList();

  Medio? get video =>
      medios.where((m) => m.tipo == TipoMedio.video).firstOrNull;

  Medio? get audio =>
      medios.where((m) => m.tipo == TipoMedio.audio).firstOrNull;
}

/// El recorrido completo de un lugar, resuelto de una sola vez.
///
/// Se carga entero porque el grafo del MVP es pequeno (8 a 12 escenas) y
/// permite navegar entre escenas sin volver a la red.
@freezed
abstract class Recorrido with _$Recorrido {
  const factory Recorrido({
    required List<Escena> escenas,
    required Map<int, List<Hotspot>> hotspotsPorEscena,
  }) = _Recorrido;

  const Recorrido._();

  /// Punto de entrada del recorrido.
  ///
  /// La base garantiza una unica escena principal por lugar mediante un indice
  /// unico parcial; el `orElse` cubre el caso de un lugar cuyo contenido aun no
  /// se ha marcado.
  Escena? get escenaInicial {
    if (escenas.isEmpty) return null;
    return escenas.firstWhere(
      (e) => e.esEscenaPrincipal,
      orElse: () => escenas.first,
    );
  }

  List<Hotspot> hotspotsDe(int escenaId) =>
      hotspotsPorEscena[escenaId] ?? const [];

  Escena? escenaPorId(int id) => escenas.where((e) => e.id == id).firstOrNull;
}

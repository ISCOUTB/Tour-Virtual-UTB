// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modelos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Lugar _$LugarFromJson(Map<String, dynamic> json) => _Lugar(
  id: (json['id'] as num).toInt(),
  nombre: json['nombre'] as String,
  slug: json['slug'] as String,
);

Map<String, dynamic> _$LugarToJson(_Lugar instance) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'slug': instance.slug,
};

_Poi _$PoiFromJson(Map<String, dynamic> json) => _Poi(
  id: (json['id'] as num).toInt(),
  lugarId: (json['lugar_id'] as num).toInt(),
  nombre: json['nombre'] as String,
  categoria: json['categoria'] as String?,
  descripcion: json['descripcion'] as String?,
  lat: (json['lat'] as num?)?.toDouble(),
  lng: (json['lng'] as num?)?.toDouble(),
  mapX: (json['map_x'] as num?)?.toDouble(),
  mapY: (json['map_y'] as num?)?.toDouble(),
  escenaPrincipalId: (json['escena_principal_id'] as num?)?.toInt(),
  audiencias:
      (json['audiencias'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$AudienciaEnumMap, e))
          .toList() ??
      const <Audiencia>[],
  activo: json['activo'] as bool? ?? true,
);

Map<String, dynamic> _$PoiToJson(_Poi instance) => <String, dynamic>{
  'id': instance.id,
  'lugar_id': instance.lugarId,
  'nombre': instance.nombre,
  'categoria': instance.categoria,
  'descripcion': instance.descripcion,
  'lat': instance.lat,
  'lng': instance.lng,
  'map_x': instance.mapX,
  'map_y': instance.mapY,
  'escena_principal_id': instance.escenaPrincipalId,
  'audiencias': instance.audiencias.map((e) => _$AudienciaEnumMap[e]!).toList(),
  'activo': instance.activo,
};

const _$AudienciaEnumMap = {
  Audiencia.externo: 'externo',
  Audiencia.estudiante: 'estudiante',
  Audiencia.docente: 'docente',
};

_Escena _$EscenaFromJson(Map<String, dynamic> json) => _Escena(
  id: (json['id'] as num).toInt(),
  lugarId: (json['lugar_id'] as num).toInt(),
  poiId: (json['poi_id'] as num?)?.toInt(),
  nombre: json['nombre'] as String?,
  imagenUrl: json['imagen_url'] as String,
  imagenUrlBaja: json['imagen_url_baja'] as String?,
  esEscenaPrincipal: json['es_escena_principal'] as bool? ?? false,
  orden: (json['orden'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$EscenaToJson(_Escena instance) => <String, dynamic>{
  'id': instance.id,
  'lugar_id': instance.lugarId,
  'poi_id': instance.poiId,
  'nombre': instance.nombre,
  'imagen_url': instance.imagenUrl,
  'imagen_url_baja': instance.imagenUrlBaja,
  'es_escena_principal': instance.esEscenaPrincipal,
  'orden': instance.orden,
};

_Hotspot _$HotspotFromJson(Map<String, dynamic> json) => _Hotspot(
  id: (json['id'] as num).toInt(),
  escenaId: (json['escena_id'] as num).toInt(),
  tipo: $enumDecode(_$TipoHotspotEnumMap, json['tipo']),
  pitch: (json['pitch'] as num).toDouble(),
  yaw: (json['yaw'] as num).toDouble(),
  escenaDestinoId: (json['escena_destino_id'] as num?)?.toInt(),
  poiId: (json['poi_id'] as num?)?.toInt(),
  etiqueta: json['etiqueta'] as String?,
);

Map<String, dynamic> _$HotspotToJson(_Hotspot instance) => <String, dynamic>{
  'id': instance.id,
  'escena_id': instance.escenaId,
  'tipo': _$TipoHotspotEnumMap[instance.tipo]!,
  'pitch': instance.pitch,
  'yaw': instance.yaw,
  'escena_destino_id': instance.escenaDestinoId,
  'poi_id': instance.poiId,
  'etiqueta': instance.etiqueta,
};

const _$TipoHotspotEnumMap = {
  TipoHotspot.navegacion: 'navegacion',
  TipoHotspot.info: 'info',
};

_Medio _$MedioFromJson(Map<String, dynamic> json) => _Medio(
  id: (json['id'] as num).toInt(),
  poiId: (json['poi_id'] as num).toInt(),
  tipo: $enumDecode(_$TipoMedioEnumMap, json['tipo']),
  url: json['url'] as String,
  orden: (json['orden'] as num?)?.toInt() ?? 0,
  duracionSeg: (json['duracion_seg'] as num?)?.toInt(),
  textoAlt: json['texto_alt'] as String?,
  subtitulosUrl: json['subtitulos_url'] as String?,
);

Map<String, dynamic> _$MedioToJson(_Medio instance) => <String, dynamic>{
  'id': instance.id,
  'poi_id': instance.poiId,
  'tipo': _$TipoMedioEnumMap[instance.tipo]!,
  'url': instance.url,
  'orden': instance.orden,
  'duracion_seg': instance.duracionSeg,
  'texto_alt': instance.textoAlt,
  'subtitulos_url': instance.subtitulosUrl,
};

const _$TipoMedioEnumMap = {
  TipoMedio.imagen: 'imagen',
  TipoMedio.video: 'video',
  TipoMedio.audio: 'audio',
};

_Ruta _$RutaFromJson(Map<String, dynamic> json) => _Ruta(
  id: (json['id'] as num).toInt(),
  lugarId: (json['lugar_id'] as num).toInt(),
  nombre: json['nombre'] as String,
  descripcion: json['descripcion'] as String?,
  audiencia: $enumDecode(_$AudienciaEnumMap, json['audiencia']),
  activa: json['activa'] as bool? ?? true,
);

Map<String, dynamic> _$RutaToJson(_Ruta instance) => <String, dynamic>{
  'id': instance.id,
  'lugar_id': instance.lugarId,
  'nombre': instance.nombre,
  'descripcion': instance.descripcion,
  'audiencia': _$AudienciaEnumMap[instance.audiencia]!,
  'activa': instance.activa,
};

_Perfil _$PerfilFromJson(Map<String, dynamic> json) => _Perfil(
  userId: json['user_id'] as String,
  rol: $enumDecode(_$RolUsuarioEnumMap, json['rol']),
  verificado: json['verificado'] as bool? ?? false,
);

Map<String, dynamic> _$PerfilToJson(_Perfil instance) => <String, dynamic>{
  'user_id': instance.userId,
  'rol': _$RolUsuarioEnumMap[instance.rol]!,
  'verificado': instance.verificado,
};

const _$RolUsuarioEnumMap = {
  RolUsuario.externo: 'externo',
  RolUsuario.estudiante: 'estudiante',
  RolUsuario.docente: 'docente',
  RolUsuario.admin: 'admin',
};

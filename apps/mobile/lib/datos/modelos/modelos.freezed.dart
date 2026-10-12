// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'modelos.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Lugar {

 int get id; String get nombre; String get slug;
/// Create a copy of Lugar
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LugarCopyWith<Lugar> get copyWith => _$LugarCopyWithImpl<Lugar>(this as Lugar, _$identity);

  /// Serializes this Lugar to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Lugar&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.slug, slug) || other.slug == slug));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nombre,slug);

@override
String toString() {
  return 'Lugar(id: $id, nombre: $nombre, slug: $slug)';
}


}

/// @nodoc
abstract mixin class $LugarCopyWith<$Res>  {
  factory $LugarCopyWith(Lugar value, $Res Function(Lugar) _then) = _$LugarCopyWithImpl;
@useResult
$Res call({
 int id, String nombre, String slug
});




}
/// @nodoc
class _$LugarCopyWithImpl<$Res>
    implements $LugarCopyWith<$Res> {
  _$LugarCopyWithImpl(this._self, this._then);

  final Lugar _self;
  final $Res Function(Lugar) _then;

/// Create a copy of Lugar
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nombre = null,Object? slug = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Lugar].
extension LugarPatterns on Lugar {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Lugar value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Lugar() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Lugar value)  $default,){
final _that = this;
switch (_that) {
case _Lugar():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Lugar value)?  $default,){
final _that = this;
switch (_that) {
case _Lugar() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String nombre,  String slug)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Lugar() when $default != null:
return $default(_that.id,_that.nombre,_that.slug);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String nombre,  String slug)  $default,) {final _that = this;
switch (_that) {
case _Lugar():
return $default(_that.id,_that.nombre,_that.slug);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String nombre,  String slug)?  $default,) {final _that = this;
switch (_that) {
case _Lugar() when $default != null:
return $default(_that.id,_that.nombre,_that.slug);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Lugar implements Lugar {
  const _Lugar({required this.id, required this.nombre, required this.slug});
  factory _Lugar.fromJson(Map<String, dynamic> json) => _$LugarFromJson(json);

@override final  int id;
@override final  String nombre;
@override final  String slug;

/// Create a copy of Lugar
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LugarCopyWith<_Lugar> get copyWith => __$LugarCopyWithImpl<_Lugar>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LugarToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Lugar&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.slug, slug) || other.slug == slug));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nombre,slug);

@override
String toString() {
  return 'Lugar(id: $id, nombre: $nombre, slug: $slug)';
}


}

/// @nodoc
abstract mixin class _$LugarCopyWith<$Res> implements $LugarCopyWith<$Res> {
  factory _$LugarCopyWith(_Lugar value, $Res Function(_Lugar) _then) = __$LugarCopyWithImpl;
@override @useResult
$Res call({
 int id, String nombre, String slug
});




}
/// @nodoc
class __$LugarCopyWithImpl<$Res>
    implements _$LugarCopyWith<$Res> {
  __$LugarCopyWithImpl(this._self, this._then);

  final _Lugar _self;
  final $Res Function(_Lugar) _then;

/// Create a copy of Lugar
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nombre = null,Object? slug = null,}) {
  return _then(_Lugar(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Poi {

 int get id;@JsonKey(name: 'lugar_id') int get lugarId; String get nombre; String? get categoria; String? get descripcion; double? get lat; double? get lng;/// Posicion del marcador sobre el render ilustrado, normalizada a [0,1].
/// Puede venir nula mientras el POI no se haya calibrado desde el panel.
@JsonKey(name: 'map_x') double? get mapX;@JsonKey(name: 'map_y') double? get mapY;@JsonKey(name: 'escena_principal_id') int? get escenaPrincipalId; List<Audiencia> get audiencias; bool get activo;
/// Create a copy of Poi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PoiCopyWith<Poi> get copyWith => _$PoiCopyWithImpl<Poi>(this as Poi, _$identity);

  /// Serializes this Poi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Poi&&(identical(other.id, id) || other.id == id)&&(identical(other.lugarId, lugarId) || other.lugarId == lugarId)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.categoria, categoria) || other.categoria == categoria)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.mapX, mapX) || other.mapX == mapX)&&(identical(other.mapY, mapY) || other.mapY == mapY)&&(identical(other.escenaPrincipalId, escenaPrincipalId) || other.escenaPrincipalId == escenaPrincipalId)&&const DeepCollectionEquality().equals(other.audiencias, audiencias)&&(identical(other.activo, activo) || other.activo == activo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,lugarId,nombre,categoria,descripcion,lat,lng,mapX,mapY,escenaPrincipalId,const DeepCollectionEquality().hash(audiencias),activo);

@override
String toString() {
  return 'Poi(id: $id, lugarId: $lugarId, nombre: $nombre, categoria: $categoria, descripcion: $descripcion, lat: $lat, lng: $lng, mapX: $mapX, mapY: $mapY, escenaPrincipalId: $escenaPrincipalId, audiencias: $audiencias, activo: $activo)';
}


}

/// @nodoc
abstract mixin class $PoiCopyWith<$Res>  {
  factory $PoiCopyWith(Poi value, $Res Function(Poi) _then) = _$PoiCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'lugar_id') int lugarId, String nombre, String? categoria, String? descripcion, double? lat, double? lng,@JsonKey(name: 'map_x') double? mapX,@JsonKey(name: 'map_y') double? mapY,@JsonKey(name: 'escena_principal_id') int? escenaPrincipalId, List<Audiencia> audiencias, bool activo
});




}
/// @nodoc
class _$PoiCopyWithImpl<$Res>
    implements $PoiCopyWith<$Res> {
  _$PoiCopyWithImpl(this._self, this._then);

  final Poi _self;
  final $Res Function(Poi) _then;

/// Create a copy of Poi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? lugarId = null,Object? nombre = null,Object? categoria = freezed,Object? descripcion = freezed,Object? lat = freezed,Object? lng = freezed,Object? mapX = freezed,Object? mapY = freezed,Object? escenaPrincipalId = freezed,Object? audiencias = null,Object? activo = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,lugarId: null == lugarId ? _self.lugarId : lugarId // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,categoria: freezed == categoria ? _self.categoria : categoria // ignore: cast_nullable_to_non_nullable
as String?,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,mapX: freezed == mapX ? _self.mapX : mapX // ignore: cast_nullable_to_non_nullable
as double?,mapY: freezed == mapY ? _self.mapY : mapY // ignore: cast_nullable_to_non_nullable
as double?,escenaPrincipalId: freezed == escenaPrincipalId ? _self.escenaPrincipalId : escenaPrincipalId // ignore: cast_nullable_to_non_nullable
as int?,audiencias: null == audiencias ? _self.audiencias : audiencias // ignore: cast_nullable_to_non_nullable
as List<Audiencia>,activo: null == activo ? _self.activo : activo // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Poi].
extension PoiPatterns on Poi {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Poi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Poi() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Poi value)  $default,){
final _that = this;
switch (_that) {
case _Poi():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Poi value)?  $default,){
final _that = this;
switch (_that) {
case _Poi() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'lugar_id')  int lugarId,  String nombre,  String? categoria,  String? descripcion,  double? lat,  double? lng, @JsonKey(name: 'map_x')  double? mapX, @JsonKey(name: 'map_y')  double? mapY, @JsonKey(name: 'escena_principal_id')  int? escenaPrincipalId,  List<Audiencia> audiencias,  bool activo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Poi() when $default != null:
return $default(_that.id,_that.lugarId,_that.nombre,_that.categoria,_that.descripcion,_that.lat,_that.lng,_that.mapX,_that.mapY,_that.escenaPrincipalId,_that.audiencias,_that.activo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'lugar_id')  int lugarId,  String nombre,  String? categoria,  String? descripcion,  double? lat,  double? lng, @JsonKey(name: 'map_x')  double? mapX, @JsonKey(name: 'map_y')  double? mapY, @JsonKey(name: 'escena_principal_id')  int? escenaPrincipalId,  List<Audiencia> audiencias,  bool activo)  $default,) {final _that = this;
switch (_that) {
case _Poi():
return $default(_that.id,_that.lugarId,_that.nombre,_that.categoria,_that.descripcion,_that.lat,_that.lng,_that.mapX,_that.mapY,_that.escenaPrincipalId,_that.audiencias,_that.activo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'lugar_id')  int lugarId,  String nombre,  String? categoria,  String? descripcion,  double? lat,  double? lng, @JsonKey(name: 'map_x')  double? mapX, @JsonKey(name: 'map_y')  double? mapY, @JsonKey(name: 'escena_principal_id')  int? escenaPrincipalId,  List<Audiencia> audiencias,  bool activo)?  $default,) {final _that = this;
switch (_that) {
case _Poi() when $default != null:
return $default(_that.id,_that.lugarId,_that.nombre,_that.categoria,_that.descripcion,_that.lat,_that.lng,_that.mapX,_that.mapY,_that.escenaPrincipalId,_that.audiencias,_that.activo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Poi extends Poi {
  const _Poi({required this.id, @JsonKey(name: 'lugar_id') required this.lugarId, required this.nombre, this.categoria, this.descripcion, this.lat, this.lng, @JsonKey(name: 'map_x') this.mapX, @JsonKey(name: 'map_y') this.mapY, @JsonKey(name: 'escena_principal_id') this.escenaPrincipalId, final  List<Audiencia> audiencias = const <Audiencia>[], this.activo = true}): _audiencias = audiencias,super._();
  factory _Poi.fromJson(Map<String, dynamic> json) => _$PoiFromJson(json);

@override final  int id;
@override@JsonKey(name: 'lugar_id') final  int lugarId;
@override final  String nombre;
@override final  String? categoria;
@override final  String? descripcion;
@override final  double? lat;
@override final  double? lng;
/// Posicion del marcador sobre el render ilustrado, normalizada a [0,1].
/// Puede venir nula mientras el POI no se haya calibrado desde el panel.
@override@JsonKey(name: 'map_x') final  double? mapX;
@override@JsonKey(name: 'map_y') final  double? mapY;
@override@JsonKey(name: 'escena_principal_id') final  int? escenaPrincipalId;
 final  List<Audiencia> _audiencias;
@override@JsonKey() List<Audiencia> get audiencias {
  if (_audiencias is EqualUnmodifiableListView) return _audiencias;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_audiencias);
}

@override@JsonKey() final  bool activo;

/// Create a copy of Poi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PoiCopyWith<_Poi> get copyWith => __$PoiCopyWithImpl<_Poi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PoiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Poi&&(identical(other.id, id) || other.id == id)&&(identical(other.lugarId, lugarId) || other.lugarId == lugarId)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.categoria, categoria) || other.categoria == categoria)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.mapX, mapX) || other.mapX == mapX)&&(identical(other.mapY, mapY) || other.mapY == mapY)&&(identical(other.escenaPrincipalId, escenaPrincipalId) || other.escenaPrincipalId == escenaPrincipalId)&&const DeepCollectionEquality().equals(other._audiencias, _audiencias)&&(identical(other.activo, activo) || other.activo == activo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,lugarId,nombre,categoria,descripcion,lat,lng,mapX,mapY,escenaPrincipalId,const DeepCollectionEquality().hash(_audiencias),activo);

@override
String toString() {
  return 'Poi(id: $id, lugarId: $lugarId, nombre: $nombre, categoria: $categoria, descripcion: $descripcion, lat: $lat, lng: $lng, mapX: $mapX, mapY: $mapY, escenaPrincipalId: $escenaPrincipalId, audiencias: $audiencias, activo: $activo)';
}


}

/// @nodoc
abstract mixin class _$PoiCopyWith<$Res> implements $PoiCopyWith<$Res> {
  factory _$PoiCopyWith(_Poi value, $Res Function(_Poi) _then) = __$PoiCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'lugar_id') int lugarId, String nombre, String? categoria, String? descripcion, double? lat, double? lng,@JsonKey(name: 'map_x') double? mapX,@JsonKey(name: 'map_y') double? mapY,@JsonKey(name: 'escena_principal_id') int? escenaPrincipalId, List<Audiencia> audiencias, bool activo
});




}
/// @nodoc
class __$PoiCopyWithImpl<$Res>
    implements _$PoiCopyWith<$Res> {
  __$PoiCopyWithImpl(this._self, this._then);

  final _Poi _self;
  final $Res Function(_Poi) _then;

/// Create a copy of Poi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? lugarId = null,Object? nombre = null,Object? categoria = freezed,Object? descripcion = freezed,Object? lat = freezed,Object? lng = freezed,Object? mapX = freezed,Object? mapY = freezed,Object? escenaPrincipalId = freezed,Object? audiencias = null,Object? activo = null,}) {
  return _then(_Poi(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,lugarId: null == lugarId ? _self.lugarId : lugarId // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,categoria: freezed == categoria ? _self.categoria : categoria // ignore: cast_nullable_to_non_nullable
as String?,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,mapX: freezed == mapX ? _self.mapX : mapX // ignore: cast_nullable_to_non_nullable
as double?,mapY: freezed == mapY ? _self.mapY : mapY // ignore: cast_nullable_to_non_nullable
as double?,escenaPrincipalId: freezed == escenaPrincipalId ? _self.escenaPrincipalId : escenaPrincipalId // ignore: cast_nullable_to_non_nullable
as int?,audiencias: null == audiencias ? _self._audiencias : audiencias // ignore: cast_nullable_to_non_nullable
as List<Audiencia>,activo: null == activo ? _self.activo : activo // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Escena {

 int get id;@JsonKey(name: 'lugar_id') int get lugarId;@JsonKey(name: 'poi_id') int? get poiId; String? get nombre;@JsonKey(name: 'imagen_url') String get imagenUrl;@JsonKey(name: 'imagen_url_baja') String? get imagenUrlBaja;@JsonKey(name: 'es_escena_principal') bool get esEscenaPrincipal; int get orden;/// Grados hacia donde abre la escena, mismo convenio que [Hotspot.yaw].
/// Nulo abre al centro del archivo, que no apunta a nada en concreto.
@JsonKey(name: 'vista_inicial_yaw') double? get vistaInicialYaw;/// Grados sobre el horizonte al abrir. Nulo abre al horizonte.
@JsonKey(name: 'vista_inicial_pitch') double? get vistaInicialPitch;/// Descripción de lo que se ve, para quien no ve la panorámica. El
/// backend aún no la envía; mientras tanto el visor usa la descripción
/// del POI.
@JsonKey(name: 'texto_alt') String? get textoAlt;
/// Create a copy of Escena
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EscenaCopyWith<Escena> get copyWith => _$EscenaCopyWithImpl<Escena>(this as Escena, _$identity);

  /// Serializes this Escena to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Escena&&(identical(other.id, id) || other.id == id)&&(identical(other.lugarId, lugarId) || other.lugarId == lugarId)&&(identical(other.poiId, poiId) || other.poiId == poiId)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.imagenUrl, imagenUrl) || other.imagenUrl == imagenUrl)&&(identical(other.imagenUrlBaja, imagenUrlBaja) || other.imagenUrlBaja == imagenUrlBaja)&&(identical(other.esEscenaPrincipal, esEscenaPrincipal) || other.esEscenaPrincipal == esEscenaPrincipal)&&(identical(other.orden, orden) || other.orden == orden)&&(identical(other.vistaInicialYaw, vistaInicialYaw) || other.vistaInicialYaw == vistaInicialYaw)&&(identical(other.vistaInicialPitch, vistaInicialPitch) || other.vistaInicialPitch == vistaInicialPitch)&&(identical(other.textoAlt, textoAlt) || other.textoAlt == textoAlt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,lugarId,poiId,nombre,imagenUrl,imagenUrlBaja,esEscenaPrincipal,orden,vistaInicialYaw,vistaInicialPitch,textoAlt);

@override
String toString() {
  return 'Escena(id: $id, lugarId: $lugarId, poiId: $poiId, nombre: $nombre, imagenUrl: $imagenUrl, imagenUrlBaja: $imagenUrlBaja, esEscenaPrincipal: $esEscenaPrincipal, orden: $orden, vistaInicialYaw: $vistaInicialYaw, vistaInicialPitch: $vistaInicialPitch, textoAlt: $textoAlt)';
}


}

/// @nodoc
abstract mixin class $EscenaCopyWith<$Res>  {
  factory $EscenaCopyWith(Escena value, $Res Function(Escena) _then) = _$EscenaCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'lugar_id') int lugarId,@JsonKey(name: 'poi_id') int? poiId, String? nombre,@JsonKey(name: 'imagen_url') String imagenUrl,@JsonKey(name: 'imagen_url_baja') String? imagenUrlBaja,@JsonKey(name: 'es_escena_principal') bool esEscenaPrincipal, int orden,@JsonKey(name: 'vista_inicial_yaw') double? vistaInicialYaw,@JsonKey(name: 'vista_inicial_pitch') double? vistaInicialPitch,@JsonKey(name: 'texto_alt') String? textoAlt
});




}
/// @nodoc
class _$EscenaCopyWithImpl<$Res>
    implements $EscenaCopyWith<$Res> {
  _$EscenaCopyWithImpl(this._self, this._then);

  final Escena _self;
  final $Res Function(Escena) _then;

/// Create a copy of Escena
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? lugarId = null,Object? poiId = freezed,Object? nombre = freezed,Object? imagenUrl = null,Object? imagenUrlBaja = freezed,Object? esEscenaPrincipal = null,Object? orden = null,Object? vistaInicialYaw = freezed,Object? vistaInicialPitch = freezed,Object? textoAlt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,lugarId: null == lugarId ? _self.lugarId : lugarId // ignore: cast_nullable_to_non_nullable
as int,poiId: freezed == poiId ? _self.poiId : poiId // ignore: cast_nullable_to_non_nullable
as int?,nombre: freezed == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String?,imagenUrl: null == imagenUrl ? _self.imagenUrl : imagenUrl // ignore: cast_nullable_to_non_nullable
as String,imagenUrlBaja: freezed == imagenUrlBaja ? _self.imagenUrlBaja : imagenUrlBaja // ignore: cast_nullable_to_non_nullable
as String?,esEscenaPrincipal: null == esEscenaPrincipal ? _self.esEscenaPrincipal : esEscenaPrincipal // ignore: cast_nullable_to_non_nullable
as bool,orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,vistaInicialYaw: freezed == vistaInicialYaw ? _self.vistaInicialYaw : vistaInicialYaw // ignore: cast_nullable_to_non_nullable
as double?,vistaInicialPitch: freezed == vistaInicialPitch ? _self.vistaInicialPitch : vistaInicialPitch // ignore: cast_nullable_to_non_nullable
as double?,textoAlt: freezed == textoAlt ? _self.textoAlt : textoAlt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Escena].
extension EscenaPatterns on Escena {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Escena value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Escena() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Escena value)  $default,){
final _that = this;
switch (_that) {
case _Escena():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Escena value)?  $default,){
final _that = this;
switch (_that) {
case _Escena() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'lugar_id')  int lugarId, @JsonKey(name: 'poi_id')  int? poiId,  String? nombre, @JsonKey(name: 'imagen_url')  String imagenUrl, @JsonKey(name: 'imagen_url_baja')  String? imagenUrlBaja, @JsonKey(name: 'es_escena_principal')  bool esEscenaPrincipal,  int orden, @JsonKey(name: 'vista_inicial_yaw')  double? vistaInicialYaw, @JsonKey(name: 'vista_inicial_pitch')  double? vistaInicialPitch, @JsonKey(name: 'texto_alt')  String? textoAlt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Escena() when $default != null:
return $default(_that.id,_that.lugarId,_that.poiId,_that.nombre,_that.imagenUrl,_that.imagenUrlBaja,_that.esEscenaPrincipal,_that.orden,_that.vistaInicialYaw,_that.vistaInicialPitch,_that.textoAlt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'lugar_id')  int lugarId, @JsonKey(name: 'poi_id')  int? poiId,  String? nombre, @JsonKey(name: 'imagen_url')  String imagenUrl, @JsonKey(name: 'imagen_url_baja')  String? imagenUrlBaja, @JsonKey(name: 'es_escena_principal')  bool esEscenaPrincipal,  int orden, @JsonKey(name: 'vista_inicial_yaw')  double? vistaInicialYaw, @JsonKey(name: 'vista_inicial_pitch')  double? vistaInicialPitch, @JsonKey(name: 'texto_alt')  String? textoAlt)  $default,) {final _that = this;
switch (_that) {
case _Escena():
return $default(_that.id,_that.lugarId,_that.poiId,_that.nombre,_that.imagenUrl,_that.imagenUrlBaja,_that.esEscenaPrincipal,_that.orden,_that.vistaInicialYaw,_that.vistaInicialPitch,_that.textoAlt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'lugar_id')  int lugarId, @JsonKey(name: 'poi_id')  int? poiId,  String? nombre, @JsonKey(name: 'imagen_url')  String imagenUrl, @JsonKey(name: 'imagen_url_baja')  String? imagenUrlBaja, @JsonKey(name: 'es_escena_principal')  bool esEscenaPrincipal,  int orden, @JsonKey(name: 'vista_inicial_yaw')  double? vistaInicialYaw, @JsonKey(name: 'vista_inicial_pitch')  double? vistaInicialPitch, @JsonKey(name: 'texto_alt')  String? textoAlt)?  $default,) {final _that = this;
switch (_that) {
case _Escena() when $default != null:
return $default(_that.id,_that.lugarId,_that.poiId,_that.nombre,_that.imagenUrl,_that.imagenUrlBaja,_that.esEscenaPrincipal,_that.orden,_that.vistaInicialYaw,_that.vistaInicialPitch,_that.textoAlt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Escena implements Escena {
  const _Escena({required this.id, @JsonKey(name: 'lugar_id') required this.lugarId, @JsonKey(name: 'poi_id') this.poiId, this.nombre, @JsonKey(name: 'imagen_url') required this.imagenUrl, @JsonKey(name: 'imagen_url_baja') this.imagenUrlBaja, @JsonKey(name: 'es_escena_principal') this.esEscenaPrincipal = false, this.orden = 0, @JsonKey(name: 'vista_inicial_yaw') this.vistaInicialYaw, @JsonKey(name: 'vista_inicial_pitch') this.vistaInicialPitch, @JsonKey(name: 'texto_alt') this.textoAlt});
  factory _Escena.fromJson(Map<String, dynamic> json) => _$EscenaFromJson(json);

@override final  int id;
@override@JsonKey(name: 'lugar_id') final  int lugarId;
@override@JsonKey(name: 'poi_id') final  int? poiId;
@override final  String? nombre;
@override@JsonKey(name: 'imagen_url') final  String imagenUrl;
@override@JsonKey(name: 'imagen_url_baja') final  String? imagenUrlBaja;
@override@JsonKey(name: 'es_escena_principal') final  bool esEscenaPrincipal;
@override@JsonKey() final  int orden;
/// Grados hacia donde abre la escena, mismo convenio que [Hotspot.yaw].
/// Nulo abre al centro del archivo, que no apunta a nada en concreto.
@override@JsonKey(name: 'vista_inicial_yaw') final  double? vistaInicialYaw;
/// Grados sobre el horizonte al abrir. Nulo abre al horizonte.
@override@JsonKey(name: 'vista_inicial_pitch') final  double? vistaInicialPitch;
/// Descripción de lo que se ve, para quien no ve la panorámica. El
/// backend aún no la envía; mientras tanto el visor usa la descripción
/// del POI.
@override@JsonKey(name: 'texto_alt') final  String? textoAlt;

/// Create a copy of Escena
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EscenaCopyWith<_Escena> get copyWith => __$EscenaCopyWithImpl<_Escena>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EscenaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Escena&&(identical(other.id, id) || other.id == id)&&(identical(other.lugarId, lugarId) || other.lugarId == lugarId)&&(identical(other.poiId, poiId) || other.poiId == poiId)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.imagenUrl, imagenUrl) || other.imagenUrl == imagenUrl)&&(identical(other.imagenUrlBaja, imagenUrlBaja) || other.imagenUrlBaja == imagenUrlBaja)&&(identical(other.esEscenaPrincipal, esEscenaPrincipal) || other.esEscenaPrincipal == esEscenaPrincipal)&&(identical(other.orden, orden) || other.orden == orden)&&(identical(other.vistaInicialYaw, vistaInicialYaw) || other.vistaInicialYaw == vistaInicialYaw)&&(identical(other.vistaInicialPitch, vistaInicialPitch) || other.vistaInicialPitch == vistaInicialPitch)&&(identical(other.textoAlt, textoAlt) || other.textoAlt == textoAlt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,lugarId,poiId,nombre,imagenUrl,imagenUrlBaja,esEscenaPrincipal,orden,vistaInicialYaw,vistaInicialPitch,textoAlt);

@override
String toString() {
  return 'Escena(id: $id, lugarId: $lugarId, poiId: $poiId, nombre: $nombre, imagenUrl: $imagenUrl, imagenUrlBaja: $imagenUrlBaja, esEscenaPrincipal: $esEscenaPrincipal, orden: $orden, vistaInicialYaw: $vistaInicialYaw, vistaInicialPitch: $vistaInicialPitch, textoAlt: $textoAlt)';
}


}

/// @nodoc
abstract mixin class _$EscenaCopyWith<$Res> implements $EscenaCopyWith<$Res> {
  factory _$EscenaCopyWith(_Escena value, $Res Function(_Escena) _then) = __$EscenaCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'lugar_id') int lugarId,@JsonKey(name: 'poi_id') int? poiId, String? nombre,@JsonKey(name: 'imagen_url') String imagenUrl,@JsonKey(name: 'imagen_url_baja') String? imagenUrlBaja,@JsonKey(name: 'es_escena_principal') bool esEscenaPrincipal, int orden,@JsonKey(name: 'vista_inicial_yaw') double? vistaInicialYaw,@JsonKey(name: 'vista_inicial_pitch') double? vistaInicialPitch,@JsonKey(name: 'texto_alt') String? textoAlt
});




}
/// @nodoc
class __$EscenaCopyWithImpl<$Res>
    implements _$EscenaCopyWith<$Res> {
  __$EscenaCopyWithImpl(this._self, this._then);

  final _Escena _self;
  final $Res Function(_Escena) _then;

/// Create a copy of Escena
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? lugarId = null,Object? poiId = freezed,Object? nombre = freezed,Object? imagenUrl = null,Object? imagenUrlBaja = freezed,Object? esEscenaPrincipal = null,Object? orden = null,Object? vistaInicialYaw = freezed,Object? vistaInicialPitch = freezed,Object? textoAlt = freezed,}) {
  return _then(_Escena(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,lugarId: null == lugarId ? _self.lugarId : lugarId // ignore: cast_nullable_to_non_nullable
as int,poiId: freezed == poiId ? _self.poiId : poiId // ignore: cast_nullable_to_non_nullable
as int?,nombre: freezed == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String?,imagenUrl: null == imagenUrl ? _self.imagenUrl : imagenUrl // ignore: cast_nullable_to_non_nullable
as String,imagenUrlBaja: freezed == imagenUrlBaja ? _self.imagenUrlBaja : imagenUrlBaja // ignore: cast_nullable_to_non_nullable
as String?,esEscenaPrincipal: null == esEscenaPrincipal ? _self.esEscenaPrincipal : esEscenaPrincipal // ignore: cast_nullable_to_non_nullable
as bool,orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,vistaInicialYaw: freezed == vistaInicialYaw ? _self.vistaInicialYaw : vistaInicialYaw // ignore: cast_nullable_to_non_nullable
as double?,vistaInicialPitch: freezed == vistaInicialPitch ? _self.vistaInicialPitch : vistaInicialPitch // ignore: cast_nullable_to_non_nullable
as double?,textoAlt: freezed == textoAlt ? _self.textoAlt : textoAlt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Hotspot {

 int get id;@JsonKey(name: 'escena_id') int get escenaId;@JsonKey(unknownEnumValue: TipoHotspot.desconocido) TipoHotspot get tipo;/// Grados. El visor lo consume como `Hotspot.latitude`.
 double get pitch;/// Grados. El visor lo consume como `Hotspot.longitude`.
 double get yaw;@JsonKey(name: 'escena_destino_id') int? get escenaDestinoId;@JsonKey(name: 'poi_id') int? get poiId; String? get etiqueta;
/// Create a copy of Hotspot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HotspotCopyWith<Hotspot> get copyWith => _$HotspotCopyWithImpl<Hotspot>(this as Hotspot, _$identity);

  /// Serializes this Hotspot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Hotspot&&(identical(other.id, id) || other.id == id)&&(identical(other.escenaId, escenaId) || other.escenaId == escenaId)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.pitch, pitch) || other.pitch == pitch)&&(identical(other.yaw, yaw) || other.yaw == yaw)&&(identical(other.escenaDestinoId, escenaDestinoId) || other.escenaDestinoId == escenaDestinoId)&&(identical(other.poiId, poiId) || other.poiId == poiId)&&(identical(other.etiqueta, etiqueta) || other.etiqueta == etiqueta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,escenaId,tipo,pitch,yaw,escenaDestinoId,poiId,etiqueta);

@override
String toString() {
  return 'Hotspot(id: $id, escenaId: $escenaId, tipo: $tipo, pitch: $pitch, yaw: $yaw, escenaDestinoId: $escenaDestinoId, poiId: $poiId, etiqueta: $etiqueta)';
}


}

/// @nodoc
abstract mixin class $HotspotCopyWith<$Res>  {
  factory $HotspotCopyWith(Hotspot value, $Res Function(Hotspot) _then) = _$HotspotCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'escena_id') int escenaId,@JsonKey(unknownEnumValue: TipoHotspot.desconocido) TipoHotspot tipo, double pitch, double yaw,@JsonKey(name: 'escena_destino_id') int? escenaDestinoId,@JsonKey(name: 'poi_id') int? poiId, String? etiqueta
});




}
/// @nodoc
class _$HotspotCopyWithImpl<$Res>
    implements $HotspotCopyWith<$Res> {
  _$HotspotCopyWithImpl(this._self, this._then);

  final Hotspot _self;
  final $Res Function(Hotspot) _then;

/// Create a copy of Hotspot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? escenaId = null,Object? tipo = null,Object? pitch = null,Object? yaw = null,Object? escenaDestinoId = freezed,Object? poiId = freezed,Object? etiqueta = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,escenaId: null == escenaId ? _self.escenaId : escenaId // ignore: cast_nullable_to_non_nullable
as int,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoHotspot,pitch: null == pitch ? _self.pitch : pitch // ignore: cast_nullable_to_non_nullable
as double,yaw: null == yaw ? _self.yaw : yaw // ignore: cast_nullable_to_non_nullable
as double,escenaDestinoId: freezed == escenaDestinoId ? _self.escenaDestinoId : escenaDestinoId // ignore: cast_nullable_to_non_nullable
as int?,poiId: freezed == poiId ? _self.poiId : poiId // ignore: cast_nullable_to_non_nullable
as int?,etiqueta: freezed == etiqueta ? _self.etiqueta : etiqueta // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Hotspot].
extension HotspotPatterns on Hotspot {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Hotspot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Hotspot() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Hotspot value)  $default,){
final _that = this;
switch (_that) {
case _Hotspot():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Hotspot value)?  $default,){
final _that = this;
switch (_that) {
case _Hotspot() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'escena_id')  int escenaId, @JsonKey(unknownEnumValue: TipoHotspot.desconocido)  TipoHotspot tipo,  double pitch,  double yaw, @JsonKey(name: 'escena_destino_id')  int? escenaDestinoId, @JsonKey(name: 'poi_id')  int? poiId,  String? etiqueta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Hotspot() when $default != null:
return $default(_that.id,_that.escenaId,_that.tipo,_that.pitch,_that.yaw,_that.escenaDestinoId,_that.poiId,_that.etiqueta);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'escena_id')  int escenaId, @JsonKey(unknownEnumValue: TipoHotspot.desconocido)  TipoHotspot tipo,  double pitch,  double yaw, @JsonKey(name: 'escena_destino_id')  int? escenaDestinoId, @JsonKey(name: 'poi_id')  int? poiId,  String? etiqueta)  $default,) {final _that = this;
switch (_that) {
case _Hotspot():
return $default(_that.id,_that.escenaId,_that.tipo,_that.pitch,_that.yaw,_that.escenaDestinoId,_that.poiId,_that.etiqueta);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'escena_id')  int escenaId, @JsonKey(unknownEnumValue: TipoHotspot.desconocido)  TipoHotspot tipo,  double pitch,  double yaw, @JsonKey(name: 'escena_destino_id')  int? escenaDestinoId, @JsonKey(name: 'poi_id')  int? poiId,  String? etiqueta)?  $default,) {final _that = this;
switch (_that) {
case _Hotspot() when $default != null:
return $default(_that.id,_that.escenaId,_that.tipo,_that.pitch,_that.yaw,_that.escenaDestinoId,_that.poiId,_that.etiqueta);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Hotspot implements Hotspot {
  const _Hotspot({required this.id, @JsonKey(name: 'escena_id') required this.escenaId, @JsonKey(unknownEnumValue: TipoHotspot.desconocido) required this.tipo, required this.pitch, required this.yaw, @JsonKey(name: 'escena_destino_id') this.escenaDestinoId, @JsonKey(name: 'poi_id') this.poiId, this.etiqueta});
  factory _Hotspot.fromJson(Map<String, dynamic> json) => _$HotspotFromJson(json);

@override final  int id;
@override@JsonKey(name: 'escena_id') final  int escenaId;
@override@JsonKey(unknownEnumValue: TipoHotspot.desconocido) final  TipoHotspot tipo;
/// Grados. El visor lo consume como `Hotspot.latitude`.
@override final  double pitch;
/// Grados. El visor lo consume como `Hotspot.longitude`.
@override final  double yaw;
@override@JsonKey(name: 'escena_destino_id') final  int? escenaDestinoId;
@override@JsonKey(name: 'poi_id') final  int? poiId;
@override final  String? etiqueta;

/// Create a copy of Hotspot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HotspotCopyWith<_Hotspot> get copyWith => __$HotspotCopyWithImpl<_Hotspot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HotspotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Hotspot&&(identical(other.id, id) || other.id == id)&&(identical(other.escenaId, escenaId) || other.escenaId == escenaId)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.pitch, pitch) || other.pitch == pitch)&&(identical(other.yaw, yaw) || other.yaw == yaw)&&(identical(other.escenaDestinoId, escenaDestinoId) || other.escenaDestinoId == escenaDestinoId)&&(identical(other.poiId, poiId) || other.poiId == poiId)&&(identical(other.etiqueta, etiqueta) || other.etiqueta == etiqueta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,escenaId,tipo,pitch,yaw,escenaDestinoId,poiId,etiqueta);

@override
String toString() {
  return 'Hotspot(id: $id, escenaId: $escenaId, tipo: $tipo, pitch: $pitch, yaw: $yaw, escenaDestinoId: $escenaDestinoId, poiId: $poiId, etiqueta: $etiqueta)';
}


}

/// @nodoc
abstract mixin class _$HotspotCopyWith<$Res> implements $HotspotCopyWith<$Res> {
  factory _$HotspotCopyWith(_Hotspot value, $Res Function(_Hotspot) _then) = __$HotspotCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'escena_id') int escenaId,@JsonKey(unknownEnumValue: TipoHotspot.desconocido) TipoHotspot tipo, double pitch, double yaw,@JsonKey(name: 'escena_destino_id') int? escenaDestinoId,@JsonKey(name: 'poi_id') int? poiId, String? etiqueta
});




}
/// @nodoc
class __$HotspotCopyWithImpl<$Res>
    implements _$HotspotCopyWith<$Res> {
  __$HotspotCopyWithImpl(this._self, this._then);

  final _Hotspot _self;
  final $Res Function(_Hotspot) _then;

/// Create a copy of Hotspot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? escenaId = null,Object? tipo = null,Object? pitch = null,Object? yaw = null,Object? escenaDestinoId = freezed,Object? poiId = freezed,Object? etiqueta = freezed,}) {
  return _then(_Hotspot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,escenaId: null == escenaId ? _self.escenaId : escenaId // ignore: cast_nullable_to_non_nullable
as int,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoHotspot,pitch: null == pitch ? _self.pitch : pitch // ignore: cast_nullable_to_non_nullable
as double,yaw: null == yaw ? _self.yaw : yaw // ignore: cast_nullable_to_non_nullable
as double,escenaDestinoId: freezed == escenaDestinoId ? _self.escenaDestinoId : escenaDestinoId // ignore: cast_nullable_to_non_nullable
as int?,poiId: freezed == poiId ? _self.poiId : poiId // ignore: cast_nullable_to_non_nullable
as int?,etiqueta: freezed == etiqueta ? _self.etiqueta : etiqueta // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Medio {

 int get id;@JsonKey(name: 'poi_id') int get poiId;@JsonKey(unknownEnumValue: TipoMedio.desconocido) TipoMedio get tipo; String get url; int get orden;@JsonKey(name: 'duracion_seg') int? get duracionSeg;@JsonKey(name: 'texto_alt') String? get textoAlt;/// Subtítulos o transcripción, en WebVTT o texto plano, en el mismo
/// idioma que [idioma].
@JsonKey(name: 'subtitulos_url') String? get subtitulosUrl;/// Etiqueta BCP 47 del idioma hablado o señado: `es`, `en`, `pt-BR`, o
/// `csn` para un video en Lengua de Señas Colombiana. Nulo se toma como
/// el idioma original del contenido, el español.
 String? get idioma;
/// Create a copy of Medio
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedioCopyWith<Medio> get copyWith => _$MedioCopyWithImpl<Medio>(this as Medio, _$identity);

  /// Serializes this Medio to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Medio&&(identical(other.id, id) || other.id == id)&&(identical(other.poiId, poiId) || other.poiId == poiId)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.url, url) || other.url == url)&&(identical(other.orden, orden) || other.orden == orden)&&(identical(other.duracionSeg, duracionSeg) || other.duracionSeg == duracionSeg)&&(identical(other.textoAlt, textoAlt) || other.textoAlt == textoAlt)&&(identical(other.subtitulosUrl, subtitulosUrl) || other.subtitulosUrl == subtitulosUrl)&&(identical(other.idioma, idioma) || other.idioma == idioma));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,poiId,tipo,url,orden,duracionSeg,textoAlt,subtitulosUrl,idioma);

@override
String toString() {
  return 'Medio(id: $id, poiId: $poiId, tipo: $tipo, url: $url, orden: $orden, duracionSeg: $duracionSeg, textoAlt: $textoAlt, subtitulosUrl: $subtitulosUrl, idioma: $idioma)';
}


}

/// @nodoc
abstract mixin class $MedioCopyWith<$Res>  {
  factory $MedioCopyWith(Medio value, $Res Function(Medio) _then) = _$MedioCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'poi_id') int poiId,@JsonKey(unknownEnumValue: TipoMedio.desconocido) TipoMedio tipo, String url, int orden,@JsonKey(name: 'duracion_seg') int? duracionSeg,@JsonKey(name: 'texto_alt') String? textoAlt,@JsonKey(name: 'subtitulos_url') String? subtitulosUrl, String? idioma
});




}
/// @nodoc
class _$MedioCopyWithImpl<$Res>
    implements $MedioCopyWith<$Res> {
  _$MedioCopyWithImpl(this._self, this._then);

  final Medio _self;
  final $Res Function(Medio) _then;

/// Create a copy of Medio
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? poiId = null,Object? tipo = null,Object? url = null,Object? orden = null,Object? duracionSeg = freezed,Object? textoAlt = freezed,Object? subtitulosUrl = freezed,Object? idioma = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,poiId: null == poiId ? _self.poiId : poiId // ignore: cast_nullable_to_non_nullable
as int,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoMedio,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,duracionSeg: freezed == duracionSeg ? _self.duracionSeg : duracionSeg // ignore: cast_nullable_to_non_nullable
as int?,textoAlt: freezed == textoAlt ? _self.textoAlt : textoAlt // ignore: cast_nullable_to_non_nullable
as String?,subtitulosUrl: freezed == subtitulosUrl ? _self.subtitulosUrl : subtitulosUrl // ignore: cast_nullable_to_non_nullable
as String?,idioma: freezed == idioma ? _self.idioma : idioma // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Medio].
extension MedioPatterns on Medio {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Medio value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Medio() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Medio value)  $default,){
final _that = this;
switch (_that) {
case _Medio():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Medio value)?  $default,){
final _that = this;
switch (_that) {
case _Medio() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'poi_id')  int poiId, @JsonKey(unknownEnumValue: TipoMedio.desconocido)  TipoMedio tipo,  String url,  int orden, @JsonKey(name: 'duracion_seg')  int? duracionSeg, @JsonKey(name: 'texto_alt')  String? textoAlt, @JsonKey(name: 'subtitulos_url')  String? subtitulosUrl,  String? idioma)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Medio() when $default != null:
return $default(_that.id,_that.poiId,_that.tipo,_that.url,_that.orden,_that.duracionSeg,_that.textoAlt,_that.subtitulosUrl,_that.idioma);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'poi_id')  int poiId, @JsonKey(unknownEnumValue: TipoMedio.desconocido)  TipoMedio tipo,  String url,  int orden, @JsonKey(name: 'duracion_seg')  int? duracionSeg, @JsonKey(name: 'texto_alt')  String? textoAlt, @JsonKey(name: 'subtitulos_url')  String? subtitulosUrl,  String? idioma)  $default,) {final _that = this;
switch (_that) {
case _Medio():
return $default(_that.id,_that.poiId,_that.tipo,_that.url,_that.orden,_that.duracionSeg,_that.textoAlt,_that.subtitulosUrl,_that.idioma);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'poi_id')  int poiId, @JsonKey(unknownEnumValue: TipoMedio.desconocido)  TipoMedio tipo,  String url,  int orden, @JsonKey(name: 'duracion_seg')  int? duracionSeg, @JsonKey(name: 'texto_alt')  String? textoAlt, @JsonKey(name: 'subtitulos_url')  String? subtitulosUrl,  String? idioma)?  $default,) {final _that = this;
switch (_that) {
case _Medio() when $default != null:
return $default(_that.id,_that.poiId,_that.tipo,_that.url,_that.orden,_that.duracionSeg,_that.textoAlt,_that.subtitulosUrl,_that.idioma);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Medio extends Medio {
  const _Medio({required this.id, @JsonKey(name: 'poi_id') required this.poiId, @JsonKey(unknownEnumValue: TipoMedio.desconocido) required this.tipo, required this.url, this.orden = 0, @JsonKey(name: 'duracion_seg') this.duracionSeg, @JsonKey(name: 'texto_alt') this.textoAlt, @JsonKey(name: 'subtitulos_url') this.subtitulosUrl, this.idioma}): super._();
  factory _Medio.fromJson(Map<String, dynamic> json) => _$MedioFromJson(json);

@override final  int id;
@override@JsonKey(name: 'poi_id') final  int poiId;
@override@JsonKey(unknownEnumValue: TipoMedio.desconocido) final  TipoMedio tipo;
@override final  String url;
@override@JsonKey() final  int orden;
@override@JsonKey(name: 'duracion_seg') final  int? duracionSeg;
@override@JsonKey(name: 'texto_alt') final  String? textoAlt;
/// Subtítulos o transcripción, en WebVTT o texto plano, en el mismo
/// idioma que [idioma].
@override@JsonKey(name: 'subtitulos_url') final  String? subtitulosUrl;
/// Etiqueta BCP 47 del idioma hablado o señado: `es`, `en`, `pt-BR`, o
/// `csn` para un video en Lengua de Señas Colombiana. Nulo se toma como
/// el idioma original del contenido, el español.
@override final  String? idioma;

/// Create a copy of Medio
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedioCopyWith<_Medio> get copyWith => __$MedioCopyWithImpl<_Medio>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MedioToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Medio&&(identical(other.id, id) || other.id == id)&&(identical(other.poiId, poiId) || other.poiId == poiId)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.url, url) || other.url == url)&&(identical(other.orden, orden) || other.orden == orden)&&(identical(other.duracionSeg, duracionSeg) || other.duracionSeg == duracionSeg)&&(identical(other.textoAlt, textoAlt) || other.textoAlt == textoAlt)&&(identical(other.subtitulosUrl, subtitulosUrl) || other.subtitulosUrl == subtitulosUrl)&&(identical(other.idioma, idioma) || other.idioma == idioma));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,poiId,tipo,url,orden,duracionSeg,textoAlt,subtitulosUrl,idioma);

@override
String toString() {
  return 'Medio(id: $id, poiId: $poiId, tipo: $tipo, url: $url, orden: $orden, duracionSeg: $duracionSeg, textoAlt: $textoAlt, subtitulosUrl: $subtitulosUrl, idioma: $idioma)';
}


}

/// @nodoc
abstract mixin class _$MedioCopyWith<$Res> implements $MedioCopyWith<$Res> {
  factory _$MedioCopyWith(_Medio value, $Res Function(_Medio) _then) = __$MedioCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'poi_id') int poiId,@JsonKey(unknownEnumValue: TipoMedio.desconocido) TipoMedio tipo, String url, int orden,@JsonKey(name: 'duracion_seg') int? duracionSeg,@JsonKey(name: 'texto_alt') String? textoAlt,@JsonKey(name: 'subtitulos_url') String? subtitulosUrl, String? idioma
});




}
/// @nodoc
class __$MedioCopyWithImpl<$Res>
    implements _$MedioCopyWith<$Res> {
  __$MedioCopyWithImpl(this._self, this._then);

  final _Medio _self;
  final $Res Function(_Medio) _then;

/// Create a copy of Medio
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? poiId = null,Object? tipo = null,Object? url = null,Object? orden = null,Object? duracionSeg = freezed,Object? textoAlt = freezed,Object? subtitulosUrl = freezed,Object? idioma = freezed,}) {
  return _then(_Medio(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,poiId: null == poiId ? _self.poiId : poiId // ignore: cast_nullable_to_non_nullable
as int,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoMedio,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,duracionSeg: freezed == duracionSeg ? _self.duracionSeg : duracionSeg // ignore: cast_nullable_to_non_nullable
as int?,textoAlt: freezed == textoAlt ? _self.textoAlt : textoAlt // ignore: cast_nullable_to_non_nullable
as String?,subtitulosUrl: freezed == subtitulosUrl ? _self.subtitulosUrl : subtitulosUrl // ignore: cast_nullable_to_non_nullable
as String?,idioma: freezed == idioma ? _self.idioma : idioma // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Ruta {

 int get id;@JsonKey(name: 'lugar_id') int get lugarId; String get nombre; String? get descripcion; Audiencia get audiencia; bool get activa;
/// Create a copy of Ruta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RutaCopyWith<Ruta> get copyWith => _$RutaCopyWithImpl<Ruta>(this as Ruta, _$identity);

  /// Serializes this Ruta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Ruta&&(identical(other.id, id) || other.id == id)&&(identical(other.lugarId, lugarId) || other.lugarId == lugarId)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.audiencia, audiencia) || other.audiencia == audiencia)&&(identical(other.activa, activa) || other.activa == activa));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,lugarId,nombre,descripcion,audiencia,activa);

@override
String toString() {
  return 'Ruta(id: $id, lugarId: $lugarId, nombre: $nombre, descripcion: $descripcion, audiencia: $audiencia, activa: $activa)';
}


}

/// @nodoc
abstract mixin class $RutaCopyWith<$Res>  {
  factory $RutaCopyWith(Ruta value, $Res Function(Ruta) _then) = _$RutaCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'lugar_id') int lugarId, String nombre, String? descripcion, Audiencia audiencia, bool activa
});




}
/// @nodoc
class _$RutaCopyWithImpl<$Res>
    implements $RutaCopyWith<$Res> {
  _$RutaCopyWithImpl(this._self, this._then);

  final Ruta _self;
  final $Res Function(Ruta) _then;

/// Create a copy of Ruta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? lugarId = null,Object? nombre = null,Object? descripcion = freezed,Object? audiencia = null,Object? activa = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,lugarId: null == lugarId ? _self.lugarId : lugarId // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,audiencia: null == audiencia ? _self.audiencia : audiencia // ignore: cast_nullable_to_non_nullable
as Audiencia,activa: null == activa ? _self.activa : activa // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Ruta].
extension RutaPatterns on Ruta {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Ruta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Ruta() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Ruta value)  $default,){
final _that = this;
switch (_that) {
case _Ruta():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Ruta value)?  $default,){
final _that = this;
switch (_that) {
case _Ruta() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'lugar_id')  int lugarId,  String nombre,  String? descripcion,  Audiencia audiencia,  bool activa)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Ruta() when $default != null:
return $default(_that.id,_that.lugarId,_that.nombre,_that.descripcion,_that.audiencia,_that.activa);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'lugar_id')  int lugarId,  String nombre,  String? descripcion,  Audiencia audiencia,  bool activa)  $default,) {final _that = this;
switch (_that) {
case _Ruta():
return $default(_that.id,_that.lugarId,_that.nombre,_that.descripcion,_that.audiencia,_that.activa);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'lugar_id')  int lugarId,  String nombre,  String? descripcion,  Audiencia audiencia,  bool activa)?  $default,) {final _that = this;
switch (_that) {
case _Ruta() when $default != null:
return $default(_that.id,_that.lugarId,_that.nombre,_that.descripcion,_that.audiencia,_that.activa);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Ruta implements Ruta {
  const _Ruta({required this.id, @JsonKey(name: 'lugar_id') required this.lugarId, required this.nombre, this.descripcion, required this.audiencia, this.activa = true});
  factory _Ruta.fromJson(Map<String, dynamic> json) => _$RutaFromJson(json);

@override final  int id;
@override@JsonKey(name: 'lugar_id') final  int lugarId;
@override final  String nombre;
@override final  String? descripcion;
@override final  Audiencia audiencia;
@override@JsonKey() final  bool activa;

/// Create a copy of Ruta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RutaCopyWith<_Ruta> get copyWith => __$RutaCopyWithImpl<_Ruta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RutaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ruta&&(identical(other.id, id) || other.id == id)&&(identical(other.lugarId, lugarId) || other.lugarId == lugarId)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.audiencia, audiencia) || other.audiencia == audiencia)&&(identical(other.activa, activa) || other.activa == activa));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,lugarId,nombre,descripcion,audiencia,activa);

@override
String toString() {
  return 'Ruta(id: $id, lugarId: $lugarId, nombre: $nombre, descripcion: $descripcion, audiencia: $audiencia, activa: $activa)';
}


}

/// @nodoc
abstract mixin class _$RutaCopyWith<$Res> implements $RutaCopyWith<$Res> {
  factory _$RutaCopyWith(_Ruta value, $Res Function(_Ruta) _then) = __$RutaCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'lugar_id') int lugarId, String nombre, String? descripcion, Audiencia audiencia, bool activa
});




}
/// @nodoc
class __$RutaCopyWithImpl<$Res>
    implements _$RutaCopyWith<$Res> {
  __$RutaCopyWithImpl(this._self, this._then);

  final _Ruta _self;
  final $Res Function(_Ruta) _then;

/// Create a copy of Ruta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? lugarId = null,Object? nombre = null,Object? descripcion = freezed,Object? audiencia = null,Object? activa = null,}) {
  return _then(_Ruta(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,lugarId: null == lugarId ? _self.lugarId : lugarId // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,audiencia: null == audiencia ? _self.audiencia : audiencia // ignore: cast_nullable_to_non_nullable
as Audiencia,activa: null == activa ? _self.activa : activa // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Perfil {

@JsonKey(name: 'user_id') String get userId; RolUsuario get rol;/// Solo un administrador lo pone en true. Un rol declarado por el propio
/// usuario llega siempre sin verificar.
 bool get verificado;
/// Create a copy of Perfil
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PerfilCopyWith<Perfil> get copyWith => _$PerfilCopyWithImpl<Perfil>(this as Perfil, _$identity);

  /// Serializes this Perfil to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Perfil&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.rol, rol) || other.rol == rol)&&(identical(other.verificado, verificado) || other.verificado == verificado));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,rol,verificado);

@override
String toString() {
  return 'Perfil(userId: $userId, rol: $rol, verificado: $verificado)';
}


}

/// @nodoc
abstract mixin class $PerfilCopyWith<$Res>  {
  factory $PerfilCopyWith(Perfil value, $Res Function(Perfil) _then) = _$PerfilCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'user_id') String userId, RolUsuario rol, bool verificado
});




}
/// @nodoc
class _$PerfilCopyWithImpl<$Res>
    implements $PerfilCopyWith<$Res> {
  _$PerfilCopyWithImpl(this._self, this._then);

  final Perfil _self;
  final $Res Function(Perfil) _then;

/// Create a copy of Perfil
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? rol = null,Object? verificado = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,rol: null == rol ? _self.rol : rol // ignore: cast_nullable_to_non_nullable
as RolUsuario,verificado: null == verificado ? _self.verificado : verificado // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Perfil].
extension PerfilPatterns on Perfil {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Perfil value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Perfil() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Perfil value)  $default,){
final _that = this;
switch (_that) {
case _Perfil():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Perfil value)?  $default,){
final _that = this;
switch (_that) {
case _Perfil() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId,  RolUsuario rol,  bool verificado)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Perfil() when $default != null:
return $default(_that.userId,_that.rol,_that.verificado);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId,  RolUsuario rol,  bool verificado)  $default,) {final _that = this;
switch (_that) {
case _Perfil():
return $default(_that.userId,_that.rol,_that.verificado);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'user_id')  String userId,  RolUsuario rol,  bool verificado)?  $default,) {final _that = this;
switch (_that) {
case _Perfil() when $default != null:
return $default(_that.userId,_that.rol,_that.verificado);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Perfil implements Perfil {
  const _Perfil({@JsonKey(name: 'user_id') required this.userId, required this.rol, this.verificado = false});
  factory _Perfil.fromJson(Map<String, dynamic> json) => _$PerfilFromJson(json);

@override@JsonKey(name: 'user_id') final  String userId;
@override final  RolUsuario rol;
/// Solo un administrador lo pone en true. Un rol declarado por el propio
/// usuario llega siempre sin verificar.
@override@JsonKey() final  bool verificado;

/// Create a copy of Perfil
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PerfilCopyWith<_Perfil> get copyWith => __$PerfilCopyWithImpl<_Perfil>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PerfilToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Perfil&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.rol, rol) || other.rol == rol)&&(identical(other.verificado, verificado) || other.verificado == verificado));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,rol,verificado);

@override
String toString() {
  return 'Perfil(userId: $userId, rol: $rol, verificado: $verificado)';
}


}

/// @nodoc
abstract mixin class _$PerfilCopyWith<$Res> implements $PerfilCopyWith<$Res> {
  factory _$PerfilCopyWith(_Perfil value, $Res Function(_Perfil) _then) = __$PerfilCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'user_id') String userId, RolUsuario rol, bool verificado
});




}
/// @nodoc
class __$PerfilCopyWithImpl<$Res>
    implements _$PerfilCopyWith<$Res> {
  __$PerfilCopyWithImpl(this._self, this._then);

  final _Perfil _self;
  final $Res Function(_Perfil) _then;

/// Create a copy of Perfil
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? rol = null,Object? verificado = null,}) {
  return _then(_Perfil(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,rol: null == rol ? _self.rol : rol // ignore: cast_nullable_to_non_nullable
as RolUsuario,verificado: null == verificado ? _self.verificado : verificado // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$PoiDetalle {

 Poi get poi; List<Medio> get medios;
/// Create a copy of PoiDetalle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PoiDetalleCopyWith<PoiDetalle> get copyWith => _$PoiDetalleCopyWithImpl<PoiDetalle>(this as PoiDetalle, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PoiDetalle&&(identical(other.poi, poi) || other.poi == poi)&&const DeepCollectionEquality().equals(other.medios, medios));
}


@override
int get hashCode => Object.hash(runtimeType,poi,const DeepCollectionEquality().hash(medios));

@override
String toString() {
  return 'PoiDetalle(poi: $poi, medios: $medios)';
}


}

/// @nodoc
abstract mixin class $PoiDetalleCopyWith<$Res>  {
  factory $PoiDetalleCopyWith(PoiDetalle value, $Res Function(PoiDetalle) _then) = _$PoiDetalleCopyWithImpl;
@useResult
$Res call({
 Poi poi, List<Medio> medios
});


$PoiCopyWith<$Res> get poi;

}
/// @nodoc
class _$PoiDetalleCopyWithImpl<$Res>
    implements $PoiDetalleCopyWith<$Res> {
  _$PoiDetalleCopyWithImpl(this._self, this._then);

  final PoiDetalle _self;
  final $Res Function(PoiDetalle) _then;

/// Create a copy of PoiDetalle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? poi = null,Object? medios = null,}) {
  return _then(_self.copyWith(
poi: null == poi ? _self.poi : poi // ignore: cast_nullable_to_non_nullable
as Poi,medios: null == medios ? _self.medios : medios // ignore: cast_nullable_to_non_nullable
as List<Medio>,
  ));
}
/// Create a copy of PoiDetalle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PoiCopyWith<$Res> get poi {
  
  return $PoiCopyWith<$Res>(_self.poi, (value) {
    return _then(_self.copyWith(poi: value));
  });
}
}


/// Adds pattern-matching-related methods to [PoiDetalle].
extension PoiDetallePatterns on PoiDetalle {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PoiDetalle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PoiDetalle() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PoiDetalle value)  $default,){
final _that = this;
switch (_that) {
case _PoiDetalle():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PoiDetalle value)?  $default,){
final _that = this;
switch (_that) {
case _PoiDetalle() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Poi poi,  List<Medio> medios)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PoiDetalle() when $default != null:
return $default(_that.poi,_that.medios);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Poi poi,  List<Medio> medios)  $default,) {final _that = this;
switch (_that) {
case _PoiDetalle():
return $default(_that.poi,_that.medios);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Poi poi,  List<Medio> medios)?  $default,) {final _that = this;
switch (_that) {
case _PoiDetalle() when $default != null:
return $default(_that.poi,_that.medios);case _:
  return null;

}
}

}

/// @nodoc


class _PoiDetalle extends PoiDetalle {
  const _PoiDetalle({required this.poi, final  List<Medio> medios = const <Medio>[]}): _medios = medios,super._();
  

@override final  Poi poi;
 final  List<Medio> _medios;
@override@JsonKey() List<Medio> get medios {
  if (_medios is EqualUnmodifiableListView) return _medios;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_medios);
}


/// Create a copy of PoiDetalle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PoiDetalleCopyWith<_PoiDetalle> get copyWith => __$PoiDetalleCopyWithImpl<_PoiDetalle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PoiDetalle&&(identical(other.poi, poi) || other.poi == poi)&&const DeepCollectionEquality().equals(other._medios, _medios));
}


@override
int get hashCode => Object.hash(runtimeType,poi,const DeepCollectionEquality().hash(_medios));

@override
String toString() {
  return 'PoiDetalle(poi: $poi, medios: $medios)';
}


}

/// @nodoc
abstract mixin class _$PoiDetalleCopyWith<$Res> implements $PoiDetalleCopyWith<$Res> {
  factory _$PoiDetalleCopyWith(_PoiDetalle value, $Res Function(_PoiDetalle) _then) = __$PoiDetalleCopyWithImpl;
@override @useResult
$Res call({
 Poi poi, List<Medio> medios
});


@override $PoiCopyWith<$Res> get poi;

}
/// @nodoc
class __$PoiDetalleCopyWithImpl<$Res>
    implements _$PoiDetalleCopyWith<$Res> {
  __$PoiDetalleCopyWithImpl(this._self, this._then);

  final _PoiDetalle _self;
  final $Res Function(_PoiDetalle) _then;

/// Create a copy of PoiDetalle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? poi = null,Object? medios = null,}) {
  return _then(_PoiDetalle(
poi: null == poi ? _self.poi : poi // ignore: cast_nullable_to_non_nullable
as Poi,medios: null == medios ? _self._medios : medios // ignore: cast_nullable_to_non_nullable
as List<Medio>,
  ));
}

/// Create a copy of PoiDetalle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PoiCopyWith<$Res> get poi {
  
  return $PoiCopyWith<$Res>(_self.poi, (value) {
    return _then(_self.copyWith(poi: value));
  });
}
}

/// @nodoc
mixin _$Recorrido {

 List<Escena> get escenas; Map<int, List<Hotspot>> get hotspotsPorEscena;
/// Create a copy of Recorrido
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecorridoCopyWith<Recorrido> get copyWith => _$RecorridoCopyWithImpl<Recorrido>(this as Recorrido, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Recorrido&&const DeepCollectionEquality().equals(other.escenas, escenas)&&const DeepCollectionEquality().equals(other.hotspotsPorEscena, hotspotsPorEscena));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(escenas),const DeepCollectionEquality().hash(hotspotsPorEscena));

@override
String toString() {
  return 'Recorrido(escenas: $escenas, hotspotsPorEscena: $hotspotsPorEscena)';
}


}

/// @nodoc
abstract mixin class $RecorridoCopyWith<$Res>  {
  factory $RecorridoCopyWith(Recorrido value, $Res Function(Recorrido) _then) = _$RecorridoCopyWithImpl;
@useResult
$Res call({
 List<Escena> escenas, Map<int, List<Hotspot>> hotspotsPorEscena
});




}
/// @nodoc
class _$RecorridoCopyWithImpl<$Res>
    implements $RecorridoCopyWith<$Res> {
  _$RecorridoCopyWithImpl(this._self, this._then);

  final Recorrido _self;
  final $Res Function(Recorrido) _then;

/// Create a copy of Recorrido
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? escenas = null,Object? hotspotsPorEscena = null,}) {
  return _then(_self.copyWith(
escenas: null == escenas ? _self.escenas : escenas // ignore: cast_nullable_to_non_nullable
as List<Escena>,hotspotsPorEscena: null == hotspotsPorEscena ? _self.hotspotsPorEscena : hotspotsPorEscena // ignore: cast_nullable_to_non_nullable
as Map<int, List<Hotspot>>,
  ));
}

}


/// Adds pattern-matching-related methods to [Recorrido].
extension RecorridoPatterns on Recorrido {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Recorrido value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Recorrido() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Recorrido value)  $default,){
final _that = this;
switch (_that) {
case _Recorrido():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Recorrido value)?  $default,){
final _that = this;
switch (_that) {
case _Recorrido() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Escena> escenas,  Map<int, List<Hotspot>> hotspotsPorEscena)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Recorrido() when $default != null:
return $default(_that.escenas,_that.hotspotsPorEscena);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Escena> escenas,  Map<int, List<Hotspot>> hotspotsPorEscena)  $default,) {final _that = this;
switch (_that) {
case _Recorrido():
return $default(_that.escenas,_that.hotspotsPorEscena);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Escena> escenas,  Map<int, List<Hotspot>> hotspotsPorEscena)?  $default,) {final _that = this;
switch (_that) {
case _Recorrido() when $default != null:
return $default(_that.escenas,_that.hotspotsPorEscena);case _:
  return null;

}
}

}

/// @nodoc


class _Recorrido extends Recorrido {
  const _Recorrido({required final  List<Escena> escenas, required final  Map<int, List<Hotspot>> hotspotsPorEscena}): _escenas = escenas,_hotspotsPorEscena = hotspotsPorEscena,super._();
  

 final  List<Escena> _escenas;
@override List<Escena> get escenas {
  if (_escenas is EqualUnmodifiableListView) return _escenas;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_escenas);
}

 final  Map<int, List<Hotspot>> _hotspotsPorEscena;
@override Map<int, List<Hotspot>> get hotspotsPorEscena {
  if (_hotspotsPorEscena is EqualUnmodifiableMapView) return _hotspotsPorEscena;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_hotspotsPorEscena);
}


/// Create a copy of Recorrido
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecorridoCopyWith<_Recorrido> get copyWith => __$RecorridoCopyWithImpl<_Recorrido>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Recorrido&&const DeepCollectionEquality().equals(other._escenas, _escenas)&&const DeepCollectionEquality().equals(other._hotspotsPorEscena, _hotspotsPorEscena));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_escenas),const DeepCollectionEquality().hash(_hotspotsPorEscena));

@override
String toString() {
  return 'Recorrido(escenas: $escenas, hotspotsPorEscena: $hotspotsPorEscena)';
}


}

/// @nodoc
abstract mixin class _$RecorridoCopyWith<$Res> implements $RecorridoCopyWith<$Res> {
  factory _$RecorridoCopyWith(_Recorrido value, $Res Function(_Recorrido) _then) = __$RecorridoCopyWithImpl;
@override @useResult
$Res call({
 List<Escena> escenas, Map<int, List<Hotspot>> hotspotsPorEscena
});




}
/// @nodoc
class __$RecorridoCopyWithImpl<$Res>
    implements _$RecorridoCopyWith<$Res> {
  __$RecorridoCopyWithImpl(this._self, this._then);

  final _Recorrido _self;
  final $Res Function(_Recorrido) _then;

/// Create a copy of Recorrido
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? escenas = null,Object? hotspotsPorEscena = null,}) {
  return _then(_Recorrido(
escenas: null == escenas ? _self._escenas : escenas // ignore: cast_nullable_to_non_nullable
as List<Escena>,hotspotsPorEscena: null == hotspotsPorEscena ? _self._hotspotsPorEscena : hotspotsPorEscena // ignore: cast_nullable_to_non_nullable
as Map<int, List<Hotspot>>,
  ));
}


}

// dart format on

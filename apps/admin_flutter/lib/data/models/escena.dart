double? _toDouble(Object? v) => (v as num?)?.toDouble();
int? _toInt(Object? v) => (v as num?)?.toInt();

/// Escena 360° de un lugar, opcionalmente ligada a un POI.
/// Respuestas: snake_case (EscenaDto). Peticiones: camelCase.
class Escena {
  const Escena({
    required this.id,
    required this.lugarId,
    this.poiId,
    this.nombre,
    this.imagenUrl,
    this.imagenUrlBaja,
    this.esEscenaPrincipal = false,
    this.orden = 0,
    this.vistaInicialYaw,
    this.vistaInicialPitch,
    this.textoAlt,
  });

  final int id;
  final int lugarId;
  final int? poiId;
  final String? nombre;
  final String? imagenUrl;
  final String? imagenUrlBaja;
  final bool esEscenaPrincipal;
  final int orden;
  final double? vistaInicialYaw;
  final double? vistaInicialPitch;

  /// Descripción de lo que se ve, para quien no ve la panorámica. El backend
  /// aún no la envía ni la guarda (tarea pendiente); solo se lee.
  final String? textoAlt;

  factory Escena.fromJson(Map<String, dynamic> j) => Escena(
        id: _toInt(j['id']) ?? 0,
        lugarId: _toInt(j['lugar_id']) ?? 0,
        poiId: _toInt(j['poi_id']),
        nombre: j['nombre'] as String?,
        imagenUrl: j['imagen_url'] as String?,
        imagenUrlBaja: j['imagen_url_baja'] as String?,
        esEscenaPrincipal: (j['es_escena_principal'] as bool?) ?? false,
        orden: _toInt(j['orden']) ?? 0,
        vistaInicialYaw: _toDouble(j['vista_inicial_yaw']),
        vistaInicialPitch: _toDouble(j['vista_inicial_pitch']),
        textoAlt: j['texto_alt'] as String?,
      );

  Map<String, dynamic> _body() => {
        'poiId': poiId,
        'nombre': nombre,
        'imagenUrl': imagenUrl,
        'imagenUrlBaja': imagenUrlBaja,
        'esEscenaPrincipal': esEscenaPrincipal,
        'orden': orden,
        'vistaInicialYaw': vistaInicialYaw,
        'vistaInicialPitch': vistaInicialPitch,
        // Backend tarea 5: hoy la API ignora `textoAlt` al escribir.
        'textoAlt': textoAlt,
      };

  /// Cuerpo de POST /api/admin/escenas (CrearEscenaRequest).
  Map<String, dynamic> toCreateJson() => {'lugarId': lugarId, ..._body()};

  /// Cuerpo de PUT /api/admin/escenas/{id} (ActualizarEscenaRequest).
  Map<String, dynamic> toUpdateJson() => _body();
}

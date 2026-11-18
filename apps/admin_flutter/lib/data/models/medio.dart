import 'enums.dart';

int? _toInt(Object? v) => (v as num?)?.toInt();

/// Archivo multimedia de un POI (imagen, video o audio).
/// Respuestas: snake_case (MedioDto). Peticiones: camelCase.
class Medio {
  const Medio({
    required this.id,
    required this.poiId,
    required this.tipo,
    this.url,
    this.orden = 0,
    this.duracionSeg,
    this.textoAlt,
    this.subtitulosUrl,
    this.idioma,
  });

  final int id;
  final int poiId;
  final TipoMedio tipo;
  final String? url;
  final int orden;
  final int? duracionSeg;
  final String? textoAlt;
  final String? subtitulosUrl;

  /// Etiqueta BCP 47 del idioma hablado o señado (`es`, `en`, `pt-BR`, `csn`).
  /// Nulo = idioma original (español). La API aún no lo acepta al escribir, así
  /// que solo se lee.
  final String? idioma;

  factory Medio.fromJson(Map<String, dynamic> j) => Medio(
        id: _toInt(j['id']) ?? 0,
        poiId: _toInt(j['poi_id']) ?? 0,
        tipo: TipoMedio.tryParse(j['tipo']),
        url: j['url'] as String?,
        orden: _toInt(j['orden']) ?? 0,
        duracionSeg: _toInt(j['duracion_seg']),
        textoAlt: j['texto_alt'] as String?,
        subtitulosUrl: j['subtitulos_url'] as String?,
        idioma: j['idioma'] as String?,
      );

  Map<String, dynamic> _body() => {
        'tipo': tipo.name,
        'url': url,
        'orden': orden,
        'duracionSeg': duracionSeg,
        'textoAlt': textoAlt,
        'subtitulosUrl': subtitulosUrl,
        // Backend tarea 4: hoy la API ignora `idioma` al escribir.
        'idioma': idioma,
      };

  /// Cuerpo de POST /api/admin/medios (CrearMedioRequest).
  Map<String, dynamic> toCreateJson() => {'poiId': poiId, ..._body()};

  /// Cuerpo de PUT /api/admin/medios/{id} (ActualizarMedioRequest).
  Map<String, dynamic> toUpdateJson() => _body();
}

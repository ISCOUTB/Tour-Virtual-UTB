import '../data/models/enums.dart';
import '../data/models/poi.dart';

/// Reglas de negocio del SRS que el panel debe aplicar en el cliente.

/// RN-01: no se puede desactivar el último POI activo.
bool puedeDesactivar(List<Poi> pois, Poi poi) {
  if (!poi.activo) return true;
  final activos = pois.where((p) => p.activo).length;
  return activos > 1;
}

/// RN-03: límite de tamaño por tipo de archivo (imagen 5 MB, video 100 MB,
/// audio 10 MB).
int maxBytesPara(TipoMedio tipo) {
  const mb = 1024 * 1024;
  switch (tipo) {
    case TipoMedio.imagen:
      return 5 * mb;
    case TipoMedio.video:
      return 100 * mb;
    case TipoMedio.audio:
      return 10 * mb;
  }
}

/// Devuelve un mensaje de error o null si el archivo es válido.
String? validarTamano(TipoMedio tipo, int bytes) {
  final max = maxBytesPara(tipo);
  if (bytes <= max) return null;
  final mb = max ~/ (1024 * 1024);
  return 'El archivo supera el límite de $mb MB para ${tipo.name}.';
}

/// Un POI está "completo" cuando tiene escena 360° principal y descripción.
/// (Propuesta de la guía, sección B.1: el audio es opcional.)
bool poiCompleto(Poi poi) =>
    poi.escenaPrincipalId != null &&
    (poi.descripcion?.trim().isNotEmpty ?? false);

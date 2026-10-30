import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../configuracion_tour.dart';
import 'modelos/modelos.dart';
import 'preferencias.dart';
import 'repositorio_contenido.dart';
import 'repositorio_demo.dart';
import 'subtitulos.dart';

/// Repositorio de la fuente con que se abrió el módulo y del idioma activo.
/// Cambiar de idioma lo reemplaza, y con él se vuelve a pedir todo el
/// contenido con el nuevo `Accept-Language`.
final repositorioContenidoProvider = Provider<RepositorioContenido>((ref) {
  final configuracion = ref.watch(configuracionTourProvider);
  return switch (configuracion.fuente) {
    ContenidoLocal(:final medios) => RepositorioDemo(medios: medios),
    ContenidoRemoto(:final urlApi) => RepositorioContenido(
      baseUrl: urlApi,
      idioma: ref.watch(idiomaProvider).toLanguageTag(),
      audiencia: configuracion.audiencia,
    ),
  };
});

final poisProvider = FutureProvider.family<List<Poi>, int>((ref, lugarId) {
  return ref.watch(repositorioContenidoProvider).obtenerPois(lugarId);
});

final recorridoProvider = FutureProvider.family<Recorrido, int>((ref, lugarId) {
  return ref.watch(repositorioContenidoProvider).obtenerRecorrido(lugarId);
});

final poiDetalleProvider = FutureProvider.family<PoiDetalle, int>((ref, poiId) {
  return ref.watch(repositorioContenidoProvider).obtenerPoiDetalle(poiId);
});

/// Subtítulos y transcripción de un medio, por URL del archivo.
final subtitulosProvider = FutureProvider.family<Subtitulos, String>((
  ref,
  url,
) {
  return ref.watch(repositorioContenidoProvider).obtenerSubtitulos(url);
});

/// Ruta activa para la audiencia que el servidor reconoce.
///
/// Da nombre y descripción a la cabecera del módulo. Es opcional: si falla o
/// no hay ruta, la cabecera usa un texto genérico.
final rutaProvider = FutureProvider.family<Ruta?, int>((ref, lugarId) {
  return ref.watch(repositorioContenidoProvider).obtenerRutaActual(lugarId);
});

/// Escena principal de un POI, si el recorrido ya cargó.
///
/// Las tarjetas la usan para asomarse a la panorámica antes de entrar. Nunca
/// dispara un error: mientras carga o si falla, no hay escena y la tarjeta
/// dibuja su versión sin foto.
Escena? escenaPrincipalDe(WidgetRef ref, Poi poi) {
  final id = poi.escenaPrincipalId;
  if (id == null) return null;
  return ref.watch(recorridoProvider(poi.lugarId)).valueOrNull?.escenaPorId(id);
}

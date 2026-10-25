import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../nucleo/configuracion.dart';
import 'modelos/modelos.dart';
import 'preferencias.dart';
import 'repositorio_contenido.dart';
import 'repositorio_demo.dart';
import 'subtitulos.dart';

/// Repositorio del idioma activo. Cambiar de idioma lo reemplaza, y con él
/// se vuelve a pedir todo el contenido con el nuevo `Accept-Language`.
final repositorioContenidoProvider = Provider<RepositorioContenido>((ref) {
  if (Configuracion.datosDemo) return const RepositorioDemo();
  return RepositorioContenido(
    baseUrl: Configuracion.apiBaseUrl,
    idioma: ref.watch(idiomaProvider).toLanguageTag(),
  );
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

Future<void> inicializarBackend() async {}

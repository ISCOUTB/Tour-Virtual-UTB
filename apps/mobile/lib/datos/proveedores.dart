import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../nucleo/configuracion.dart';
import 'modelos/modelos.dart';
import 'repositorio_contenido.dart';

final repositorioContenidoProvider = Provider<RepositorioContenido>((ref) {
  return RepositorioContenido(baseUrl: Configuracion.apiBaseUrl);
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

final mapaUrlProvider = FutureProvider.family<String?, int>((ref, lugarId) {
  return ref.watch(repositorioContenidoProvider).obtenerUrlMapa(lugarId);
});

Future<void> inicializarBackend() async {}

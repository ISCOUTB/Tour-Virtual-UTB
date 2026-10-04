import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../nucleo/configuracion.dart';
import 'modelos/modelos.dart';
import 'repositorio_contenido.dart';

final clienteSupabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final repositorioContenidoProvider = Provider<RepositorioContenido>((ref) {
  return RepositorioContenido(ref.watch(clienteSupabaseProvider));
});

/// POIs del lugar, ya filtrados por audiencia en la base.
final poisProvider = FutureProvider.family<List<Poi>, int>((ref, lugarId) {
  return ref.watch(repositorioContenidoProvider).obtenerPois(lugarId);
});

/// Recorrido completo del lugar.
final recorridoProvider = FutureProvider.family<Recorrido, int>((ref, lugarId) {
  return ref.watch(repositorioContenidoProvider).obtenerRecorrido(lugarId);
});

/// Ficha multimedia de un POI.
final poiDetalleProvider = FutureProvider.family<PoiDetalle, int>((ref, poiId) {
  return ref.watch(repositorioContenidoProvider).obtenerPoiDetalle(poiId);
});

// La escena que se esta viendo NO vive en un provider. Estuvo en uno indexado
// por lugarId, que se autoinicializaba a la escena principal del lugar; como
// los cinco POI comparten lugar, ese valor nunca era nulo y tapaba la escena
// que pedia la ruta: cualquier POI abria la Biblioteca. Ahora es estado de
// RecorridoScreen, que es su alcance real: una pantalla, un recorrido.

/// Garantiza una sesion antes de consultar contenido.
///
/// Los visitantes externos entran sin cuenta mediante sesion anonima, lo que
/// les da un `user_id` valido para analitica sin recolectar ningun dato
/// personal. Si el proyecto no tiene habilitadas las sesiones anonimas, la app
/// sigue funcionando con el rol `anon`, que tambien puede leer contenido
/// publico segun las politicas RLS.
Future<void> asegurarSesion() async {
  final auth = Supabase.instance.client.auth;
  if (auth.currentSession != null) return;

  try {
    await auth.signInAnonymously();
  } catch (error) {
    debugPrint('Sesion anonima no disponible, se continua como anon: $error');
  }
}

/// Inicializa Supabase. Debe llamarse antes de `runApp`.
Future<void> inicializarSupabase() async {
  await Supabase.initialize(
    url: Configuracion.supabaseUrl,
    publishableKey: Configuracion.supabaseClavePublicable,
  );
  await asegurarSesion();
}

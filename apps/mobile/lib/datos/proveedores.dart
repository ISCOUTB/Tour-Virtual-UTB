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

/// Escena que se esta viendo dentro de un recorrido.
///
/// Vive aparte de [recorridoProvider] para que moverse entre escenas no vuelva
/// a pedir datos: el grafo ya esta cargado en memoria.
final escenaActualProvider = NotifierProvider.family<EscenaActual, int?, int>(
  EscenaActual.new,
);

class EscenaActual extends FamilyNotifier<int?, int> {
  @override
  int? build(int lugarId) {
    // Arranca en la escena principal en cuanto el recorrido este disponible.
    final recorrido = ref.watch(recorridoProvider(lugarId)).valueOrNull;
    return recorrido?.escenaInicial?.id;
  }

  void irA(int escenaId) => state = escenaId;
}

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

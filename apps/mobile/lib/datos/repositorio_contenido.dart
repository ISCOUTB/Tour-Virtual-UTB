import 'package:supabase_flutter/supabase_flutter.dart';

import '../nucleo/errores.dart';
import 'modelos/modelos.dart';

/// Acceso al contenido del recorrido.
///
/// Consulta Supabase directamente. El filtrado por audiencia lo aplican las
/// politicas RLS en Postgres a partir del rol que viaja en el JWT, de modo que
/// aqui no hay ni debe haber logica de permisos: si se reimplantara en el
/// cliente, seria evadible.
class RepositorioContenido {
  RepositorioContenido(this._cliente);

  final SupabaseClient _cliente;

  static const _tiempoLimite = Duration(seconds: 15);

  // Ojo con `order()`: en el cliente de Supabase es DESCENDENTE por defecto.
  // Sin `ascending: true` el recorrido se listaba del ultimo al primero y las
  // escenas salian en orden inverso, lo que ademas cambia cual cae en
  // `escenas.first` cuando ninguna esta marcada como principal.

  /// POIs visibles para el usuario actual.
  ///
  /// La lista puede ser mas corta que el total en base: RLS descarta los que no
  /// corresponden a su audiencia.
  Future<List<Poi>> obtenerPois(int lugarId) {
    return _ejecutar(() async {
      final filas = await _cliente
          .from('pois')
          .select()
          .eq('lugar_id', lugarId)
          .eq('activo', true)
          .order('id', ascending: true)
          .timeout(_tiempoLimite);

      return filas.map(Poi.fromJson).toList();
    });
  }

  /// Recorrido completo de un lugar: escenas y hotspots resueltos de una vez.
  ///
  /// Se traen juntos para que moverse entre escenas no toque la red. El grafo
  /// del MVP son 8 a 12 escenas, asi que el costo de la carga inicial es menor
  /// que el de una espera por cada salto.
  Future<Recorrido> obtenerRecorrido(int lugarId) {
    return _ejecutar(() async {
      final filasEscenas = await _cliente
          .from('escenas')
          .select()
          .eq('lugar_id', lugarId)
          .order('orden', ascending: true)
          .timeout(_tiempoLimite);

      final escenas = filasEscenas.map(Escena.fromJson).toList();
      if (escenas.isEmpty) {
        throw const FalloSinContenido(
          'Este lugar todavia no tiene un recorrido publicado.',
        );
      }

      final filasHotspots = await _cliente
          .from('hotspots')
          .select()
          .inFilter('escena_id', escenas.map((e) => e.id).toList())
          .timeout(_tiempoLimite);

      final hotspots = filasHotspots.map(Hotspot.fromJson).toList();
      final porEscena = <int, List<Hotspot>>{};
      for (final hotspot in hotspots) {
        porEscena.putIfAbsent(hotspot.escenaId, () => []).add(hotspot);
      }

      return Recorrido(escenas: escenas, hotspotsPorEscena: porEscena);
    });
  }

  /// Ficha de un POI con su contenido multimedia ordenado.
  Future<PoiDetalle> obtenerPoiDetalle(int poiId) {
    return _ejecutar(() async {
      final fila = await _cliente
          .from('pois')
          .select()
          .eq('id', poiId)
          .maybeSingle()
          .timeout(_tiempoLimite);

      if (fila == null) {
        throw const FalloSinContenido();
      }

      final filasMedios = await _cliente
          .from('medios')
          .select()
          .eq('poi_id', poiId)
          .order('orden', ascending: true)
          .timeout(_tiempoLimite);

      return PoiDetalle(
        poi: Poi.fromJson(fila),
        medios: filasMedios.map(Medio.fromJson).toList(),
      );
    });
  }

  /// Recorrido curado que corresponde al perfil del usuario.
  ///
  /// RLS solo devuelve las rutas de su audiencia, asi que basta con pedir la
  /// primera activa del lugar.
  Future<Ruta?> obtenerRutaActual(int lugarId) {
    return _ejecutar(() async {
      final fila = await _cliente
          .from('rutas')
          .select()
          .eq('lugar_id', lugarId)
          .eq('activa', true)
          .limit(1)
          .maybeSingle()
          .timeout(_tiempoLimite);

      return fila == null ? null : Ruta.fromJson(fila);
    });
  }

  /// Convierte cualquier excepcion de la capa de red en un [FalloApp], para que
  /// la interfaz nunca reciba un error que no sepa presentar.
  Future<T> _ejecutar<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } catch (error) {
      throw traducirFallo(error);
    }
  }
}

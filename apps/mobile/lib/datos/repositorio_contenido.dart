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

  /// Convierte una ruta de objeto de Storage en URL publica.
  ///
  /// La base guarda "bucket/archivo" y no una URL absoluta, para que la misma
  /// fila funcione en escritorio y en emulador, donde el anfitrion es
  /// 10.0.2.2. Una URL absoluta se devuelve tal cual, que es como quedaran los
  /// medios al moverlos a Cloudflare R2.
  String _resolverMedio(String valor) {
    if (valor.startsWith('http://') || valor.startsWith('https://')) {
      return valor;
    }
    final corte = valor.indexOf('/');
    if (corte <= 0) return valor;
    return _cliente.storage
        .from(valor.substring(0, corte))
        .getPublicUrl(valor.substring(corte + 1));
  }

  Map<String, dynamic> _conMediosResueltos(
    Map<String, dynamic> fila,
    List<String> campos,
  ) {
    final copia = Map<String, dynamic>.from(fila);
    for (final campo in campos) {
      final valor = copia[campo];
      if (valor is String && valor.isNotEmpty) {
        copia[campo] = _resolverMedio(valor);
      }
    }
    return copia;
  }

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

      final escenas = filasEscenas
          .map(
            (f) => Escena.fromJson(
              _conMediosResueltos(f, const ['imagen_url', 'imagen_url_baja']),
            ),
          )
          .toList();
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

      final visibles = escenas.map((e) => e.id).toSet();
      final porEscena = <int, List<Hotspot>>{};
      for (final hotspot in filasHotspots.map(Hotspot.fromJson)) {
        // Si RLS oculto la escena de destino, no se dibuja la puerta que lleva
        // a ella: seria un control visible que al tocarlo no hace nada.
        final destino = hotspot.escenaDestinoId;
        if (hotspot.tipo == TipoHotspot.navegacion &&
            (destino == null || !visibles.contains(destino))) {
          continue;
        }
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
        medios: filasMedios
            .map((f) => Medio.fromJson(_conMediosResueltos(f, const ['url'])))
            .toList(),
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

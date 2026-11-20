import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'geo.dart';

/// Tipo de tramo del grafo peatonal.
enum TipoTramo {
  sendero,
  via,
  escalera,

  /// Del camino a la puerta de un lugar.
  acceso,
  desconocido;

  static TipoTramo leer(Object? valor) =>
      values.where((t) => t.name == valor).firstOrNull ?? desconocido;
}

@immutable
class TramoCampus {
  const TramoCampus({
    required this.a,
    required this.b,
    required this.metros,
    required this.tipo,
    required this.escalones,
    required this.techado,
  });

  final String a;
  final String b;
  final double metros;
  final TipoTramo tipo;
  final bool escalones;

  /// Bajo techo el GPS empeora: sirve para avisarlo.
  final bool techado;
}

/// Una entrada de un lugar del campus (la Biblioteca tiene dos).
@immutable
class AccesoLugar {
  const AccesoLugar({
    required this.poiId,
    required this.nombre,
    required this.punto,
    required this.nodo,
    required this.principal,
    required this.verificado,
  });

  final int poiId;
  final String nombre;
  final PuntoGeo punto;

  /// Nodo del grafo en la puerta.
  final String nodo;
  final bool principal;

  /// Medido en el campus. Si no, sale del catálogo (centro del edificio o una
  /// estimación) y la app avisa de que la llegada es aproximada.
  final bool verificado;
}

/// Una ruta calculada: puntos a seguir de donde estás a la puerta.
@immutable
class RutaCampus {
  const RutaCampus({
    required this.puntos,
    required this.destino,
    required this.metros,
    required this.usaEscaleras,
  });

  /// Empieza en el punto del camino más cercano a la posición de partida y
  /// termina en la puerta.
  final List<PuntoGeo> puntos;
  final AccesoLugar destino;
  final double metros;
  final bool usaEscaleras;
}

/// Grafo peatonal del campus (RF-27, AD-02), generado por
/// `scripts/grafo_campus.py` a partir de OpenStreetMap (ODbL).
class GrafoCampus {
  GrafoCampus({
    required this.version,
    required this.declinacion,
    required this.nodos,
    required this.tramos,
    required this.accesos,
  }) {
    for (final t in tramos) {
      _vecinos.putIfAbsent(t.a, () => []).add(t);
      _vecinos.putIfAbsent(t.b, () => []).add(t);
    }
  }

  factory GrafoCampus.desdeJson(Map<String, dynamic> json) {
    PuntoGeo punto(Map<String, dynamic> j) =>
        PuntoGeo((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble());
    return GrafoCampus(
      version: json['version'] as String? ?? '',
      declinacion: (json['declinacion'] as num?)?.toDouble() ?? 0,
      nodos: {
        for (final n in (json['nodos'] as List).cast<Map<String, dynamic>>())
          n['id'] as String: punto(n),
      },
      tramos: [
        for (final t in (json['aristas'] as List).cast<Map<String, dynamic>>())
          TramoCampus(
            a: t['a'] as String,
            b: t['b'] as String,
            metros: (t['metros'] as num).toDouble(),
            tipo: TipoTramo.leer(t['tipo']),
            escalones: t['escalones'] as bool? ?? false,
            techado: t['techado'] as bool? ?? false,
          ),
      ],
      accesos: [
        for (final a in (json['accesos'] as List).cast<Map<String, dynamic>>())
          AccesoLugar(
            poiId: (a['poi_id'] as num).toInt(),
            nombre: a['nombre'] as String? ?? '',
            punto: punto(a),
            nodo: a['nodo'] as String,
            principal: a['principal'] as bool? ?? false,
            verificado: a['verificado'] as bool? ?? false,
          ),
      ],
    );
  }

  static const archivo =
      'packages/tour_virtual/assets/navegacion/grafo_campus.json';

  final String version;

  /// Declinación magnética del campus, en grados (positiva al este). La
  /// brújula da el norte magnético; el GPS y el grafo, el geográfico.
  final double declinacion;
  final Map<String, PuntoGeo> nodos;
  final List<TramoCampus> tramos;
  final List<AccesoLugar> accesos;
  final _vecinos = <String, List<TramoCampus>>{};

  List<AccesoLugar> accesosDe(int poiId) =>
      accesos.where((a) => a.poiId == poiId).toList();

  /// Si se puede llegar a un lugar con la guía.
  bool tieneAcceso(int poiId) => accesos.any((a) => a.poiId == poiId);

  /// Ruta más corta de [desde] a la entrada más cercana del lugar, con A*
  /// (heurística: Haversine a la entrada más próxima). Nula si no hay camino.
  ///
  /// La ruta entra al grafo por el punto del tramo más cercano a [desde], no
  /// por el nodo más cercano: los vértices de OSM pueden estar a 50 m.
  RutaCampus? ruta(PuntoGeo desde, int poiId, {bool sinEscaleras = false}) {
    final destinos = accesosDe(poiId);
    if (destinos.isEmpty) return null;
    final objetivos = {for (final d in destinos) d.nodo: d};

    bool usable(TramoCampus t) => !(sinEscaleras && t.escalones);

    // Entrada al grafo: el punto más cercano de cualquier tramo usable.
    TramoCampus? entrada;
    var mejor = (punto: desde, fraccion: 0.0, metros: double.infinity);
    for (final t in tramos) {
      if (!usable(t)) continue;
      final p = proyectarEnTramo(desde, nodos[t.a]!, nodos[t.b]!);
      if (p.metros < mejor.metros) {
        mejor = p;
        entrada = t;
      }
    }
    if (entrada == null) return null;

    const inicio = '_inicio';
    double h(String nodo) {
      final p = nodo == inicio ? mejor.punto : nodos[nodo]!;
      return destinos
          .map((d) => distanciaMetros(p, d.punto))
          .reduce((a, b) => a < b ? a : b);
    }

    final costo = <String, double>{inicio: 0};
    final previo = <String, String>{};
    final previoTramo = <String, TramoCampus?>{};
    final abiertos = <String>{inicio};
    final cerrados = <String>{};

    Iterable<(String, double, TramoCampus?)> vecinos(String nodo) sync* {
      if (nodo == inicio) {
        // Del punto de entrada a los dos extremos de su tramo.
        yield (entrada!.a, entrada.metros * mejor.fraccion, entrada);
        yield (entrada.b, entrada.metros * (1 - mejor.fraccion), entrada);
        return;
      }
      for (final t in _vecinos[nodo] ?? const <TramoCampus>[]) {
        if (!usable(t)) continue;
        yield (t.a == nodo ? t.b : t.a, t.metros, t);
      }
    }

    String? llegada;
    while (abiertos.isNotEmpty) {
      // El grafo tiene unos 200 nodos: una búsqueda lineal del mínimo basta.
      final actual = abiertos.reduce(
        (a, b) => costo[a]! + h(a) <= costo[b]! + h(b) ? a : b,
      );
      if (objetivos.containsKey(actual)) {
        llegada = actual;
        break;
      }
      abiertos.remove(actual);
      cerrados.add(actual);
      for (final (vecino, metros, tramo) in vecinos(actual)) {
        if (cerrados.contains(vecino)) continue;
        final nuevo = costo[actual]! + metros;
        if (nuevo < (costo[vecino] ?? double.infinity)) {
          costo[vecino] = nuevo;
          previo[vecino] = actual;
          previoTramo[vecino] = tramo;
          abiertos.add(vecino);
        }
      }
    }
    if (llegada == null) return null;

    final camino = <PuntoGeo>[];
    var usaEscaleras = false;
    for (String? n = llegada; n != null; n = previo[n]) {
      camino.add(n == inicio ? mejor.punto : nodos[n]!);
      if (previoTramo[n]?.escalones ?? false) usaEscaleras = true;
    }
    // Sin puntos repetidos: si se parte justo sobre un nodo, la entrada y el
    // nodo coinciden, y el rumbo entre dos puntos iguales inventaba un giro.
    final puntos = <PuntoGeo>[];
    for (final p in camino.reversed) {
      if (puntos.isEmpty || distanciaMetros(puntos.last, p) > 0.5) {
        puntos.add(p);
      }
    }
    return RutaCampus(
      puntos: puntos,
      destino: objetivos[llegada]!,
      metros: costo[llegada]!,
      usaEscaleras: usaEscaleras,
    );
  }
}

/// El grafo empaquetado. Se lee con `load` y no con `loadString`, igual que
/// el plano: en las pruebas de widgets el isolate de `loadString` no termina.
final grafoCampusProvider = FutureProvider<GrafoCampus>((ref) async {
  final datos = await rootBundle.load(GrafoCampus.archivo);
  final texto = utf8.decode(
    datos.buffer.asUint8List(datos.offsetInBytes, datos.lengthInBytes),
  );
  return GrafoCampus.desdeJson(jsonDecode(texto) as Map<String, dynamic>);
});

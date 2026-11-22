import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'geo.dart';
import 'grafo_campus.dart';

/// Correcciones de la guía hechas en el campus, en el teléfono.
///
/// Una indicación que sale mal en la prueba se corrige allí mismo: la puerta
/// real, un tramo que no se puede usar o que tiene escalones, un camino que
/// falta, la brújula corrida. Se aplican al grafo empaquetado al momento, se
/// copian a los otros teléfonos como texto y `scripts/grafo_campus.py` las
/// lleva al grafo oficial.
///
/// Solo existen en el modo campo (`--dart-define=CAMPO=true`): el visitante
/// nunca las ve ni las guarda.
///
/// Las de tramos se identifican por geometría y no por el id de los nodos:
/// otra corrección puede partir ese tramo, y el script regenera los ids desde
/// OSM.
@immutable
sealed class Correccion {
  const Correccion({required this.id, required this.fecha, this.autor});

  /// Quien la hizo, o nulo. Nunca vacío: [nuevoAutor] lo normaliza.

  final String id;
  final DateTime fecha;
  final String? autor;

  String get tipo;

  Map<String, dynamic> _datos();

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipo': tipo,
    'fecha': fecha.toIso8601String(),
    'autor': ?autor,
    ..._datos(),
  };

  /// Nula si el tipo no se conoce: un teléfono con una versión más nueva de
  /// la app no debe romper la importación de uno más viejo.
  static Correccion? fromJson(Map<String, dynamic> j) {
    final id = j['id'] as String?;
    final fecha = DateTime.tryParse(j['fecha'] as String? ?? '');
    if (id == null || fecha == null) return null;
    final autor = nuevoAutor(j['autor'] as String?);
    PuntoGeo punto(Object? v) {
      final m = v as Map<String, dynamic>;
      return PuntoGeo(
        (m['lat'] as num).toDouble(),
        (m['lng'] as num).toDouble(),
      );
    }

    try {
      return switch (j['tipo']) {
        'entrada' => CorreccionEntrada(
          id: id,
          fecha: fecha,
          autor: autor,
          poiId: (j['poi_id'] as num).toInt(),
          nombre: j['nombre'] as String? ?? '',
          punto: punto(j),
          precision: (j['precision'] as num?)?.toDouble(),
        ),
        'tramo' => CorreccionTramo(
          id: id,
          fecha: fecha,
          autor: autor,
          desde: punto(j['desde']),
          hasta: punto(j['hasta']),
          bloqueado: j['bloqueado'] as bool?,
          escalones: j['escalones'] as bool?,
        ),
        'camino' => CorreccionCamino(
          id: id,
          fecha: fecha,
          autor: autor,
          puntos: [for (final p in j['puntos'] as List) punto(p)],
          escalones: j['escalones'] as bool? ?? false,
        ),
        'brujula' => CorreccionBrujula(
          id: id,
          fecha: fecha,
          autor: autor,
          grados: (j['grados'] as num).toDouble(),
        ),
        'magnetico' => CorreccionMagnetico(
          id: id,
          fecha: fecha,
          autor: autor,
          tolerancia: (j['tolerancia'] as num?)?.toDouble(),
        ),
        'radio' => CorreccionRadio(
          id: id,
          fecha: fecha,
          autor: autor,
          metros: (j['metros'] as num).toDouble(),
        ),
        'prueba' => CorreccionPrueba(
          id: id,
          fecha: fecha,
          autor: autor,
          poiId: (j['poi_id'] as num).toInt(),
          puerta: punto(j['puerta']),
          destino: punto(j['destino']),
          llegadaApp: j['llegada_app'] == null ? null : punto(j['llegada_app']),
        ),
        'nota' => CorreccionNota(
          id: id,
          fecha: fecha,
          autor: autor,
          texto: j['texto'] as String? ?? '',
          punto: j['lat'] == null ? null : punto(j),
          poiId: (j['poi_id'] as num?)?.toInt(),
        ),
        _ => null,
      };
    } catch (error) {
      debugPrint('Corrección ilegible ($id): $error');
      return null;
    }
  }
}

Map<String, double> _geo(PuntoGeo p) => {
  'lat': double.parse(p.lat.toStringAsFixed(7)),
  'lng': double.parse(p.lng.toStringAsFixed(7)),
};

/// La puerta real de un lugar está aquí.
class CorreccionEntrada extends Correccion {
  const CorreccionEntrada({
    required super.id,
    required super.fecha,
    super.autor,
    required this.poiId,
    required this.nombre,
    required this.punto,
    this.precision,
  });

  final int poiId;

  /// Nombre de la entrada (la Biblioteca tiene dos). Uno nuevo la agrega.
  final String nombre;
  final PuntoGeo punto;

  /// Radio de confianza del promedio del GPS, en metros.
  final double? precision;

  @override
  String get tipo => 'entrada';

  @override
  Map<String, dynamic> _datos() => {
    'poi_id': poiId,
    'nombre': nombre,
    ..._geo(punto),
    if (precision != null)
      'precision': double.parse(precision!.toStringAsFixed(1)),
  };
}

/// Un tramo del grafo no se puede usar, o tiene (o no) escalones.
class CorreccionTramo extends Correccion {
  const CorreccionTramo({
    required super.id,
    required super.fecha,
    super.autor,
    required this.desde,
    required this.hasta,
    this.bloqueado,
    this.escalones,
  });

  final PuntoGeo desde;
  final PuntoGeo hasta;

  /// Nadie puede pasar: cerrado, privado o no existe. Para reabrirlo se
  /// deshace la corrección.
  final bool? bloqueado;
  final bool? escalones;

  @override
  String get tipo => 'tramo';

  @override
  Map<String, dynamic> _datos() => {
    'desde': _geo(desde),
    'hasta': _geo(hasta),
    'bloqueado': ?bloqueado,
    'escalones': ?escalones,
  };
}

/// Un camino que el grafo no tiene, grabado caminándolo.
class CorreccionCamino extends Correccion {
  const CorreccionCamino({
    required super.id,
    required super.fecha,
    super.autor,
    required this.puntos,
    this.escalones = false,
  });

  final List<PuntoGeo> puntos;
  final bool escalones;

  double get metros {
    var total = 0.0;
    for (var i = 0; i < puntos.length - 1; i++) {
      total += distanciaMetros(puntos[i], puntos[i + 1]);
    }
    return total;
  }

  @override
  String get tipo => 'camino';

  @override
  Map<String, dynamic> _datos() => {
    'puntos': [for (final p in puntos) _geo(p)],
    'escalones': escalones,
  };
}

/// Ajuste que se suma a la brújula (grados, positivo en sentido horario).
/// Manda el último.
class CorreccionBrujula extends Correccion {
  const CorreccionBrujula({
    required super.id,
    required super.fecha,
    super.autor,
    required this.grados,
  });

  final double grados;

  @override
  String get tipo => 'brujula';

  @override
  Map<String, dynamic> _datos() => {
    'grados': double.parse(grados.toStringAsFixed(1)),
  };
}

/// Cuánto se aparta el campo magnético antes de dar la brújula por
/// interferida. Nula: el rango mundial (20-75 µT). Manda la última.
class CorreccionMagnetico extends Correccion {
  const CorreccionMagnetico({
    required super.id,
    required super.fecha,
    super.autor,
    this.tolerancia,
  });

  final double? tolerancia;

  @override
  String get tipo => 'magnetico';

  @override
  Map<String, dynamic> _datos() => {'tolerancia': tolerancia};
}

/// Radio de llegada para probar en el campus. Manda el último.
class CorreccionRadio extends Correccion {
  const CorreccionRadio({
    required super.id,
    required super.fecha,
    super.autor,
    required this.metros,
  });

  final double metros;

  @override
  String get tipo => 'radio';

  @override
  Map<String, dynamic> _datos() => {'metros': metros};
}

/// «Estoy en la puerta»: dónde está la puerta real, dónde la tenía la guía y
/// dónde dio la llegada, si la dio. No cambia el grafo; sirve para medir
/// RF-29 y para ver qué entradas mover.
class CorreccionPrueba extends Correccion {
  const CorreccionPrueba({
    required super.id,
    required super.fecha,
    super.autor,
    required this.poiId,
    required this.puerta,
    required this.destino,
    this.llegadaApp,
  });

  final int poiId;
  final PuntoGeo puerta;
  final PuntoGeo destino;
  final PuntoGeo? llegadaApp;

  /// Metros entre la puerta real y la que tenía la guía.
  double get errorEntrada => distanciaMetros(puerta, destino);

  @override
  String get tipo => 'prueba';

  @override
  Map<String, dynamic> _datos() => {
    'poi_id': poiId,
    'puerta': _geo(puerta),
    'destino': _geo(destino),
    if (llegadaApp case final l?) 'llegada_app': _geo(l),
    'error_entrada_m': double.parse(errorEntrada.toStringAsFixed(1)),
  };
}

/// Algo que corregir después, con el lugar donde pasó.
class CorreccionNota extends Correccion {
  const CorreccionNota({
    required super.id,
    required super.fecha,
    super.autor,
    required this.texto,
    this.punto,
    this.poiId,
  });

  final String texto;
  final PuntoGeo? punto;
  final int? poiId;

  @override
  String get tipo => 'nota';

  @override
  Map<String, dynamic> _datos() => {
    'texto': texto,
    if (punto case final p?) ..._geo(p),
    'poi_id': ?poiId,
  };
}

/// Todas las correcciones de este teléfono y las importadas de otros.
@immutable
class CorreccionesCampo {
  const CorreccionesCampo({this.lista = const [], this.anuladas = const {}});

  static const formato = 'correcciones-guia-1';

  /// Más allá de esto, una punta de un camino grabado no se une al grafo.
  static const radioEnganche = 30.0;

  /// Un tramo corregido coincide con los del grafo a esta distancia.
  static const toleranciaTramo = 3.0;

  /// Ordenadas por fecha: se aplican en ese orden.
  final List<Correccion> lista;

  /// Ids deshechos. Se comparten, para que una importación no las reviva.
  final Set<String> anuladas;

  List<Correccion> get vigentes =>
      lista.where((c) => !anuladas.contains(c.id)).toList();

  bool get isEmpty => vigentes.isEmpty;

  /// Ajuste de la brújula vigente, en grados.
  double get ajusteBrujula =>
      vigentes.whereType<CorreccionBrujula>().lastOrNull?.grados ?? 0;

  /// La última corrección del detector de metal, o nula si no hay.
  CorreccionMagnetico? get magnetico =>
      vigentes.whereType<CorreccionMagnetico>().lastOrNull;

  /// Radio de llegada vigente, o nulo para el de la app.
  double? get radioLlegada =>
      vigentes.whereType<CorreccionRadio>().lastOrNull?.metros;

  /// Agrega [c]. Un ajuste (radio, detector, brújula) anula los anteriores
  /// del mismo tipo: manda el último, y tocar «+» cuatro veces no debe dejar
  /// cuatro correcciones en la lista.
  CorreccionesCampo agregar(Correccion c) {
    final reemplazadas = switch (c) {
      CorreccionRadio() => vigentes.whereType<CorreccionRadio>(),
      CorreccionMagnetico() => vigentes.whereType<CorreccionMagnetico>(),
      CorreccionBrujula() => vigentes.whereType<CorreccionBrujula>(),
      _ => const <Correccion>[],
    }.map((x) => x.id);
    return CorreccionesCampo(
      lista: _ordenar([...lista, c]),
      anuladas: {...anuladas, ...reemplazadas},
    );
  }

  CorreccionesCampo anular(String id) =>
      CorreccionesCampo(lista: lista, anuladas: {...anuladas, id});

  /// Une las de otro teléfono. Una corrección ya presente no se duplica y una
  /// anulada en cualquiera de los dos queda anulada.
  CorreccionesCampo unir(CorreccionesCampo otras) {
    final porId = {for (final c in lista) c.id: c};
    for (final c in otras.lista) {
      porId.putIfAbsent(c.id, () => c);
    }
    return CorreccionesCampo(
      lista: _ordenar(porId.values.toList()),
      anuladas: {...anuladas, ...otras.anuladas},
    );
  }

  static List<Correccion> _ordenar(List<Correccion> l) =>
      l..sort((a, b) => a.fecha.compareTo(b.fecha));

  Map<String, dynamic> toJson() => {
    'formato': formato,
    'generado': DateTime.now().toIso8601String(),
    'correcciones': [for (final c in lista) c.toJson()],
    'anuladas': anuladas.toList()..sort(),
  };

  String exportar() => const JsonEncoder.withIndent(' ').convert(toJson());

  /// Lee el texto copiado de otro teléfono. Acepta el JSON con texto
  /// alrededor (un mensaje de WhatsApp, por ejemplo).
  static CorreccionesCampo? importar(String texto) {
    final inicio = texto.indexOf('{'), fin = texto.lastIndexOf('}');
    if (inicio < 0 || fin <= inicio) return null;
    try {
      final j = jsonDecode(texto.substring(inicio, fin + 1));
      if (j is! Map<String, dynamic> || j['formato'] != formato) return null;
      return CorreccionesCampo.fromJson(j);
    } on FormatException {
      return null;
    }
  }

  factory CorreccionesCampo.fromJson(Map<String, dynamic> j) =>
      CorreccionesCampo(
        lista: _ordenar([
          for (final c in (j['correcciones'] as List? ?? const []))
            if (c is Map<String, dynamic>) ?Correccion.fromJson(c),
        ]),
        anuladas: {
          for (final a in (j['anuladas'] as List? ?? const [])) a as String,
        },
      );

  /// El grafo con las correcciones aplicadas, en orden. Sin correcciones
  /// devuelve [base] tal cual.
  GrafoCampus aplicar(GrafoCampus base) {
    final vigentes = this.vigentes;
    if (vigentes.isEmpty) return base;
    final e = _Edicion(base);
    for (final c in vigentes) {
      switch (c) {
        case CorreccionEntrada():
          e.moverEntrada(c);
        case CorreccionTramo():
          e.cambiarTramo(c);
        case CorreccionCamino():
          e.agregarCamino(c);
        case CorreccionBrujula() ||
            CorreccionMagnetico() ||
            CorreccionRadio() ||
            CorreccionPrueba() ||
            CorreccionNota():
          break;
      }
    }
    return e.grafo(
      version: '${base.version}+campo${vigentes.length}',
      ajusteBrujula: ajusteBrujula,
      magnetico: magnetico,
    );
  }
}

/// Copia editable del grafo.
class _Edicion {
  _Edicion(GrafoCampus base)
    : _base = base,
      nodos = {...base.nodos},
      tramos = [...base.tramos],
      accesos = [...base.accesos];

  final GrafoCampus _base;
  final Map<String, PuntoGeo> nodos;
  final List<TramoCampus> tramos;
  final List<AccesoLugar> accesos;
  var _siguiente = 0;

  String _nuevoNodo(PuntoGeo p) {
    String id;
    do {
      id = 'campo${_siguiente++}';
    } while (nodos.containsKey(id));
    nodos[id] = p;
    return id;
  }

  TramoCampus _tramo(
    String a,
    String b, {
    required TipoTramo tipo,
    bool escalones = false,
    bool techado = false,
  }) => TramoCampus(
    a: a,
    b: b,
    metros: distanciaMetros(nodos[a]!, nodos[b]!),
    tipo: tipo,
    escalones: escalones,
    techado: techado,
  );

  /// Nodo del grafo en el punto de camino más cercano a [p], partiendo el
  /// tramo si hace falta. Nulo si no hay camino a [maximo] metros.
  String? enganchar(PuntoGeo p, {double maximo = double.infinity}) {
    TramoCampus? mejor;
    var proyeccion = (punto: p, fraccion: 0.0, metros: double.infinity);
    for (final t in tramos) {
      // A la puerta de otro lugar no se engancha nada.
      if (t.tipo == TipoTramo.acceso) continue;
      final q = proyectarEnTramo(p, nodos[t.a]!, nodos[t.b]!);
      if (q.metros < proyeccion.metros) {
        proyeccion = q;
        mejor = t;
      }
    }
    if (mejor == null || proyeccion.metros > maximo) return null;
    final a = nodos[mejor.a]!, b = nodos[mejor.b]!;
    if (distanciaMetros(proyeccion.punto, a) < 1) return mejor.a;
    if (distanciaMetros(proyeccion.punto, b) < 1) return mejor.b;
    final medio = _nuevoNodo(proyeccion.punto);
    tramos
      ..remove(mejor)
      ..add(
        _tramo(
          mejor.a,
          medio,
          tipo: mejor.tipo,
          escalones: mejor.escalones,
          techado: mejor.techado,
        ),
      )
      ..add(
        _tramo(
          medio,
          mejor.b,
          tipo: mejor.tipo,
          escalones: mejor.escalones,
          techado: mejor.techado,
        ),
      );
    return medio;
  }

  void moverEntrada(CorreccionEntrada c) {
    final junto = enganchar(c.punto);
    if (junto == null) return;
    var puerta = junto;
    if (distanciaMetros(nodos[junto]!, c.punto) > 0.5) {
      puerta = _nuevoNodo(c.punto);
      tramos.add(_tramo(junto, puerta, tipo: TipoTramo.acceso));
    }
    final i = accesos.indexWhere(
      (a) => a.poiId == c.poiId && a.nombre == c.nombre,
    );
    final anterior = i < 0 ? null : accesos[i];
    final nuevo = AccesoLugar(
      poiId: c.poiId,
      nombre: c.nombre,
      punto: c.punto,
      nodo: puerta,
      principal: anterior?.principal ?? !accesos.any((a) => a.poiId == c.poiId),
      verificado: true,
    );
    if (i < 0) {
      accesos.add(nuevo);
    } else {
      accesos[i] = nuevo;
    }
  }

  /// Los tramos que caen sobre el segmento corregido, aunque otra corrección
  /// los haya partido después.
  void cambiarTramo(CorreccionTramo c) {
    const tolerancia = CorreccionesCampo.toleranciaTramo;
    for (var i = tramos.length - 1; i >= 0; i--) {
      final t = tramos[i];
      final a = nodos[t.a]!, b = nodos[t.b]!;
      if (proyectarEnTramo(a, c.desde, c.hasta).metros > tolerancia ||
          proyectarEnTramo(b, c.desde, c.hasta).metros > tolerancia) {
        continue;
      }
      if (c.bloqueado == true) {
        tramos.removeAt(i);
        continue;
      }
      final escalones = c.escalones ?? t.escalones;
      tramos[i] = TramoCampus(
        a: t.a,
        b: t.b,
        metros: t.metros,
        tipo: c.escalones == null
            ? t.tipo
            : escalones
            ? TipoTramo.escalera
            : (t.tipo == TipoTramo.escalera ? TipoTramo.sendero : t.tipo),
        escalones: escalones,
        techado: t.techado,
      );
    }
  }

  void agregarCamino(CorreccionCamino c) {
    if (c.puntos.length < 2) return;
    // Las puntas se unen al camino más cercano antes de agregar el nuevo:
    // después, lo más cercano a cada punta era el propio camino y quedaba
    // suelto, sin que ninguna ruta lo usara.
    final juntos = [
      for (final p in [c.puntos.first, c.puntos.last])
        enganchar(p, maximo: CorreccionesCampo.radioEnganche),
    ];
    final ids = [for (final p in c.puntos) _nuevoNodo(p)];
    final tipo = c.escalones ? TipoTramo.escalera : TipoTramo.sendero;
    for (var i = 0; i < ids.length - 1; i++) {
      tramos.add(
        _tramo(ids[i], ids[i + 1], tipo: tipo, escalones: c.escalones),
      );
    }
    for (final (punta, junto) in [
      (ids.first, juntos[0]),
      (ids.last, juntos[1]),
    ]) {
      if (junto != null) {
        tramos.add(_tramo(punta, junto, tipo: TipoTramo.sendero));
      }
    }
  }

  GrafoCampus grafo({
    required String version,
    required double ajusteBrujula,
    CorreccionMagnetico? magnetico,
  }) => GrafoCampus(
    version: version,
    declinacion: _base.declinacion + ajusteBrujula,
    // Sin tolerancia, el rango mundial: se olvida el campo del lugar.
    campoMagnetico: magnetico != null && magnetico.tolerancia == null
        ? null
        : _base.campoMagnetico,
    toleranciaCampo: magnetico?.tolerancia ?? _base.toleranciaCampo,
    nodos: nodos,
    tramos: tramos,
    accesos: accesos,
  );
}

/// Ajuste de brújula entre -180° y 180°.
double normalizarAjuste(double grados) {
  final g = normalizarGrados(grados);
  return g > 180 ? g - 360 : g;
}

/// Quita del camino grabado los puntos que se apartan menos de [tolerancia]
/// metros de la recta entre sus vecinos (Douglas-Peucker): queda la forma
/// del camino sin el ruido del GPS.
List<PuntoGeo> simplificarTrazo(List<PuntoGeo> puntos, double tolerancia) {
  if (puntos.length < 3) return [...puntos];
  var lejos = 0.0, indice = 0;
  for (var i = 1; i < puntos.length - 1; i++) {
    final d = proyectarEnTramo(puntos[i], puntos.first, puntos.last).metros;
    if (d > lejos) {
      lejos = d;
      indice = i;
    }
  }
  if (lejos <= tolerancia) return [puntos.first, puntos.last];
  final izquierda = simplificarTrazo(puntos.sublist(0, indice + 1), tolerancia);
  final derecha = simplificarTrazo(puntos.sublist(indice), tolerancia);
  return [...izquierda.sublist(0, izquierda.length - 1), ...derecha];
}

/// Nulo en vez de un nombre vacío.
String? nuevoAutor(String? nombre) {
  final limpio = nombre?.trim();
  return limpio == null || limpio.isEmpty ? null : limpio;
}

/// Un id corto que no choca entre teléfonos.
String nuevoIdCorreccion() {
  final azar = math.Random();
  final sufijo = List.generate(
    6,
    (_) => 'abcdefghijkmnpqrstuvwxyz23456789'[azar.nextInt(32)],
  ).join();
  return '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}-$sufijo';
}

import 'dart:math' as math;

import 'package:tour_virtual/navegacion/geo.dart';
import 'package:tour_virtual/navegacion/grafo_campus.dart';
import 'package:tour_virtual/navegacion/seguimiento.dart';

/// La lógica de la app de levantamiento, aparte de la interfaz para poder
/// probarla sin teléfono. Los criterios son los de la fase 0 del plan
/// (docs/plan-realidad-aumentada.md) y los mismos que aplica
/// `scripts/grafo_campus.py`: si cambian aquí, cambian allá.

typedef Json = Map<String, dynamic>;

/// Una entrada vale si dos medidas de días distintos, cada una con esta
/// precisión o mejor, quedan a [toleranciaEntreDias] o menos entre sí.
const precisionAceptable = 5.0;
const toleranciaEntreDias = 5.0;

/// Lecturas peores no se usan para nada: ni para promediar ni como
/// provisionales.
const precisionProvisional = 15.0;

/// RNF-27: error de orientación de 10° como máximo.
const errorRumboMaximo = 10.0;

/// AD-03: la llegada se da a 10 m.
const radioLlegada = 10.0;

/// Para comprobar la brújula contra un tramo, el tramo tiene que ser largo
/// (en uno corto, unos metros de error del mapa ya son varios grados) y la
/// persona tiene que estar encima.
const largoMinimoTramoBrujula = 20.0;
const distanciaMaximaTramoBrujula = 5.0;

/// Para marcar un tramo, a esta distancia o menos.
const distanciaMaximaMarcaTramo = 15.0;

/// Formato del JSON exportado. El 1 (la herramienta dentro de apps/mobile)
/// solo tenía accesos, nortes y recorridos; se lee igual.
const formatoDatos = 2;
const clavesDatos = [
  'accesos',
  'nortes',
  'tramos',
  'brujula',
  'pruebas',
  'recorridos',
];

/// Los datos guardados, con todas las listas presentes.
Json normalizarDatos(Json? crudo) {
  final datos = <String, dynamic>{...?crudo};
  datos['formato'] = formatoDatos;
  for (final clave in clavesDatos) {
    datos[clave] = <dynamic>[...((datos[clave] as List?) ?? const [])];
  }
  return datos;
}

Json posicionJson(LecturaPosicion l) => {
  'lat': l.punto.lat,
  'lng': l.punto.lng,
  'precision': _redondear(l.precision),
};

/// A un decimal: más no significa nada con el GPS de un teléfono.
double _redondear(double valor) => (valor * 10).round() / 10;

PuntoGeo puntoDe(Json m) =>
    PuntoGeo((m['lat'] as num).toDouble(), (m['lng'] as num).toDouble());

double _precision(Json m) => (m['precision'] as num).toDouble();
String _dia(Json m) => (m['fecha'] as String).substring(0, 10);

// --- Entradas -------------------------------------------------------------

/// Promedio de las lecturas de una medida de 60 s, ponderado por la
/// precisión (las buenas pesan más). Las peores que [descartarSobre] no
/// entran. Nulo si no queda ninguna.
({PuntoGeo punto, double precision, int usadas, int descartadas})?
promedioLecturas(
  List<LecturaPosicion> lecturas, {
  double descartarSobre = precisionProvisional,
}) {
  final usadas = lecturas.where((l) => l.precision <= descartarSobre).toList();
  if (usadas.isEmpty) return null;
  var sLat = 0.0, sLng = 0.0, sPeso = 0.0, sPrec = 0.0;
  for (final l in usadas) {
    final p = math.max(l.precision, 0.5);
    final peso = 1 / (p * p);
    sLat += l.punto.lat * peso;
    sLng += l.punto.lng * peso;
    sPeso += peso;
    sPrec += l.precision;
  }
  return (
    punto: PuntoGeo(sLat / sPeso, sLng / sPeso),
    precision: sPrec / usadas.length,
    usadas: usadas.length,
    descartadas: lecturas.length - usadas.length,
  );
}

enum EstadoAcceso {
  sinMedir,

  /// Hay medidas, pero todas peores que [precisionProvisional].
  sinUtiles,

  /// Hay medidas útiles, pero no pasan el criterio: el grafo las usa con
  /// `verificado: false`.
  sinConfirmar,
  aceptado,
}

class EvaluacionAcceso {
  const EvaluacionAcceso(this.estado, this.motivo, {this.punto});

  final EstadoAcceso estado;
  final String motivo;

  /// El punto que usaría el grafo, si hay medidas útiles.
  final PuntoGeo? punto;
}

/// Promedio ponderado de medidas ya guardadas.
PuntoGeo _promedio(List<Json> medidas) {
  var sLat = 0.0, sLng = 0.0, sPeso = 0.0;
  for (final m in medidas) {
    final p = math.max(_precision(m), 0.5);
    final peso = 1 / (p * p);
    final q = puntoDe(m);
    sLat += q.lat * peso;
    sLng += q.lng * peso;
    sPeso += peso;
  }
  return PuntoGeo(sLat / sPeso, sLng / sPeso);
}

/// Si las medidas de una entrada pasan el criterio de la fase 0. Es la regla
/// de `evaluar_acceso` en `scripts/grafo_campus.py`.
EvaluacionAcceso evaluarAcceso(List<Json> medidas) {
  if (medidas.isEmpty) {
    return const EvaluacionAcceso(EstadoAcceso.sinMedir, 'sin medir');
  }
  final buenas = medidas
      .where((m) => _precision(m) <= precisionAceptable)
      .toList();
  ({double metros, Json a, Json b})? par;
  for (var i = 0; i < buenas.length; i++) {
    for (var j = i + 1; j < buenas.length; j++) {
      final a = buenas[i], b = buenas[j];
      if (_dia(a) == _dia(b)) continue;
      final d = distanciaMetros(puntoDe(a), puntoDe(b));
      if (par == null || d < par.metros) par = (metros: d, a: a, b: b);
    }
  }
  final dias = buenas.map(_dia).toSet().length;
  if (par != null && par.metros <= toleranciaEntreDias) {
    final pa = puntoDe(par.a), pb = puntoDe(par.b);
    final centro = PuntoGeo((pa.lat + pb.lat) / 2, (pa.lng + pb.lng) / 2);
    final grupo = buenas
        .where(
          (m) => distanciaMetros(centro, puntoDe(m)) <= toleranciaEntreDias,
        )
        .toList();
    return EvaluacionAcceso(
      EstadoAcceso.aceptado,
      '${grupo.length} medidas en $dias días, a '
      '${par.metros.toStringAsFixed(1)} m',
      punto: _promedio(grupo),
    );
  }
  final String motivo;
  if (par != null) {
    motivo =
        'las medidas de días distintos quedan a '
        '${par.metros.toStringAsFixed(1)} m (máx. 5): medir otra vez';
  } else if (buenas.isNotEmpty) {
    motivo = 'falta una medida en otro día';
  } else {
    final mejor = medidas.map(_precision).reduce(math.min);
    motivo =
        'ninguna medida con precisión de 5 m o mejor (la mejor: '
        '±${mejor.toStringAsFixed(1)} m)';
  }
  final usables = buenas.isNotEmpty
      ? buenas
      : medidas.where((m) => _precision(m) <= precisionProvisional).toList();
  if (usables.isEmpty) return EvaluacionAcceso(EstadoAcceso.sinUtiles, motivo);
  return EvaluacionAcceso(
    EstadoAcceso.sinConfirmar,
    motivo,
    punto: _promedio(usables),
  );
}

/// Medidas de una entrada (por lugar y nombre, como las junta el script).
List<Json> medidasDe(Json datos, int poiId, String nombre) => [
  for (final m in (datos['accesos'] as List).cast<Json>())
    if (m['poi_id'] == poiId && m['nombre'] == nombre) m,
];

// --- Brújula --------------------------------------------------------------

/// Media de ángulos: promediar 359° y 1° tiene que dar 0°, no 180°.
double mediaCircular(Iterable<double> grados) {
  var x = 0.0, y = 0.0;
  for (final g in grados) {
    x += math.cos(g * math.pi / 180);
    y += math.sin(g * math.pi / 180);
  }
  return normalizarGrados(math.atan2(y, x) * 180 / math.pi);
}

/// Error de la brújula al apuntar a lo largo de un tramo de rumbo
/// [rumboTramo] (de a hacia b): se compara con el sentido más cercano, porque
/// se puede apuntar hacia cualquiera de los dos extremos. Positivo si la
/// brújula marca a la derecha del camino.
double errorBrujula(double rumboTramo, double rumboBrujula) {
  final ida = diferenciaAngular(rumboTramo, rumboBrujula);
  final vuelta = diferenciaAngular(
    normalizarGrados(rumboTramo + 180),
    rumboBrujula,
  );
  return ida.abs() <= vuelta.abs() ? ida : vuelta;
}

class ResumenBrujula {
  const ResumenBrujula({
    required this.comprobaciones,
    required this.sesgo,
    required this.p95,
    required this.maximo,
  });

  final int comprobaciones;

  /// Error medio: lo que hay que corregir en la declinación.
  final double sesgo;

  /// Percentil 95 y máximo del error una vez corregido el sesgo.
  final double p95;
  final double maximo;

  bool get cumple => comprobaciones >= 8 && p95 <= errorRumboMaximo;
}

/// Las comprobaciones viejas conservan el magnético crudo: después de
/// corregir la declinación hay que reevaluarlas con el nuevo valor.
List<double> erroresDeBrujula(Iterable<Json> medidas, double declinacion) => [
  for (final m in medidas)
    if (m['rumbo_tramo'] is num && m['rumbo_magnetico'] is num)
      errorBrujula(
        (m['rumbo_tramo'] as num).toDouble(),
        normalizarGrados(
          (m['rumbo_magnetico'] as num).toDouble() + declinacion,
        ),
      )
    else
      (m['error'] as num).toDouble() +
          declinacion -
          (m['declinacion'] as num? ?? declinacion),
];

/// Igual que el informe de `scripts/grafo_campus.py`. Nulo con menos de dos.
ResumenBrujula? resumirBrujula(List<double> errores) {
  if (errores.length < 2) return null;
  final sesgo = errores.reduce((a, b) => a + b) / errores.length;
  final residuos = errores.map((e) => (e - sesgo).abs()).toList()..sort();
  final i = math.min(residuos.length - 1, (0.95 * residuos.length).ceil() - 1);
  return ResumenBrujula(
    comprobaciones: errores.length,
    sesgo: sesgo,
    p95: residuos[i],
    maximo: residuos.last,
  );
}

// --- Tramos ---------------------------------------------------------------

/// El tramo del grafo más cercano a una posición.
class TramoCercano {
  const TramoCercano({
    required this.tramo,
    required this.punto,
    required this.metros,
    required this.rumbo,
  });

  final TramoCampus tramo;

  /// El punto del tramo más cercano a la posición.
  final PuntoGeo punto;

  /// Distancia de la posición al tramo.
  final double metros;

  /// Rumbo del tramo, de su nodo a hacia su nodo b.
  final double rumbo;
}

TramoCercano? tramoCercano(GrafoCampus grafo, PuntoGeo posicion) {
  TramoCercano? mejor;
  for (final t in grafo.tramos) {
    final a = grafo.nodos[t.a], b = grafo.nodos[t.b];
    if (a == null || b == null) continue;
    final p = proyectarEnTramo(posicion, a, b);
    if (mejor == null || p.metros < mejor.metros) {
      mejor = TramoCercano(
        tramo: t,
        punto: p.punto,
        metros: p.metros,
        rumbo: rumboGrados(a, b),
      );
    }
  }
  return mejor;
}

/// La última marca guardada para un tramo, si la hay.
Json? marcaDe(Json datos, TramoCampus tramo) => (datos['tramos'] as List)
    .cast<Json>()
    .where((m) => m['a'] == tramo.a && m['b'] == tramo.b)
    .lastOrNull;

// --- Prueba de la guía ----------------------------------------------------

/// Camina una ruta con la misma lógica que la guía de la app
/// ([GrafoCampus.ruta] y [SeguimientoRuta]) y anota lo que pasa: cada punto
/// alcanzado, cada indicación, cada desvío y recálculo, cuándo la app da por
/// llegada y dónde está de verdad la puerta. Con eso se mide si el radio de
/// 10 m (AD-03), los giros y el recálculo funcionan en el campus.
class RegistroPrueba {
  RegistroPrueba._({
    required this.grafo,
    required this.poiId,
    required this.sinEscaleras,
    required this.inicio,
    required RutaCampus ruta,
    required DateTime Function() reloj,
  }) : _reloj = reloj,
       seguimiento = SeguimientoRuta(ruta),
       metrosRuta = ruta.metros,
       fecha = reloj();

  /// Nulo si no hay ruta desde [desde].
  static RegistroPrueba? iniciar(
    GrafoCampus grafo,
    int poiId,
    LecturaPosicion desde, {
    bool sinEscaleras = false,
    DateTime Function() reloj = DateTime.now,
  }) {
    final ruta = grafo.ruta(desde.punto, poiId, sinEscaleras: sinEscaleras);
    if (ruta == null) return null;
    final registro = RegistroPrueba._(
      grafo: grafo,
      poiId: poiId,
      sinEscaleras: sinEscaleras,
      inicio: desde,
      ruta: ruta,
      reloj: reloj,
    );
    registro._evento('inicio', desde, {
      'metros_ruta': ruta.metros.round(),
      'puntos': ruta.puntos.length,
      'destino': ruta.destino.nombre,
    });
    registro.lectura(desde);
    return registro;
  }

  final GrafoCampus grafo;
  final int poiId;
  final bool sinEscaleras;
  final LecturaPosicion inicio;
  final double metrosRuta;
  final DateTime fecha;
  final DateTime Function() _reloj;

  SeguimientoRuta seguimiento;
  final eventos = <Json>[];
  Json? llegadaApp;
  Json? puertaReal;
  var recalculos = 0;
  var indicacionesMalas = 0;

  EstadoSeguimiento? _ultimoEstado;
  var _ultimoObjetivo = -1;
  Maniobra? _ultimaManiobra;

  bool get terminada => puertaReal != null;
  AccesoLugar get destino => seguimiento.ruta.destino;

  /// La indicación que la app estaría dando ahora.
  Maniobra? get maniobra => seguimiento.proximaManiobra();

  /// Distancia entre donde la app dio la llegada y la puerta real.
  double? get errorLlegada {
    final a = llegadaApp, b = puertaReal;
    if (a == null || b == null) return null;
    return distanciaMetros(puntoDe(a), puntoDe(b));
  }

  /// Pasa si la app detectó la llegada a 10 m o menos de la puerta real y
  /// nadie marcó una indicación equivocada. La llegada requiere precisión
  /// de 10 m o mejor y la referencia en la puerta, de 5 m o mejor.
  bool get paso =>
      (errorLlegada ?? double.infinity) <= radioLlegada &&
      (llegadaApp?['precision'] as num? ?? double.infinity) <= radioLlegada &&
      (puertaReal?['precision'] as num? ?? double.infinity) <=
          precisionAceptable &&
      indicacionesMalas == 0;

  void _evento(String tipo, LecturaPosicion l, [Json extra = const {}]) {
    eventos.add({
      't': _reloj().toIso8601String(),
      'tipo': tipo,
      ...posicionJson(l),
      ...extra,
    });
  }

  /// Una lectura del GPS, igual que la recibe la pantalla de la guía.
  void lectura(LecturaPosicion l) {
    if (terminada) return;
    seguimiento.actualizar(l);
    if (seguimiento.estado == EstadoSeguimiento.fueraDeRuta) {
      recalculos++;
      _evento('fuera_de_ruta', l);
      final nueva = grafo.ruta(l.punto, poiId, sinEscaleras: sinEscaleras);
      if (nueva != null) {
        seguimiento = SeguimientoRuta(nueva)..actualizar(l);
        _ultimoObjetivo = -1;
        _ultimaManiobra = null;
      }
    }
    if (seguimiento.estado != _ultimoEstado) {
      _ultimoEstado = seguimiento.estado;
      _evento('estado', l, {'estado': seguimiento.estado.name});
    }
    if (seguimiento.objetivo != _ultimoObjetivo) {
      _ultimoObjetivo = seguimiento.objetivo;
      _evento('objetivo', l, {
        'objetivo': seguimiento.objetivo,
        'de': seguimiento.ruta.puntos.length,
      });
    }
    if (seguimiento.estado == EstadoSeguimiento.llegada && llegadaApp == null) {
      llegadaApp = posicionJson(l);
      _evento('llegada_app', l, {
        'metros_al_acceso': _redondear(distanciaMetros(l.punto, destino.punto)),
      });
    }
    final m = maniobra;
    if (seguimiento.estado == EstadoSeguimiento.guiando &&
        m != null &&
        m != _ultimaManiobra) {
      _ultimaManiobra = m;
      _evento('indicacion', l, {
        'giro': m.giro.name,
        'metros': m.metros.round(),
        'llegada': m.llegada,
      });
    }
  }

  /// Quien prueba dice que la indicación actual no corresponde con el camino.
  void marcarIndicacionMala(LecturaPosicion l, {String nota = ''}) {
    if (terminada) return;
    indicacionesMalas++;
    final m = maniobra;
    _evento('indicacion_mala', l, {
      if (m != null) 'giro': m.giro.name,
      if (m != null) 'metros': m.metros.round(),
      if (nota.isNotEmpty) 'nota': nota,
    });
  }

  /// Quien prueba llegó a la puerta: termina la prueba.
  void marcarPuerta(LecturaPosicion l) {
    if (terminada) return;
    puertaReal = posicionJson(l);
    _evento('puerta_real', l, {
      'metros_al_acceso': _redondear(distanciaMetros(l.punto, destino.punto)),
    });
  }

  Json toJson() => {
    'poi_id': poiId,
    'destino': destino.nombre,
    'metros_ruta': metrosRuta.round(),
    'sin_escaleras': sinEscaleras,
    'inicio': posicionJson(inicio),
    'eventos': eventos,
    'recalculos': recalculos,
    'indicaciones_malas': indicacionesMalas,
    'llegada_app': llegadaApp,
    'puerta_real': puertaReal,
    'error_llegada_m': switch (errorLlegada) {
      final e? => _redondear(e),
      null => null,
    },
    'paso': paso,
    'fecha': fecha.toIso8601String(),
  };
}

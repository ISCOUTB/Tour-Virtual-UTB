import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'geo.dart';
import 'grafo_campus.dart';

/// Una lectura del GPS.
@immutable
class LecturaPosicion {
  const LecturaPosicion({
    required this.punto,
    required this.precision,
    this.rumbo,
    this.velocidad,
    this.momento,
  });

  final PuntoGeo punto;

  /// Radio de confianza, en metros (68 %).
  final double precision;

  /// Rumbo de desplazamiento según el GPS, si se está moviendo.
  final double? rumbo;

  /// m/s.
  final double? velocidad;

  /// Cuándo se tomó. Nulo si la fuente no lo dice (se toma como reciente).
  final DateTime? momento;
}

/// Qué hacer con una lectura antes de guiar con ella.
enum UsoLectura {
  /// Reciente y precisa: sirve para calcular la ruta y seguirla.
  guiar,

  /// Llega, pero con un radio de confianza mayor que
  /// [SeguimientoRuta.precisionMaxima]: prueba que hay señal, nada más.
  debil,

  /// Tomada hace más de [antiguedadMaxima]: como si no hubiera llegado.
  vieja,
}

/// Una lectura más vieja que esto no se usa. Al abrir el GPS, Android puede
/// entregar primero la última posición conocida, que puede ser de la casa: con
/// ella la guía calculaba la ruta desde allá y se rendía «fuera del campus».
/// El filtro viene de MAPSUTB (su ADR 0017).
const antiguedadMaxima = Duration(seconds: 10);

UsoLectura usoDeLectura(
  LecturaPosicion lectura,
  DateTime ahora, {
  double precisionMaxima = SeguimientoRuta.precisionPorDefecto,
}) {
  final momento = lectura.momento;
  if (momento != null && ahora.difference(momento) > antiguedadMaxima) {
    return UsoLectura.vieja;
  }
  if (lectura.precision > precisionMaxima) return UsoLectura.debil;
  return UsoLectura.guiar;
}

/// Si una lectura dice con certeza que se está fuera del campus: lejos del
/// camino más cercano aun suponiendo el peor error del GPS. Una lectura de
/// ±500 m nunca lo decide.
bool fueraDelCampusCon(LecturaPosicion lectura, GrafoCampus grafo) =>
    grafo.distanciaAlCamino(lectura.punto) - lectura.precision >
    GrafoCampus.distanciaMaximaEntrada;

/// Qué hacer en la próxima maniobra.
enum Giro { recto, ligeraDerecha, derecha, ligeraIzquierda, izquierda, vuelta }

/// La próxima maniobra y a cuántos metros está. Si [llegada], la maniobra es
/// llegar al destino.
@immutable
class Maniobra {
  const Maniobra({
    required this.giro,
    required this.metros,
    this.llegada = false,
  });

  final Giro giro;
  final double metros;
  final bool llegada;

  @override
  bool operator ==(Object other) =>
      other is Maniobra &&
      other.giro == giro &&
      other.llegada == llegada &&
      // Para anunciar de nuevo no basta un metro de diferencia.
      (other.metros / 10).round() == (metros / 10).round();

  @override
  int get hashCode => Object.hash(giro, llegada, (metros / 10).round());
}

enum EstadoSeguimiento {
  /// Aún no hay lectura útil.
  buscandoSenal,

  /// Hay lecturas, pero con precisión peor que [SeguimientoRuta.precisionMaxima].
  senalDebil,
  guiando,

  /// Se alejó de la ruta: hay que calcular otra desde donde está.
  fueraDeRuta,
  llegada,
}

/// Sigue una ruta con las lecturas del GPS (RF-29 a RF-31).
///
/// Un punto de la ruta se da por alcanzado a [radio] metros (10 por AD-03),
/// pero solo si la lectura es igual o más precisa que el radio, o si dos
/// lecturas seguidas lo confirman: el ruido del GPS, sobre todo junto a
/// edificios, daba llegadas falsas.
class SeguimientoRuta {
  SeguimientoRuta(
    this.ruta, {
    this.radio = radioPorDefecto,
    this.radioDesvio = 25,
    this.precisionMaxima = precisionPorDefecto,
  }) : assert(ruta.puntos.isNotEmpty);

  /// AD-03. En el modo campo se puede cambiar para probar.
  static const radioPorDefecto = 10.0;

  /// Lecturas con un radio de confianza mayor no guían.
  static const precisionPorDefecto = 50.0;

  final RutaCampus ruta;
  final double radio;

  /// Más allá de esta distancia de la ruta (más la precisión), está fuera.
  final double radioDesvio;

  /// Lecturas con un radio de confianza mayor no se usan para guiar.
  final double precisionMaxima;

  List<PuntoGeo> get _puntos => ruta.puntos;

  /// Índice del próximo punto por alcanzar.
  int objetivo = 0;
  EstadoSeguimiento estado = EstadoSeguimiento.buscandoSenal;
  LecturaPosicion? ultima;
  var _confirmaciones = 0;
  var _lecturasFuera = 0;

  PuntoGeo get puntoObjetivo => _puntos[math.min(objetivo, _puntos.length - 1)];

  /// Metros hasta la puerta, siguiendo la ruta.
  double get metrosRestantes {
    final l = ultima;
    if (l == null) return ruta.metros;
    if (objetivo >= _puntos.length) return 0;
    var total = distanciaMetros(l.punto, _puntos[objetivo]);
    for (var i = objetivo; i < _puntos.length - 1; i++) {
      total += distanciaMetros(_puntos[i], _puntos[i + 1]);
    }
    return total;
  }

  /// Rumbo geográfico hacia el próximo punto, desde la última posición.
  double? get rumboAlObjetivo {
    final l = ultima;
    if (l == null || estado == EstadoSeguimiento.llegada) return null;
    return rumboGrados(l.punto, puntoObjetivo);
  }

  /// Cuánto adelante de la persona, sobre la ruta, mira la flecha.
  static const metrosDeMira = 15.0;

  /// A esta distancia de la ruta o menos (el error típico del GPS junto a los
  /// edificios), se da por hecho que la persona va sobre ella.
  static const metrosSobreLaRuta = 4.0;

  /// La posición promediada con las anteriores. Solo la usa la flecha: la
  /// llegada y el avance siguen con la lectura cruda.
  PuntoGeo? suavizada;

  /// Rumbo para la flecha: hacia un punto [metrosDeMira] adelante sobre la
  /// ruta.
  ///
  /// [rumboAlObjetivo] apunta al próximo vértice desde la última lectura: con
  /// el vértice a 10-20 m, un salto del GPS de 5 m movía la flecha 15-30° cada
  /// dos segundos (la «flecha temblorosa» de la prueba en el campus). Aquí, si
  /// la persona está a [metrosSobreLaRuta] o menos de la ruta, la flecha sale
  /// de su proyección sobre la ruta: el ruido lateral del GPS no la mueve. Si
  /// se aleja más, sale de la posición (suavizada) y la devuelve al camino.
  double? get rumboGuia {
    final p = suavizada;
    if (p == null || estado == EstadoSeguimiento.llegada) return null;
    final (sobre, alejamiento) = _proyeccion(p);
    final desde = alejamiento <= metrosSobreLaRuta ? sobre.punto : p;
    final mira = _avanzar(sobre.indice, sobre.punto, metrosDeMira);
    if (distanciaMetros(desde, mira) < 2) return rumboAlObjetivo;
    return rumboGrados(desde, mira);
  }

  /// El punto de la ruta [metrosDeMira] más allá de la proyección de [p] en lo
  /// que falta de ruta (o la puerta, si queda menos).
  PuntoGeo puntoDeMira(PuntoGeo p) {
    final (sobre, _) = _proyeccion(p);
    return _avanzar(sobre.indice, sobre.punto, metrosDeMira);
  }

  /// El punto de lo que falta de ruta más cercano a [p], el tramo en que cae y
  /// a cuántos metros de [p] está.
  (({int indice, PuntoGeo punto}), double) _proyeccion(PuntoGeo p) {
    final desde = math.max(0, objetivo - 1);
    if (desde >= _puntos.length - 1) {
      return (
        (indice: _puntos.length - 1, punto: _puntos.last),
        distanciaMetros(p, _puntos.last),
      );
    }
    var mejor = (indice: desde, punto: _puntos[desde], metros: double.infinity);
    for (var i = desde; i < _puntos.length - 1; i++) {
      final q = proyectarEnTramo(p, _puntos[i], _puntos[i + 1]);
      if (q.metros < mejor.metros) {
        mejor = (indice: i, punto: q.punto, metros: q.metros);
      }
    }
    return ((indice: mejor.indice, punto: mejor.punto), mejor.metros);
  }

  /// El punto [metros] más adelante sobre la ruta, partiendo de [punto] en el
  /// tramo [indice].
  PuntoGeo _avanzar(int indice, PuntoGeo punto, double metros) {
    var resto = metros;
    var desdePunto = punto;
    for (var i = indice; i < _puntos.length - 1; i++) {
      final hasta = _puntos[i + 1];
      final tramo = distanciaMetros(desdePunto, hasta);
      if (tramo >= resto && tramo > 0) {
        final t = resto / tramo;
        return PuntoGeo(
          desdePunto.lat + t * (hasta.lat - desdePunto.lat),
          desdePunto.lng + t * (hasta.lng - desdePunto.lng),
        );
      }
      resto -= tramo;
      desdePunto = hasta;
    }
    return _puntos.last;
  }

  void _suavizar(LecturaPosicion lectura) {
    final antes = suavizada;
    // Un salto grande es un cambio real (o un recálculo): no se arrastra.
    if (antes == null || distanciaMetros(antes, lectura.punto) > 25) {
      suavizada = lectura.punto;
      return;
    }
    // Media móvil que pesa más las lecturas precisas.
    final peso = lectura.precision <= 8 ? 0.5 : 0.3;
    suavizada = PuntoGeo(
      antes.lat + peso * (lectura.punto.lat - antes.lat),
      antes.lng + peso * (lectura.punto.lng - antes.lng),
    );
  }

  void actualizar(LecturaPosicion lectura) {
    if (estado == EstadoSeguimiento.llegada) return;
    ultima = lectura;
    if (lectura.precision > precisionMaxima) {
      estado = EstadoSeguimiento.senalDebil;
      return;
    }
    _suavizar(lectura);

    // Salta los puntos que ya quedaron atrás: si va sobre el tramo siguiente
    // (pasado su comienzo y cerca de él), el objetivo es el final de ese
    // tramo. Sin esto, quien arrancaba unos metros adelante era mandado a
    // darse la vuelta. El último punto, la puerta, no se salta: exige llegar.
    while (objetivo < _puntos.length - 1) {
      final p = proyectarEnTramo(
        lectura.punto,
        _puntos[objetivo],
        _puntos[objetivo + 1],
      );
      if (p.fraccion <= 0 || p.metros > radioDesvio) break;
      objetivo++;
    }

    // Avanza todos los puntos que ya quedaron dentro del radio.
    while (objetivo < _puntos.length) {
      final d = distanciaMetros(lectura.punto, _puntos[objetivo]);
      if (d > radio) {
        _confirmaciones = 0;
        break;
      }
      final segura = lectura.precision <= radio;
      if (!segura) {
        _confirmaciones++;
        if (_confirmaciones < 2) break;
      }
      _confirmaciones = 0;
      objetivo++;
    }
    if (objetivo >= _puntos.length) {
      estado = EstadoSeguimiento.llegada;
      return;
    }

    // Desvío: distancia al resto de la ruta, dos lecturas seguidas.
    final desvio = _distanciaARuta(lectura.punto);
    if (desvio > radioDesvio + lectura.precision) {
      _lecturasFuera++;
      if (_lecturasFuera >= 2) {
        estado = EstadoSeguimiento.fueraDeRuta;
        return;
      }
    } else {
      _lecturasFuera = 0;
    }
    estado = EstadoSeguimiento.guiando;
  }

  double _distanciaARuta(PuntoGeo p) {
    final desde = math.max(0, objetivo - 1);
    var minimo = distanciaMetros(p, _puntos[desde]);
    for (var i = desde; i < _puntos.length - 1; i++) {
      minimo = math.min(
        minimo,
        proyectarEnTramo(p, _puntos[i], _puntos[i + 1]).metros,
      );
    }
    return minimo;
  }

  /// La próxima maniobra: el primer giro de verdad (30° o más) o la llegada.
  /// Los vértices de un camino curvo no se anuncian uno por uno.
  Maniobra? proximaManiobra() {
    final l = ultima;
    if (l == null) return null;
    if (estado == EstadoSeguimiento.llegada) {
      return const Maniobra(giro: Giro.recto, metros: 0, llegada: true);
    }
    var metros = distanciaMetros(l.punto, _puntos[objetivo]);
    var entrada = rumboGrados(l.punto, _puntos[objetivo]);
    for (var i = objetivo; i < _puntos.length - 1; i++) {
      final salida = rumboGrados(_puntos[i], _puntos[i + 1]);
      final giro = diferenciaAngular(entrada, salida);
      if (giro.abs() >= 30) {
        return Maniobra(giro: clasificarGiro(giro), metros: metros);
      }
      metros += distanciaMetros(_puntos[i], _puntos[i + 1]);
      entrada = salida;
    }
    return Maniobra(giro: Giro.recto, metros: metros, llegada: true);
  }

  static Giro clasificarGiro(double giro) {
    final a = giro.abs();
    if (a >= 150) return Giro.vuelta;
    if (a >= 60) return giro > 0 ? Giro.derecha : Giro.izquierda;
    return giro > 0 ? Giro.ligeraDerecha : Giro.ligeraIzquierda;
  }
}

/// Las indicaciones de una ruta completa, de la salida a la puerta: para verla
/// antes de caminar o sin GPS. Con la regla de [SeguimientoRuta]: solo se
/// anuncia un giro de 30° o más, y el último paso es la llegada.
List<Maniobra> pasosDeRuta(List<PuntoGeo> puntos) {
  if (puntos.length < 2) {
    return const [Maniobra(giro: Giro.recto, metros: 0, llegada: true)];
  }
  final pasos = <Maniobra>[];
  var metros = distanciaMetros(puntos[0], puntos[1]);
  var entrada = rumboGrados(puntos[0], puntos[1]);
  for (var i = 1; i < puntos.length - 1; i++) {
    final tramo = distanciaMetros(puntos[i], puntos[i + 1]);
    if (tramo < 0.5) continue;
    final salida = rumboGrados(puntos[i], puntos[i + 1]);
    final giro = diferenciaAngular(entrada, salida);
    if (giro.abs() >= 30) {
      pasos.add(
        Maniobra(giro: SeguimientoRuta.clasificarGiro(giro), metros: metros),
      );
      metros = 0;
    }
    metros += tramo;
    entrada = salida;
  }
  pasos.add(Maniobra(giro: Giro.recto, metros: metros, llegada: true));
  return pasos;
}

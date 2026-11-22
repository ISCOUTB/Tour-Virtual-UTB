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
  });

  final PuntoGeo punto;

  /// Radio de confianza, en metros (68 %).
  final double precision;

  /// Rumbo de desplazamiento según el GPS, si se está moviendo.
  final double? rumbo;

  /// m/s.
  final double? velocidad;
}

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
    this.precisionMaxima = 50,
  }) : assert(ruta.puntos.isNotEmpty);

  /// AD-03. En el modo campo se puede cambiar para probar.
  static const radioPorDefecto = 10.0;

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

  void actualizar(LecturaPosicion lectura) {
    if (estado == EstadoSeguimiento.llegada) return;
    ultima = lectura;
    if (lectura.precision > precisionMaxima) {
      estado = EstadoSeguimiento.senalDebil;
      return;
    }

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
        return Maniobra(giro: _clasificar(giro), metros: metros);
      }
      metros += distanciaMetros(_puntos[i], _puntos[i + 1]);
      entrada = salida;
    }
    return Maniobra(giro: Giro.recto, metros: metros, llegada: true);
  }

  static Giro _clasificar(double giro) {
    final a = giro.abs();
    if (a >= 150) return Giro.vuelta;
    if (a >= 60) return giro > 0 ? Giro.derecha : Giro.izquierda;
    return giro > 0 ? Giro.ligeraDerecha : Giro.ligeraIzquierda;
  }
}

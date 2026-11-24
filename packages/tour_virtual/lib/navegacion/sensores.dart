import 'dart:async';
import 'dart:math' as math;

import 'package:dchs_motion_sensors/dchs_motion_sensors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'geo.dart';
import 'modo_campo.dart';
import 'seguimiento.dart';

/// Si el dispositivo tiene GPS y brújula de verdad. En escritorio y en web no:
/// allí la guía usa una posición simulada, igual que el visor 360 apaga el
/// giroscopio fuera del teléfono.
bool get haySensoresDeNavegacion =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

enum PermisoUbicacion {
  concedido,
  denegado,

  /// Denegado para siempre: solo se cambia en los ajustes del sistema.
  denegadoSiempre,

  /// La ubicación del teléfono está apagada.
  servicioApagado,
}

/// De dónde sale la posición. La posición vive solo en memoria: nunca se
/// guarda ni se envía (RN-10).
abstract class FuenteUbicacion {
  bool get simulada;
  Future<PermisoUbicacion> pedirPermiso();
  Stream<LecturaPosicion> lecturas();

  /// Ajustes del sistema, para quien negó el permiso para siempre.
  Future<void> abrirAjustes() async {}
}

class UbicacionGps extends FuenteUbicacion {
  @override
  bool get simulada => false;

  @override
  Future<PermisoUbicacion> pedirPermiso() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return PermisoUbicacion.servicioApagado;
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    return switch (permiso) {
      LocationPermission.whileInUse ||
      LocationPermission.always => PermisoUbicacion.concedido,
      LocationPermission.deniedForever => PermisoUbicacion.denegadoSiempre,
      _ => PermisoUbicacion.denegado,
    };
  }

  @override
  Stream<LecturaPosicion> lecturas() {
    // Cada 2 s (AD-03): más seguido no mejora la precisión y gasta batería.
    final ajustes = defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 0,
            intervalDuration: const Duration(seconds: 2),
          )
        : const LocationSettings(accuracy: LocationAccuracy.best);
    return Geolocator.getPositionStream(locationSettings: ajustes).map(
      (p) => LecturaPosicion(
        punto: PuntoGeo(p.latitude, p.longitude),
        precision: p.accuracy,
        rumbo: p.speed > 0.6 && p.heading >= 0 ? p.heading : null,
        velocidad: p.speed,
        momento: p.timestamp,
      ),
    );
  }

  @override
  Future<void> abrirAjustes() async {
    try {
      await Geolocator.openAppSettings();
    } catch (error) {
      debugPrint('No se pudieron abrir los ajustes: $error');
    }
  }
}

/// Camina sola por la ruta que se le dé, a paso de persona, con un poco de
/// ruido. Es la posición del escritorio y de las pruebas.
class UbicacionSimulada extends FuenteUbicacion {
  UbicacionSimulada({
    this.inicio = puntoDePartida,
    this.velocidad = 1.4,
    this.intervalo = const Duration(seconds: 1),
    this.precision = 5,
  });

  /// La portería junto a la glorieta, en la entrada del campus.
  static const puntoDePartida = PuntoGeo(10.37075, -75.46598);

  final PuntoGeo inicio;
  final double velocidad;
  final Duration intervalo;
  final double precision;

  List<PuntoGeo> _camino = const [];

  /// Sigue [puntos] desde [desde] (o desde [inicio]). Tras un recálculo
  /// continúa desde donde iba en vez de volver a la portería.
  void seguir(List<PuntoGeo> puntos, {PuntoGeo? desde}) {
    _camino = [desde ?? inicio, ...puntos];
    _recorrido = 0;
  }

  double _recorrido = 0;

  @override
  bool get simulada => true;

  @override
  Future<PermisoUbicacion> pedirPermiso() async => PermisoUbicacion.concedido;

  @override
  Stream<LecturaPosicion> lecturas() async* {
    yield LecturaPosicion(
      punto: inicio,
      precision: precision,
      momento: DateTime.now(),
    );
    final azar = math.Random(7);
    while (true) {
      await Future<void>.delayed(intervalo);
      if (_camino.length < 2) {
        yield LecturaPosicion(
          punto: inicio,
          precision: precision,
          momento: DateTime.now(),
        );
        continue;
      }
      _recorrido += velocidad * intervalo.inMilliseconds / 1000;
      final (punto, rumbo) = _enCamino(_recorrido);
      // Ruido de unos metros, como un GPS a cielo abierto.
      final ruido = PuntoGeo(
        punto.lat + (azar.nextDouble() - 0.5) * 0.000018,
        punto.lng + (azar.nextDouble() - 0.5) * 0.000018,
      );
      yield LecturaPosicion(
        punto: ruido,
        precision: precision,
        rumbo: rumbo,
        velocidad: velocidad,
        momento: DateTime.now(),
      );
    }
  }

  (PuntoGeo, double) _enCamino(double metros) {
    var resto = metros;
    for (var i = 0; i < _camino.length - 1; i++) {
      final a = _camino[i], b = _camino[i + 1];
      final tramo = distanciaMetros(a, b);
      if (resto <= tramo || i == _camino.length - 2) {
        final t = tramo == 0 ? 1.0 : (resto / tramo).clamp(0.0, 1.0);
        return (
          PuntoGeo(a.lat + t * (b.lat - a.lat), a.lng + t * (b.lng - a.lng)),
          rumboGrados(a, b),
        );
      }
      resto -= tramo;
    }
    return (_camino.last, 0);
  }
}

/// Hacia dónde mira el teléfono.
@immutable
class LecturaRumbo {
  const LecturaRumbo({
    required this.grados,
    required this.inclinacion,
    this.descalibrada = false,
    this.intensidad,
  });

  /// Rumbo geográfico hacia donde apunta la cámara (o la parte de arriba del
  /// teléfono si está acostado), en grados desde el norte.
  final double grados;

  /// Inclinación de la cámara sobre el horizonte, en grados: 0 mirando al
  /// frente, -90 mirando al suelo.
  final double inclinacion;

  /// El campo magnético medido no es el de la Tierra: hay metal cerca o la
  /// brújula necesita calibrarse (UC-17, flujo 4a).
  final bool descalibrada;

  /// Campo magnético medido, en µT. Lo muestra el modo campo.
  final double? intensidad;
}

abstract class FuenteRumbo {
  bool get simulada;
  Stream<LecturaRumbo> lecturas();
}

/// Hacia dónde mira el teléfono, para la flecha y el cono del plano (RF-29:
/// rumbo al nodo menos rumbo de la brújula).
///
/// La brújula manda mientras esté calibrada: es lo único que sigue al
/// teléfono cuando se gira la cámara. Antes, al caminar mandaba el rumbo del
/// GPS: se actualiza cada 2 s con ±20° de ruido, no sabe hacia dónde apunta
/// la cámara y, al pasar de caminar a parar, la flecha saltaba de una fuente a
/// la otra. Ahora el GPS solo entra si la brújula está interferida (metal
/// cerca) y la persona camina con buena señal; si no, no hay flecha.
double? rumboNavegacion(LecturaPosicion? posicion, LecturaRumbo? brujula) {
  if (brujula != null && !brujula.descalibrada) return brujula.grados;
  final gps = posicion?.rumbo;
  if (gps != null &&
      gps.isFinite &&
      gps >= 0 &&
      (posicion?.velocidad ?? 0) > 0.6 &&
      posicion!.precision <= 20) {
    return normalizarGrados(gps);
  }
  return null;
}

/// Suaviza el rumbo de la brújula con el giroscopio (filtro complementario).
///
/// El giroscopio sigue cada giro del teléfono al instante y sin ruido, pero se
/// desvía con el tiempo; la brújula no se desvía, pero tiembla con cada paso y
/// con cada pulso del acelerómetro. El rumbo gira con el giroscopio y se
/// acerca a la brújula con una constante de [constante] segundos: la flecha ya
/// no tiembla y sigue respondiendo al instante. Sin giroscopio, sigue a la
/// brújula con un paso bajo de [constanteSinGiroscopio] segundos.
class FiltroRumbo {
  FiltroRumbo({this.constante = 1.5, this.constanteSinGiroscopio = 0.45});

  final double constante;
  final double constanteSinGiroscopio;

  double? _rumbo;
  var _conGiroscopio = false;

  double? get rumbo => _rumbo;

  /// Gira el rumbo con la velocidad angular [velocidad] (rad/s, ejes del
  /// teléfono) durante [segundos]. [arriba] es la gravedad medida (apunta
  /// hacia arriba en reposo): solo cuenta el giro alrededor de la vertical.
  void girar(List<double> velocidad, List<double> arriba, double segundos) {
    final r = _rumbo;
    final norma = math.sqrt(
      arriba[0] * arriba[0] + arriba[1] * arriba[1] + arriba[2] * arriba[2],
    );
    if (r == null || norma < 0.1 || segundos <= 0 || segundos > 0.5) return;
    _conGiroscopio = true;
    final vertical =
        (velocidad[0] * arriba[0] +
            velocidad[1] * arriba[1] +
            velocidad[2] * arriba[2]) /
        norma;
    // Un giro positivo alrededor de la vertical es antihorario visto desde
    // arriba: el rumbo, que crece en sentido horario, baja.
    _rumbo = normalizarGrados(r - vertical * segundos * 180 / math.pi);
  }

  /// Acerca el rumbo a la [brujula] según los [segundos] desde la anterior.
  double corregir(double brujula, double segundos) {
    final r = _rumbo;
    final diferencia = r == null ? 0.0 : diferenciaAngular(r, brujula);
    // Al empezar, o tras un salto grande (el teléfono pasó de acostado a
    // vertical), se toma la brújula tal cual en vez de girar despacio.
    if (r == null || diferencia.abs() > 60) return _rumbo = brujula;
    final tau = _conGiroscopio ? constante : constanteSinGiroscopio;
    final k = (segundos / tau).clamp(0.0, 1.0);
    return _rumbo = normalizarGrados(r + k * diferencia);
  }

  void reiniciar() {
    _rumbo = null;
    _conGiroscopio = false;
  }
}

/// Rumbo calculado con el acelerómetro y el magnetómetro.
///
/// Es la misma cuenta que `SensorManager.getRotationMatrix` de Android: con la
/// gravedad y el campo magnético salen el este (H = campo × gravedad) y el
/// norte (M = gravedad × H) en ejes del teléfono. La cámara trasera mira por
/// -Z, así que su rumbo es atan2(-Hz, -Mz). Así sirve igual con el teléfono
/// vertical (modo cámara) que acostado (plano). La «orientación absoluta» del
/// paquete da el rumbo de la parte de arriba del teléfono, que con el teléfono
/// vertical apunta al cielo y se vuelve inestable.
class RumboSensores extends FuenteRumbo {
  RumboSensores({
    this.declinacion = 0,
    this.campoEsperado,
    this.tolerancia = toleranciaCampo,
    this.filtrar = true,
    MotionSensors? sensores,
  }) : _sensores = sensores ?? MotionSensors();

  /// Con falso, el rumbo como se calculaba antes del giroscopio: solo el paso
  /// bajo sobre los vectores. Lo usa la prueba en el teléfono para comparar.
  final bool filtrar;

  /// Declinación magnética (grados, positiva al este): pasa del norte de la
  /// brújula al geográfico.
  final double declinacion;

  /// Campo terrestre del lugar en µT, para detectar metal cerca.
  final double? campoEsperado;

  /// Desviación admitida sobre [campoEsperado] (fracción).
  final double tolerancia;
  final MotionSensors _sensores;

  @override
  bool get simulada => false;

  @override
  Stream<LecturaRumbo> lecturas() {
    // 50 ms (20 Hz): fluido para la flecha sin gastar de más. El giroscopio a
    // 100 Hz: integra mejor los giros rápidos.
    _sensores.accelerometerUpdateInterval = 50000;
    _sensores.magnetometerUpdateInterval = 50000;
    _sensores.gyroscopeUpdateInterval = 10000;
    late StreamController<LecturaRumbo> salida;
    StreamSubscription<AccelerometerEvent>? acel;
    StreamSubscription<MagnetometerEvent>? mag;
    StreamSubscription<GyroscopeEvent>? giro;
    List<double>? g, m;
    final filtro = FiltroRumbo();
    final reloj = Stopwatch()..start();
    var ultimaBrujula = 0, ultimoGiro = 0;

    void calcular() {
      final gv = g, mv = m;
      if (gv == null || mv == null) return;
      final lectura = rumboDesdeSensores(
        gv,
        mv,
        declinacion: declinacion,
        campoEsperado: campoEsperado,
        tolerancia: tolerancia,
      );
      if (lectura == null) return;
      final ahora = reloj.elapsedMicroseconds;
      final grados = filtrar
          ? filtro.corregir(lectura.grados, (ahora - ultimaBrujula) / 1e6)
          : lectura.grados;
      ultimaBrujula = ahora;
      salida.add(
        LecturaRumbo(
          grados: grados,
          inclinacion: lectura.inclinacion,
          descalibrada: lectura.descalibrada,
          intensidad: lectura.intensidad,
        ),
      );
    }

    salida = StreamController<LecturaRumbo>(
      onListen: () {
        // Filtro de paso bajo sobre los vectores, no sobre los ángulos: así
        // no salta al cruzar 0°/360°.
        const a = 0.15;
        acel = _sensores.accelerometer.listen((e) {
          g = g == null
              ? [e.x, e.y, e.z]
              : [
                  g![0] + a * (e.x - g![0]),
                  g![1] + a * (e.y - g![1]),
                  g![2] + a * (e.z - g![2]),
                ];
          calcular();
        }, onError: salida.addError);
        mag = _sensores.magnetometer.listen((e) {
          m = m == null
              ? [e.x, e.y, e.z]
              : [
                  m![0] + a * (e.x - m![0]),
                  m![1] + a * (e.y - m![1]),
                  m![2] + a * (e.z - m![2]),
                ];
        }, onError: salida.addError);
        // Sin giroscopio (algunos teléfonos de gama baja) el filtro sigue a la
        // brújula con un paso bajo: no es un error para la guía.
        giro = _sensores.gyroscope.listen((e) {
          final ahora = reloj.elapsedMicroseconds;
          final arriba = g;
          if (arriba != null && ultimoGiro > 0) {
            filtro.girar([e.x, e.y, e.z], arriba, (ahora - ultimoGiro) / 1e6);
          }
          ultimoGiro = ahora;
        }, onError: (Object error) => debugPrint('Giroscopio: $error'));
      },
      onCancel: () async {
        await acel?.cancel();
        await mag?.cancel();
        await giro?.cancel();
      },
    );
    return salida.stream;
  }
}

/// La cuenta de [RumboSensores], aparte para poder probarla sin sensores.
///
/// [gravedad] y [campo] en ejes del teléfono (x a la derecha, y hacia arriba
/// de la pantalla, z saliendo de la pantalla). Nulo si los vectores no
/// permiten calcularlo (caída libre, sin campo).
LecturaRumbo? rumboDesdeSensores(
  List<double> gravedad,
  List<double> campo, {
  double declinacion = 0,
  double? campoEsperado,
  double tolerancia = toleranciaCampo,
}) {
  final ax = gravedad[0], ay = gravedad[1], az = gravedad[2];
  final ex = campo[0], ey = campo[1], ez = campo[2];
  var hx = ey * az - ez * ay;
  var hy = ez * ax - ex * az;
  var hz = ex * ay - ey * ax;
  final normaH = math.sqrt(hx * hx + hy * hy + hz * hz);
  final normaA = math.sqrt(ax * ax + ay * ay + az * az);
  if (normaH < 0.1 || normaA < 0.1) return null;
  hx /= normaH;
  hy /= normaH;
  hz /= normaH;
  final gx = ax / normaA, gy = ay / normaA, gz = az / normaA;
  final my = gz * hx - gx * hz;
  final mz = gx * hy - gy * hx;

  // Cámara trasera (-Z) si el teléfono está más vertical que acostado; si
  // está acostado, la parte de arriba (+Y), como una brújula de mano.
  final vertical = gz.abs() < 0.7;
  final este = vertical ? -hz : hy;
  final norte = vertical ? -mz : my;
  final magnetico = math.atan2(este, norte) * 180 / math.pi;
  // Elevación de la cámara (-Z): el acelerómetro en reposo apunta hacia
  // arriba, así que su componente vertical es -gz. Acostado boca arriba da
  // -90 (mira al suelo); vertical, 0.
  final inclinacion = math.asin((-gz).clamp(-1.0, 1.0)) * 180 / math.pi;
  final intensidad = math.sqrt(ex * ex + ey * ey + ez * ez);
  return LecturaRumbo(
    grados: normalizarGrados(magnetico + declinacion),
    inclinacion: inclinacion,
    descalibrada: campoAnomalo(intensidad, campoEsperado, tolerancia),
    intensidad: intensidad,
  );
}

/// Si el campo medido no es el de la Tierra en ese lugar: metal cerca o
/// brújula sin calibrar.
///
/// Sin el campo del lugar se usa el rango mundial (25-65 µT, con margen).
/// En Cartagena el campo es de 33 µT: con el rango mundial, una reja que lo
/// llevaba a 60 µT pasaba por bueno y la flecha giraba hacia ella.
bool campoAnomalo(
  double intensidad,
  double? esperado, [
  double tolerancia = toleranciaCampo,
]) {
  if (esperado == null) return intensidad < 20 || intensidad > 75;
  return (intensidad - esperado).abs() > esperado * tolerancia;
}

/// Desviación admitida sobre el campo esperado. Los magnetómetros de los
/// teléfonos calibrados quedan a unos pocos µT del valor real; uno sin
/// calibrar puede pasarse, y en el modo campo se puede ampliar.
const toleranciaCampo = 0.35;

/// Rumbo de escritorio y de pruebas: mira hacia donde camina la posición
/// simulada, o hacia el norte.
class RumboSimulado extends FuenteRumbo {
  RumboSimulado([this.fijo = 0]);

  final double fijo;

  @override
  bool get simulada => true;

  @override
  Stream<LecturaRumbo> lecturas() async* {
    yield LecturaRumbo(grados: fijo, inclinacion: -20);
  }
}

/// En el escritorio, o en un ensayo del modo campo, una posición simulada
/// que camina sola por la ruta. Brújula y cámara siguen siendo las reales.
final fuenteUbicacionProvider = Provider<FuenteUbicacion>(
  (ref) => haySensoresDeNavegacion && !ref.watch(ensayoCampoProvider)
      ? UbicacionGps()
      : UbicacionSimulada(),
);

/// La brújula del grafo: su declinación (con el ajuste de campo, si hay) y
/// el campo magnético del campus.
typedef AjusteBrujula = ({
  double declinacion,
  double? campoEsperado,
  double tolerancia,
});

final fuenteRumboProvider = Provider.family<FuenteRumbo, AjusteBrujula>(
  (ref, ajuste) => haySensoresDeNavegacion
      ? RumboSensores(
          declinacion: ajuste.declinacion,
          campoEsperado: ajuste.campoEsperado,
          tolerancia: ajuste.tolerancia,
        )
      : RumboSimulado(),
);

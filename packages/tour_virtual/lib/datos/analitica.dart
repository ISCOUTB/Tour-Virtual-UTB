import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../configuracion_tour.dart';
import '../nucleo/errores.dart';
import 'preferencias.dart';
import 'proveedores.dart';

// Analítica de uso (RF-23 a RF-25 del SRS v3.1).
//
// Cada evento va a `POST /api/eventos` y alimenta las métricas del panel. Lo
// que se manda es anónimo (RNF-22): un identificador de sesión al azar que
// nace al abrir el módulo y no se guarda en ningún sitio, el tipo de evento y
// los ids de contenido. Nunca el usuario, su ubicación ni datos del teléfono.
//
// La sección 7 de docs/arquitectura.md pide además consentimiento explícito.
// Mientras no lo hay, los eventos esperan en memoria sin salir del teléfono;
// si se acepta se envían, y si se rechaza se descartan.

/// Tipos de evento que acepta la API (`PanelService.TiposEvento`). Son los KPI
/// del documento de MVP.
enum TipoEvento {
  mapaAbierto('virtual_map_open'),
  escenaVista('scene_viewed'),
  hotspotTocado('hotspot_tapped'),
  medioReproducido('poi_media_played'),
  recorridoCompletado('tour_completed');

  const TipoEvento(this.clave);

  /// Nombre del tipo en la API.
  final String clave;
}

@immutable
class EventoAnalitica {
  const EventoAnalitica({
    required this.sesionId,
    required this.tipo,
    this.poiId,
    this.escenaId,
    this.datos = const {},
  });

  final String sesionId;
  final TipoEvento tipo;
  final int? poiId;
  final int? escenaId;

  /// Detalle libre (`payload`). La API rechaza más de 2 KB.
  final Map<String, Object> datos;

  /// Cuerpo de `RegistrarEventoRequest`. Ese DTO no lleva nombres propios, así
  /// que ASP.NET espera camelCase, no el snake_case del contenido.
  Map<String, Object?> toJson() => {
    'sesionId': sesionId,
    'tipo': tipo.clave,
    if (poiId != null) 'poiId': poiId,
    if (escenaId != null) 'escenaId': escenaId,
    if (datos.isNotEmpty) 'payload': datos,
  };

  @override
  String toString() =>
      'EventoAnalitica(${tipo.clave}, poi: $poiId, escena: $escenaId, $datos)';
}

/// Quién decide si se envía la analítica.
enum ConsentimientoAnalitica {
  /// El módulo pregunta una vez y deja cambiarlo en los ajustes.
  preguntar,

  /// La app anfitriona ya obtuvo el consentimiento con su propia política.
  concedido,

  /// No se envía nada, ni se pregunta.
  denegado,
}

/// Identificador de sesión: un UUID v4 al azar.
///
/// Se crea al abrir el módulo y muere con él. No se guarda, así que dos
/// visitas del mismo teléfono no se pueden unir.
String nuevaSesionId([Random? azar]) {
  final r = azar ?? Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // versión 4
  b[8] = (b[8] & 0x3f) | 0x80; // variante RFC 4122
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

/// Espera antes de reintentar tras [fallos] envíos fallidos seguidos: 5 s,
/// 10 s, 20 s… hasta 2 minutos.
Duration esperaPorDefecto(int fallos) =>
    Duration(seconds: min(5 * pow(2, max(0, fallos - 1)).toInt(), 120));

/// Cola de eventos que se envían de uno en uno sin bloquear la interfaz
/// (RF-24).
///
/// [registrar] es síncrono y nunca lanza: la interfaz no espera ni se entera de
/// un fallo de red. Un fallo transitorio (sin conexión, tiempo agotado, error
/// del servidor) deja el evento en la cola y reintenta más tarde; uno que la
/// API rechaza no tiene arreglo y se descarta. La cola vive en memoria: lo que
/// no se envió antes de cerrar el módulo se pierde, a cambio de no guardar
/// nada de la visita en el teléfono.
class ColaAnalitica {
  ColaAnalitica({
    required Future<bool> Function(EventoAnalitica evento) enviar,
    String? sesionId,
    Duration Function(int fallos) espera = esperaPorDefecto,
  }) : _enviar = enviar,
       _espera = espera,
       sesionId = sesionId ?? nuevaSesionId();

  final Future<bool> Function(EventoAnalitica evento) _enviar;
  final Duration Function(int fallos) _espera;
  final String sesionId;

  /// Tope de eventos en espera. Sin red durante mucho rato, se descartan los
  /// más antiguos.
  static const maxPendientes = 100;

  final _pendientes = Queue<EventoAnalitica>();
  bool? _consentimiento;
  var _enviando = false;
  var _cerrada = false;
  var _fallos = 0;
  Timer? _reintento;

  /// Eventos que todavía no llegaron a la API.
  int get pendientes => _pendientes.length;

  /// Nulo mientras no hay respuesta: se acumula sin enviar.
  bool? get consentimiento => _consentimiento;

  set consentimiento(bool? valor) {
    _consentimiento = valor;
    if (valor == false) {
      _pendientes.clear();
      _cancelarReintento();
    } else if (valor == true) {
      _programar();
    }
  }

  void registrar(
    TipoEvento tipo, {
    int? poiId,
    int? escenaId,
    Map<String, Object> datos = const {},
  }) {
    if (_cerrada || _consentimiento == false) return;
    if (_pendientes.length >= maxPendientes) _pendientes.removeFirst();
    _pendientes.add(
      EventoAnalitica(
        sesionId: sesionId,
        tipo: tipo,
        poiId: poiId,
        escenaId: escenaId,
        datos: datos,
      ),
    );
    _programar();
  }

  /// Deja de enviar y olvida lo pendiente. Se llama al cerrar el módulo.
  void cerrar() {
    _cerrada = true;
    _pendientes.clear();
    _cancelarReintento();
  }

  void _cancelarReintento() {
    _reintento?.cancel();
    _reintento = null;
    _fallos = 0;
  }

  void _programar() {
    if (_cerrada || _consentimiento != true) return;
    if (_enviando || _reintento != null || _pendientes.isEmpty) return;
    _enviando = true;
    // En una microtarea y no en línea: quien registra suele estar a mitad de
    // un gesto o de un setState, y el envío no debe correr dentro.
    scheduleMicrotask(_vaciar);
  }

  Future<void> _vaciar() async {
    try {
      while (!_cerrada && _consentimiento == true && _pendientes.isNotEmpty) {
        final evento = _pendientes.first;
        try {
          final aceptado = await _enviar(evento);
          if (!aceptado) {
            debugPrint('La API rechazó $evento; se descarta.');
          }
          _fallos = 0;
        } on FalloApp catch (fallo) {
          if (_cerrada || _consentimiento != true) return;
          _fallos++;
          final espera = _espera(_fallos);
          debugPrint('Evento sin enviar ($fallo); reintento en $espera.');
          _reintento = Timer(espera, () {
            _reintento = null;
            _programar();
          });
          return;
        } catch (error) {
          // Un error que no es de red no se arregla reintentando.
          debugPrint('No se pudo enviar $evento: $error; se descarta.');
        }
        // Si durante el envío se rechazó el consentimiento, la cola ya se
        // vació y este evento no está.
        if (_pendientes.isNotEmpty && identical(_pendientes.first, evento)) {
          _pendientes.removeFirst();
        }
      }
    } finally {
      _enviando = false;
    }
  }
}

/// Si se puede enviar la analítica: verdadero, falso, o nulo mientras se
/// espera la respuesta del usuario.
final consentimientoAnaliticaProvider = Provider<bool?>((ref) {
  final configuracion = ref.watch(configuracionTourProvider);
  // Sin API no hay a dónde enviar.
  if (configuracion.esLocal) return false;
  return switch (configuracion.analitica) {
    ConsentimientoAnalitica.concedido => true,
    ConsentimientoAnalitica.denegado => false,
    ConsentimientoAnalitica.preguntar => ref.watch(
      preferenciasProvider.select((p) => p.analitica),
    ),
  };
});

/// Si el usuario decide sobre la analítica dentro del módulo: el aviso de la
/// lista y el interruptor de los ajustes.
final analiticaEnElModuloProvider = Provider<bool>((ref) {
  final configuracion = ref.watch(configuracionTourProvider);
  return !configuracion.esLocal &&
      configuracion.analitica == ConsentimientoAnalitica.preguntar;
});

/// Cola de analítica de esta apertura del módulo. `TourVirtual` crea un
/// contenedor por apertura, así que cada una es una sesión nueva.
final analiticaProvider = Provider<ColaAnalitica>((ref) {
  final cola = ColaAnalitica(
    // El repositorio se lee en cada envío: cambia al cambiar de idioma.
    enviar: (evento) =>
        ref.read(repositorioContenidoProvider).registrarEvento(evento),
  );
  ref.onDispose(cola.cerrar);
  ref.listen<bool?>(
    consentimientoAnaliticaProvider,
    (_, valor) => cola.consentimiento = valor,
    fireImmediately: true,
  );
  return cola;
});

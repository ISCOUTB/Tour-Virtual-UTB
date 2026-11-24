import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../configuracion_tour.dart';
import '../../datos/modelos/modelos.dart';
import '../../datos/plano_campus.dart';
import '../../datos/progreso.dart';
import '../../datos/proveedores.dart';
import '../../l10n/textos.dart';
import '../../navegacion/correcciones.dart';
import '../../navegacion/espacios.dart';
import '../../navegacion/geo.dart';
import '../../navegacion/grafo_campus.dart';
import '../../navegacion/modo_campo.dart';
import '../../navegacion/pantalla_activa.dart';
import '../../navegacion/seguimiento.dart';
import '../../navegacion/sensores.dart';
import '../../navegacion/voz_guia.dart';
import '../../nucleo/idiomas.dart';
import '../../nucleo/rutas.dart';
import '../../nucleo/tema.dart';
import '../comunes/anillo_progreso.dart';
import '../comunes/componentes.dart';
import '../comunes/fondos.dart';
import '../comunes/ilustracion_max.dart';
import '../ficha_poi.dart';
import '../inicio/buscador_destinos.dart';
import '../postal_escena.dart';
import '../vista_async.dart';
import 'plano_ruta.dart';
import 'vista_camara.dart';

part 'campo_guia.dart';
part 'piezas_guia.dart';

/// Guía a pie hasta un lugar del campus (F-06, RF-26 a RF-34).
///
/// Pide la ubicación explicando para qué, calcula la ruta en el grafo
/// peatonal, la sigue con el GPS y la muestra en el plano o con una flecha
/// sobre la cámara. Da cada indicación en pantalla, por voz (o por el lector
/// de pantalla, si está activo) y con una vibración. Al llegar abre la tarjeta
/// del lugar (RF-32). Si falta el permiso, el GPS o la cámara, lo dice y
/// ofrece el mapa o el 360 (RF-33). La posición nunca sale del teléfono
/// (RN-10).
class PantallaNavegacion extends ConsumerWidget {
  const PantallaNavegacion({super.key, required this.poiId, this.espacioId});

  final int poiId;

  /// Un salón, laboratorio u oficina del catálogo de espacios: la guía lleva
  /// a la entrada del edificio y dice en qué piso está.
  final String? espacioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lugar = ref.watch(configuracionTourProvider).lugarId;
    final pois = ref.watch(poisProvider(lugar));
    final grafo = ref.watch(grafoGuiaProvider);
    final plano = ref.watch(planoCampusProvider);
    final modoCampo = ref.watch(modoCampoProvider);
    final radio = modoCampo
        ? ref.watch(correccionesCampoProvider).radioLlegada
        : null;
    final espacio = espacioId == null
        ? null
        : ref.watch(catalogoEspaciosProvider).valueOrNull?.destino(espacioId!);
    return Scaffold(
      body: VistaAsync<(List<Poi>, GrafoCampus, PlanoCampus)>(
        valor: switch ((pois, grafo, plano)) {
          (
            AsyncData(:final value),
            AsyncData(value: final g),
            AsyncData(value: final p),
          ) =>
            AsyncData((value, g, p)),
          (AsyncError(:final error, :final stackTrace), _, _) ||
          (_, AsyncError(:final error, :final stackTrace), _) ||
          (
            _,
            _,
            AsyncError(:final error, :final stackTrace),
          ) => AsyncError(error, stackTrace),
          _ => const AsyncLoading(),
        },
        alReintentar: () => ref.invalidate(poisProvider(lugar)),
        enDatos: (datos) {
          final (lista, grafoCampus, planoCampus) = datos;
          final poi = lista.where((p) => p.id == poiId).firstOrNull;
          if (poi == null) {
            return Center(child: Text(Textos.of(context).falloSinContenido));
          }
          return _Guia(
            // El ensayo cambia la fuente de la posición: guía nueva.
            key: ValueKey(ref.watch(ensayoCampoProvider)),
            poi: poi,
            espacio: espacio,
            lugares: lista,
            paradas: [...lista.where((p) => p.esParada)],
            grafo: grafoCampus,
            plano: planoCampus,
            modoCampo: modoCampo,
            radioLlegada: radio ?? SeguimientoRuta.radioPorDefecto,
          );
        },
      ),
    );
  }
}

enum _Fase {
  intro,
  pidiendo,
  sinPermiso,
  gpsApagado,
  guiando,
  sinRuta,

  /// A más de [GrafoCampus.distanciaMaximaEntrada] de cualquier camino. El GPS
  /// sigue escuchando: al entrar al campus, la guía empieza sola.
  fueraDelCampus,
  llegada,

  /// La ruta entera sobre el plano, con sus pasos, desde un punto elegido:
  /// sin GPS, sin permiso o desde la casa (de MAPSUTB: la partida a mano).
  vistaPrevia,
}

enum _Vista { plano, camara }

class _Guia extends ConsumerStatefulWidget {
  const _Guia({
    super.key,
    required this.poi,
    this.espacio,
    this.lugares = const [],
    required this.paradas,
    required this.grafo,
    required this.plano,
    this.modoCampo = false,
    this.radioLlegada = SeguimientoRuta.radioPorDefecto,
  });

  final Poi poi;

  /// El salón u oficina que se busca dentro del lugar, si se llegó por el
  /// buscador.
  final DestinoBusqueda? espacio;

  /// Todos los lugares: puntos de partida de la vista previa.
  final List<Poi> lugares;
  final List<Poi> paradas;

  /// En el modo campo cambia con cada corrección: la ruta se recalcula.
  final GrafoCampus grafo;
  final PlanoCampus plano;
  final bool modoCampo;
  final double radioLlegada;

  @override
  ConsumerState<_Guia> createState() => _GuiaState();
}

class _GuiaState extends ConsumerState<_Guia> with WidgetsBindingObserver {
  var _fase = _Fase.intro;
  PermisoUbicacion? _permiso;
  var _vista = _Vista.plano;
  var _sinEscaleras = false;
  var _camaraFallo = false;
  var _recalculando = false;
  var _enPrimerPlano = true;
  var _sesion = 0;
  final _pantalla = PantallaActiva();
  Future<void> _cancelacion = Future<void>.value();

  // Se leen una vez al montar: en dispose ya no se puede usar ref.
  late final FuenteUbicacion _ubicacion;
  late FuenteRumbo _fuenteRumbo;
  late final VozGuia _voz;
  StreamSubscription<LecturaPosicion>? _subPosicion;
  StreamSubscription<LecturaRumbo>? _subRumbo;

  SeguimientoRuta? _seguimiento;
  LecturaRumbo? _rumbo;
  Maniobra? _anunciada;

  // Modo campo (ver campo_guia.dart).
  /// Última posición, también después de la llegada: para marcar la puerta.
  LecturaPosicion? _posicionCampo;

  /// Dónde dio la app la llegada.
  PuntoGeo? _llegadaApp;
  final _oyentesCampo = <void Function(LecturaPosicion)>[];

  /// Camino que se está grabando, o nulo.
  List<PuntoGeo>? _trazo;

  /// Tramo que se va a corregir, resaltado en el plano.
  List<PuntoGeo> _resaltado = const [];

  /// Sin una lectura útil en este tiempo, se dice que no llega la señal en
  /// vez de «Buscando señal» para siempre (de MAPSUTB, su ADR 0017).
  static const _esperaPrimeraLectura = Duration(seconds: 30);
  static const _esperaSinSenal = Duration(seconds: 15);
  Timer? _vigia;
  var _sinSenal = false;

  /// Última lectura que no era vieja, aunque fuera imprecisa: para decir
  /// «señal débil» antes de tener ruta.
  LecturaPosicion? _ultimaLectura;

  /// Vista previa: lugar de partida (nulo: la entrada principal).
  int? _origenPrevia;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ubicacion = ref.read(fuenteUbicacionProvider);
    _fuenteRumbo = ref.read(fuenteRumboProvider(_ajusteBrujula(widget.grafo)));
    _voz = ref.read(vozGuiaProvider);
  }

  /// Para la extensión del modo campo, que no puede llamar a setState.
  void _refrescar(VoidCallback cambio) => setState(cambio);

  static AjusteBrujula _ajusteBrujula(GrafoCampus g) => (
    declinacion: g.declinacion,
    campoEsperado: g.campoMagnetico,
    tolerancia: g.toleranciaCampo,
  );

  @override
  void didUpdateWidget(_Guia anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.grafo == widget.grafo &&
        anterior.radioLlegada == widget.radioLlegada) {
      return;
    }
    final ajuste = _ajusteBrujula(widget.grafo);
    if (ajuste != _ajusteBrujula(anterior.grafo)) {
      _fuenteRumbo = ref.read(fuenteRumboProvider(ajuste));
      if (_subRumbo != null) {
        final viejo = _subRumbo!;
        _subRumbo = null;
        _cancelacion = Future.wait<void>([_cancelacion, viejo.cancel()]);
        _suscribirBrujula(_sesion);
      }
    }
    // Una corrección de campo cambió el grafo: ruta nueva desde donde está.
    // Después del cuadro, porque puede cambiar de fase.
    WidgetsBinding.instance.addPostFrameCallback((_) => _rehacerRuta());
  }

  void _rehacerRuta() {
    if (!mounted) return;
    final ultima = _seguimiento?.ultima ?? _posicionCampo;
    if (ultima == null || _seguimiento == null) return;
    if (_fase == _Fase.llegada) {
      // En el campo, tras mover la puerta se vuelve a guiar hacia la nueva.
      if (!widget.modoCampo) return;
      _llegadaApp = null;
      setState(() => _fase = _Fase.guiando);
    } else if (_fase != _Fase.guiando) {
      return;
    }
    _anunciada = null;
    _seguimiento = null;
    _alLeer(ultima);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pausar();
    super.dispose();
  }

  void _pausar({bool callar = true}) {
    _sesion++;
    _vigia?.cancel();
    _vigia = null;
    _cancelacion = Future.wait<void>([
      _cancelacion,
      if (_subPosicion != null) _subPosicion!.cancel(),
      if (_subRumbo != null) _subRumbo!.cancel(),
    ]).then((_) {});
    _subPosicion = null;
    _subRumbo = null;
    _rumbo = null;
    if (callar) unawaited(_voz.callar());
    unawaited(_pantalla.cambiar(false));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    _enPrimerPlano = estado == AppLifecycleState.resumed;
    if (!_enPrimerPlano) {
      _pausar();
    } else if (_fase == _Fase.guiando || _fase == _Fase.fueraDelCampus) {
      _anunciada = null;
      unawaited(_escuchar());
    }
  }

  Future<void> _empezar() async {
    setState(() => _fase = _Fase.pidiendo);
    final permiso = await _ubicacion.pedirPermiso();
    if (!mounted) return;
    _permiso = permiso;
    switch (permiso) {
      case PermisoUbicacion.concedido:
        setState(() => _fase = _Fase.guiando);
        _escuchar();
      case PermisoUbicacion.servicioApagado:
        setState(() => _fase = _Fase.gpsApagado);
      case PermisoUbicacion.denegado || PermisoUbicacion.denegadoSiempre:
        setState(() => _fase = _Fase.sinPermiso);
    }
  }

  Future<void> _escuchar() async {
    final sesion = ++_sesion;
    await _cancelacion;
    if (!mounted || !_enPrimerPlano || sesion != _sesion) return;
    final enCampus = _fase != _Fase.fueraDelCampus;
    if (enCampus) unawaited(_pantalla.cambiar(true));
    _armarVigia();
    _subPosicion = _ubicacion.lecturas().listen(
      (lectura) {
        if (sesion != _sesion) return;
        if (widget.modoCampo) _alLeerCampo(lectura);
        _alLeer(lectura);
      },
      onError: (Object error) {
        if (sesion != _sesion) return;
        debugPrint('GPS: $error');
        if (mounted) {
          _pausar();
          setState(() => _fase = _Fase.gpsApagado);
        }
      },
    );
    if (enCampus) _suscribirBrujula(sesion);
  }

  /// Se rearma con cada lectura útil: si deja de haberlas, se avisa.
  void _armarVigia() {
    _vigia?.cancel();
    final sesion = _sesion;
    _vigia = Timer(
      _ultimaLectura == null ? _esperaPrimeraLectura : _esperaSinSenal,
      () {
        if (!mounted || sesion != _sesion) return;
        setState(() => _sinSenal = true);
      },
    );
  }

  /// Fuera del campus: sin brújula ni pantalla encendida, pero el GPS sigue
  /// para empezar solo al llegar.
  void _irFueraDelCampus() {
    final brujula = _subRumbo;
    _subRumbo = null;
    _rumbo = null;
    if (brujula != null) {
      _cancelacion = Future.wait<void>([_cancelacion, brujula.cancel()]);
    }
    unawaited(_pantalla.cambiar(false));
    _seguimiento = null;
    setState(() => _fase = _Fase.fueraDelCampus);
  }

  void _volverAlCampus() {
    unawaited(_pantalla.cambiar(true));
    if (_subRumbo == null) _suscribirBrujula(_sesion);
    setState(() => _fase = _Fase.guiando);
  }

  void _suscribirBrujula(int sesion) {
    _subRumbo = _fuenteRumbo.lecturas().listen(
      (r) {
        if (!mounted || !_enPrimerPlano || sesion != _sesion) return;
        final antes = _rumbo;
        // Repintar con cada lectura del sensor (20 Hz) es gastar batería: solo
        // si cambió algo que se vea.
        if (antes == null ||
            diferenciaAngular(antes.grados, r.grados).abs() > 1 ||
            (antes.inclinacion - r.inclinacion).abs() > 2 ||
            antes.descalibrada != r.descalibrada) {
          if (mounted) setState(() => _rumbo = r);
        }
      },
      onError: (Object error) {
        if (sesion != _sesion) return;
        debugPrint('Brújula: $error');
        if (mounted) setState(() => _rumbo = null);
      },
    );
  }

  bool _calcular(PuntoGeo desde) {
    final ruta = widget.grafo.ruta(
      desde,
      widget.poi.id,
      sinEscaleras: _sinEscaleras,
    );
    if (ruta == null) {
      // Desde la casa, «no encontré un camino» parecía un fallo.
      final lejos =
          widget.grafo.distanciaAlCamino(desde) >
          GrafoCampus.distanciaMaximaEntrada;
      if (lejos) {
        _irFueraDelCampus();
      } else {
        _pausar();
        setState(() => _fase = _Fase.sinRuta);
      }
      return false;
    }
    final ubicacion = _ubicacion;
    if (ubicacion is UbicacionSimulada) {
      ubicacion.seguir(ruta.puntos, desde: desde);
    }
    _seguimiento = SeguimientoRuta(ruta, radio: widget.radioLlegada);
    return true;
  }

  void _alLeer(LecturaPosicion lectura) {
    if (!mounted || !_enPrimerPlano) return;
    if (_fase != _Fase.guiando && _fase != _Fase.fueraDelCampus) return;
    final uso = usoDeLectura(lectura, DateTime.now());
    // La última posición conocida al abrir el GPS puede ser de otro lugar.
    if (uso == UsoLectura.vieja) return;
    _ultimaLectura = lectura;
    _armarVigia();
    if (_sinSenal) setState(() => _sinSenal = false);

    if (_fase == _Fase.fueraDelCampus) {
      final cerca =
          uso == UsoLectura.guiar &&
          widget.grafo.distanciaAlCamino(lectura.punto) <=
              GrafoCampus.distanciaMaximaEntrada;
      if (!cerca) return;
      _volverAlCampus();
    }

    if (_seguimiento == null) {
      // Con una lectura imprecisa no se calcula la ruta ni se decide que está
      // fuera del campus, salvo que lo esté aun con el peor error.
      if (uso == UsoLectura.debil) {
        if (fueraDelCampusCon(lectura, widget.grafo)) {
          _irFueraDelCampus();
        } else {
          setState(() {});
        }
        return;
      }
      if (!_calcular(lectura.punto)) return;
    }
    final seguimiento = _seguimiento!..actualizar(lectura);

    if (seguimiento.estado == EstadoSeguimiento.fueraDeRuta) {
      _recalculando = true;
      _anunciar(Textos.of(context).navRecalculando);
      if (!_calcular(lectura.punto)) return;
      _seguimiento!.actualizar(lectura);
    } else if (seguimiento.estado == EstadoSeguimiento.guiando) {
      _recalculando = false;
    }

    final actual = _seguimiento!;
    if (actual.estado == EstadoSeguimiento.llegada) {
      if (widget.modoCampo) {
        // En el campo los sensores siguen: hay que poder decir «la puerta
        // real es aquí» si la llegada salió antes o después.
        _llegadaApp = lectura.punto;
        unawaited(_pantalla.cambiar(true));
      } else {
        _pausar(callar: false);
      }
      HapticFeedback.heavyImpact();
      final txt = Textos.of(context);
      _anunciar(
        [txt.navLlegaste(widget.poi.nombre), ?_textoEspacio(txt)].join('. '),
      );
      setState(() => _fase = _Fase.llegada);
      return;
    }
    final maniobra = actual.proximaManiobra();
    if (maniobra != null &&
        actual.estado == EstadoSeguimiento.guiando &&
        maniobra != _anunciada) {
      _anunciada = maniobra;
      HapticFeedback.selectionClick();
      _anunciar(_textoManiobra(Textos.of(context), maniobra));
    }
    setState(() {});
  }

  /// Por el lector de pantalla si está activo (hablaría encima de él); si
  /// no, con la voz del teléfono. El texto siempre está también en pantalla.
  void _anunciar(String texto) {
    if (MediaQuery.accessibleNavigationOf(context)) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        texto,
        Directionality.of(context),
      );
    } else {
      _voz.decir(
        texto,
        idioma: Localizations.localeOf(context).toLanguageTag(),
      );
    }
  }

  static int _redondear(double metros) =>
      metros < 20 ? metros.round() : (metros / 5).round() * 5;

  String _textoManiobra(Textos txt, Maniobra m) {
    final metros = _redondear(m.metros);
    if (m.llegada) return txt.navLlegando(widget.poi.nombre, metros);
    return switch (m.giro) {
      Giro.recto => txt.navRecto(metros),
      Giro.derecha => txt.navDerecha(metros),
      Giro.izquierda => txt.navIzquierda(metros),
      Giro.ligeraDerecha => txt.navLigeraDerecha(metros),
      Giro.ligeraIzquierda => txt.navLigeraIzquierda(metros),
      Giro.vuelta => txt.navVuelta,
    };
  }

  static IconData _icono(Maniobra? m) => switch (m) {
    null => Icons.navigation_rounded,
    Maniobra(llegada: true) => Icons.flag_rounded,
    Maniobra(giro: Giro.recto) => Icons.straight_rounded,
    Maniobra(giro: Giro.derecha) => Icons.turn_right_rounded,
    Maniobra(giro: Giro.izquierda) => Icons.turn_left_rounded,
    Maniobra(giro: Giro.ligeraDerecha) => Icons.turn_slight_right_rounded,
    Maniobra(giro: Giro.ligeraIzquierda) => Icons.turn_slight_left_rounded,
    Maniobra(giro: Giro.vuelta) => Icons.u_turn_left_rounded,
  };

  /// «El Salón 401 está en el Cuarto Piso.» Nulo si no se busca un espacio.
  String? _textoEspacio(Textos txt) {
    final e = widget.espacio;
    if (e == null) return null;
    final piso = e.piso;
    return piso == null
        ? txt.navEspacioAqui(e.titulo)
        : txt.navEspacioPiso(e.titulo, piso.nombre);
  }

  /// La ruta sin GPS: se apagan los sensores y se muestra entera.
  void _verPrevia() {
    _pausar();
    setState(() {
      _seguimiento = null;
      _sinSenal = false;
      _fase = _Fase.vistaPrevia;
    });
  }

  ({PuntoGeo punto, String nombre}) _partidaPrevia(Textos txt) {
    final id = _origenPrevia;
    if (id != null) {
      final accesos = widget.grafo.accesosDe(id);
      final lugar = widget.lugares.where((p) => p.id == id).firstOrNull;
      if (accesos.isNotEmpty && lugar != null) {
        final acceso = accesos.firstWhere(
          (a) => a.principal,
          orElse: () => accesos.first,
        );
        return (punto: acceso.punto, nombre: lugar.nombre);
      }
    }
    return (
      punto: UbicacionSimulada.puntoDePartida,
      nombre: txt.navEntradaPrincipal,
    );
  }

  void _cambiarEscaleras(bool valor) {
    setState(() => _sinEscaleras = valor);
    final ultima = _seguimiento?.ultima;
    if (ultima != null) {
      _anunciada = null;
      if (_calcular(ultima.punto)) _seguimiento!.actualizar(ultima);
      setState(() {});
    }
  }

  void _salir() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Rutas.inicio);
    }
  }

  /// La siguiente parada del recorrido que aún no se ha visto, para seguir
  /// desde la llegada.
  Poi? _siguienteParada() {
    final paradas = widget.paradas;
    final i = paradas.indexWhere((p) => p.id == widget.poi.id);
    if (i < 0) return null;
    final vistos = ref.watch(progresoProvider);
    for (var k = 1; k < paradas.length; k++) {
      final p = paradas[(i + k) % paradas.length];
      if (!vistos.contains(p.id) && p.id != widget.poi.id) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final txt = Textos.of(context);
    final lugar = widget.poi.nombre;
    final abajo = MediaQuery.paddingOf(context).bottom;
    final numero = widget.paradas.indexWhere((p) => p.id == widget.poi.id);
    final seguimiento = _seguimiento;
    final guiando = _fase == _Fase.guiando;
    final escena = escenaPrincipalDe(ref, widget.poi);
    final postal = escena == null
        ? null
        : _PostalDestino(
            escena: escena,
            poi: widget.poi,
            numero: numero < 0 ? null : numero + 1,
          );

    final contenido = switch (_fase) {
      _Fase.intro || _Fase.pidiendo => _vistaIntro(txt, lugar, postal),
      _Fase.sinPermiso => _EstadoGuia(
        icono: Icons.location_off_outlined,
        texto: txt.navSinPermiso,
        principal: _permiso == PermisoUbicacion.denegadoSiempre
            ? (txt.navAbrirAjustes, _ubicacion.abrirAjustes)
            : (txt.navPermitir, _empezar),
        secundarias: [(txt.navVerRutaSinGps, _verPrevia), ?_salidaAl360(txt)],
        postal: postal,
      ),
      _Fase.gpsApagado => _EstadoGuia(
        icono: Icons.gps_off_rounded,
        texto: txt.navGpsApagado,
        principal: (txt.reintentar, _empezar),
        secundarias: [(txt.navVerRutaSinGps, _verPrevia), ?_salidaAl360(txt)],
        postal: postal,
      ),
      _Fase.sinRuta => _EstadoGuia(
        icono: Icons.wrong_location_outlined,
        texto: txt.navSinRuta(lugar),
        principal: (txt.volver, _salir),
        secundarias: [?_salidaAl360(txt)],
        postal: postal,
      ),
      _Fase.fueraDelCampus => _EstadoGuia(
        icono: Icons.explore_outlined,
        texto: txt.navFueraDelCampus,
        principal: (txt.navVerRutaSinGps, _verPrevia),
        secundarias: [(txt.volver, _salir), ?_salidaAl360(txt)],
        postal: postal,
      ),
      _Fase.guiando when _seguimiento == null && _sinSenal => _EstadoGuia(
        icono: Icons.gps_not_fixed_rounded,
        texto: txt.navSinSenal,
        principal: (txt.navVerRutaSinGps, _verPrevia),
        secundarias: [(txt.volver, _salir)],
        postal: postal,
      ),
      _Fase.llegada => _vistaLlegada(txt, postal),
      _Fase.guiando => _vistaGuia(txt),
      _Fase.vistaPrevia => _vistaPrevia(txt),
    };

    final restantes = seguimiento?.metrosRestantes;
    final total = seguimiento?.ruta.metros;
    return Material(
      color: ColoresUtb.fondo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CabeceraGuia(
            poi: widget.poi,
            numero: numero < 0 ? null : numero + 1,
            total: widget.paradas.length,
            sobretitulo: switch (_fase) {
              _Fase.guiando => txt.navCaminandoHacia,
              _Fase.llegada => txt.navLlegada,
              _ => txt.comoLlegar,
            },
            alVolver: _salir,
            avance: guiando && restantes != null && total != null && total > 0
                ? (1 - restantes / total).clamp(0.0, 1.0)
                : null,
            metrosRestantes: guiando && restantes != null
                ? _redondear(restantes)
                : null,
            pose: switch (_fase) {
              _Fase.intro || _Fase.pidiendo => PoseMax.telefono,
              _Fase.sinPermiso || _Fase.gpsApagado => PoseMax.apenado,
              _Fase.sinRuta => PoseMax.pensativo,
              _Fase.fueraDelCampus || _Fase.vistaPrevia => PoseMax.mapa,
              _Fase.llegada => PoseMax.celebrando,
              _Fase.guiando when _seguimiento == null && _sinSenal =>
                PoseMax.pensativo,
              _Fase.guiando => null,
            },
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                MedidasUtb.margen,
                guiando ? 14 : 0,
                MedidasUtb.margen,
                (widget.modoCampo ? 8 : 12) + (widget.modoCampo ? 0 : abajo),
              ),
              child: contenido,
            ),
          ),
          if (widget.modoCampo)
            Padding(
              padding: EdgeInsets.fromLTRB(
                MedidasUtb.margen,
                0,
                MedidasUtb.margen,
                abajo + 12,
              ),
              child: _BarraCampo(guia: this),
            ),
        ],
      ),
    );
  }

  /// Antes de empezar: qué va a pasar, «sin escaleras» y el permiso.
  Widget _vistaIntro(Textos txt, String lugar, Widget? postal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 20),
            children: [
              if (widget.espacio case final espacio?) ...[
                _TarjetaEspacio(espacio: espacio),
                const SizedBox(height: 12),
              ],
              if (postal != null) ...[postal, const SizedBox(height: 12)],
              _TarjetaComoFunciona(titulo: txt.navPermisoTitulo(lugar)),
              const SizedBox(height: 12),
              TarjetaUtb(
                padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
                child: _InterruptorEscaleras(
                  valor: _sinEscaleras,
                  alCambiar: (v) => setState(() => _sinEscaleras = v),
                ),
              ),
            ],
          ),
        ),
        _Acciones(
          principal: (
            txt.navPermitir,
            _fase == _Fase.pidiendo ? null : _empezar,
          ),
          secundarias: [(txt.navVerRutaSinGps, _verPrevia)],
        ),
      ],
    );
  }

  /// Al llegar: la postal del lugar, su ficha y, si queda, la siguiente
  /// parada del recorrido. La cabecera ya dice «Llegaste» y el lugar.
  Widget _vistaLlegada(Textos txt, Widget? postal) {
    final textos = Theme.of(context).textTheme;
    final paleta = PaletaUtb.de(context);
    final siguiente = _siguienteParada();
    return ListView(
      padding: const EdgeInsets.only(top: 20),
      children: [
        if (_textoEspacio(txt) case final texto?) ...[
          RecuadroInfo(icono: Icons.stairs_rounded, texto: texto),
          const SizedBox(height: 16),
        ],
        if (postal != null) ...[postal, const SizedBox(height: 16)],
        if (widget.poi.descripcion case final d? when d.isNotEmpty) ...[
          TextoDeContenido(
            d,
            style: textos.bodyLarge?.copyWith(color: paleta.textoSecundario),
          ),
          const SizedBox(height: 18),
        ],
        FilledButton(
          onPressed: () =>
              abrirPoi(context, ref, poi: widget.poi, pois: widget.paradas),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(txt.navVerFicha),
        ),
        if (_salidaAl360(txt) case (final etiqueta, final accion)) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: accion,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.threesixty_rounded),
            label: Text(etiqueta),
          ),
        ],
        if (siguiente != null) ...[
          const SizedBox(height: 20),
          _TarjetaSiguiente(
            poi: siguiente,
            alIr: () =>
                context.pushReplacement(Rutas.haciaNavegacion(siguiente.id)),
          ),
        ],
        const SizedBox(height: 8),
        TextButton(onPressed: _salir, child: Text(txt.navTerminar)),
      ],
    );
  }

  /// La ruta entera desde un punto elegido, con sus pasos: para verla antes
  /// de salir, sin GPS o desde la casa.
  Widget _vistaPrevia(Textos txt) {
    final textos = Theme.of(context).textTheme;
    final paleta = PaletaUtb.de(context);
    final partida = _partidaPrevia(txt);
    final ruta = widget.grafo.ruta(
      partida.punto,
      widget.poi.id,
      sinEscaleras: _sinEscaleras,
    );
    final origenes = [
      for (final p in widget.lugares)
        if (p.id != widget.poi.id && widget.grafo.tieneAcceso(p.id)) p,
    ]..sort((a, b) => a.nombre.compareTo(b.nombre));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 20),
            children: [
              if (widget.espacio case final espacio?) ...[
                _TarjetaEspacio(espacio: espacio),
                const SizedBox(height: 12),
              ],
              _SelectorPartida(
                nombre: partida.nombre,
                lugares: origenes,
                alElegir: (id) => setState(() => _origenPrevia = id),
              ),
              const SizedBox(height: 12),
              if (ruta == null)
                RecuadroInfo(
                  icono: Icons.wrong_location_outlined,
                  texto: txt.navSinRuta(widget.poi.nombre),
                )
              else ...[
                _ResumenRuta(ruta: ruta),
                const SizedBox(height: 12),
                SizedBox(
                  height: 260,
                  child: Semantics(
                    image: true,
                    label: txt.navPlanoSemantica(widget.poi.nombre),
                    child: PlanoRuta(
                      plano: widget.plano,
                      ruta: ruta.puntos,
                      destino: ruta.destino.punto,
                      posicion: partida.punto,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  mayusculasDe(context, txt.navPasoAPaso),
                  style: estiloSobretitulo(color: paleta.textoSecundario),
                ),
                const SizedBox(height: 8),
                TarjetaUtb(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: Column(
                    children: [
                      for (final (i, paso) in pasosDeRuta(ruta.puntos).indexed)
                        _FilaPaso(
                          icono: _icono(paso),
                          texto: _textoManiobra(txt, paso),
                          ultimo: paso.llegada,
                          primero: i == 0,
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TarjetaUtb(
                padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
                child: _InterruptorEscaleras(
                  valor: _sinEscaleras,
                  alCambiar: (v) => setState(() => _sinEscaleras = v),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                txt.navPreviaNota,
                style: textos.bodySmall?.copyWith(color: paleta.textoTerciario),
              ),
            ],
          ),
        ),
        _Acciones(
          principal: (txt.navGuiarmeConGps, _empezar),
          secundarias: [(txt.volver, _salir)],
        ),
      ],
    );
  }

  (String, VoidCallback)? _salidaAl360(Textos txt) {
    final escena = widget.poi.escenaPrincipalId;
    if (escena == null) return null;
    return (
      txt.verEn360,
      () => context.push(
        Rutas.haciaRecorrido(widget.poi.lugarId, escenaId: escena),
      ),
    );
  }

  Widget _vistaGuia(Textos txt) {
    final seguimiento = _seguimiento;
    final lectura = seguimiento?.ultima;
    final maniobra = seguimiento?.proximaManiobra();
    final textos = Theme.of(context).textTheme;

    final previa = _ultimaLectura;
    final String titular;
    if (seguimiento == null || lectura == null) {
      titular =
          previa != null &&
              previa.precision > SeguimientoRuta.precisionPorDefecto
          ? txt.navSenalDebil(previa.precision.round())
          : txt.navBuscando;
    } else if (_recalculando) {
      titular = txt.navRecalculando;
    } else if (seguimiento.estado == EstadoSeguimiento.senalDebil) {
      titular = txt.navSenalDebil(lectura.precision.round());
    } else {
      titular = maniobra == null
          ? txt.navBuscando
          : _textoManiobra(txt, maniobra);
    }
    final restantes = seguimiento?.metrosRestantes;
    final detalle = restantes == null
        ? null
        : txt.navFaltan(
            _redondear(restantes),
            (restantes / 1.2 / 60).ceil().clamp(1, 99),
          );

    final rumboAlObjetivo = seguimiento?.rumboGuia;
    final rumbo = rumboNavegacion(lectura, _rumbo);
    final giro = (rumboAlObjetivo == null || rumbo == null)
        ? null
        : diferenciaAngular(rumbo, rumboAlObjetivo);

    final avisos = <(IconData, String)>[
      if (widget.espacio case final e?)
        (Icons.meeting_room_outlined, [e.titulo, ?e.piso?.nombre].join(' · ')),
      if (_ubicacion.simulada) (Icons.science_outlined, txt.navSimulada),
      if (seguimiento != null && !seguimiento.ruta.destino.verificado)
        (Icons.info_outline_rounded, txt.navAproximada),
      if (_rumbo?.descalibrada ?? false)
        (Icons.explore_off_outlined, txt.navCalibrar),
    ];

    final vista = switch (_vista) {
      _Vista.camara when !_camaraFallo => VistaCamara(
        giro: giro,
        inclinacion: _rumbo?.inclinacion ?? -30,
        metros: maniobra == null ? null : _redondear(maniobra.metros),
        destino: switch ((rumbo, seguimiento?.suavizada, seguimiento)) {
          (final r?, final p?, final s?) => (
            giro: diferenciaAngular(r, rumboGrados(p, s.ruta.destino.punto)),
            metros: _redondear(distanciaMetros(p, s.ruta.destino.punto)),
            nombre: widget.poi.nombre,
          ),
          _ => null,
        },
        alFallar: () {
          setState(() {
            _camaraFallo = true;
            _vista = _Vista.plano;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(txt.navCamaraNoDisponible)));
        },
      ),
      _ => Semantics(
        image: true,
        label: txt.navPlanoSemantica(widget.poi.nombre),
        child: PlanoRuta(
          plano: widget.plano,
          ruta: seguimiento == null
              ? const []
              : seguimiento.ruta.puntos.sublist(
                  seguimiento.objetivo.clamp(0, seguimiento.ruta.puntos.length),
                ),
          destino:
              seguimiento?.ruta.destino.punto ??
              widget.grafo.accesosDe(widget.poi.id).first.punto,
          posicion: lectura?.punto ?? previa?.punto,
          precision: lectura?.precision ?? previa?.precision,
          rumbo: rumbo,
          resaltado: _resaltado,
          trazo: _trazo ?? const [],
        ),
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // La indicación: lo que hay que hacer ahora, grande y en una región
        // viva para el lector de pantalla.
        _TarjetaDestacada(
          padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.26),
                  ),
                ),
                child: Icon(
                  _icono(maniobra),
                  size: 36,
                  color: ColoresUtb.texto,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(titular, style: textos.titleLarge),
                    ),
                    if (detalle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        detalle,
                        style: textos.bodyMedium?.copyWith(
                          color: ColoresUtb.textoSobreAzul,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (avisos.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final (icono, texto) in avisos)
                ChipEtiqueta(texto: texto, icono: icono),
            ],
          ),
        ],
        const SizedBox(height: 12),
        SegmentedButton<_Vista>(
          segments: [
            ButtonSegment(
              value: _Vista.plano,
              label: Text(txt.navPlano),
              icon: const Icon(Icons.map_rounded),
            ),
            ButtonSegment(
              value: _Vista.camara,
              label: Text(txt.navCamara),
              icon: const Icon(Icons.photo_camera_rounded),
              enabled: !_camaraFallo,
            ),
          ],
          selected: {_vista},
          onSelectionChanged: (s) => setState(() => _vista = s.first),
          expandedInsets: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        Expanded(child: vista),
        const SizedBox(height: 10),
        TarjetaUtb(
          radio: 22,
          padding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
          child: Row(
            children: [
              Expanded(
                child: _InterruptorEscaleras(
                  valor: _sinEscaleras,
                  alCambiar: _cambiarEscaleras,
                  compacto: true,
                ),
              ),
              const SizedBox(width: 4),
              TextButton(onPressed: _salir, child: Text(txt.navTerminar)),
            ],
          ),
        ),
      ],
    );
  }
}

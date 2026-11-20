import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../configuracion_tour.dart';
import '../../datos/modelos/modelos.dart';
import '../../datos/plano_campus.dart';
import '../../datos/proveedores.dart';
import '../../l10n/textos.dart';
import '../../navegacion/geo.dart';
import '../../navegacion/grafo_campus.dart';
import '../../navegacion/pantalla_activa.dart';
import '../../navegacion/seguimiento.dart';
import '../../navegacion/sensores.dart';
import '../../navegacion/voz_guia.dart';
import '../../nucleo/rutas.dart';
import '../../nucleo/tema.dart';
import '../comunes/componentes.dart';
import '../comunes/ilustracion_max.dart';
import '../ficha_poi.dart';
import '../vista_async.dart';
import 'plano_ruta.dart';
import 'vista_camara.dart';

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
  const PantallaNavegacion({super.key, required this.poiId});

  final int poiId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lugar = ref.watch(configuracionTourProvider).lugarId;
    final pois = ref.watch(poisProvider(lugar));
    final grafo = ref.watch(grafoCampusProvider);
    final plano = ref.watch(planoCampusProvider);
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
            poi: poi,
            paradas: [...lista.where((p) => p.esParada)],
            grafo: grafoCampus,
            plano: planoCampus,
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
  llegada,
}

enum _Vista { plano, camara }

class _Guia extends ConsumerStatefulWidget {
  const _Guia({
    required this.poi,
    required this.paradas,
    required this.grafo,
    required this.plano,
  });

  final Poi poi;
  final List<Poi> paradas;
  final GrafoCampus grafo;
  final PlanoCampus plano;

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
  late final FuenteRumbo _fuenteRumbo;
  late final VozGuia _voz;
  StreamSubscription<LecturaPosicion>? _subPosicion;
  StreamSubscription<LecturaRumbo>? _subRumbo;

  SeguimientoRuta? _seguimiento;
  LecturaRumbo? _rumbo;
  Maniobra? _anunciada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ubicacion = ref.read(fuenteUbicacionProvider);
    _fuenteRumbo = ref.read(fuenteRumboProvider(widget.grafo.declinacion));
    _voz = ref.read(vozGuiaProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pausar();
    super.dispose();
  }

  void _pausar({bool callar = true}) {
    _sesion++;
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
    } else if (_fase == _Fase.guiando) {
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
    unawaited(_pantalla.cambiar(true));
    _subPosicion = _ubicacion.lecturas().listen(
      (lectura) {
        if (sesion == _sesion) _alLeer(lectura);
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
      _pausar();
      setState(() => _fase = _Fase.sinRuta);
      return false;
    }
    final ubicacion = _ubicacion;
    if (ubicacion is UbicacionSimulada && _seguimiento == null) {
      ubicacion.camino = ruta.puntos;
    }
    _seguimiento = SeguimientoRuta(ruta);
    return true;
  }

  void _alLeer(LecturaPosicion lectura) {
    if (!mounted || !_enPrimerPlano || _fase != _Fase.guiando) return;
    if (_seguimiento == null && !_calcular(lectura.punto)) return;
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
      _pausar(callar: false);
      HapticFeedback.heavyImpact();
      _anunciar(Textos.of(context).navLlegaste(widget.poi.nombre));
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

  @override
  Widget build(BuildContext context) {
    final txt = Textos.of(context);
    final lugar = widget.poi.nombre;
    final arriba = MediaQuery.paddingOf(context).top;
    final abajo = MediaQuery.paddingOf(context).bottom;

    final contenido = switch (_fase) {
      _Fase.intro || _Fase.pidiendo => _Panel(
        pose: PoseMax.telefono,
        titulo: txt.navPermisoTitulo(lugar),
        texto: txt.navPermisoTexto,
        principal: (txt.navPermitir, _fase == _Fase.pidiendo ? null : _empezar),
      ),
      _Fase.sinPermiso => _Panel(
        pose: PoseMax.apenado,
        titulo: txt.navTitulo(lugar),
        texto: txt.navSinPermiso,
        principal: _permiso == PermisoUbicacion.denegadoSiempre
            ? (txt.navAbrirAjustes, _ubicacion.abrirAjustes)
            : (txt.navPermitir, _empezar),
        secundaria: _salidaAl360(txt),
      ),
      _Fase.gpsApagado => _Panel(
        pose: PoseMax.apenado,
        titulo: txt.navTitulo(lugar),
        texto: txt.navGpsApagado,
        principal: (txt.reintentar, _empezar),
        secundaria: _salidaAl360(txt),
      ),
      _Fase.sinRuta => _Panel(
        pose: PoseMax.pensativo,
        titulo: txt.navTitulo(lugar),
        texto: txt.navSinRuta(lugar),
        principal: (txt.volver, _salir),
        secundaria: _salidaAl360(txt),
      ),
      _Fase.llegada => _Panel(
        pose: PoseMax.invitando,
        titulo: txt.navLlegaste(lugar),
        texto: widget.poi.descripcion ?? '',
        principal: (
          txt.navVerFicha,
          () => abrirPoi(context, ref, poi: widget.poi, pois: widget.paradas),
        ),
        secundaria: (txt.navTerminar, _salir),
      ),
      _Fase.guiando => _vistaGuia(txt),
    };

    return Material(
      color: ColoresUtb.fondo,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          MedidasUtb.margen,
          arriba + 8,
          MedidasUtb.margen,
          abajo + 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                BotonCircular(
                  icono: Icons.arrow_back_rounded,
                  etiqueta: txt.volver,
                  alTocar: _salir,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      txt.navTitulo(lugar),
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(child: contenido),
          ],
        ),
      ),
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

    final String titular;
    if (seguimiento == null || lectura == null) {
      titular = txt.navBuscando;
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

    final rumboAlObjetivo = seguimiento?.rumboAlObjetivo;
    final rumbo = rumboNavegacion(lectura, _rumbo);
    final giro = (rumboAlObjetivo == null || rumbo == null)
        ? null
        : diferenciaAngular(rumbo, rumboAlObjetivo);

    final avisos = <(IconData, String)>[
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
          posicion: lectura?.punto,
          precision: lectura?.precision,
          rumbo: rumbo,
        ),
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // La indicación: lo que hay que hacer ahora, grande y en una región
        // viva para el lector de pantalla.
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ColoresUtb.destacadaInicio, ColoresUtb.destacadaFin],
            ),
            borderRadius: BorderRadius.circular(MedidasUtb.radioTarjeta),
          ),
          child: Row(
            children: [
              Icon(_icono(maniobra), size: 44, color: ColoresUtb.texto),
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
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: SwitchListTile(
                value: _sinEscaleras,
                onChanged: _cambiarEscaleras,
                secondary: const Icon(
                  Icons.accessible_rounded,
                  color: ColoresUtb.azulClaro,
                ),
                title: Text(txt.navSinEscaleras, style: textos.titleSmall),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            TextButton(onPressed: _salir, child: Text(txt.navTerminar)),
          ],
        ),
      ],
    );
  }
}

/// Un estado de la guía fuera del recorrido: pedir permiso, un fallo, la
/// llegada. Max pone la cara.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.pose,
    required this.titulo,
    required this.texto,
    required this.principal,
    this.secundaria,
  });

  final PoseMax pose;
  final String titulo;
  final String texto;
  final (String, VoidCallback?) principal;
  final (String, VoidCallback)? secundaria;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final paleta = PaletaUtb.de(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: IlustracionMax(pose: pose, alto: 210, difuminarBase: true),
          ),
          const SizedBox(height: 18),
          Semantics(
            header: true,
            child: Text(
              titulo,
              style: textos.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
          if (texto.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              texto,
              style: textos.bodyLarge?.copyWith(color: paleta.textoSecundario),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: principal.$2,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
            child: Text(principal.$1),
          ),
          if (secundaria case (final etiqueta, final accion)) ...[
            const SizedBox(height: 6),
            TextButton(onPressed: accion, child: Text(etiqueta)),
          ],
        ],
      ),
    );
  }
}

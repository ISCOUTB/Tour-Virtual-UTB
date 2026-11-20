import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../datos/georreferencia_3d.dart';
import '../../datos/modelos/modelos.dart';
import '../../l10n/textos.dart';
import '../../navegacion/geo.dart';
import '../../nucleo/movimiento.dart';
import '../../nucleo/tema.dart';

const archivoModelo3d =
    'packages/tour_virtual/assets/mapa3d/campus_elmapita.glb';

/// El mapa 2D se mantiene en plataformas sin WebView nativa.
bool get admiteMapa3d =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

final recursosMapa3dProvider = FutureProvider.autoDispose<String>((ref) async {
  await rootBundle.load(archivoModelo3d);
  return rootBundle.loadString('packages/tour_virtual/assets/mapa3d/visor.js');
});

/// Comandos explícitos: ningún dato de contenido se interpola como código.
class ControladorMapa3d {
  Future<void> Function(String)? _ejecutar;

  Future<void> _orden(String nombre, List<Object?> argumentos) async {
    await _ejecutar?.call(
      'window.tour3d.$nombre(${argumentos.map(jsonEncode).join(',')});',
    );
  }

  Future<void> vista(
    bool inclinada,
    PuntoGeo foco,
    double radio, {
    required bool quieto,
    bool instantaneo = false,
  }) {
    final p = Georreferencia3d.aModelo(foco.lat, foco.lng);
    return _orden('vista', [inclinada, p.x, p.z, radio, quieto, instantaneo]);
  }

  Future<void> centrar(Poi poi) {
    if (!poi.tienePosicionEnMapa) return Future<void>.value();
    final p = Georreferencia3d.aModelo(poi.lat!, poi.lng!);
    return _orden('centrar', [p.x, p.z]);
  }

  void zoom(double factor) => unawaited(_orden('zoom', [factor]));
  void girar(double grados) => unawaited(_orden('girar', [grados]));
  void verTodo() => unawaited(_orden('todo', []));
}

/// Visor local: el modelo y el motor WebGL van dentro del APK.
class MapaCampus3d extends ConsumerStatefulWidget {
  const MapaCampus3d({
    super.key,
    required this.pois,
    required this.visitados,
    required this.controlador,
    required this.alCargar,
    required this.alFallar,
    required this.alTocarPoi,
    required this.alMoverCamara,
  });

  final List<Poi> pois;
  final Set<int> visitados;
  final ControladorMapa3d controlador;
  final VoidCallback alCargar;
  final VoidCallback alFallar;
  final ValueChanged<Poi> alTocarPoi;
  final void Function(PuntoGeo, double) alMoverCamara;

  @override
  ConsumerState<MapaCampus3d> createState() => _MapaCampus3dState();
}

class _MapaCampus3dState extends ConsumerState<MapaCampus3d> {
  WebViewController? _web;
  Timer? _tiempoCarga;
  var _listo = false;
  var _fallo = false;
  String? _ultimaConfiguracion;

  @override
  void initState() {
    super.initState();
    _tiempoCarga = Timer(const Duration(seconds: 35), _fallar);
  }

  @override
  void dispose() {
    _tiempoCarga?.cancel();
    widget.controlador._ejecutar = null;
    super.dispose();
  }

  void _fallar() {
    if (!mounted || _fallo) return;
    _fallo = true;
    _tiempoCarga?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.alFallar();
    });
  }

  Future<void> _ejecutar(String codigo) async {
    if (!mounted || !_listo || _fallo) return;
    try {
      await _web?.runJavaScript(codigo);
    } catch (error) {
      debugPrint('Mapa 3D: $error');
      _fallar();
    }
  }

  Future<void> _recibir(JavaScriptMessage mensaje) async {
    if (!mounted || _fallo) return;
    try {
      final dato = jsonDecode(mensaje.message) as Map<String, dynamic>;
      switch (dato['tipo']) {
        case 'listo':
          _listo = true;
          _tiempoCarga?.cancel();
          widget.controlador._ejecutar = _ejecutar;
          await _configurar();
          if (mounted && !_fallo) widget.alCargar();
        case 'error':
          _fallar();
        case 'poi':
          final poi = widget.pois.where((p) => p.id == dato['id']).firstOrNull;
          if (poi != null) widget.alTocarPoi(poi);
        case 'camara':
          final x = dato['x'], z = dato['z'], radio = dato['radio'];
          if (x is num &&
              z is num &&
              radio is num &&
              x.isFinite &&
              z.isFinite &&
              radio.isFinite &&
              radio > 0) {
            widget.alMoverCamara(
              Georreferencia3d.aGeografico(x.toDouble(), z.toDouble()),
              radio.toDouble(),
            );
          }
      }
    } catch (error) {
      debugPrint('Mensaje del mapa 3D inválido: $error');
    }
  }

  String _configuracion() {
    final paradas = widget.pois.where((p) => p.esParada).toList();
    final txt = Textos.of(context);
    String etiqueta(Poi poi) {
      final nombre = poi.esParada
          ? txt.paradaSemantica(paradas.indexOf(poi) + 1, poi.nombre)
          : poi.nombre;
      return widget.visitados.contains(poi.id)
          ? txt.yaVisitado(nombre)
          : nombre;
    }

    return jsonEncode({
      'quieto': sinMovimiento(context),
      'norte': Georreferencia3d.norteCamara,
      'descripcion': Textos.of(context).mapa3dDescripcion,
      'escalaTexto': MediaQuery.textScalerOf(context).scale(14) / 14,
      'color':
          '#${(ColoresUtb.azul.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}',
      'texto': '#ffffff',
      'visitado':
          '#${(ColoresUtb.verde.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}',
      'pois': [
        for (final poi in widget.pois)
          if (poi.tienePosicionEnMapa && poi.lat!.isFinite && poi.lng!.isFinite)
            {
              'id': poi.id,
              'nombre': poi.nombre,
              'etiqueta': etiqueta(poi),
              'x': Georreferencia3d.aModelo(poi.lat!, poi.lng!).x,
              'z': Georreferencia3d.aModelo(poi.lat!, poi.lng!).z,
              'numero': poi.esParada ? paradas.indexOf(poi) + 1 : null,
              'visitado': widget.visitados.contains(poi.id),
            },
      ],
    });
  }

  Future<void> _configurar() async {
    if (!mounted || !_listo) return;
    final configuracion = _configuracion();
    if (configuracion == _ultimaConfiguracion) return;
    _ultimaConfiguracion = configuracion;
    await _ejecutar('window.tour3d.configurar($configuracion);');
  }

  @override
  Widget build(BuildContext context) {
    final recursos = ref.watch(recursosMapa3dProvider);
    if (recursos.hasError) {
      _fallar();
      return const SizedBox.shrink();
    }
    final js = recursos.valueOrNull;
    if (js == null) return const SizedBox.shrink();
    if (_listo) unawaited(_configurar());
    return ModelViewer(
      src: archivoModelo3d,
      alt: Textos.of(context).mapa3dDescripcion,
      backgroundColor: ColoresPlano.tierra,
      ar: false,
      autoRotate: false,
      cameraControls: true,
      disableTap: true,
      interactionPrompt: InteractionPrompt.none,
      cameraOrbit: '${Georreferencia3d.norteCamara}deg 0.1deg 1100m',
      minCameraOrbit: 'auto 0.1deg 70m',
      maxCameraOrbit: 'auto 80deg 2600m',
      cameraTarget: '138m 0m -154m',
      fieldOfView: '25deg',
      minFieldOfView: '25deg',
      maxFieldOfView: '25deg',
      shadowIntensity: 0.35,
      minHotspotOpacity: 1,
      maxHotspotOpacity: 1,
      exposure: 1.1,
      relatedJs: js,
      relatedCss: _estiloPines,
      debugLogging: false,
      javascriptChannels: {
        JavascriptChannel('TourMapa3d', onMessageReceived: _recibir),
      },
      onWebViewCreated: (web) => _web = web,
    );
  }
}

const _estiloPines = '''
model-viewer { --poster-color: transparent; }
.poi { min-width:48px; min-height:48px; padding:8px; border:2px solid white;
  border-radius:50%; background:var(--color-pin); color:var(--texto-pin);
  font:700 var(--tam-texto)/1 Roboto, sans-serif; cursor:pointer;
  box-shadow:0 3px 8px #0007; }
.poi:focus-visible { outline:3px solid #fff; outline-offset:4px; }
.poi.visitado { border-width:4px; background:var(--visitado); }
.poi.lugar { background:transparent; box-shadow:none; border:none; }
.poi.lugar::before { content:''; display:block; width:14px; height:14px;
  margin:auto; border-radius:50%; background:var(--color-pin); border:2px solid white; }
.poi[hidden] { display:none; }
''';

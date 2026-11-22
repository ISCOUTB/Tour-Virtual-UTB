import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

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
import '../comunes/componentes.dart';

const archivoModelo3d =
    'packages/tour_virtual/assets/mapa3d/campus_elmapita.glb';

/// El mapa 2D se mantiene en plataformas sin WebView nativa.
bool get admiteMapa3d =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Código y estilos del visor. El modelo solo se comprueba aquí: lo sirve
/// model_viewer_plus desde el bundle.
typedef RecursosMapa3d = ({String js, String css});

final recursosMapa3dProvider = FutureProvider.autoDispose<RecursosMapa3d>((
  ref,
) async {
  await rootBundle.load(archivoModelo3d);
  const carpeta = 'packages/tour_virtual/assets/mapa3d';
  return (
    js: await rootBundle.loadString('$carpeta/visor.js'),
    css: await rootBundle.loadString('$carpeta/visor.css'),
  );
});

/// Duraciones de los vuelos de cámara del visor.
abstract final class Vuelo3d {
  /// Inclinar al entrar: algo más que [Movimiento.largo], es un cambio de
  /// punto de vista y no un ajuste.
  static const inclinar = Duration(milliseconds: 900);

  /// Enderezar al salir, antes del fundido al plano.
  static const enderezar = Duration(milliseconds: 650);
}

/// Comandos explícitos: ningún dato de contenido se interpola como código.
class ControladorMapa3d {
  Future<void> Function(String)? _ejecutar;

  Future<void> _orden(String nombre, List<Object?> argumentos) async {
    await _ejecutar?.call(
      'window.tour3d.$nombre(${argumentos.map(jsonEncode).join(',')});',
    );
  }

  /// Encuadra [foco] con [alto] metros del modelo a la vista en vertical.
  ///
  /// Se habla en metros visibles y no en distancia de cámara: model-viewer
  /// ajusta el campo de visión a la proporción de la vista, y con un radio
  /// calculado aquí el 3D aparecía 1,6 veces más lejos que el plano.
  Future<void> vista(
    bool inclinada,
    PuntoGeo foco,
    double alto, {
    required bool quieto,
    bool instantaneo = false,
    Duration duracion = Vuelo3d.inclinar,
  }) {
    final p = Georreferencia3d.aModelo(foco.lat, foco.lng);
    return _orden('vista', [
      inclinada,
      p.x,
      p.z,
      alto,
      quieto,
      instantaneo,
      duracion.inMilliseconds,
    ]);
  }

  /// Vuela hasta [poi] y lo marca como elegido.
  Future<void> centrar(Poi poi) async {
    await seleccionar(poi);
    if (!poi.tienePosicionEnMapa) return;
    final p = Georreferencia3d.aModelo(poi.lat!, poi.lng!);
    await _orden('centrar', [p.x, p.z]);
  }

  Future<void> seleccionar(Poi? poi) => _orden('seleccionar', [poi?.id]);

  /// Zonas de la vista que tapan los controles de Flutter, en píxeles
  /// lógicos: ahí el visor no pone nombres.
  Future<void> reservar(List<Rect> zonas) => _orden('reservar', [
    [
      for (final z in zonas) [z.left, z.top, z.right, z.bottom],
    ],
  ]);

  void zoom(double factor) => unawaited(_orden('zoom', [factor]));
  void girar(double grados) => unawaited(_orden('girar', [grados]));
  void orientarNorte() => unawaited(_orden('norte', []));
  void verTodo() => unawaited(_orden('todo', []));
}

/// Encuadre de la cámara 3D que se devuelve a Flutter.
typedef Camara3d = ({PuntoGeo centro, double alto, double rumbo});

/// Visor local: el modelo y el motor WebGL van dentro del APK.
class MapaCampus3d extends ConsumerStatefulWidget {
  const MapaCampus3d({
    super.key,
    required this.pois,
    required this.visitados,
    required this.seleccion,
    required this.controlador,
    required this.alCargar,
    required this.alFallar,
    required this.alTocarPoi,
    required this.alMoverCamara,
  });

  final List<Poi> pois;
  final Set<int> visitados;

  /// Parada elegida en el carrusel: lleva su nombre y el pulso.
  final int? seleccion;
  final ControladorMapa3d controlador;
  final VoidCallback alCargar;
  final VoidCallback alFallar;
  final ValueChanged<Poi> alTocarPoi;
  final ValueChanged<Camara3d> alMoverCamara;

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
          final x = dato['x'], z = dato['z'];
          final alto = dato['alto'], rumbo = dato['rumbo'];
          if (x is num &&
              z is num &&
              alto is num &&
              rumbo is num &&
              x.isFinite &&
              z.isFinite &&
              alto.isFinite &&
              rumbo.isFinite &&
              alto > 0) {
            widget.alMoverCamara((
              centro: Georreferencia3d.aGeografico(x.toDouble(), z.toDouble()),
              alto: alto.toDouble(),
              rumbo: rumbo.toDouble(),
            ));
          }
      }
    } catch (error) {
      debugPrint('Mensaje del mapa 3D inválido: $error');
    }
  }

  Future<String> _configuracion() async {
    final paradas = widget.pois.where((p) => p.esParada).toList();
    final txt = Textos.of(context);
    final quieto = sinMovimiento(context);
    final contraste = PaletaUtb.de(context).altoContraste;
    final escalaTexto = MediaQuery.textScalerOf(context).scale(13) / 13;
    String etiqueta(Poi poi) {
      final nombre = poi.esParada
          ? txt.paradaSemantica(paradas.indexOf(poi) + 1, poi.nombre)
          : poi.categoria == null
          ? poi.nombre
          : '${poi.nombre}, ${EstiloCategoria.nombre(txt, poi.categoria!)}';
      return widget.visitados.contains(poi.id)
          ? txt.yaVisitado(nombre)
          : nombre;
    }

    final pois = [
      for (final poi in widget.pois)
        if (poi.tienePosicionEnMapa && poi.lat!.isFinite && poi.lng!.isFinite)
          poi,
    ];
    final iconos = {
      for (final poi in pois)
        if (!poi.esParada) poi.id: await _iconoCategoria(poi.categoria),
    };
    if (!mounted) return '';

    return jsonEncode({
      'quieto': quieto,
      'contraste': contraste,
      'norte': Georreferencia3d.norteCamara,
      'descripcion': txt.mapa3dDescripcion,
      'escalaTexto': escalaTexto,
      'color': _css(ColoresUtb.azul),
      'colorClaro': _css(Color.lerp(ColoresUtb.azul, Colors.white, 0.22)!),
      'visitado': _css(ColoresUtb.verde),
      'visitadoClaro': _css(Color.lerp(ColoresUtb.verde, Colors.white, 0.22)!),
      'seleccion': widget.seleccion,
      'pois': [
        for (final poi in pois)
          {
            'id': poi.id,
            'nombre': poi.nombre,
            'etiqueta': etiqueta(poi),
            'x': Georreferencia3d.aModelo(poi.lat!, poi.lng!).x,
            'z': Georreferencia3d.aModelo(poi.lat!, poi.lng!).z,
            'numero': poi.esParada ? paradas.indexOf(poi) + 1 : null,
            'visitado': widget.visitados.contains(poi.id),
            'icono': ?iconos[poi.id],
          },
      ],
    });
  }

  Future<void> _configurar() async {
    if (!mounted || !_listo) return;
    final configuracion = await _configuracion();
    if (!mounted || configuracion.isEmpty) return;
    if (configuracion == _ultimaConfiguracion) return;
    _ultimaConfiguracion = configuracion;
    await _ejecutar('window.tour3d.configurar($configuracion);');
  }

  @override
  void didUpdateWidget(MapaCampus3d anterior) {
    super.didUpdateWidget(anterior);
    // La selección viaja sola, sin rehacer los pines.
    if (anterior.seleccion != widget.seleccion && _listo) {
      final poi = widget.pois
          .where((p) => p.id == widget.seleccion)
          .firstOrNull;
      unawaited(widget.controlador.seleccionar(poi));
    }
  }

  @override
  Widget build(BuildContext context) {
    final recursos = ref.watch(recursosMapa3dProvider);
    if (recursos.hasError) {
      _fallar();
      return const SizedBox.shrink();
    }
    final codigo = recursos.valueOrNull;
    if (codigo == null) return const SizedBox.shrink();
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
      // Arranca cenital y sobre el norte, como el plano: el fundido de
      // entrada parte de ahí.
      cameraOrbit: '${Georreferencia3d.norteCamara}deg 0.1deg 1100m',
      // Sin pasar de 62°: más tumbada, la vista se llenaba de horizonte y el
      // campus quedaba en una franja.
      minCameraOrbit: 'auto 0.1deg 60m',
      maxCameraOrbit: 'auto 62deg 1500m',
      cameraTarget: '138m 0m -154m',
      fieldOfView: '25deg',
      minFieldOfView: '25deg',
      maxFieldOfView: '25deg',
      shadowIntensity: 0.35,
      minHotspotOpacity: 1,
      maxHotspotOpacity: 1,
      exposure: 1.35,
      relatedJs: codigo.js,
      relatedCss: codigo.css,
      debugLogging: false,
      javascriptChannels: {
        JavascriptChannel('TourMapa3d', onMessageReceived: _recibir),
      },
      onWebViewCreated: (web) => _web = web,
    );
  }
}

String _css(Color color) =>
    '#${(color.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}';

final _iconos = <String, Future<String>>{};

/// El icono de la categoría, en PNG, para el visor 3D.
///
/// Se dibuja con el mismo `IconData` y color del plano 2D: el WebView no
/// tiene la fuente de iconos de Material.
Future<String> _iconoCategoria(String? categoria) {
  final estilo = EstiloCategoria.de(categoria);
  final clave = '${estilo.icono.codePoint}-${estilo.color.toARGB32()}';
  return _iconos[clave] ??= () async {
    const lado = 48.0;
    final grabadora = ui.PictureRecorder();
    final pintor = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(estilo.icono.codePoint),
        style: TextStyle(
          fontFamily: estilo.icono.fontFamily,
          package: estilo.icono.fontPackage,
          fontSize: lado,
          height: 1,
          color: estilo.color,
        ),
      ),
    )..layout();
    pintor.paint(
      Canvas(grabadora),
      Offset((lado - pintor.width) / 2, (lado - pintor.height) / 2),
    );
    final imagen = await grabadora.endRecording().toImage(
      lado.toInt(),
      lado.toInt(),
    );
    final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
    imagen.dispose();
    return 'data:image/png;base64,${base64Encode(datos!.buffer.asUint8List())}';
  }();
}

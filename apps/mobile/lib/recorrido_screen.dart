import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panorama_viewer/panorama_viewer.dart' as pv;

import 'datos/modelos/modelos.dart';
import 'datos/proveedores.dart';
import 'ui/vista_async.dart';

/// Control de camara del visor 360.
///
/// `panorama_viewer` mueve la vista con el giroscopio a traves de
/// `dchs_motion_sensors`, que solo tiene implementacion en Android e iOS. En
/// escritorio y web ese canal no existe y el visor lanza MissingPluginException
/// en bucle hasta tumbar la aplicacion, asi que ahi se navega solo arrastrando.
pv.SensorControl get _controlDeSensores {
  if (kIsWeb) return pv.SensorControl.none;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS => pv.SensorControl.orientation,
    _ => pv.SensorControl.none,
  };
}

/// Visor 360 del recorrido de un lugar.
///
/// El recorrido completo se carga una sola vez y los saltos entre escenas se
/// resuelven en memoria, sin volver a la red.
class RecorridoScreen extends ConsumerWidget {
  const RecorridoScreen({
    super.key,
    required this.lugarId,
    this.escenaInicialId,
  });

  final int lugarId;

  /// Escena por la que entrar, cuando se llega desde un POI concreto del mapa.
  /// Si es nula, se arranca por la escena principal del lugar.
  final int? escenaInicialId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recorrido = ref.watch(recorridoProvider(lugarId));

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: VistaAsync<Recorrido>(
        valor: recorrido,
        sobreFondoOscuro: true,
        alReintentar: () => ref.invalidate(recorridoProvider(lugarId)),
        enDatos: (datos) =>
            _Visor(recorrido: datos, escenaInicialId: escenaInicialId),
      ),
    );
  }
}

class _Visor extends StatefulWidget {
  const _Visor({required this.recorrido, this.escenaInicialId});

  final Recorrido recorrido;
  final int? escenaInicialId;

  @override
  State<_Visor> createState() => _VisorState();
}

class _VisorState extends State<_Visor> {
  /// Escena a la que el usuario ha navegado con los hotspots.
  ///
  /// Nula mientras no se mueva, y entonces manda la que pidio la ruta. Vivio
  /// en un provider indexado por lugarId que se autoinicializaba a la escena
  /// principal del lugar: como nunca era nulo, la escena de la ruta no se
  /// llegaba a mirar y todos los POI abrian la Biblioteca.
  int? _elegida;

  @override
  Widget build(BuildContext context) {
    final recorrido = widget.recorrido;

    // Prioridad: lo que el usuario eligio navegando, luego la entrada que pide
    // la ruta, y por ultimo la escena principal del lugar.
    final escena = switch (_elegida ?? widget.escenaInicialId) {
      final int id => recorrido.escenaPorId(id) ?? recorrido.escenaInicial,
      null => recorrido.escenaInicial,
    };

    if (escena == null) {
      return const Center(
        child: Text(
          'Este recorrido todavia no tiene escenas publicadas.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final hotspots = recorrido.hotspotsDe(escena.id);

    return Stack(
      children: [
        _Panorama(
          // La clave fuerza a reconstruir el visor al cambiar de escena; sin
          // ella conserva la orientacion y la textura de la escena anterior.
          key: ValueKey(escena.id),
          escena: escena,
          hotspots: [
            for (final hotspot in hotspots)
              pv.Hotspot(
                latitude: hotspot.pitch,
                longitude: hotspot.yaw,
                width: 60,
                height: 60,
                widget: _BotonHotspot(
                  hotspot: hotspot,
                  alTocar: () => _tocarHotspot(context, hotspot),
                ),
              ),
          ],
        ),
        if (escena.nombre != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: Center(child: _EtiquetaEscena(texto: escena.nombre!)),
          ),
      ],
    );
  }

  void _tocarHotspot(BuildContext context, Hotspot hotspot) {
    switch (hotspot.tipo) {
      case TipoHotspot.navegacion:
        final destino = hotspot.escenaDestinoId;
        if (destino != null && widget.recorrido.escenaPorId(destino) != null) {
          setState(() => _elegida = destino);
        }
      case TipoHotspot.info:
        final poiId = hotspot.poiId;
        if (poiId != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(hotspot.etiqueta ?? 'Punto de interes'),
              ),
            );
        }
    }
  }
}

/// Visor 360 de una escena, con la carga de la panoramica resuelta aparte.
///
/// `PanoramaViewer` no dibuja su hijo en el arbol de widgets: lo usa como
/// fuente de textura y le pide el ImageProvider. Por eso `loadingBuilder` y
/// `errorBuilder` de un `Image.network` entregado ahi nunca se muestran, y una
/// panoramica que falla deja el area vacia sin explicacion alguna. La imagen se
/// resuelve aqui primero y el visor solo se construye cuando hay algo que
/// mostrar.
class _Panorama extends StatefulWidget {
  const _Panorama({super.key, required this.escena, required this.hotspots});

  final Escena escena;
  final List<pv.Hotspot> hotspots;

  @override
  State<_Panorama> createState() => _PanoramaState();
}

enum _EstadoPanorama { cargando, lista, fallida }

class _PanoramaState extends State<_Panorama> {
  ImageProvider? _proveedor;
  ImageStream? _flujo;
  ImageStreamListener? _oyente;
  var _estado = _EstadoPanorama.cargando;

  @override
  void initState() {
    super.initState();
    _resolver();
  }

  @override
  void dispose() {
    _desuscribir();
    super.dispose();
  }

  void _desuscribir() {
    if (_flujo != null && _oyente != null) {
      _flujo!.removeListener(_oyente!);
    }
    _flujo = null;
    _oyente = null;
  }

  /// Carga primero la version ligera y luego la completa.
  ///
  /// Una equirectangular de 4096 px tarda en llegar por una wifi compartida, y
  /// hasta ahora el usuario solo veia un indicador de progreso sin tamano. La
  /// ligera pesa unas veinte veces menos y deja ver la escena de inmediato.
  Future<void> _resolver() async {
    _desuscribir();
    setState(() => _estado = _EstadoPanorama.cargando);

    final baja = widget.escena.imagenUrlBaja;
    var hayAlgo = false;
    if (baja != null && baja.isNotEmpty) {
      hayAlgo = await _intentar(NetworkImage(baja));
    }

    final completa = await _intentar(NetworkImage(widget.escena.imagenUrl));

    // Solo es un fallo si no se pudo mostrar ninguna de las dos.
    if (!completa && !hayAlgo && mounted) {
      setState(() => _estado = _EstadoPanorama.fallida);
    }
  }

  /// Resuelve un proveedor y lo adopta si carga. Devuelve si lo consiguio.
  Future<bool> _intentar(ImageProvider proveedor) {
    final listo = Completer<bool>();
    late final ImageStreamListener oyente;

    void terminar(bool exito) {
      if (!listo.isCompleted) listo.complete(exito);
    }

    oyente = ImageStreamListener(
      (_, _) {
        if (mounted) {
          setState(() {
            _proveedor = proveedor;
            _estado = _EstadoPanorama.lista;
          });
        }
        terminar(true);
      },
      onError: (error, pila) {
        // Sin esto la excepcion sube al manejador global y el usuario solo ve
        // un area en blanco.
        debugPrint('Panoramica fallo: $error');
        terminar(false);
      },
    );

    final flujo = proveedor.resolve(const ImageConfiguration())
      ..addListener(oyente);

    return listo.future.whenComplete(() => flujo.removeListener(oyente));
  }

  @override
  Widget build(BuildContext context) {
    final proveedor = _proveedor;

    return switch (_estado) {
      _EstadoPanorama.cargando => const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      _EstadoPanorama.fallida => ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.white70,
                  size: 44,
                ),
                const SizedBox(height: 14),
                const Text(
                  'No pudimos cargar esta panoramica.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 18),
                FilledButton.tonalIcon(
                  onPressed: _resolver,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
      _EstadoPanorama.lista when proveedor != null => pv.PanoramaViewer(
        // Sin `animSpeed` el visor se queda quieto, que es el valor por
        // defecto del paquete. Antes se le pasaba 1.0 y la escena giraba sola
        // sin parar: arrastraba los hotspots fuera de cuadro, dejaba el
        // AnimationController en repeat() para siempre y era justo el
        // movimiento continuo que WCAG 2.2 pide no imponer. Ya no se pasa.
        longitude: widget.escena.vistaInicialYaw ?? 0,
        latitude: widget.escena.vistaInicialPitch ?? 0,
        sensorControl: _controlDeSensores,
        hotspots: widget.hotspots,
        child: Image(image: proveedor, fit: BoxFit.cover),
      ),
      _ => const ColoredBox(color: Colors.black),
    };
  }
}

class _BotonHotspot extends StatelessWidget {
  const _BotonHotspot({required this.hotspot, required this.alTocar});

  final Hotspot hotspot;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final esNavegacion = hotspot.tipo == TipoHotspot.navegacion;

    return Semantics(
      button: true,
      label:
          hotspot.etiqueta ??
          (esNavegacion ? 'Avanzar a la siguiente escena' : 'Ver informacion'),
      child: GestureDetector(
        onTap: alTocar,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xAA000000),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(
            esNavegacion
                ? Icons.keyboard_double_arrow_up
                : Icons.info_outline_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _EtiquetaEscena extends StatelessWidget {
  const _EtiquetaEscena({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          texto,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}

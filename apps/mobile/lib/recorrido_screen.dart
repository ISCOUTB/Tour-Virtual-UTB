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
        enDatos: (datos) => _Visor(
          lugarId: lugarId,
          recorrido: datos,
          escenaInicialId: escenaInicialId,
        ),
      ),
    );
  }
}

class _Visor extends ConsumerWidget {
  const _Visor({
    required this.lugarId,
    required this.recorrido,
    this.escenaInicialId,
  });

  final int lugarId;
  final Recorrido recorrido;
  final int? escenaInicialId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Prioridad: escena que el usuario eligio navegando, luego la de entrada
    // pedida por la ruta, y por ultimo la principal del lugar. Se resuelve al
    // leer y no escribiendo estado durante el build.
    final escenaId = ref.watch(escenaActualProvider(lugarId));
    final escena = switch (escenaId ?? escenaInicialId) {
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
                  alTocar: () => _tocarHotspot(context, ref, hotspot),
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

  void _tocarHotspot(BuildContext context, WidgetRef ref, Hotspot hotspot) {
    switch (hotspot.tipo) {
      case TipoHotspot.navegacion:
        final destino = hotspot.escenaDestinoId;
        if (destino != null && recorrido.escenaPorId(destino) != null) {
          ref.read(escenaActualProvider(lugarId).notifier).irA(destino);
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
  late ImageProvider _proveedor;
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

  void _resolver() {
    _desuscribir();
    setState(() => _estado = _EstadoPanorama.cargando);

    _proveedor = NetworkImage(widget.escena.imagenUrl);
    _oyente = ImageStreamListener(
      (_, _) {
        if (mounted) setState(() => _estado = _EstadoPanorama.lista);
      },
      onError: (error, pila) {
        // Sin esto la excepcion sube al manejador global y el usuario solo ve
        // un area en blanco.
        debugPrint('Panoramica ${widget.escena.imagenUrl} fallo: $error');
        if (mounted) setState(() => _estado = _EstadoPanorama.fallida);
      },
    );
    _flujo = _proveedor.resolve(const ImageConfiguration())
      ..addListener(_oyente!);
  }

  @override
  Widget build(BuildContext context) {
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
      _EstadoPanorama.lista => pv.PanoramaViewer(
        animSpeed: 1.0,
        sensorControl: _controlDeSensores,
        hotspots: widget.hotspots,
        child: Image(image: _proveedor, fit: BoxFit.cover),
      ),
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

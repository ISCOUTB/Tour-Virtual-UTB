import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';

import '../datos/modelos/modelos.dart';
import '../l10n/textos.dart';
import '../nucleo/movimiento.dart';
import '../nucleo/tema.dart';
import 'comunes/componentes.dart';
import 'comunes/fondos.dart';

/// Ventana a la panorámica de un lugar, encuadrada donde abre el visor 360.
///
/// No es una miniatura recortada al centro del archivo: usa el yaw y el pitch
/// calibrados de la escena, así que muestra exactamente lo que el usuario verá
/// al entrar. Con [interactiva] se gira arrastrando, con inercia, y el
/// panorama da la vuelta completa sin costuras.
///
/// Sin escena (todavía cargando, sin panorámica o en modo demo) dibuja una
/// postal de marca con el icono de la categoría, sin afirmar nada sobre el
/// lugar.
class PostalEscena extends StatefulWidget {
  const PostalEscena({
    super.key,
    required this.escena,
    required this.estilo,
    this.numero,
    this.interactiva = false,
    this.campoVision = 150,
  });

  final Escena? escena;
  final EstiloCategoria estilo;

  /// Número de parada para la postal sin foto.
  final int? numero;
  final bool interactiva;

  /// Grados horizontales visibles. Menos es más zoom.
  final double campoVision;

  @override
  State<PostalEscena> createState() => _PostalEscenaState();
}

class _PostalEscenaState extends State<PostalEscena>
    with SingleTickerProviderStateMixin {
  /// Grados girados por el usuario respecto al encuadre calibrado.
  double _giro = 0;
  double _anchoImagen = 1;
  var _fallo = false;

  late final AnimationController _inercia;

  @override
  void initState() {
    super.initState();
    // Se crea aquí y no de forma perezosa: un `late` sin usar se
    // inicializaría por primera vez en dispose, pidiendo un ticker a un
    // árbol que ya se está desmontando.
    _inercia = AnimationController.unbounded(vsync: this)
      ..addListener(() => setState(() => _giro = _inercia.value));
  }

  @override
  void dispose() {
    _inercia.dispose();
    super.dispose();
  }

  void _arrastrar(DragUpdateDetails d) {
    _inercia.stop();
    setState(() => _giro -= d.delta.dx / _anchoImagen * 360);
  }

  void _soltar(DragEndDetails d) {
    final grados = -d.velocity.pixelsPerSecond.dx / _anchoImagen * 360;
    _inercia.value = _giro;
    _inercia.animateWith(FrictionSimulation(0.12, _giro, grados));
  }

  /// Giro sin arrastrar, para el lector de pantalla y el acceso con
  /// interruptores (WCAG 2.5.7).
  void _girar(double grados) {
    _inercia.stop();
    final destino = _giro + grados;
    if (sinMovimiento(context)) {
      setState(() => _giro = destino);
      return;
    }
    _inercia.value = _giro;
    _inercia.animateTo(
      destino,
      duration: Movimiento.largo,
      curve: Movimiento.vaiven,
    );
  }

  @override
  Widget build(BuildContext context) {
    final escena = widget.escena;
    if (escena == null || _fallo) {
      return _PostalSinFoto(estilo: widget.estilo, numero: widget.numero);
    }

    final baja = escena.imagenUrlBaja;
    final ligera = NetworkImage(
      baja != null && baja.isNotEmpty ? baja : escena.imagenUrl,
    );
    // La ficha es grande: ahí se pide la completa, reducida a 2048 px para no
    // decodificar 32 MB en un teléfono de gama baja.
    final nitida = widget.interactiva
        ? ResizeImage(NetworkImage(escena.imagenUrl), width: 2048)
        : null;

    final ventana = LayoutBuilder(
      builder: (context, caja) {
        final w = caja.maxWidth;
        final h = caja.maxHeight;
        var anchoImg = w * 360 / widget.campoVision;
        if (anchoImg / 2 < h) anchoImg = h * 2;
        final altoImg = anchoImg / 2;
        _anchoImagen = anchoImg;

        final yaw = (escena.vistaInicialYaw ?? 0) + _giro;
        final pitch = escena.vistaInicialPitch ?? 0;
        final cx = (yaw + 180) / 360 * anchoImg;
        final cy = (90 - pitch) / 180 * altoImg;
        final arriba = (h / 2 - cy).clamp(h - altoImg, 0.0);
        final izquierda = (w / 2 - cx) % anchoImg;

        Widget capa(ImageProvider proveedor, {required bool base}) => Image(
          image: proveedor,
          width: anchoImg,
          height: altoImg,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          frameBuilder: (context, hijo, cuadro, sincrono) => AnimatedOpacity(
            opacity: cuadro == null && !sincrono ? 0 : 1,
            duration: const Duration(milliseconds: 380),
            child: hijo,
          ),
          errorBuilder: (context, error, pila) {
            // Solo la capa ligera decide el fallo: si la nítida no llega,
            // la ligera ya está a la vista.
            if (base) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _fallo = true);
              });
            }
            return const SizedBox.shrink();
          },
        );

        // Dos copias lado a lado: el panorama es cíclico y así el giro nunca
        // deja ver un borde.
        Widget franja(ImageProvider proveedor, {required bool base}) => Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: izquierda - anchoImg,
              top: arriba,
              child: capa(proveedor, base: base),
            ),
            Positioned(
              left: izquierda,
              top: arriba,
              child: capa(proveedor, base: base),
            ),
          ],
        );

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _PostalSinFoto.vacia(),
              franja(ligera, base: true),
              if (nitida != null) franja(nitida, base: false),
            ],
          ),
        );
      },
    );

    if (!widget.interactiva) return ventana;

    final txt = Textos.of(context);
    return Semantics(
      image: true,
      label: txt.vistaPanoramicaDe(escena.nombre ?? txt.esteLugar),
      hint: txt.deslizaParaGirar,
      customSemanticsActions: {
        CustomSemanticsAction(label: txt.girarIzquierda): () => _girar(-45),
        CustomSemanticsAction(label: txt.girarDerecha): () => _girar(45),
      },
      child: GestureDetector(
        onHorizontalDragUpdate: _arrastrar,
        onHorizontalDragEnd: _soltar,
        child: ventana,
      ),
    );
  }
}

class _PostalSinFoto extends StatelessWidget {
  const _PostalSinFoto({required this.estilo, this.numero}) : _vacia = false;

  /// Solo el fondo, para que la foto aparezca sobre él al cargar.
  const _PostalSinFoto.vacia()
    : estilo = const EstiloCategoria(ColoresUtb.azulClaro, Icons.place_rounded),
      numero = null,
      _vacia = true;

  final EstiloCategoria estilo;
  final int? numero;
  final bool _vacia;

  @override
  Widget build(BuildContext context) {
    return FondoCabeceraUtb(
      radioInferior: 0,
      child: _vacia
          ? const SizedBox.expand()
          // Se encoge para caber en postales pequeñas y con la letra grande
          // del sistema: el número es un adorno que el lector no lee.
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Icon(estilo.icono, color: ColoresUtb.texto),
                  ),
                  if (numero != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      numeroParada(numero!),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

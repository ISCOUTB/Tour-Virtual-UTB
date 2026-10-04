import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../datos/modelos/modelos.dart';
import '../datos/progreso.dart';
import '../datos/proveedores.dart';
import '../nucleo/rutas.dart';
import 'recorrido_completado.dart';
import 'reproductores.dart';
import 'vista_async.dart';

/// Abre un punto de interés y registra la visita (RF-19).
///
/// Es la puerta única desde el mapa y desde la lista del recorrido, para que
/// ambas superficies cuenten el progreso igual.
Future<void> abrirPoi(
  BuildContext context,
  WidgetRef ref, {
  required Poi poi,
  required int totalPois,
}) async {
  final progreso = ref.read(progresoProvider.notifier);
  // Milisegundos la primera vez, ya resuelto despues. Sin esperarlo, el
  // conjunto todavia vacio hacia pasar por nuevo un lugar ya visitado.
  await progreso.cargado;
  if (!context.mounted) return;

  final primeraVez = progreso.marcarVisitado(poi.id);

  await mostrarFichaPoi(
    context,
    poiId: poi.id,
    alVerEn360: () {
      // Cerrar la ficha antes de navegar: al volver del visor el usuario
      // espera el mapa, no una hoja abierta sobre él.
      Navigator.of(context).pop();
      context.push(
        Rutas.haciaRecorrido(poi.lugarId, escenaId: poi.escenaPrincipalId),
      );
    },
  );

  // El cierre se muestra al salir de la ficha y no encima de ella: apilar dos
  // hojas esconde justo el momento que se quiere celebrar.
  if (!primeraVez || !context.mounted) return;
  if (ref.read(progresoProvider).length >= totalPois) {
    await mostrarRecorridoCompletado(context);
  }
}

/// Abre la ficha de un punto de interés.
///
/// Es el paso intermedio que faltaba entre el mapa y el visor 360: antes, tocar
/// un marcador saltaba directo a descargar una panorámica a pantalla completa,
/// de modo que un POI sin panorámica no ofrecía absolutamente nada. La ficha
/// entrega lo que sí se sabe del lugar aunque el recorrido falle.
///
/// Cubre RF-12 a RF-17 del SRS v3.1.
Future<void> mostrarFichaPoi(
  BuildContext context, {
  required int poiId,
  required VoidCallback alVerEn360,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.38,
      maxChildSize: 0.95,
      builder: (context, control) =>
          _FichaPoi(poiId: poiId, control: control, alVerEn360: alVerEn360),
    ),
  );
}

class _FichaPoi extends ConsumerWidget {
  const _FichaPoi({
    required this.poiId,
    required this.control,
    required this.alVerEn360,
  });

  final int poiId;
  final ScrollController control;
  final VoidCallback alVerEn360;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalle = ref.watch(poiDetalleProvider(poiId));

    return VistaAsync<PoiDetalle>(
      valor: detalle,
      alReintentar: () => ref.invalidate(poiDetalleProvider(poiId)),
      enDatos: (datos) =>
          _Contenido(detalle: datos, control: control, alVerEn360: alVerEn360),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.detalle,
    required this.control,
    required this.alVerEn360,
  });

  final PoiDetalle detalle;
  final ScrollController control;
  final VoidCallback alVerEn360;

  @override
  Widget build(BuildContext context) {
    final poi = detalle.poi;
    final tema = Theme.of(context);

    return ListView(
      controller: control,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        Text(poi.nombre, style: tema.textTheme.headlineSmall),
        if (poi.categoria != null) ...[
          const SizedBox(height: 8),
          _Categoria(texto: poi.categoria!),
        ],
        const SizedBox(height: 18),

        // El contenido definitivo lo redacta Comunicaciones. Mientras no llegue,
        // la ficha lo dice en lugar de mostrar un hueco mudo.
        if (poi.descripcion case final texto?)
          Text(texto, style: tema.textTheme.bodyLarge)
        else
          const _Ausente(
            icono: Icons.notes_rounded,
            mensaje: 'Todavía no hay descripción de este lugar.',
          ),

        const SizedBox(height: 26),
        _Seccion(
          titulo: 'Galería',
          child: _Galeria(imagenes: detalle.imagenes),
        ),

        // El audio va justo detrás de la descripción y la galería: es el
        // contenido que sí existe para los cinco lugares, y dejarlo tras la
        // sección de video —vacía en todos— lo escondía bajo un hueco.
        const SizedBox(height: 26),
        _Seccion(
          titulo: 'Audio narrado',
          child: detalle.audio == null
              ? const _Ausente(
                  icono: Icons.volume_off_outlined,
                  mensaje: 'Este lugar aún no tiene audio narrado.',
                )
              : ReproductorAudio(medio: detalle.audio!),
        ),

        const SizedBox(height: 26),
        _Seccion(
          titulo: 'Video',
          child: detalle.video == null
              ? const _Ausente(
                  icono: Icons.videocam_off_outlined,
                  mensaje: 'Este lugar aún no tiene video.',
                )
              : ReproductorVideo(medio: detalle.video!),
        ),

        const SizedBox(height: 30),
        // Un POI sin escena no tiene nada que abrir: la ruta se quedaba sin
        // el parametro de escena y el visor caia a la escena principal del
        // lugar, es decir a otro sitio distinto del que se habia tocado.
        if (poi.escenaPrincipalId != null)
          FilledButton.icon(
            onPressed: alVerEn360,
            icon: const Icon(Icons.threesixty_rounded),
            label: const Text('Ver en 360'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          )
        else
          const _Ausente(
            icono: Icons.threesixty_outlined,
            mensaje: 'Este lugar todavía no tiene recorrido en 360.',
          ),
      ],
    );
  }
}

class _Categoria extends StatelessWidget {
  const _Categoria({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tema.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Text(
            texto,
            style: tema.textTheme.labelLarge?.copyWith(
              color: tema.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

/// Mensaje explícito para un recurso que no está disponible.
///
/// RF-16 lo exige con prioridad alta, y hoy es el caso corriente y no la
/// excepción: ningún POI tiene multimedia cargada todavía.
class _Ausente extends StatelessWidget {
  const _Ausente({required this.icono, required this.mensaje});

  final IconData icono;
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      children: [
        Icon(icono, size: 20, color: tema.colorScheme.outline),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            mensaje,
            style: tema.textTheme.bodyMedium?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Galería con desplazamiento horizontal (RF-15).
class _Galeria extends StatelessWidget {
  const _Galeria({required this.imagenes});

  final List<Medio> imagenes;

  @override
  Widget build(BuildContext context) {
    if (imagenes.isEmpty) {
      return const _Ausente(
        icono: Icons.image_not_supported_outlined,
        mensaje: 'Este lugar aún no tiene fotos.',
      );
    }

    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imagenes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _Miniatura(
          medio: imagenes[i],
          alTocar: () => _abrirPantallaCompleta(context, i),
        ),
      ),
    );
  }

  void _abrirPantallaCompleta(BuildContext context, int inicial) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _GaleriaCompleta(imagenes: imagenes, inicial: inicial),
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.medio, required this.alTocar});

  final Medio medio;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Semantics(
      button: true,
      // texto_alt es el campo que el panel de administración debe exigir antes
      // de publicar; si falta, al menos se anuncia que es una foto del lugar.
      label: medio.textoAlt ?? 'Foto del lugar',
      child: InkWell(
        onTap: alTocar,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: medio.url,
            width: 224,
            height: 168,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(
              width: 224,
              color: tema.colorScheme.surfaceContainerHighest,
            ),
            errorWidget: (_, _, _) => Container(
              width: 224,
              color: tema.colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.broken_image_outlined,
                color: tema.colorScheme.outline,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GaleriaCompleta extends StatelessWidget {
  const _GaleriaCompleta({required this.imagenes, required this.inicial});

  final List<Medio> imagenes;
  final int inicial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${inicial + 1} de ${imagenes.length}'),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: inicial),
        itemCount: imagenes.length,
        itemBuilder: (context, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: imagenes[i].url,
              fit: BoxFit.contain,
              errorWidget: (_, _, _) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'No pudimos cargar esta foto.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

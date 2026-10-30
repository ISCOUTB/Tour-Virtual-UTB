import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../datos/modelos/modelos.dart';
import '../datos/progreso.dart';
import '../datos/proveedores.dart';
import '../l10n/textos.dart';
import '../nucleo/errores.dart';
import '../nucleo/idiomas.dart';
import '../nucleo/rutas.dart';
import '../nucleo/tema.dart';
import 'comunes/componentes.dart';
import 'comunes/inclinable.dart';
import 'postal_escena.dart';
import 'recorrido_completado.dart';
import 'reproductores.dart';
import 'vista_async.dart';

/// Abre un punto de interés y registra la visita (RF-19).
///
/// Es la puerta única desde la lista, el mapa y el carrusel, para que todas
/// las superficies cuenten el progreso igual. [pois] son las paradas del
/// recorrido: dan el número de parada y deciden cuándo se completó. Un lugar
/// que no está entre ellas abre su ficha sin número y no cuenta como visita.
Future<void> abrirPoi(
  BuildContext context,
  WidgetRef ref, {
  required Poi poi,
  required List<Poi> pois,
}) async {
  final progreso = ref.read(progresoProvider.notifier);
  // Milisegundos la primera vez, ya resuelto despues. Sin esperarlo, el
  // conjunto todavia vacio hacia pasar por nuevo un lugar ya visitado.
  await progreso.cargado;
  if (!context.mounted) return;

  final indice = pois.indexWhere((p) => p.id == poi.id);
  final primeraVez = indice >= 0 && progreso.marcarVisitado(poi.id);

  await mostrarFichaPoi(
    context,
    poi: poi,
    numero: indice + 1,
    total: pois.length,
    alVerEn360: () {
      // Cerrar la ficha antes de navegar: al volver del visor el usuario
      // espera la lista o el mapa, no una hoja abierta encima.
      Navigator.of(context).pop();
      context.push(
        Rutas.haciaRecorrido(poi.lugarId, escenaId: poi.escenaPrincipalId),
      );
    },
  );

  // El cierre se muestra al salir de la ficha y no encima de ella: apilar dos
  // hojas esconde justo el momento que se quiere celebrar.
  if (!primeraVez || !context.mounted) return;
  final visibles = pois.map((p) => p.id).toSet();
  final vistos = ref.read(progresoProvider).where(visibles.contains).length;
  if (vistos >= pois.length) await mostrarRecorridoCompletado(context);
}

/// Ficha de un punto de interés (RF-12 a RF-17 del SRS v3.1).
///
/// Es el paso intermedio entre la lista o el mapa y el visor 360: entrega lo
/// que sí se sabe del lugar aunque la panorámica falle. Se abre con los datos
/// que ya trae la lista, así que el título aparece sin esperar a la red.
Future<void> mostrarFichaPoi(
  BuildContext context, {
  required Poi poi,
  required int numero,
  required int total,
  required VoidCallback alVerEn360,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.42,
      maxChildSize: 0.96,
      builder: (context, control) => _FichaPoi(
        poi: poi,
        numero: numero,
        total: total,
        control: control,
        alVerEn360: alVerEn360,
      ),
    ),
  );
}

class _FichaPoi extends ConsumerWidget {
  const _FichaPoi({
    required this.poi,
    required this.numero,
    required this.total,
    required this.control,
    required this.alVerEn360,
  });

  final Poi poi;
  final int numero;
  final int total;
  final ScrollController control;
  final VoidCallback alVerEn360;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalle = ref.watch(poiDetalleProvider(poi.id));
    final actual = detalle.valueOrNull?.poi ?? poi;
    final escena = escenaPrincipalDe(ref, actual);
    final estilo = EstiloCategoria.de(actual.categoria);
    final textos = Theme.of(context).textTheme;
    final txt = Textos.of(context);
    final paleta = PaletaUtb.de(context);
    final abajo = MediaQuery.paddingOf(context).bottom;
    final idiomaContenido = ref
        .watch(repositorioContenidoProvider)
        .idiomaContenido;
    final ui = Localizations.localeOf(context);

    final sobretitulo = [
      if (actual.categoria != null)
        EstiloCategoria.nombre(txt, actual.categoria!),
      if (numero > 0) txt.paradaNDeTotal(numero, total),
    ].join(' · ');

    return ListView(
      controller: control,
      padding: EdgeInsets.fromLTRB(
        MedidasUtb.margen,
        0,
        MedidasUtb.margen,
        28 + abajo,
      ),
      children: [
        _Postal(
          escena: escena,
          estilo: estilo,
          numero: numero > 0 ? numero : null,
        ),
        const SizedBox(height: 22),
        if (sobretitulo.isNotEmpty) ...[
          Row(
            children: [
              Icon(estilo.icono, size: 16, color: estilo.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mayusculasDe(context, sobretitulo),
                  style: estiloSobretitulo(color: paleta.textoSecundario),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Semantics(
          header: true,
          child: TextoDeContenido(actual.nombre, style: textos.headlineMedium),
        ),
        const SizedBox(height: 12),

        // El contenido definitivo lo redacta Comunicaciones. Mientras no
        // llegue, la ficha lo dice en lugar de mostrar un hueco mudo.
        if (actual.descripcion case final texto?) ...[
          TextoDeContenido(
            texto,
            style: textos.bodyLarge?.copyWith(
              color: paleta.altoContraste
                  ? ColoresUtb.texto
                  : Colors.white.withValues(alpha: 0.86),
            ),
          ),
          // Mientras el servidor no traduzca, la descripción llega en
          // español: se dice, en vez de dejar a quien no lo lee con un
          // párrafo que no entiende y sin saber por qué.
          if (!mismoIdioma(idiomaContenido, ui.languageCode)) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.translate_rounded,
                  size: 16,
                  color: paleta.textoSecundario,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    txt.textoEnIdioma(nombreDeIdioma(idiomaContenido)),
                    style: textos.bodySmall?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ] else
          Text(
            txt.sinDescripcion,
            style: textos.bodyLarge?.copyWith(color: paleta.textoSecundario),
          ),
        const SizedBox(height: 22),

        // Un POI sin escena no tiene nada que abrir: la ruta se quedaba sin
        // el parámetro de escena y el visor caía a la escena principal del
        // lugar, es decir a otro sitio distinto del que se había tocado.
        if (actual.escenaPrincipalId != null)
          FilledButton.icon(
            onPressed: alVerEn360,
            icon: const Icon(Icons.threesixty_rounded),
            label: Text(txt.verEn360),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
          )
        else
          RecuadroInfo(icono: Icons.threesixty_rounded, texto: txt.sin360),

        const SizedBox(height: 28),
        ...detalle.when(
          data: (d) => _medios(context, txt, ui, d),
          loading: () => const [
            BloqueEsqueleto(alto: 84, radio: 22),
            SizedBox(height: 12),
            BloqueEsqueleto(alto: 64, radio: 18),
          ],
          error: (error, _) => [
            VistaError(
              fallo: traducirFallo(error),
              alReintentar: () => ref.invalidate(poiDetalleProvider(poi.id)),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _medios(
    BuildContext context,
    Textos txt,
    Locale ui,
    PoiDetalle d,
  ) {
    final audio = d.audioPara(ui.toLanguageTag());
    // Una lista y no una frase: «fotos, video ni audio» no se traduce
    // palabra por palabra, y cada idioma enumera a su manera.
    final faltan = [
      if (d.imagenes.isEmpty) txt.fotos,
      if (d.video == null) txt.video,
      if (audio == null) txt.audioNarrado,
    ];

    // El audio va primero: es el medio que sí existe para los cinco lugares,
    // y detrás del video —vacío en todos— quedaba escondido bajo un hueco.
    return [
      if (audio != null) ...[
        _Seccion(txt.audioNarrado),
        ReproductorAudio(audios: d.audios, inicial: audio),
        const SizedBox(height: 26),
      ],
      // El video en Lengua de Señas Colombiana va justo después: para quien
      // la usa es la narración.
      if (d.videoSenas != null) ...[
        _Seccion(txt.lenguaDeSenas, icono: Icons.sign_language_rounded),
        ReproductorVideo(medio: d.videoSenas!),
        const SizedBox(height: 26),
      ],
      if (d.imagenes.isNotEmpty) ...[
        _Seccion(txt.galeria),
        _Galeria(imagenes: d.imagenes),
        const SizedBox(height: 26),
      ],
      if (d.video != null) ...[
        _Seccion(txt.video),
        ReproductorVideo(medio: d.video!),
        const SizedBox(height: 26),
      ],
      // RF-16: un recurso que no existe se nombra, no se calla. Hoy es el
      // caso corriente, así que va en un solo recuadro y no en tres huecos.
      if (faltan.isNotEmpty)
        RecuadroInfo(
          icono: Icons.hourglass_empty_rounded,
          encabezado: txt.contenidoEnPreparacion,
          texto: txt.todaviaNoHay(faltan.join(' · ')),
        ),
    ];
  }
}

class _Postal extends StatelessWidget {
  const _Postal({
    required this.escena,
    required this.estilo,
    required this.numero,
  });

  final Escena? escena;
  final EstiloCategoria estilo;

  /// Nulo en un lugar que no es parada.
  final int? numero;

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(24);

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Inclinable(
        maximo: 0.07,
        radio: radio,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radio,
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PostalEscena(
                  escena: escena,
                  estilo: estilo,
                  numero: numero,
                  interactiva: true,
                ),
                if (escena != null)
                  const Positioned(
                    left: 12,
                    bottom: 12,
                    child: IgnorePointer(child: _PistaGiro()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PistaGiro extends StatelessWidget {
  const _PistaGiro();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: PaletaUtb.de(context).veloOscuro,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swipe_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                Textos.of(context).deslizaParaMirar,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.titulo, {this.icono});

  final String titulo;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final color = PaletaUtb.de(context).textoSecundario;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            if (icono != null) ...[
              Icon(icono, size: 20, color: color),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                titulo,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Galería con desplazamiento horizontal (RF-15).
class _Galeria extends StatelessWidget {
  const _Galeria({required this.imagenes});

  final List<Medio> imagenes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imagenes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _Miniatura(
          medio: imagenes[i],
          alTocar: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              fullscreenDialog: true,
              builder: (_) => _GaleriaCompleta(imagenes: imagenes, inicial: i),
            ),
          ),
        ),
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
    final radio = BorderRadius.circular(20);
    const vacio = ColoredBox(color: ColoresUtb.superficie);

    return Semantics(
      button: true,
      // texto_alt es el campo que el panel de administración debe exigir antes
      // de publicar; si falta, al menos se anuncia que es una foto del lugar.
      label: medio.textoAlt ?? Textos.of(context).fotoDelLugar,
      onTap: alTocar,
      excludeSemantics: true,
      child: InkWell(
        onTap: alTocar,
        borderRadius: radio,
        child: ClipRRect(
          borderRadius: radio,
          child: CachedNetworkImage(
            imageUrl: medio.url,
            width: 210,
            height: 150,
            fit: BoxFit.cover,
            placeholder: (_, _) => const SizedBox(width: 210, child: vacio),
            errorWidget: (_, _, _) => const SizedBox(
              width: 210,
              child: ColoredBox(
                color: ColoresUtb.superficie,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: ColoresUtb.textoTerciario,
                ),
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
        title: Text(
          Textos.of(context).fotoNDeTotal(inicial + 1, imagenes.length),
        ),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: inicial),
        itemCount: imagenes.length,
        itemBuilder: (context, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Semantics(
              image: true,
              label: imagenes[i].textoAlt ?? Textos.of(context).fotoDelLugar,
              child: CachedNetworkImage(
                imageUrl: imagenes[i].url,
                fit: BoxFit.contain,
                errorWidget: (context, _, _) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    Textos.of(context).fotoNoCargo,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

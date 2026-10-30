import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../datos/modelos/modelos.dart';
import '../datos/preferencias.dart';
import '../datos/proveedores.dart';
import '../datos/subtitulos.dart';
import '../l10n/textos.dart';
import '../nucleo/idiomas.dart';
import '../nucleo/movimiento.dart';
import '../nucleo/tema.dart';
import 'comunes/componentes.dart';
import 'vista_async.dart';

String _formato(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Mensaje de fallo compartido por ambos reproductores.
///
/// Un recurso multimedia que no carga tiene que decirlo (RF-16). Es el caso
/// corriente mientras el contenido institucional no esté publicado.
class _FalloMedio extends StatelessWidget {
  const _FalloMedio({required this.mensaje, required this.alReintentar});

  final String mensaje;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    return RecuadroInfo(
      icono: Icons.error_outline_rounded,
      texto: mensaje,
      accion: TextButton(
        onPressed: alReintentar,
        child: Text(Textos.of(context).reintentar),
      ),
    );
  }
}

/// Video del POI reproducido dentro de la propia pantalla (RF-13).
///
/// Si el medio trae subtítulos, se dibujan sobre la imagen mientras suena,
/// con el mismo interruptor que el audio.
class ReproductorVideo extends ConsumerStatefulWidget {
  const ReproductorVideo({super.key, required this.medio});

  final Medio medio;

  @override
  ConsumerState<ReproductorVideo> createState() => _ReproductorVideoState();
}

class _ReproductorVideoState extends ConsumerState<ReproductorVideo> {
  VideoPlayerController? _control;
  Object? _fallo;

  @override
  void initState() {
    super.initState();
    _preparar();
  }

  @override
  void dispose() {
    _control?.dispose();
    super.dispose();
  }

  Future<void> _preparar() async {
    setState(() => _fallo = null);
    final anterior = _control;
    _control = null;
    await anterior?.dispose();

    final c = VideoPlayerController.networkUrl(Uri.parse(widget.medio.url));
    try {
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => _control = c);
    } catch (error) {
      debugPrint('Video ${widget.medio.url} fallo: $error');
      await c.dispose();
      if (mounted) setState(() => _fallo = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final txt = Textos.of(context);
    if (_fallo != null) {
      return _FalloMedio(mensaje: txt.videoNoCargo, alReintentar: _preparar);
    }

    final c = _control;
    if (c == null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: BloqueEsqueleto(alto: double.infinity, radio: 22),
      );
    }

    final subtitulos = widget.medio.subtitulosUrl;
    final mostrar = ref.watch(preferenciasProvider.select((p) => p.subtitulos));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
            aspectRatio: c.value.aspectRatio,
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: c,
              builder: (context, valor, _) => Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(c),
                  if (subtitulos != null && mostrar)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 18,
                      child: _SubtitulosEnVivo(
                        url: subtitulos,
                        posicion: valor.position,
                        activo:
                            valor.isPlaying || valor.position > Duration.zero,
                        sobreImagen: true,
                      ),
                    ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: VideoProgressIndicator(
                      c,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: ColoresUtb.azulClaro,
                        bufferedColor: Color(0x55FFFFFF),
                        backgroundColor: Color(0x24FFFFFF),
                      ),
                    ),
                  ),
                  IconButton.filled(
                    iconSize: 36,
                    tooltip: valor.isPlaying
                        ? txt.pausarVideo
                        : txt.reproducirVideo,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.55),
                      minimumSize: const Size.square(64),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                    ),
                    onPressed: () => valor.isPlaying ? c.pause() : c.play(),
                    icon: Icon(
                      valor.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (subtitulos != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _Transcripcion(
                  url: subtitulos,
                  idioma: widget.medio.idiomaEfectivo,
                ),
              ),
              const _BotonSubtitulos(),
            ],
          ),
        ],
      ],
    );
  }
}

/// Audio narrado con reproducir, pausar y reanudar (RF-14).
///
/// Cada lugar puede tener una narración por idioma. Suena primero la del
/// idioma de quien escucha y, si hay varias, se puede cambiar. Mientras
/// suena, los subtítulos muestran cada frase (WCAG 1.2.2): quien no oye, o
/// está en un lugar con ruido, sigue la historia igual.
class ReproductorAudio extends ConsumerStatefulWidget {
  const ReproductorAudio({
    super.key,
    required this.audios,
    required this.inicial,
  });

  /// Todas las narraciones del lugar.
  final List<Medio> audios;

  /// La que suena al abrir: la del idioma de la interfaz si existe.
  final Medio inicial;

  @override
  ConsumerState<ReproductorAudio> createState() => _ReproductorAudioState();
}

class _ReproductorAudioState extends ConsumerState<ReproductorAudio> {
  final _reproductor = AudioPlayer();
  late Medio _actual = widget.inicial;
  Object? _fallo;

  @override
  void initState() {
    super.initState();
    _preparar();
  }

  @override
  void dispose() {
    _reproductor.dispose();
    super.dispose();
  }

  Future<void> _preparar() async {
    setState(() => _fallo = null);
    try {
      await _reproductor.setUrl(_actual.url);
    } catch (error) {
      debugPrint('Audio ${_actual.url} fallo: $error');
      if (mounted) setState(() => _fallo = error);
    }
  }

  Future<void> _cambiar(Medio medio) async {
    if (medio.id == _actual.id) return;
    await _reproductor.stop();
    setState(() => _actual = medio);
    await _preparar();
  }

  @override
  Widget build(BuildContext context) {
    final txt = Textos.of(context);
    if (_fallo != null) {
      // `just_audio` se reparte en paquetes por plataforma y no todas tienen
      // implementacion: sin la suya el canal nativo no existe y la llamada
      // revienta con MissingPluginException. Decir «no pudimos cargar el
      // audio» ahi manda a buscar un fallo de red que no existe.
      final sinSoporte = _fallo is MissingPluginException;
      return _FalloMedio(
        mensaje: sinSoporte ? txt.audioSinSoporte : txt.audioNoCargo,
        alReintentar: _preparar,
      );
    }

    final textos = Theme.of(context).textTheme;
    final paleta = PaletaUtb.de(context);
    final ui = Localizations.localeOf(context);
    final subtitulos = _actual.subtitulosUrl;
    final mostrarSubtitulos = ref.watch(
      preferenciasProvider.select((p) => p.subtitulos),
    );

    return TarjetaUtb(
      radio: 22,
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.audios.length > 1)
            _SelectorIdioma(
              audios: widget.audios,
              actual: _actual,
              alElegir: _cambiar,
            )
          else if (!mismoIdioma(_actual.idiomaEfectivo, ui.languageCode))
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 0, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.translate_rounded,
                    size: 16,
                    color: paleta.textoSecundario,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      txt.narracionEn(nombreDeIdioma(_actual.idiomaEfectivo)),
                      style: textos.bodySmall?.copyWith(
                        color: paleta.textoSecundario,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          StreamBuilder<PlayerState>(
            stream: _reproductor.playerStateStream,
            builder: (context, estado) {
              final sonando = estado.data?.playing ?? false;
              return StreamBuilder<Duration>(
                stream: _reproductor.positionStream,
                builder: (context, posicion) {
                  final pos = posicion.data ?? Duration.zero;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _controles(context, sonando, pos),
                      if (subtitulos != null && mostrarSubtitulos)
                        _SubtitulosEnVivo(
                          url: subtitulos,
                          posicion: pos,
                          activo: sonando || pos > Duration.zero,
                        ),
                    ],
                  );
                },
              );
            },
          ),
          const Divider(height: 17),
          Row(
            children: [
              Expanded(
                child: _Transcripcion(
                  url: subtitulos,
                  idioma: _actual.idiomaEfectivo,
                ),
              ),
              if (subtitulos != null) const _BotonSubtitulos(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _controles(BuildContext context, bool sonando, Duration pos) {
    final txt = Textos.of(context);
    final textos = Theme.of(context).textTheme;
    final paleta = PaletaUtb.de(context);
    final total = _reproductor.duration ?? Duration.zero;
    final maximo = total.inMilliseconds.toDouble();

    return Row(
      children: [
        IconButton.filled(
          iconSize: 30,
          tooltip: sonando ? txt.pausarAudio : txt.escucharHistoria,
          style: IconButton.styleFrom(
            backgroundColor: ColoresUtb.azul,
            foregroundColor: ColoresUtb.texto,
            minimumSize: const Size.square(56),
          ),
          onPressed: () => sonando ? _reproductor.pause() : _reproductor.play(),
          icon: AnimatedSwitcher(
            duration: sinMovimiento(context) ? Duration.zero : Movimiento.corto,
            transitionBuilder: (hijo, animacion) =>
                ScaleTransition(scale: animacion, child: hijo),
            child: Icon(
              sonando ? Icons.pause_rounded : Icons.play_arrow_rounded,
              key: ValueKey(sonando),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Wrap(
                  spacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text(
                      sonando ? txt.escuchando : txt.escucharHistoria,
                      style: textos.titleSmall,
                    ),
                    // El deslizador ya da la posición al lector de pantalla.
                    ExcludeSemantics(
                      child: Text(
                        '${_formato(pos)} / ${_formato(total)}',
                        style: textos.labelMedium?.copyWith(
                          color: paleta.textoSecundario,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Slider(
                value: maximo == 0
                    ? 0
                    : pos.inMilliseconds
                          .clamp(0, total.inMilliseconds)
                          .toDouble(),
                max: maximo == 0 ? 1 : maximo,
                semanticFormatterCallback: (_) =>
                    txt.posicionDeTotal(_formato(pos), _formato(total)),
                onChanged: maximo == 0
                    ? null
                    : (v) =>
                          _reproductor.seek(Duration(milliseconds: v.round())),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Narraciones disponibles, cada una con el nombre de su idioma escrito en
/// ese idioma.
class _SelectorIdioma extends StatelessWidget {
  const _SelectorIdioma({
    required this.audios,
    required this.actual,
    required this.alElegir,
  });

  final List<Medio> audios;
  final Medio actual;
  final ValueChanged<Medio> alElegir;

  @override
  Widget build(BuildContext context) {
    final txt = Textos.of(context);
    final paleta = PaletaUtb.de(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            txt.escucharEn,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: paleta.textoSecundario),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final audio in audios)
                ChoiceChip(
                  selected: audio.id == actual.id,
                  onSelected: (_) => alElegir(audio),
                  showCheckmark: false,
                  label: Semantics(
                    attributedLabel: atribuirIdioma(
                      nombreDeIdioma(audio.idiomaEfectivo),
                      localeDeEtiqueta(audio.idiomaEfectivo),
                    ),
                    excludeSemantics: true,
                    child: Text(
                      nombreDeIdioma(audio.idiomaEfectivo),
                      locale: localeDeEtiqueta(audio.idiomaEfectivo),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Interruptor de subtítulos, compartido por todos los reproductores: quien
/// los necesita los quiere en todos, y quien los apaga, también.
class _BotonSubtitulos extends ConsumerWidget {
  const _BotonSubtitulos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activos = ref.watch(preferenciasProvider.select((p) => p.subtitulos));
    final txt = Textos.of(context);
    return Semantics(
      toggled: activos,
      child: IconButton(
        tooltip: txt.subtitulos,
        isSelected: activos,
        color: PaletaUtb.de(context).textoSecundario,
        selectedIcon: const Icon(
          Icons.closed_caption_rounded,
          color: ColoresUtb.azulClaro,
        ),
        icon: const Icon(Icons.closed_caption_off_outlined),
        onPressed: () =>
            ref.read(preferenciasProvider.notifier).cambiarSubtitulos(!activos),
      ),
    );
  }
}

/// La frase que suena en este momento.
///
/// No es una región viva: el lector de pantalla leería cada frase encima de
/// la propia narración. Quien usa lector tiene la transcripción completa.
class _SubtitulosEnVivo extends ConsumerWidget {
  const _SubtitulosEnVivo({
    required this.url,
    required this.posicion,
    required this.activo,
    this.sobreImagen = false,
  });

  final String url;
  final Duration posicion;

  /// Si ya empezó a sonar. Antes de eso no se reserva espacio.
  final bool activo;

  /// Sobre el video: fondo opaco para leerse sobre cualquier imagen.
  final bool sobreImagen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitulos = ref.watch(subtitulosProvider(url)).valueOrNull;
    if (!activo || subtitulos == null || !subtitulos.sincronizados) {
      return const SizedBox.shrink();
    }

    final linea = subtitulos.en(posicion);
    final estilo = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: ColoresUtb.texto,
      fontWeight: FontWeight.w500,
      height: 1.35,
    );

    if (sobreImagen) {
      if (linea == null) return const SizedBox.shrink();
      return Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              linea.texto,
              textAlign: TextAlign.center,
              style: estilo,
            ),
          ),
        ),
      );
    }

    // Dos líneas reservadas: sin ellas la tarjeta saltaba de alto con cada
    // frase y los controles se movían bajo el dedo.
    final reserva = MediaQuery.textScalerOf(context).scale(16) * 1.35 * 2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 0, 6),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: reserva),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3, right: 10),
              child: Icon(
                Icons.closed_caption_rounded,
                size: 18,
                color: PaletaUtb.de(context).textoSecundario,
              ),
            ),
            Expanded(child: Text(linea?.texto ?? '', style: estilo)),
          ],
        ),
      ),
    );
  }
}

/// Alternativa en texto del audio narrado (WCAG 2.2, 1.2.1).
///
/// Hoy ningún audio tiene `subtitulos_url`: la tarjeta lo dice, igual que la
/// ficha dice qué contenido falta, en lugar de callarlo.
class _Transcripcion extends StatelessWidget {
  const _Transcripcion({required this.url, required this.idioma});

  final String? url;

  /// Idioma del medio, que es el de su transcripción.
  final String idioma;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final txt = Textos.of(context);
    final paleta = PaletaUtb.de(context);
    final url = this.url;

    if (url == null || url.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 0, 8),
        child: Row(
          children: [
            Icon(
              Icons.subtitles_off_outlined,
              size: 18,
              color: paleta.textoTenue,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                txt.transcripcionEnPreparacion,
                style: textos.bodySmall?.copyWith(color: paleta.textoTenue),
              ),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => _HojaTranscripcion(url: url, idioma: idioma),
        ),
        icon: const Icon(Icons.subtitles_outlined),
        label: Text(txt.leerTranscripcion),
      ),
    );
  }
}

class _HojaTranscripcion extends ConsumerWidget {
  const _HojaTranscripcion({required this.url, required this.idioma});

  final String url;
  final String idioma;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final txt = Textos.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, control) => VistaAsync<Subtitulos>(
        valor: ref.watch(subtitulosProvider(url)),
        alReintentar: () => ref.invalidate(subtitulosProvider(url)),
        enDatos: (subtitulos) => ListView(
          controller: control,
          padding: const EdgeInsets.fromLTRB(
            MedidasUtb.margen,
            0,
            MedidasUtb.margen,
            32,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(txt.transcripcion, style: textos.headlineSmall),
            ),
            const SizedBox(height: 14),
            // El idioma va en el tramo: el lector de pantalla lo lee con la
            // voz de la narración aunque la interfaz esté en otro.
            SelectableText.rich(
              TextSpan(
                text: subtitulos.texto,
                locale: localeDeEtiqueta(idioma),
              ),
              style: textos.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

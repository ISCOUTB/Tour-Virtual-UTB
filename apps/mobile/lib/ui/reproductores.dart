import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../datos/modelos/modelos.dart';

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
    final tema = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: tema.colorScheme.outline),
          const SizedBox(width: 12),
          Expanded(child: Text(mensaje, style: tema.textTheme.bodyMedium)),
          TextButton(onPressed: alReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

/// Video del POI reproducido dentro de la propia pantalla (RF-13).
class ReproductorVideo extends StatefulWidget {
  const ReproductorVideo({super.key, required this.medio});

  final Medio medio;

  @override
  State<ReproductorVideo> createState() => _ReproductorVideoState();
}

class _ReproductorVideoState extends State<ReproductorVideo> {
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
    if (_fallo != null) {
      return _FalloMedio(
        mensaje: 'No pudimos cargar el video.',
        alReintentar: _preparar,
      );
    }

    final c = _control;
    if (c == null) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: c.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(c),
            VideoProgressIndicator(c, allowScrubbing: true),
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: c,
              builder: (context, valor, _) => Semantics(
                button: true,
                label: valor.isPlaying ? 'Pausar video' : 'Reproducir video',
                child: IconButton.filled(
                  iconSize: 36,
                  onPressed: () => valor.isPlaying ? c.pause() : c.play(),
                  icon: Icon(
                    valor.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Audio narrado con reproducir, pausar y reanudar (RF-14).
class ReproductorAudio extends StatefulWidget {
  const ReproductorAudio({super.key, required this.medio});

  final Medio medio;

  @override
  State<ReproductorAudio> createState() => _ReproductorAudioState();
}

class _ReproductorAudioState extends State<ReproductorAudio> {
  final _reproductor = AudioPlayer();
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
      await _reproductor.setUrl(widget.medio.url);
    } catch (error) {
      debugPrint('Audio ${widget.medio.url} fallo: $error');
      if (mounted) setState(() => _fallo = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fallo != null) {
      return _FalloMedio(
        mensaje: 'No pudimos cargar el audio.',
        alReintentar: _preparar,
      );
    }

    final tema = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: StreamBuilder<PlayerState>(
        stream: _reproductor.playerStateStream,
        builder: (context, snap) {
          final sonando = snap.data?.playing ?? false;

          return Row(
            children: [
              Semantics(
                button: true,
                label: sonando ? 'Pausar audio narrado' : 'Escuchar historia',
                child: IconButton.filled(
                  iconSize: 30,
                  onPressed: () =>
                      sonando ? _reproductor.pause() : _reproductor.play(),
                  icon: Icon(
                    sonando ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StreamBuilder<Duration>(
                  stream: _reproductor.positionStream,
                  builder: (context, posSnap) {
                    final total = _reproductor.duration ?? Duration.zero;
                    final pos = posSnap.data ?? Duration.zero;
                    final maximo = total.inMilliseconds.toDouble();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Slider(
                          value: maximo == 0
                              ? 0
                              : pos.inMilliseconds
                                    .clamp(0, total.inMilliseconds)
                                    .toDouble(),
                          max: maximo == 0 ? 1 : maximo,
                          onChanged: maximo == 0
                              ? null
                              : (v) => _reproductor.seek(
                                  Duration(milliseconds: v.round()),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 4),
                          child: Text(
                            '${_formato(pos)} / ${_formato(total)}',
                            style: tema.textTheme.labelMedium,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

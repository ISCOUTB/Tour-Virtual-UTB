import 'package:flutter/foundation.dart';

/// Una línea de subtítulo con su intervalo.
@immutable
class LineaSubtitulo {
  const LineaSubtitulo(this.inicio, this.fin, this.texto);

  final Duration inicio;
  final Duration fin;
  final String texto;
}

/// Subtítulos o transcripción de un audio o un video.
///
/// Lee WebVTT y SRT conservando los tiempos, que es lo que permite mostrar
/// cada frase mientras suena (WCAG 1.2.2) además de la transcripción completa
/// (1.2.1). Un archivo de texto plano también vale: entonces solo hay
/// transcripción, sin subtítulos en vivo.
@immutable
class Subtitulos {
  const Subtitulos(this.lineas);

  factory Subtitulos.leer(String fuente) {
    final bloques = fuente
        .replaceAll('﻿', '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split(RegExp(r'\n\s*\n'));

    final lineas = <LineaSubtitulo>[];
    final sueltas = <String>[];
    for (final bloque in bloques) {
      final filas = bloque
          .split('\n')
          .map((f) => f.trim())
          .where((f) => f.isNotEmpty)
          .toList();
      if (filas.isEmpty) continue;
      final primera = filas.first;
      if (primera.startsWith('WEBVTT') ||
          primera.startsWith('NOTE') ||
          primera.startsWith('STYLE') ||
          primera.startsWith('REGION')) {
        continue;
      }

      final iTiempo = filas.indexWhere((f) => f.contains('-->'));
      if (iTiempo < 0) {
        // Un número de cue suelto no es texto.
        sueltas.addAll(filas.where((f) => !_numeroDeCue.hasMatch(f)));
        continue;
      }

      final partes = filas[iTiempo].split('-->');
      final inicio = _tiempo(partes.first);
      // Tras el fin pueden venir ajustes de posición («align:start»).
      final fin = _tiempo(partes.last.trim().split(RegExp(r'\s+')).first);
      final texto = _limpiar(filas.sublist(iTiempo + 1).join(' '));
      if (inicio != null && fin != null && texto.isNotEmpty) {
        lineas.add(LineaSubtitulo(inicio, fin, texto));
      }
    }

    if (lineas.isEmpty && sueltas.isNotEmpty) {
      return Subtitulos([
        LineaSubtitulo(
          Duration.zero,
          Duration.zero,
          _limpiar(sueltas.join(' ')),
        ),
      ]);
    }
    lineas.sort((a, b) => a.inicio.compareTo(b.inicio));
    return Subtitulos(lineas);
  }

  final List<LineaSubtitulo> lineas;

  static final _numeroDeCue = RegExp(r'^\d+$');
  static final _etiqueta = RegExp(r'<[^>]+>');
  static final _espacios = RegExp(r'\s+');

  /// Si los tiempos permiten mostrar cada línea mientras suena.
  bool get sincronizados => lineas.any((l) => l.fin > Duration.zero);

  /// Transcripción completa en un solo texto.
  String get texto => lineas.map((l) => l.texto).join(' ').trim();

  bool get vacios => texto.isEmpty;

  /// Línea que corresponde a [posicion], o nula si en ese momento no se dice
  /// nada.
  LineaSubtitulo? en(Duration posicion) {
    for (final linea in lineas) {
      if (posicion < linea.inicio) return null;
      if (posicion < linea.fin) return linea;
    }
    return null;
  }

  /// `hh:mm:ss.mmm`, `mm:ss.mmm` o la coma de SRT.
  static Duration? _tiempo(String crudo) {
    final partes = crudo.trim().replaceAll(',', '.').split(':');
    if (partes.length < 2 || partes.length > 3) return null;
    final segundos = double.tryParse(partes.last);
    final minutos = int.tryParse(partes[partes.length - 2]);
    final horas = partes.length == 3 ? int.tryParse(partes.first) : 0;
    if (segundos == null || minutos == null || horas == null) return null;
    return Duration(
      hours: horas,
      minutes: minutos,
      milliseconds: (segundos * 1000).round(),
    );
  }

  static String _limpiar(String texto) => texto
      .replaceAll(_etiqueta, '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll(_espacios, ' ')
      .trim();
}

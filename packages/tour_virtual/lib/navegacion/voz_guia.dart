import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Indicaciones habladas con la voz del propio teléfono, en el idioma de la
/// interfaz. No son audios grabados: las frases cambian a cada paso.
///
/// Nunca falla hacia afuera: si el teléfono no tiene voz para ese idioma o la
/// plataforma no la implementa (escritorio, pruebas), la guía sigue con el
/// texto en pantalla, que siempre está.
abstract class VozGuia {
  Future<void> decir(String texto, {required String idioma});
  Future<void> callar();
}

class VozDelTelefono implements VozGuia {
  FlutterTts? _tts;
  String? _idioma;
  var _disponible = true;

  @override
  Future<void> decir(String texto, {required String idioma}) async {
    if (!_disponible) return;
    try {
      final tts = _tts ??= FlutterTts();
      if (_idioma != idioma) {
        _idioma = idioma;
        await tts.setLanguage(idioma);
        // Algo más lento que lo normal: se escucha caminando y con ruido.
        await tts.setSpeechRate(0.48);
      }
      await tts.stop();
      await tts.speak(texto);
    } catch (error) {
      _disponible = false;
      debugPrint('Voz de la guía no disponible: $error');
    }
  }

  @override
  Future<void> callar() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}

/// Para las pruebas: recuerda lo que dijo.
class VozMuda implements VozGuia {
  final dichos = <String>[];

  @override
  Future<void> decir(String texto, {required String idioma}) async =>
      dichos.add(texto);

  @override
  Future<void> callar() async {}
}

final vozGuiaProvider = Provider<VozGuia>((ref) {
  final voz = VozDelTelefono();
  ref.onDispose(voz.callar);
  return voz;
});

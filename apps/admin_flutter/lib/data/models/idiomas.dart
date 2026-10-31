/// Idiomas del contenido, con su nombre escrito en ese idioma. Son los 11 de
/// la interfaz de la app móvil más la Lengua de Señas Colombiana (`csn`), que
/// solo aplica a video. Etiquetas BCP 47, como las guarda `medios.idioma`.
const Map<String, String> idiomasContenido = {
  'es': 'Español',
  'en': 'English',
  'pt-BR': 'Português (Brasil)',
  'pt-PT': 'Português (Portugal)',
  'fr': 'Français',
  'it': 'Italiano',
  'de': 'Deutsch',
  'tr': 'Türkçe',
  'ko': '한국어',
  'ja': '日本語',
  'zh': '中文（简体）',
  'csn': 'Lengua de Señas Colombiana',
};

/// Idioma original del contenido: lo que no tiene etiqueta se toma como español.
const String idiomaOriginal = 'es';

/// Nombre legible de una etiqueta. Nula se toma como el idioma original; una
/// etiqueta desconocida se devuelve en mayúsculas.
String nombreDeIdioma(String? etiqueta) {
  final tag = (etiqueta == null || etiqueta.isEmpty)
      ? idiomaOriginal
      : etiqueta.replaceAll('_', '-');
  if (idiomasContenido.containsKey(tag)) return idiomasContenido[tag]!;
  if (tag.toLowerCase() == 'pt') return idiomasContenido['pt-BR']!;
  return tag.toUpperCase();
}

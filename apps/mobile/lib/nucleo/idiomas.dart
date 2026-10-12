import 'package:flutter/widgets.dart';

/// Un idioma de la interfaz, con su nombre escrito en ese mismo idioma.
///
/// El selector los muestra así («Deutsch», «日本語») porque quien busca su
/// idioma lo reconoce por cómo se escribe, no por cómo se llama en español.
class IdiomaUi {
  const IdiomaUi(this.locale, this.nombre);

  final Locale locale;
  final String nombre;
}

/// Idiomas con traducción completa, en el orden del selector.
///
/// Son los de la comunidad internacional de la UTB. Para añadir uno: su
/// archivo `lib/l10n/textos_<código>.arb`, una línea aquí y su nombre en
/// [nombreDeIdioma]. `test/textos_test.dart` comprueba que no le falte
/// ninguna clave.
const idiomasUi = [
  IdiomaUi(Locale('es'), 'Español'),
  IdiomaUi(Locale('en'), 'English'),
  IdiomaUi(Locale('pt'), 'Português (Brasil)'),
  IdiomaUi(Locale('pt', 'PT'), 'Português (Portugal)'),
  IdiomaUi(Locale('fr'), 'Français'),
  IdiomaUi(Locale('it'), 'Italiano'),
  IdiomaUi(Locale('de'), 'Deutsch'),
  IdiomaUi(Locale('tr'), 'Türkçe'),
  IdiomaUi(Locale('ko'), '한국어'),
  IdiomaUi(Locale('ja'), '日本語'),
  IdiomaUi(Locale('zh'), '中文（简体）'),
];

/// Idioma en que llega hoy el contenido del servidor: nombres, descripciones
/// y narraciones se escriben primero en español.
const idiomaOriginal = Locale('es');

/// Elige el idioma de la interfaz a partir de los del teléfono, en orden.
///
/// Gana el primero que tenga traducción. Para el portugués cuenta el país:
/// Portugal tiene su variante, y cualquier otro país usa la de Brasil. Si
/// ninguno de los idiomas del teléfono está traducido, se usa el inglés y no
/// el español: quien llega con el teléfono en alemán o en árabe lo entiende
/// mejor.
Locale resolverIdioma(List<Locale> delTelefono) {
  for (final preferido in delTelefono) {
    final codigo = preferido.languageCode.toLowerCase();
    if (codigo == 'pt') {
      return preferido.countryCode?.toUpperCase() == 'PT'
          ? const Locale('pt', 'PT')
          : const Locale('pt');
    }
    for (final idioma in idiomasUi) {
      if (idioma.locale.languageCode == codigo) return idioma.locale;
    }
  }
  return const Locale('en');
}

/// Nombre de un idioma escrito en ese idioma, a partir de su etiqueta BCP 47
/// («es», «pt-BR», «csn»).
///
/// Sirve para decir en qué idioma está un contenido o una narración. Una
/// etiqueta desconocida se devuelve tal cual, en mayúsculas.
String nombreDeIdioma(String etiqueta) {
  final partes = etiqueta.replaceAll('_', '-').split('-');
  final codigo = partes.first.toLowerCase();
  final pais = partes.length > 1 ? partes.last.toUpperCase() : null;

  return switch (codigo) {
    'es' => 'Español',
    'en' => 'English',
    'pt' when pais == 'PT' => 'Português (Portugal)',
    'pt' => 'Português',
    'fr' => 'Français',
    'it' => 'Italiano',
    'de' => 'Deutsch',
    'tr' => 'Türkçe',
    'ko' => '한국어',
    'ja' => '日本語',
    'zh' => '中文',
    // Lengua de Señas Colombiana. Va escrita en español porque es la lengua
    // de señas de Colombia y así la nombra su comunidad.
    'csn' => 'Lengua de Señas Colombiana',
    _ => etiqueta.toUpperCase(),
  };
}

/// Si la etiqueta BCP 47 es de una lengua de señas que el módulo reconoce.
///
/// Un video con idioma `csn` es un video en Lengua de Señas Colombiana: no
/// hace falta un tipo de medio aparte para él.
bool esLenguaDeSenas(String? etiqueta) =>
    etiqueta != null && etiqueta.toLowerCase().split('-').first == 'csn';

/// Locale a partir de una etiqueta BCP 47 («pt-BR», «zh-Hans»).
Locale localeDeEtiqueta(String etiqueta) {
  final partes = etiqueta.replaceAll('_', '-').split('-');
  String? escritura;
  String? pais;
  for (final parte in partes.skip(1)) {
    if (parte.length == 4) {
      escritura = parte;
    } else if (parte.length == 2 || parte.length == 3) {
      pais = parte.toUpperCase();
    }
  }
  return Locale.fromSubtags(
    languageCode: partes.first.toLowerCase(),
    scriptCode: escritura,
    countryCode: pais,
  );
}

/// Si dos etiquetas o locales comparten idioma, sin mirar el país.
bool mismoIdioma(String? a, String? b) {
  if (a == null || b == null) return false;
  String base(String x) =>
      x.replaceAll('_', '-').split('-').first.toLowerCase();
  return base(a) == base(b);
}

/// Mayúsculas que respetan el idioma.
///
/// `toUpperCase` de Dart ignora el idioma, y en turco convierte «i» en «I»
/// cuando debe ser «İ» (y «ı» en «I»): «ilk durak» saldría «ILK DURAK».
String mayusculas(String texto, Locale idioma) {
  if (idioma.languageCode == 'tr' || idioma.languageCode == 'az') {
    return texto.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
  }
  return texto.toUpperCase();
}

/// [mayusculas] con el idioma activo de la interfaz.
String mayusculasDe(BuildContext context, String texto) =>
    mayusculas(texto, Localizations.localeOf(context));

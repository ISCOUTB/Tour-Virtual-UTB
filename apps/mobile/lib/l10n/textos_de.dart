// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'textos.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class TextosDe extends Textos {
  TextosDe([String locale = 'de']) : super(locale);

  @override
  String get tituloApp => 'UTB Virtueller Rundgang';

  @override
  String get tourVirtual => 'Virtueller Rundgang';

  @override
  String get volver => 'Zurück';

  @override
  String get reintentar => 'Erneut versuchen';

  @override
  String get listo => 'Fertig';

  @override
  String get falloConexion =>
      'Keine Verbindung möglich. Prüfe deine Internetverbindung und versuche es erneut.';

  @override
  String get falloTiempo =>
      'Der Server hat zu lange gebraucht. Versuche es erneut.';

  @override
  String get falloSesion =>
      'Deine Sitzung ist abgelaufen. Melde dich erneut an, um fortzufahren.';

  @override
  String get falloSinContenido => 'Hier sind noch keine Inhalte verfügbar.';

  @override
  String get falloInesperado =>
      'Etwas ist schiefgelaufen. Versuche es gleich noch einmal.';

  @override
  String get falloPanoramasSoloConApi =>
      'Panoramen sind nur sichtbar, wenn die App mit der API verbunden ist.';

  @override
  String get enlaceInvalido => 'Dieser Link ist ungültig.';

  @override
  String get rutaPorDefecto => 'Campus-Rundgang';

  @override
  String cantidadLugares(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total Orte',
      one: '1 Ort',
    );
    return '$_temp0';
  }

  @override
  String get titularSinLugares => 'Noch keine Orte';

  @override
  String get titularEmpieza => 'Starte deinen Rundgang';

  @override
  String get recorridoCompleto => 'Rundgang abgeschlossen';

  @override
  String titularAvance(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$hechos von $total Orten besucht',
      one: '$hechos von 1 Ort besucht',
    );
    return '$_temp0';
  }

  @override
  String get detalleEmpieza =>
      'Entdecke den Campus, einen Ort nach dem anderen.';

  @override
  String get detalleCompleto => 'Kehre jederzeit zu jedem Ort zurück.';

  @override
  String detalleSiguiente(String nombre) {
    return 'Als Nächstes: $nombre';
  }

  @override
  String lugaresVisitados(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$hechos von $total Orten besucht',
      one: '$hechos von 1 Ort besucht',
    );
    return '$_temp0';
  }

  @override
  String get modoRecorrido => 'Rundgang';

  @override
  String get modoMapa => 'Karte';

  @override
  String get idiomaYAccesibilidad => 'Sprache und Barrierefreiheit';

  @override
  String get sinLugaresPublicados =>
      'In diesem Rundgang wurden noch keine Orte veröffentlicht.';

  @override
  String get paradas => 'Stationen';

  @override
  String avanceLugares(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$hechos von $total Orten',
      one: '$hechos von 1 Ort',
    );
    return '$_temp0';
  }

  @override
  String conocisteLosLugares(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Du hast alle $total Orte gesehen',
      one: 'Du hast den Ort gesehen',
    );
    return '$_temp0';
  }

  @override
  String get vuelveACualquiera => 'Kehre jederzeit zu jedem zurück.';

  @override
  String get volverAEmpezar => 'Neu beginnen';

  @override
  String get primeraParada => 'Erste Station';

  @override
  String get empezarRecorrido => 'Rundgang starten';

  @override
  String get siguienteParada => 'Nächste Station';

  @override
  String get continuarRecorrido => 'Rundgang fortsetzen';

  @override
  String paradaNDeTotal(int numero, int total) {
    return 'Station $numero von $total';
  }

  @override
  String get visitado => 'Besucht';

  @override
  String get lugarDelCampus => 'Ort auf dem Campus';

  @override
  String get campus => 'Campus';

  @override
  String yaVisitado(String nombre) {
    return '$nombre, bereits besucht';
  }

  @override
  String paradaSemantica(int numero, String nombre) {
    return 'Station $numero, $nombre';
  }

  @override
  String get sugerencia => 'Tipp';

  @override
  String get sugerenciaTitulo => 'Finde jede Station auf dem Campus';

  @override
  String get sugerenciaTexto =>
      'Die Karte zeigt, wo jeder Ort liegt und welche du schon besucht hast.';

  @override
  String get abrirMapa => 'Karte öffnen';

  @override
  String get pieOficial =>
      'Offizieller Rundgang der Universidad Tecnológica de Bolívar';

  @override
  String get datosDemostracion => 'Demodaten';

  @override
  String get categoriaRecursos => 'Lernressourcen';

  @override
  String get categoriaAcademico => 'Studium';

  @override
  String get categoriaBienestar => 'Gesundheit';

  @override
  String get categoriaServicios => 'Service';

  @override
  String get categoriaDeporte => 'Sport';

  @override
  String get verTodoCampus => 'Ganzen Campus anzeigen';

  @override
  String get acercar => 'Vergrößern';

  @override
  String get alejar => 'Verkleinern';

  @override
  String get mapaNoCargo => 'Die Campuskarte konnte nicht geladen werden.';

  @override
  String get mapaDescripcion =>
      'Illustrierte Campuskarte. Jede Station hat eine nummerierte Markierung.';

  @override
  String visitadosDeTotal(int hechos, int total) {
    return '$hechos von $total besucht';
  }

  @override
  String get sinUbicacionMapa => 'Nicht auf der Karte';

  @override
  String get sinDescripcion =>
      'Für diesen Ort gibt es noch keine Beschreibung.';

  @override
  String get verEn360 => 'In 360° ansehen';

  @override
  String get sin360 => 'Für diesen Ort gibt es noch keinen 360°-Rundgang.';

  @override
  String get audioNarrado => 'Audioführung';

  @override
  String get galeria => 'Galerie';

  @override
  String get video => 'Video';

  @override
  String get lenguaDeSenas => 'Gebärdensprache';

  @override
  String get contenidoEnPreparacion => 'Inhalte in Vorbereitung';

  @override
  String todaviaNoHay(String lista) {
    return 'Noch nicht verfügbar: $lista';
  }

  @override
  String get fotos => 'Fotos';

  @override
  String textoEnIdioma(String idioma) {
    return 'Informationen verfügbar auf $idioma';
  }

  @override
  String get deslizaParaMirar => 'Wischen zum Umsehen';

  @override
  String get fotoDelLugar => 'Foto des Ortes';

  @override
  String fotoNDeTotal(int numero, int total) {
    return '$numero von $total';
  }

  @override
  String get fotoNoCargo => 'Dieses Foto konnte nicht geladen werden.';

  @override
  String get videoNoCargo => 'Das Video konnte nicht geladen werden.';

  @override
  String get pausarVideo => 'Video pausieren';

  @override
  String get reproducirVideo => 'Video abspielen';

  @override
  String get audioSinSoporte =>
      'Audio kann auf dieser Plattform nicht abgespielt werden.';

  @override
  String get audioNoCargo => 'Das Audio konnte nicht geladen werden.';

  @override
  String get pausarAudio => 'Audioführung pausieren';

  @override
  String get escucharHistoria => 'Geschichte anhören';

  @override
  String get escuchando => 'Wird abgespielt';

  @override
  String get transcripcionEnPreparacion => 'Transkript in Vorbereitung';

  @override
  String get leerTranscripcion => 'Transkript lesen';

  @override
  String get transcripcion => 'Transkript';

  @override
  String get subtitulos => 'Untertitel';

  @override
  String narracionEn(String idioma) {
    return 'Erzählung auf $idioma';
  }

  @override
  String get escucharEn => 'Anhören auf';

  @override
  String posicionDeTotal(String posicion, String total) {
    return '$posicion von $total';
  }

  @override
  String vistaPanoramicaDe(String nombre) {
    return 'Panoramaansicht: $nombre';
  }

  @override
  String get esteLugar => 'dieser Ort';

  @override
  String get deslizaParaGirar => 'Zur Seite wischen zum Drehen';

  @override
  String get girarIzquierda => 'Nach links drehen';

  @override
  String get girarDerecha => 'Nach rechts drehen';

  @override
  String get sinEscenas =>
      'Dieser Rundgang hat noch keine veröffentlichten Szenen.';

  @override
  String get siguienteEscena => 'Nächste Szene';

  @override
  String get puntoDeInteres => 'Sehenswürdigkeit';

  @override
  String get caminandoHacia => 'Unterwegs zu';

  @override
  String escenaNDeTotal(int numero, int total) {
    return 'Szene $numero von $total';
  }

  @override
  String get pistaGiroscopio =>
      'Bewege das Handy oder ziehe, um dich umzusehen';

  @override
  String get pistaArrastre => 'Ziehe oder nutze die Pfeile, um dich umzusehen';

  @override
  String get preparando360 => '360°-Rundgang wird vorbereitet';

  @override
  String get panoramaNoCargo => 'Dieses Panorama konnte nicht geladen werden.';

  @override
  String get avanzarSiguienteEscena => 'Zur nächsten Szene';

  @override
  String get verInformacion => 'Informationen ansehen';

  @override
  String irA(String destino) {
    return 'Gehe zu: $destino';
  }

  @override
  String get desdeAquiPuedesIr => 'Von hier aus geht es zu';

  @override
  String get movimientoTelefono => 'Ansicht mit dem Handy bewegen';

  @override
  String estasEn(String escena) {
    return 'Du bist hier: $escena';
  }

  @override
  String vista360De(String escena) {
    return '360°-Ansicht: $escena';
  }

  @override
  String get conocisteTodo => 'Du hast den ganzen Rundgang gesehen';

  @override
  String get cierreTexto =>
      'Du hast die Orte gesehen, die den Alltag an der UTB ausmachen. Kehre jederzeit zu jedem davon zurück.';

  @override
  String get seguirExplorando => 'Weiter erkunden';

  @override
  String get idioma => 'Sprache';

  @override
  String get idiomaDelTelefono => 'Sprache des Handys';

  @override
  String get accesibilidad => 'Barrierefreiheit';

  @override
  String get tamanoTexto => 'Textgröße';

  @override
  String get tamanoNormal => 'Normal';

  @override
  String get tamanoGrande => 'Groß';

  @override
  String get tamanoMuyGrande => 'Sehr groß';

  @override
  String get muestraTexto => 'So liest sich der Text in dieser Größe.';

  @override
  String get altoContraste => 'Hoher Kontrast';

  @override
  String get altoContrasteDetalle => 'Deutlichere Texte und Ränder.';

  @override
  String get reducirMovimiento => 'Bewegung reduzieren';

  @override
  String get reducirMovimientoDetalle =>
      'Entfernt Animationen, Drehungen und 3D-Effekte.';

  @override
  String get movimientoTelefonoDetalle =>
      'Im 360°-Rundgang folgt die Ansicht der Bewegung deines Handys.';

  @override
  String get subtitulosDetalle =>
      'Zeigt den Text der Erzählung während der Wiedergabe.';

  @override
  String get ajustesSistema =>
      'Diese Einstellungen ergänzen die Bedienungshilfen deines Handys.';
}

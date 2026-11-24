// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'textos.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class TextosEn extends Textos {
  TextosEn([String locale = 'en']) : super(locale);

  @override
  String get tituloApp => 'UTB Virtual Tour';

  @override
  String get tourVirtual => 'Virtual tour';

  @override
  String get volver => 'Back';

  @override
  String get reintentar => 'Try again';

  @override
  String get listo => 'Done';

  @override
  String get falloConexion =>
      'We couldn\'t connect. Check your internet connection and try again.';

  @override
  String get falloTiempo => 'The server took too long to respond. Try again.';

  @override
  String get falloSesion => 'Your session expired. Sign in again to continue.';

  @override
  String get falloSinContenido => 'There\'s no content available here yet.';

  @override
  String get falloInesperado => 'Something went wrong. Try again in a moment.';

  @override
  String get falloPanoramasSoloConApi =>
      'Panoramas only appear when the app is connected to the API.';

  @override
  String get enlaceInvalido => 'That link isn\'t valid.';

  @override
  String get rutaPorDefecto => 'Campus tour';

  @override
  String cantidadLugares(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total places',
      one: '1 place',
    );
    return '$_temp0';
  }

  @override
  String get titularSinLugares => 'No places yet';

  @override
  String get titularEmpieza => 'Start your tour';

  @override
  String get recorridoCompleto => 'Tour complete';

  @override
  String titularAvance(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'You\'ve seen $hechos of $total places',
      one: 'You\'ve seen $hechos of 1 place',
    );
    return '$_temp0';
  }

  @override
  String get detalleEmpieza => 'Explore the campus, one place at a time.';

  @override
  String get detalleCompleto => 'Come back to any place whenever you like.';

  @override
  String detalleSiguiente(String nombre) {
    return 'Next: $nombre';
  }

  @override
  String lugaresVisitados(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$hechos of $total places visited',
      one: '$hechos of 1 place visited',
    );
    return '$_temp0';
  }

  @override
  String get modoRecorrido => 'Tour';

  @override
  String get modoMapa => 'Map';

  @override
  String get idiomaYAccesibilidad => 'Language and accessibility';

  @override
  String get sinLugaresPublicados =>
      'No places have been published on this tour yet.';

  @override
  String get paradas => 'Stops';

  @override
  String avanceLugares(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$hechos of $total places',
      one: '$hechos of 1 place',
    );
    return '$_temp0';
  }

  @override
  String conocisteLosLugares(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'You\'ve seen all $total places',
      one: 'You\'ve seen the place',
    );
    return '$_temp0';
  }

  @override
  String get vuelveACualquiera => 'Come back to any of them whenever you like.';

  @override
  String get volverAEmpezar => 'Start over';

  @override
  String get primeraParada => 'First stop';

  @override
  String get empezarRecorrido => 'Start tour';

  @override
  String get siguienteParada => 'Next stop';

  @override
  String get continuarRecorrido => 'Continue tour';

  @override
  String paradaNDeTotal(int numero, int total) {
    return 'Stop $numero of $total';
  }

  @override
  String get visitado => 'Visited';

  @override
  String get lugarDelCampus => 'Place on campus';

  @override
  String get campus => 'Campus';

  @override
  String yaVisitado(String nombre) {
    return '$nombre, visited';
  }

  @override
  String paradaSemantica(int numero, String nombre) {
    return 'Stop $numero, $nombre';
  }

  @override
  String get sugerencia => 'Tip';

  @override
  String get sugerenciaTitulo => 'Find each stop on campus';

  @override
  String get sugerenciaTexto =>
      'The map shows where each place is and which ones you\'ve already visited.';

  @override
  String get abrirMapa => 'Open the map';

  @override
  String get pieOficial =>
      'Official tour of the Universidad Tecnológica de Bolívar';

  @override
  String get datosDemostracion => 'Demo data';

  @override
  String get categoriaRecursos => 'Resources';

  @override
  String get categoriaAcademico => 'Academic';

  @override
  String get categoriaBienestar => 'Wellbeing';

  @override
  String get categoriaServicios => 'Services';

  @override
  String get categoriaDeporte => 'Sports';

  @override
  String get categoriaCultura => 'Culture';

  @override
  String get categoriaAdministrativo => 'Administration';

  @override
  String get categoriaSostenibilidad => 'Sustainability';

  @override
  String get verTodoCampus => 'View the whole campus';

  @override
  String get acercar => 'Zoom in';

  @override
  String get alejar => 'Zoom out';

  @override
  String get mapaNoCargo => 'We couldn\'t load the campus map.';

  @override
  String get mapaDescripcion =>
      'Campus map. Each stop has a numbered marker and other places a dot.';

  @override
  String visitadosDeTotal(int hechos, int total) {
    return '$hechos of $total visited';
  }

  @override
  String get sinUbicacionMapa => 'Not on the map';

  @override
  String get masLugares => 'More places on campus';

  @override
  String get creditoOsm => '© OpenStreetMap contributors';

  @override
  String get sinDescripcion => 'There\'s no description of this place yet.';

  @override
  String get verEn360 => 'View in 360°';

  @override
  String get sin360 => 'This place doesn\'t have a 360° view yet.';

  @override
  String get audioNarrado => 'Narrated audio';

  @override
  String get galeria => 'Gallery';

  @override
  String get video => 'Video';

  @override
  String get lenguaDeSenas => 'Sign language';

  @override
  String get contenidoEnPreparacion => 'Content coming soon';

  @override
  String todaviaNoHay(String lista) {
    return 'Not available yet: $lista';
  }

  @override
  String get fotos => 'Photos';

  @override
  String textoEnIdioma(String idioma) {
    return 'Information available in $idioma';
  }

  @override
  String get deslizaParaMirar => 'Swipe to look around';

  @override
  String get fotoDelLugar => 'Photo of the place';

  @override
  String fotoNDeTotal(int numero, int total) {
    return '$numero of $total';
  }

  @override
  String get fotoNoCargo => 'We couldn\'t load this photo.';

  @override
  String get videoNoCargo => 'We couldn\'t load the video.';

  @override
  String get pausarVideo => 'Pause video';

  @override
  String get reproducirVideo => 'Play video';

  @override
  String get audioSinSoporte => 'Audio can\'t be played on this platform.';

  @override
  String get audioNoCargo => 'We couldn\'t load the audio.';

  @override
  String get pausarAudio => 'Pause narration';

  @override
  String get escucharHistoria => 'Listen to the story';

  @override
  String get escuchando => 'Listening';

  @override
  String get transcripcionEnPreparacion => 'Transcript coming soon';

  @override
  String get leerTranscripcion => 'Read the transcript';

  @override
  String get transcripcion => 'Transcript';

  @override
  String get subtitulos => 'Captions';

  @override
  String narracionEn(String idioma) {
    return 'Narration in $idioma';
  }

  @override
  String posicionDeTotal(String posicion, String total) {
    return '$posicion of $total';
  }

  @override
  String vistaPanoramicaDe(String nombre) {
    return 'Panoramic view of $nombre';
  }

  @override
  String get esteLugar => 'this place';

  @override
  String get deslizaParaGirar => 'Swipe sideways to turn';

  @override
  String get girarIzquierda => 'Turn left';

  @override
  String get girarDerecha => 'Turn right';

  @override
  String get orientarNorte => 'Face north';

  @override
  String get sinEscenas => 'This tour has no published scenes yet.';

  @override
  String get siguienteEscena => 'Next scene';

  @override
  String get puntoDeInteres => 'Point of interest';

  @override
  String get caminandoHacia => 'Walking to';

  @override
  String escenaNDeTotal(int numero, int total) {
    return 'Scene $numero of $total';
  }

  @override
  String get pistaGiroscopio => 'Move your phone or drag to look around';

  @override
  String get pistaArrastre => 'Drag or use the arrows to look around';

  @override
  String get preparando360 => 'Preparing the 360° tour';

  @override
  String get panoramaNoCargo => 'We couldn\'t load this panorama.';

  @override
  String get avanzarSiguienteEscena => 'Go to the next scene';

  @override
  String get verInformacion => 'View information';

  @override
  String irA(String destino) {
    return 'Go to $destino';
  }

  @override
  String get desdeAquiPuedesIr => 'From here you can go to';

  @override
  String get movimientoTelefono => 'Move the view with your phone';

  @override
  String estasEn(String escena) {
    return 'You\'re at $escena';
  }

  @override
  String vista360De(String escena) {
    return '360° view of $escena';
  }

  @override
  String get conocisteTodo => 'You\'ve seen the whole tour';

  @override
  String get cierreTexto =>
      'You\'ve seen the places that make up daily life at UTB. Come back to any of them whenever you like.';

  @override
  String get seguirExplorando => 'Keep exploring';

  @override
  String get idioma => 'Language';

  @override
  String get idiomaDelTelefono => 'Phone language';

  @override
  String get accesibilidad => 'Accessibility';

  @override
  String get tamanoTexto => 'Text size';

  @override
  String get tamanoNormal => 'Normal';

  @override
  String get tamanoGrande => 'Large';

  @override
  String get tamanoMuyGrande => 'Extra large';

  @override
  String get muestraTexto => 'This is how text reads at this size.';

  @override
  String get altoContraste => 'High contrast';

  @override
  String get altoContrasteDetalle => 'Bolder text and borders.';

  @override
  String get reducirMovimiento => 'Reduce motion';

  @override
  String get reducirMovimientoDetalle =>
      'Turns off animations, spins and 3D effects.';

  @override
  String get movimientoTelefonoDetalle =>
      'In the 360° tour, the view follows your phone\'s movement.';

  @override
  String get subtitulosDetalle => 'Shows the narration text while it plays.';

  @override
  String get ajustesSistema =>
      'These settings add to your phone\'s own accessibility settings.';

  @override
  String get privacidad => 'Privacy';

  @override
  String get analiticaTitulo => 'Will you help us improve the tour?';

  @override
  String analiticaTexto(String ajustes) {
    return 'If you agree, the app counts which scenes, places and narrations are used, without your name, your location or anything that identifies you. You can change this at any time in “$ajustes”.';
  }

  @override
  String get analiticaAceptar => 'Yes, share';

  @override
  String get analiticaRechazar => 'No, thanks';

  @override
  String analiticaGuardada(String ajustes) {
    return 'Saved. You can change this in “$ajustes”.';
  }

  @override
  String get analiticaAjuste => 'Share usage statistics';

  @override
  String get analiticaAjusteDetalle =>
      'Anonymous: which scenes, places and narrations are used. Never your name or your location.';

  @override
  String get guiaTitulo => 'Hi, I’m Max';

  @override
  String get guiaTexto => 'I’ll show you around the UTB campus.';

  @override
  String get guia360 => 'Step into each place in 360° and look around.';

  @override
  String get guiaMapa => 'Find every stop on the campus map.';

  @override
  String get guiaAudio => 'Listen to each place’s story in your language.';

  @override
  String get guiaEmpezar => 'Start the tour';

  @override
  String get guiaExplorar => 'Explore on my own';

  @override
  String get verGuia => 'See the welcome again';

  @override
  String get verGuiaDetalle => 'Max explains again how the tour works.';

  @override
  String get ayuda => 'Help';

  @override
  String get comoLlegar => 'Get directions';

  @override
  String navTitulo(String lugar) {
    return 'Directions to $lugar';
  }

  @override
  String navPermisoTitulo(String lugar) {
    return 'I’ll guide you to $lugar';
  }

  @override
  String get navPermisoTexto =>
      'I use your phone’s GPS while the guide is open. Your location never leaves your phone and is not stored.';

  @override
  String get navPermitir => 'Allow location';

  @override
  String get navSinPermiso =>
      'Without location permission I can’t guide you. You can find the place on the map or see it in 360°.';

  @override
  String get navAbrirAjustes => 'Open settings';

  @override
  String get navGpsApagado =>
      'Your phone’s location is turned off. Turn it on and try again.';

  @override
  String get navSimulada => 'Simulated location';

  @override
  String get navBuscando => 'Looking for GPS signal…';

  @override
  String navSenalDebil(int metros) {
    return 'Weak signal (±$metros m). Move to an open space.';
  }

  @override
  String navRecto(int metros) {
    return 'Go straight for $metros m';
  }

  @override
  String navDerecha(int metros) {
    return 'In $metros m, turn right';
  }

  @override
  String navIzquierda(int metros) {
    return 'In $metros m, turn left';
  }

  @override
  String navLigeraDerecha(int metros) {
    return 'In $metros m, bear right';
  }

  @override
  String navLigeraIzquierda(int metros) {
    return 'In $metros m, bear left';
  }

  @override
  String get navVuelta => 'Turn around';

  @override
  String navLlegando(String lugar, int metros) {
    return '$lugar is $metros m away';
  }

  @override
  String navFaltan(int metros, int minutos) {
    return '$metros m to go · about $minutos min';
  }

  @override
  String get navRecalculando => 'You left the route. Finding a new one…';

  @override
  String get navSinEscaleras => 'Avoid stairs';

  @override
  String get navPlano => 'Map';

  @override
  String get navCamara => 'Camera';

  @override
  String get navTerminar => 'End';

  @override
  String navLlegaste(String lugar) {
    return 'You’ve arrived at $lugar';
  }

  @override
  String get navVerFicha => 'See the details';

  @override
  String get navCamaraAviso => 'Watch the path, not the screen.';

  @override
  String get navCamaraNoDisponible =>
      'The camera couldn’t be opened. Follow the route on the map.';

  @override
  String get navCalibrar =>
      'The compass is inaccurate: move your phone in a figure eight.';

  @override
  String navSinRuta(String lugar) {
    return 'I couldn’t find a way to $lugar.';
  }

  @override
  String get navFueraDelCampus =>
      'You’re outside the campus. The guide starts by itself when you reach UTB; meanwhile, you can view the route without GPS.';

  @override
  String get navCaminandoHacia => 'Walking to';

  @override
  String get navLlegada => 'You’ve arrived';

  @override
  String get navIdeaRuta =>
      'I take you along the campus paths and tell you before each turn.';

  @override
  String get navIdeaCamara =>
      'Raise your phone to see an arrow over the camera showing the way.';

  @override
  String get navSinEscalerasDetalle => 'Avoids steps along the route.';

  @override
  String get navAproximada => 'This place’s entrance is still approximate.';

  @override
  String navPlanoSemantica(String lugar) {
    return 'Map with the route to $lugar';
  }

  @override
  String get verMapa3d => 'View 3D map';

  @override
  String get verMapa2d => 'Return to 2D map';

  @override
  String get mapa3dDescripcion =>
      '3D campus model. Tap a stop to view its details.';

  @override
  String get mapa3dNoDisponible =>
      'The 3D map could not open. You can use the 2D map or try again.';

  @override
  String get creditoModelo3d => '3D model: ElMapita UTB';

  @override
  String get mapa3dCargando => 'Loading the 3D map';

  @override
  String get navSinSenal =>
      'No GPS signal. Step into an open space: the guide carries on by itself as soon as there is one.';

  @override
  String get navVerRutaSinGps => 'View the route without GPS';

  @override
  String get navEntradaPrincipal => 'Main entrance';

  @override
  String get navDesde => 'From';

  @override
  String navResumenRuta(int minutos, int metros) {
    return '$minutos min · $metros m';
  }

  @override
  String get navConEscaleras => 'With stairs';

  @override
  String get navPasoAPaso => 'Step by step';

  @override
  String get navPreviaNota =>
      'This route starts from the point you chose, not from where you are.';

  @override
  String get navGuiarmeConGps => 'Guide me with GPS';

  @override
  String navEspacioPiso(String espacio, String piso) {
    return '$espacio is here, on: $piso.';
  }

  @override
  String navEspacioAqui(String espacio) {
    return '$espacio is in this place.';
  }

  @override
  String get buscarTitulo => 'Where are you going?';

  @override
  String get buscarPista => 'Search for a place, room or office';

  @override
  String buscarSinResultados(String consulta) {
    return 'No results for “$consulta”. Try the room number or the building name.';
  }

  @override
  String get buscarBorrar => 'Clear search';

  @override
  String get buscarCredito => 'Rooms and offices: MAPSUTB';

  @override
  String get buscarComoLlegar => 'Directions';

  @override
  String buscarVerTodos(int cantidad) {
    return 'Show all $cantidad results';
  }
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'textos.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class TextosEs extends Textos {
  TextosEs([String locale = 'es']) : super(locale);

  @override
  String get tituloApp => 'UTB Tour Virtual';

  @override
  String get tourVirtual => 'Tour virtual';

  @override
  String get volver => 'Volver';

  @override
  String get reintentar => 'Reintentar';

  @override
  String get listo => 'Listo';

  @override
  String get falloConexion =>
      'No pudimos conectarnos. Revisa tu conexión a internet e intenta de nuevo.';

  @override
  String get falloTiempo =>
      'El servidor tardó demasiado en responder. Intenta de nuevo.';

  @override
  String get falloSesion => 'Tu sesión expiró. Vuelve a entrar para continuar.';

  @override
  String get falloSinContenido => 'Todavía no hay contenido disponible aquí.';

  @override
  String get falloInesperado =>
      'Algo salió mal. Intenta de nuevo en un momento.';

  @override
  String get falloPanoramasSoloConApi =>
      'Las panorámicas solo se ven con la app conectada a la API.';

  @override
  String get enlaceInvalido => 'Ese enlace no es válido.';

  @override
  String get rutaPorDefecto => 'Recorrido del campus';

  @override
  String cantidadLugares(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total lugares',
      one: '1 lugar',
    );
    return '$_temp0';
  }

  @override
  String get titularSinLugares => 'Aún no hay lugares';

  @override
  String get titularEmpieza => 'Empieza tu recorrido';

  @override
  String get recorridoCompleto => 'Recorrido completo';

  @override
  String titularAvance(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Llevas $hechos de $total lugares',
      one: 'Llevas $hechos de 1 lugar',
    );
    return '$_temp0';
  }

  @override
  String get detalleEmpieza => 'Conoce el campus, un lugar a la vez.';

  @override
  String get detalleCompleto => 'Vuelve a cualquier lugar cuando quieras.';

  @override
  String detalleSiguiente(String nombre) {
    return 'Siguiente: $nombre';
  }

  @override
  String lugaresVisitados(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$hechos de $total lugares visitados',
      one: '$hechos de 1 lugar visitado',
    );
    return '$_temp0';
  }

  @override
  String get modoRecorrido => 'Recorrido';

  @override
  String get modoMapa => 'Mapa';

  @override
  String get idiomaYAccesibilidad => 'Idioma y accesibilidad';

  @override
  String get sinLugaresPublicados =>
      'Todavía no hay lugares publicados en este recorrido.';

  @override
  String get paradas => 'Paradas';

  @override
  String avanceLugares(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$hechos de $total lugares',
      one: '$hechos de 1 lugar',
    );
    return '$_temp0';
  }

  @override
  String conocisteLosLugares(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Conociste los $total lugares',
      one: 'Conociste el lugar',
    );
    return '$_temp0';
  }

  @override
  String get vuelveACualquiera => 'Vuelve a cualquiera cuando quieras.';

  @override
  String get volverAEmpezar => 'Volver a empezar';

  @override
  String get primeraParada => 'Primera parada';

  @override
  String get empezarRecorrido => 'Empezar recorrido';

  @override
  String get siguienteParada => 'Siguiente parada';

  @override
  String get continuarRecorrido => 'Continuar recorrido';

  @override
  String paradaNDeTotal(int numero, int total) {
    return 'Parada $numero de $total';
  }

  @override
  String get visitado => 'Visitado';

  @override
  String get lugarDelCampus => 'Lugar del campus';

  @override
  String get campus => 'Campus';

  @override
  String yaVisitado(String nombre) {
    return '$nombre, ya visitado';
  }

  @override
  String paradaSemantica(int numero, String nombre) {
    return 'Parada $numero, $nombre';
  }

  @override
  String get sugerencia => 'Sugerencia';

  @override
  String get sugerenciaTitulo => 'Ubica cada parada en el campus';

  @override
  String get sugerenciaTexto =>
      'El mapa muestra dónde queda cada lugar y cuáles ya visitaste.';

  @override
  String get abrirMapa => 'Abrir el mapa';

  @override
  String get pieOficial =>
      'Recorrido oficial de la Universidad Tecnológica de Bolívar';

  @override
  String get datosDemostracion => 'Datos de demostración';

  @override
  String get categoriaRecursos => 'Recursos';

  @override
  String get categoriaAcademico => 'Académico';

  @override
  String get categoriaBienestar => 'Bienestar';

  @override
  String get categoriaServicios => 'Servicios';

  @override
  String get categoriaDeporte => 'Deporte';

  @override
  String get categoriaCultura => 'Cultura';

  @override
  String get categoriaAdministrativo => 'Administrativo';

  @override
  String get categoriaSostenibilidad => 'Sostenibilidad';

  @override
  String get verTodoCampus => 'Ver todo el campus';

  @override
  String get acercar => 'Acercar';

  @override
  String get alejar => 'Alejar';

  @override
  String get mapaNoCargo => 'No pudimos cargar el mapa del campus.';

  @override
  String get mapaDescripcion =>
      'Plano del campus. Cada parada tiene un marcador numerado y los demás lugares, un punto.';

  @override
  String visitadosDeTotal(int hechos, int total) {
    return '$hechos de $total visitados';
  }

  @override
  String get sinUbicacionMapa => 'Sin ubicación en el mapa';

  @override
  String get masLugares => 'Más lugares del campus';

  @override
  String get creditoOsm => '© colaboradores de OpenStreetMap';

  @override
  String get sinDescripcion => 'Todavía no hay descripción de este lugar.';

  @override
  String get verEn360 => 'Ver en 360°';

  @override
  String get sin360 => 'Este lugar todavía no tiene recorrido en 360°.';

  @override
  String get audioNarrado => 'Audio narrado';

  @override
  String get galeria => 'Galería';

  @override
  String get video => 'Video';

  @override
  String get lenguaDeSenas => 'Lengua de señas';

  @override
  String get contenidoEnPreparacion => 'Contenido en preparación';

  @override
  String todaviaNoHay(String lista) {
    return 'Todavía no hay: $lista';
  }

  @override
  String get fotos => 'Fotos';

  @override
  String textoEnIdioma(String idioma) {
    return 'Información disponible en $idioma';
  }

  @override
  String get deslizaParaMirar => 'Desliza para mirar';

  @override
  String get fotoDelLugar => 'Foto del lugar';

  @override
  String fotoNDeTotal(int numero, int total) {
    return '$numero de $total';
  }

  @override
  String get fotoNoCargo => 'No pudimos cargar esta foto.';

  @override
  String get videoNoCargo => 'No pudimos cargar el video.';

  @override
  String get pausarVideo => 'Pausar video';

  @override
  String get reproducirVideo => 'Reproducir video';

  @override
  String get audioSinSoporte =>
      'El audio no se puede reproducir en esta plataforma.';

  @override
  String get audioNoCargo => 'No pudimos cargar el audio.';

  @override
  String get pausarAudio => 'Pausar audio narrado';

  @override
  String get escucharHistoria => 'Escuchar historia';

  @override
  String get escuchando => 'Escuchando';

  @override
  String get transcripcionEnPreparacion => 'Transcripción en preparación';

  @override
  String get leerTranscripcion => 'Leer la transcripción';

  @override
  String get transcripcion => 'Transcripción';

  @override
  String get subtitulos => 'Subtítulos';

  @override
  String narracionEn(String idioma) {
    return 'Narración en $idioma';
  }

  @override
  String posicionDeTotal(String posicion, String total) {
    return '$posicion de $total';
  }

  @override
  String vistaPanoramicaDe(String nombre) {
    return 'Vista panorámica de $nombre';
  }

  @override
  String get esteLugar => 'este lugar';

  @override
  String get deslizaParaGirar => 'Desliza a los lados para girar';

  @override
  String get girarIzquierda => 'Girar a la izquierda';

  @override
  String get girarDerecha => 'Girar a la derecha';

  @override
  String get orientarNorte => 'Orientar al norte';

  @override
  String get sinEscenas =>
      'Este recorrido todavía no tiene escenas publicadas.';

  @override
  String get siguienteEscena => 'Siguiente escena';

  @override
  String get puntoDeInteres => 'Punto de interés';

  @override
  String get caminandoHacia => 'Caminando hacia';

  @override
  String escenaNDeTotal(int numero, int total) {
    return 'Escena $numero de $total';
  }

  @override
  String get pistaGiroscopio =>
      'Mueve el teléfono o arrastra para mirar alrededor';

  @override
  String get pistaArrastre => 'Arrastra o usa las flechas para mirar alrededor';

  @override
  String get preparando360 => 'Preparando el recorrido 360°';

  @override
  String get panoramaNoCargo => 'No pudimos cargar esta panorámica.';

  @override
  String get avanzarSiguienteEscena => 'Avanzar a la siguiente escena';

  @override
  String get verInformacion => 'Ver información';

  @override
  String irA(String destino) {
    return 'Ir a $destino';
  }

  @override
  String get desdeAquiPuedesIr => 'Desde aquí puedes ir a';

  @override
  String get movimientoTelefono => 'Mover la vista con el teléfono';

  @override
  String estasEn(String escena) {
    return 'Estás en $escena';
  }

  @override
  String vista360De(String escena) {
    return 'Vista 360° de $escena';
  }

  @override
  String get conocisteTodo => 'Conociste todo el recorrido';

  @override
  String get cierreTexto =>
      'Ya viste los lugares que hacen el día a día en la UTB. Cuando quieras, vuelve a cualquiera de ellos.';

  @override
  String get seguirExplorando => 'Seguir explorando';

  @override
  String get idioma => 'Idioma';

  @override
  String get idiomaDelTelefono => 'Idioma del teléfono';

  @override
  String get accesibilidad => 'Accesibilidad';

  @override
  String get tamanoTexto => 'Tamaño del texto';

  @override
  String get tamanoNormal => 'Normal';

  @override
  String get tamanoGrande => 'Grande';

  @override
  String get tamanoMuyGrande => 'Muy grande';

  @override
  String get muestraTexto => 'Así se lee el texto con este tamaño.';

  @override
  String get altoContraste => 'Alto contraste';

  @override
  String get altoContrasteDetalle => 'Textos y bordes más marcados.';

  @override
  String get reducirMovimiento => 'Reducir movimiento';

  @override
  String get reducirMovimientoDetalle =>
      'Quita animaciones, giros y efectos 3D.';

  @override
  String get movimientoTelefonoDetalle =>
      'En el recorrido 360°, la vista sigue el movimiento del teléfono.';

  @override
  String get subtitulosDetalle =>
      'Muestra el texto de la narración mientras suena.';

  @override
  String get ajustesSistema =>
      'Estos ajustes se suman a los de accesibilidad de tu teléfono.';

  @override
  String get privacidad => 'Privacidad';

  @override
  String get analiticaTitulo => '¿Nos ayudas a mejorar el recorrido?';

  @override
  String analiticaTexto(String ajustes) {
    return 'Si aceptas, la app cuenta qué escenas, lugares y narraciones se usan, sin tu nombre, tu ubicación ni nada que te identifique. Puedes cambiarlo cuando quieras en «$ajustes».';
  }

  @override
  String get analiticaAceptar => 'Sí, compartir';

  @override
  String get analiticaRechazar => 'No, gracias';

  @override
  String analiticaGuardada(String ajustes) {
    return 'Guardado. Puedes cambiarlo en «$ajustes».';
  }

  @override
  String get analiticaAjuste => 'Compartir estadísticas de uso';

  @override
  String get analiticaAjusteDetalle =>
      'Anónimas: qué escenas, lugares y narraciones se usan. Nunca tu nombre ni tu ubicación.';

  @override
  String get guiaTitulo => 'Hola, soy Max';

  @override
  String get guiaTexto => 'Te acompaño a recorrer el campus de la UTB.';

  @override
  String get guia360 => 'Entra a cada lugar en 360° y mira a tu alrededor.';

  @override
  String get guiaMapa => 'Ubica cada parada en el mapa del campus.';

  @override
  String get guiaAudio => 'Escucha la historia de cada lugar en tu idioma.';

  @override
  String get guiaEmpezar => 'Empezar el recorrido';

  @override
  String get guiaExplorar => 'Explorar por mi cuenta';

  @override
  String get verGuia => 'Ver la bienvenida';

  @override
  String get verGuiaDetalle =>
      'Max te vuelve a contar cómo funciona el recorrido.';

  @override
  String get ayuda => 'Ayuda';

  @override
  String get comoLlegar => 'Cómo llegar';

  @override
  String navTitulo(String lugar) {
    return 'Cómo llegar a $lugar';
  }

  @override
  String navPermisoTitulo(String lugar) {
    return 'Te guío hasta $lugar';
  }

  @override
  String get navPermisoTexto =>
      'Uso el GPS del teléfono mientras la guía está abierta. Tu ubicación no sale del teléfono ni se guarda.';

  @override
  String get navPermitir => 'Permitir ubicación';

  @override
  String get navSinPermiso =>
      'Sin permiso de ubicación no puedo guiarte. Puedes ubicar el lugar en el mapa o verlo en 360°.';

  @override
  String get navAbrirAjustes => 'Abrir ajustes';

  @override
  String get navGpsApagado =>
      'La ubicación del teléfono está apagada. Actívala y vuelve a intentarlo.';

  @override
  String get navSimulada => 'Ubicación simulada';

  @override
  String get navBuscando => 'Buscando señal GPS…';

  @override
  String navSenalDebil(int metros) {
    return 'Señal débil (±$metros m). Busca un espacio abierto.';
  }

  @override
  String navRecto(int metros) {
    return 'Sigue recto $metros m';
  }

  @override
  String navDerecha(int metros) {
    return 'En $metros m, gira a la derecha';
  }

  @override
  String navIzquierda(int metros) {
    return 'En $metros m, gira a la izquierda';
  }

  @override
  String navLigeraDerecha(int metros) {
    return 'En $metros m, ve hacia la derecha';
  }

  @override
  String navLigeraIzquierda(int metros) {
    return 'En $metros m, ve hacia la izquierda';
  }

  @override
  String get navVuelta => 'Da la vuelta';

  @override
  String navLlegando(String lugar, int metros) {
    return '$lugar está a $metros m';
  }

  @override
  String navFaltan(int metros, int minutos) {
    return 'Faltan $metros m · unos $minutos min';
  }

  @override
  String get navRecalculando => 'Te saliste de la ruta. Calculo otra…';

  @override
  String get navSinEscaleras => 'Sin escaleras';

  @override
  String get navPlano => 'Plano';

  @override
  String get navCamara => 'Cámara';

  @override
  String get navTerminar => 'Terminar';

  @override
  String navLlegaste(String lugar) {
    return 'Llegaste a $lugar';
  }

  @override
  String get navVerFicha => 'Ver la ficha';

  @override
  String get navCamaraAviso => 'Mira el camino, no la pantalla.';

  @override
  String get navCamaraNoDisponible =>
      'No se pudo abrir la cámara. Sigue la ruta en el plano.';

  @override
  String get navCalibrar =>
      'La brújula está imprecisa: mueve el teléfono dibujando un ocho.';

  @override
  String navSinRuta(String lugar) {
    return 'No encontré un camino hasta $lugar.';
  }

  @override
  String get navFueraDelCampus =>
      'Estás fuera del campus. La guía funciona dentro de la UTB: ábrela cuando llegues.';

  @override
  String get navAproximada => 'La entrada de este lugar aún es aproximada.';

  @override
  String navPlanoSemantica(String lugar) {
    return 'Plano con la ruta hasta $lugar';
  }

  @override
  String get verMapa3d => 'Ver mapa en 3D';

  @override
  String get verMapa2d => 'Volver al mapa 2D';

  @override
  String get mapa3dDescripcion =>
      'Maqueta 3D del campus. Toca una parada para ver su ficha.';

  @override
  String get mapa3dNoDisponible =>
      'No se pudo abrir el mapa 3D. Puedes seguir en el plano o intentarlo de nuevo.';

  @override
  String get creditoModelo3d => 'Modelo 3D: ElMapita UTB';

  @override
  String get mapa3dCargando => 'Cargando el mapa 3D';
}

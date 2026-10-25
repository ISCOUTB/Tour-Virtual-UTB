// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'textos.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class TextosIt extends Textos {
  TextosIt([String locale = 'it']) : super(locale);

  @override
  String get tituloApp => 'UTB Tour virtuale';

  @override
  String get tourVirtual => 'Tour virtuale';

  @override
  String get volver => 'Indietro';

  @override
  String get reintentar => 'Riprova';

  @override
  String get listo => 'Fatto';

  @override
  String get falloConexion =>
      'Impossibile connettersi. Controlla la connessione a internet e riprova.';

  @override
  String get falloTiempo =>
      'Il server ha impiegato troppo tempo a rispondere. Riprova.';

  @override
  String get falloSesion =>
      'La sessione è scaduta. Accedi di nuovo per continuare.';

  @override
  String get falloSinContenido =>
      'Qui non ci sono ancora contenuti disponibili.';

  @override
  String get falloInesperado =>
      'Qualcosa è andato storto. Riprova tra un momento.';

  @override
  String get falloPanoramasSoloConApi =>
      'Le panoramiche sono visibili solo con l’app collegata all’API.';

  @override
  String get enlaceInvalido => 'Questo link non è valido.';

  @override
  String get rutaPorDefecto => 'Percorso del campus';

  @override
  String cantidadLugares(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total luoghi',
      one: '1 luogo',
    );
    return '$_temp0';
  }

  @override
  String get titularSinLugares => 'Ancora nessun luogo';

  @override
  String get titularEmpieza => 'Inizia il tuo percorso';

  @override
  String get recorridoCompleto => 'Percorso completato';

  @override
  String titularAvance(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      hechos,
      locale: localeName,
      other: 'Hai visitato $hechos luoghi su $total',
      one: 'Hai visitato 1 luogo su $total',
    );
    return '$_temp0';
  }

  @override
  String get detalleEmpieza => 'Scopri il campus, un luogo alla volta.';

  @override
  String get detalleCompleto => 'Torna in qualsiasi luogo quando vuoi.';

  @override
  String detalleSiguiente(String nombre) {
    return 'Prossimo: $nombre';
  }

  @override
  String lugaresVisitados(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      hechos,
      locale: localeName,
      other: '$hechos luoghi visitati su $total',
      one: '1 luogo visitato su $total',
    );
    return '$_temp0';
  }

  @override
  String get modoRecorrido => 'Percorso';

  @override
  String get modoMapa => 'Mappa';

  @override
  String get idiomaYAccesibilidad => 'Lingua e accessibilità';

  @override
  String get sinLugaresPublicados =>
      'In questo percorso non ci sono ancora luoghi pubblicati.';

  @override
  String get paradas => 'Tappe';

  @override
  String avanceLugares(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$hechos su $total luoghi',
      one: '$hechos su 1 luogo',
    );
    return '$_temp0';
  }

  @override
  String conocisteLosLugares(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Hai visto tutti i $total luoghi',
      one: 'Hai visto il luogo',
    );
    return '$_temp0';
  }

  @override
  String get vuelveACualquiera => 'Torna in uno qualsiasi quando vuoi.';

  @override
  String get volverAEmpezar => 'Ricomincia';

  @override
  String get primeraParada => 'Prima tappa';

  @override
  String get empezarRecorrido => 'Inizia il percorso';

  @override
  String get siguienteParada => 'Prossima tappa';

  @override
  String get continuarRecorrido => 'Continua il percorso';

  @override
  String paradaNDeTotal(int numero, int total) {
    return 'Tappa $numero di $total';
  }

  @override
  String get visitado => 'Visitato';

  @override
  String get lugarDelCampus => 'Luogo del campus';

  @override
  String get campus => 'Campus';

  @override
  String yaVisitado(String nombre) {
    return '$nombre, già visitato';
  }

  @override
  String paradaSemantica(int numero, String nombre) {
    return 'Tappa $numero, $nombre';
  }

  @override
  String get sugerencia => 'Suggerimento';

  @override
  String get sugerenciaTitulo => 'Trova ogni tappa nel campus';

  @override
  String get sugerenciaTexto =>
      'La mappa mostra dove si trova ogni luogo e quali hai già visitato.';

  @override
  String get abrirMapa => 'Apri la mappa';

  @override
  String get pieOficial =>
      'Percorso ufficiale della Universidad Tecnológica de Bolívar';

  @override
  String get datosDemostracion => 'Dati dimostrativi';

  @override
  String get categoriaRecursos => 'Risorse';

  @override
  String get categoriaAcademico => 'Didattica';

  @override
  String get categoriaBienestar => 'Benessere';

  @override
  String get categoriaServicios => 'Servizi';

  @override
  String get categoriaDeporte => 'Sport';

  @override
  String get categoriaCultura => 'Cultura';

  @override
  String get categoriaAdministrativo => 'Amministrazione';

  @override
  String get categoriaSostenibilidad => 'Sostenibilità';

  @override
  String get verTodoCampus => 'Vedi tutto il campus';

  @override
  String get acercar => 'Ingrandisci';

  @override
  String get alejar => 'Riduci';

  @override
  String get mapaNoCargo => 'Impossibile caricare la mappa del campus.';

  @override
  String get mapaDescripcion =>
      'Mappa del campus. Ogni tappa ha un indicatore numerato e gli altri luoghi un punto.';

  @override
  String visitadosDeTotal(int hechos, int total) {
    return '$hechos di $total visitati';
  }

  @override
  String get sinUbicacionMapa => 'Non presente sulla mappa';

  @override
  String get masLugares => 'Altri luoghi del campus';

  @override
  String get creditoOsm => '© contributori di OpenStreetMap';

  @override
  String get sinDescripcion =>
      'Non c’è ancora una descrizione di questo luogo.';

  @override
  String get verEn360 => 'Guarda a 360°';

  @override
  String get sin360 => 'Questo luogo non ha ancora una visita a 360°.';

  @override
  String get audioNarrado => 'Audio narrato';

  @override
  String get galeria => 'Galleria';

  @override
  String get video => 'Video';

  @override
  String get lenguaDeSenas => 'Lingua dei segni';

  @override
  String get contenidoEnPreparacion => 'Contenuti in preparazione';

  @override
  String todaviaNoHay(String lista) {
    return 'Non ancora disponibili: $lista';
  }

  @override
  String get fotos => 'Foto';

  @override
  String textoEnIdioma(String idioma) {
    return 'Informazioni disponibili in $idioma';
  }

  @override
  String get deslizaParaMirar => 'Scorri per guardare';

  @override
  String get fotoDelLugar => 'Foto del luogo';

  @override
  String fotoNDeTotal(int numero, int total) {
    return '$numero di $total';
  }

  @override
  String get fotoNoCargo => 'Impossibile caricare questa foto.';

  @override
  String get videoNoCargo => 'Impossibile caricare il video.';

  @override
  String get pausarVideo => 'Metti in pausa il video';

  @override
  String get reproducirVideo => 'Riproduci il video';

  @override
  String get audioSinSoporte =>
      'L’audio non può essere riprodotto su questa piattaforma.';

  @override
  String get audioNoCargo => 'Impossibile caricare l’audio.';

  @override
  String get pausarAudio => 'Metti in pausa l’audio narrato';

  @override
  String get escucharHistoria => 'Ascolta la storia';

  @override
  String get escuchando => 'In ascolto';

  @override
  String get transcripcionEnPreparacion => 'Trascrizione in preparazione';

  @override
  String get leerTranscripcion => 'Leggi la trascrizione';

  @override
  String get transcripcion => 'Trascrizione';

  @override
  String get subtitulos => 'Sottotitoli';

  @override
  String narracionEn(String idioma) {
    return 'Narrazione in $idioma';
  }

  @override
  String get escucharEn => 'Ascolta in';

  @override
  String posicionDeTotal(String posicion, String total) {
    return '$posicion di $total';
  }

  @override
  String vistaPanoramicaDe(String nombre) {
    return 'Vista panoramica di $nombre';
  }

  @override
  String get esteLugar => 'questo luogo';

  @override
  String get deslizaParaGirar => 'Scorri lateralmente per ruotare';

  @override
  String get girarIzquierda => 'Ruota a sinistra';

  @override
  String get girarDerecha => 'Ruota a destra';

  @override
  String get sinEscenas => 'Questo percorso non ha ancora scene pubblicate.';

  @override
  String get siguienteEscena => 'Scena successiva';

  @override
  String get puntoDeInteres => 'Punto d’interesse';

  @override
  String get caminandoHacia => 'In cammino verso';

  @override
  String escenaNDeTotal(int numero, int total) {
    return 'Scena $numero di $total';
  }

  @override
  String get pistaGiroscopio =>
      'Muovi il telefono o trascina per guardarti intorno';

  @override
  String get pistaArrastre => 'Trascina o usa le frecce per guardarti intorno';

  @override
  String get preparando360 => 'Preparazione del percorso a 360°';

  @override
  String get panoramaNoCargo => 'Impossibile caricare questa panoramica.';

  @override
  String get avanzarSiguienteEscena => 'Vai alla scena successiva';

  @override
  String get verInformacion => 'Vedi informazioni';

  @override
  String irA(String destino) {
    return 'Vai a $destino';
  }

  @override
  String get desdeAquiPuedesIr => 'Da qui puoi andare a';

  @override
  String get movimientoTelefono => 'Muovi la vista con il telefono';

  @override
  String estasEn(String escena) {
    return 'Sei qui: $escena';
  }

  @override
  String vista360De(String escena) {
    return 'Vista a 360° di $escena';
  }

  @override
  String get conocisteTodo => 'Hai visto tutto il percorso';

  @override
  String get cierreTexto =>
      'Hai visto i luoghi che fanno la vita quotidiana dell’UTB. Quando vuoi, torna in uno qualsiasi.';

  @override
  String get seguirExplorando => 'Continua a esplorare';

  @override
  String get idioma => 'Lingua';

  @override
  String get idiomaDelTelefono => 'Lingua del telefono';

  @override
  String get accesibilidad => 'Accessibilità';

  @override
  String get tamanoTexto => 'Dimensione del testo';

  @override
  String get tamanoNormal => 'Normale';

  @override
  String get tamanoGrande => 'Grande';

  @override
  String get tamanoMuyGrande => 'Molto grande';

  @override
  String get muestraTexto =>
      'Ecco come si legge il testo con questa dimensione.';

  @override
  String get altoContraste => 'Contrasto elevato';

  @override
  String get altoContrasteDetalle => 'Testi e bordi più marcati.';

  @override
  String get reducirMovimiento => 'Riduci movimento';

  @override
  String get reducirMovimientoDetalle =>
      'Elimina animazioni, rotazioni ed effetti 3D.';

  @override
  String get movimientoTelefonoDetalle =>
      'Nel percorso a 360°, la vista segue i movimenti del telefono.';

  @override
  String get subtitulosDetalle =>
      'Mostra il testo della narrazione durante la riproduzione.';

  @override
  String get ajustesSistema =>
      'Queste impostazioni si aggiungono a quelle di accessibilità del telefono.';
}

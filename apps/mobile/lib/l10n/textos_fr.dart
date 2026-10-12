// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'textos.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class TextosFr extends Textos {
  TextosFr([String locale = 'fr']) : super(locale);

  @override
  String get tituloApp => 'UTB Visite virtuelle';

  @override
  String get tourVirtual => 'Visite virtuelle';

  @override
  String get volver => 'Retour';

  @override
  String get reintentar => 'Réessayer';

  @override
  String get listo => 'Terminé';

  @override
  String get falloConexion =>
      'Connexion impossible. Vérifiez votre connexion internet et réessayez.';

  @override
  String get falloTiempo =>
      'Le serveur a mis trop de temps à répondre. Réessayez.';

  @override
  String get falloSesion =>
      'Votre session a expiré. Reconnectez-vous pour continuer.';

  @override
  String get falloSinContenido => 'Aucun contenu n’est encore disponible ici.';

  @override
  String get falloInesperado =>
      'Une erreur s’est produite. Réessayez dans un instant.';

  @override
  String get falloPanoramasSoloConApi =>
      'Les panoramas ne s’affichent que lorsque l’appli est connectée à l’API.';

  @override
  String get enlaceInvalido => 'Ce lien n’est pas valide.';

  @override
  String get rutaPorDefecto => 'Visite du campus';

  @override
  String cantidadLugares(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total lieux',
      one: '1 lieu',
    );
    return '$_temp0';
  }

  @override
  String get titularSinLugares => 'Aucun lieu pour l’instant';

  @override
  String get titularEmpieza => 'Commencez votre visite';

  @override
  String get recorridoCompleto => 'Visite terminée';

  @override
  String titularAvance(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      hechos,
      locale: localeName,
      other: 'Vous avez visité $hechos lieux sur $total',
      one: 'Vous avez visité 1 lieu sur $total',
    );
    return '$_temp0';
  }

  @override
  String get detalleEmpieza => 'Découvrez le campus, un lieu à la fois.';

  @override
  String get detalleCompleto =>
      'Revenez dans n’importe quel lieu quand vous voulez.';

  @override
  String detalleSiguiente(String nombre) {
    return 'Prochain lieu : $nombre';
  }

  @override
  String lugaresVisitados(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      hechos,
      locale: localeName,
      other: '$hechos lieux visités sur $total',
      one: '1 lieu visité sur $total',
      zero: '0 lieu visité sur $total',
    );
    return '$_temp0';
  }

  @override
  String get modoRecorrido => 'Parcours';

  @override
  String get modoMapa => 'Carte';

  @override
  String get idiomaYAccesibilidad => 'Langue et accessibilité';

  @override
  String get sinLugaresPublicados =>
      'Aucun lieu n’a encore été publié dans ce parcours.';

  @override
  String get paradas => 'Étapes';

  @override
  String avanceLugares(int hechos, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$hechos sur $total lieux',
      one: '$hechos sur 1 lieu',
    );
    return '$_temp0';
  }

  @override
  String conocisteLosLugares(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Vous avez découvert les $total lieux',
      one: 'Vous avez découvert le lieu',
    );
    return '$_temp0';
  }

  @override
  String get vuelveACualquiera => 'Revenez-y quand vous voulez.';

  @override
  String get volverAEmpezar => 'Recommencer';

  @override
  String get primeraParada => 'Première étape';

  @override
  String get empezarRecorrido => 'Commencer la visite';

  @override
  String get siguienteParada => 'Étape suivante';

  @override
  String get continuarRecorrido => 'Continuer la visite';

  @override
  String paradaNDeTotal(int numero, int total) {
    return 'Étape $numero sur $total';
  }

  @override
  String get visitado => 'Visité';

  @override
  String get lugarDelCampus => 'Lieu du campus';

  @override
  String get campus => 'Campus';

  @override
  String yaVisitado(String nombre) {
    return '$nombre, déjà visité';
  }

  @override
  String paradaSemantica(int numero, String nombre) {
    return 'Étape $numero, $nombre';
  }

  @override
  String get sugerencia => 'Suggestion';

  @override
  String get sugerenciaTitulo => 'Situez chaque étape sur le campus';

  @override
  String get sugerenciaTexto =>
      'La carte montre où se trouve chaque lieu et ceux que vous avez déjà visités.';

  @override
  String get abrirMapa => 'Ouvrir la carte';

  @override
  String get pieOficial =>
      'Visite officielle de la Universidad Tecnológica de Bolívar';

  @override
  String get datosDemostracion => 'Données de démonstration';

  @override
  String get categoriaRecursos => 'Ressources';

  @override
  String get categoriaAcademico => 'Études';

  @override
  String get categoriaBienestar => 'Bien-être';

  @override
  String get categoriaServicios => 'Services';

  @override
  String get categoriaDeporte => 'Sport';

  @override
  String get verTodoCampus => 'Voir tout le campus';

  @override
  String get acercar => 'Zoom avant';

  @override
  String get alejar => 'Zoom arrière';

  @override
  String get mapaNoCargo => 'Impossible de charger la carte du campus.';

  @override
  String get mapaDescripcion =>
      'Carte illustrée du campus. Chaque étape a un repère numéroté.';

  @override
  String visitadosDeTotal(int hechos, int total) {
    return '$hechos sur $total visités';
  }

  @override
  String get sinUbicacionMapa => 'Absent de la carte';

  @override
  String get sinDescripcion => 'Ce lieu n’a pas encore de description.';

  @override
  String get verEn360 => 'Voir à 360°';

  @override
  String get sin360 => 'Ce lieu n’a pas encore de visite à 360°.';

  @override
  String get audioNarrado => 'Audio commenté';

  @override
  String get galeria => 'Galerie';

  @override
  String get video => 'Vidéo';

  @override
  String get lenguaDeSenas => 'Langue des signes';

  @override
  String get contenidoEnPreparacion => 'Contenu en préparation';

  @override
  String todaviaNoHay(String lista) {
    return 'Pas encore disponible : $lista';
  }

  @override
  String get fotos => 'Photos';

  @override
  String textoEnIdioma(String idioma) {
    return 'Informations disponibles en $idioma';
  }

  @override
  String get deslizaParaMirar => 'Faites glisser pour regarder';

  @override
  String get fotoDelLugar => 'Photo du lieu';

  @override
  String fotoNDeTotal(int numero, int total) {
    return '$numero sur $total';
  }

  @override
  String get fotoNoCargo => 'Impossible de charger cette photo.';

  @override
  String get videoNoCargo => 'Impossible de charger la vidéo.';

  @override
  String get pausarVideo => 'Mettre la vidéo en pause';

  @override
  String get reproducirVideo => 'Lire la vidéo';

  @override
  String get audioSinSoporte =>
      'L’audio ne peut pas être lu sur cette plateforme.';

  @override
  String get audioNoCargo => 'Impossible de charger l’audio.';

  @override
  String get pausarAudio => 'Mettre le commentaire en pause';

  @override
  String get escucharHistoria => 'Écouter l’histoire';

  @override
  String get escuchando => 'Écoute en cours';

  @override
  String get transcripcionEnPreparacion => 'Transcription en préparation';

  @override
  String get leerTranscripcion => 'Lire la transcription';

  @override
  String get transcripcion => 'Transcription';

  @override
  String get subtitulos => 'Sous-titres';

  @override
  String narracionEn(String idioma) {
    return 'Commentaire en $idioma';
  }

  @override
  String get escucharEn => 'Écouter en';

  @override
  String posicionDeTotal(String posicion, String total) {
    return '$posicion sur $total';
  }

  @override
  String vistaPanoramicaDe(String nombre) {
    return 'Vue panoramique de $nombre';
  }

  @override
  String get esteLugar => 'ce lieu';

  @override
  String get deslizaParaGirar => 'Faites glisser sur les côtés pour tourner';

  @override
  String get girarIzquierda => 'Tourner à gauche';

  @override
  String get girarDerecha => 'Tourner à droite';

  @override
  String get sinEscenas => 'Ce parcours n’a pas encore de scènes publiées.';

  @override
  String get siguienteEscena => 'Scène suivante';

  @override
  String get puntoDeInteres => 'Point d’intérêt';

  @override
  String get caminandoHacia => 'En route vers';

  @override
  String escenaNDeTotal(int numero, int total) {
    return 'Scène $numero sur $total';
  }

  @override
  String get pistaGiroscopio =>
      'Bougez le téléphone ou faites glisser pour regarder autour';

  @override
  String get pistaArrastre =>
      'Faites glisser ou utilisez les flèches pour regarder autour';

  @override
  String get preparando360 => 'Préparation de la visite à 360°';

  @override
  String get panoramaNoCargo => 'Impossible de charger ce panorama.';

  @override
  String get avanzarSiguienteEscena => 'Passer à la scène suivante';

  @override
  String get verInformacion => 'Voir les informations';

  @override
  String irA(String destino) {
    return 'Aller vers $destino';
  }

  @override
  String get desdeAquiPuedesIr => 'D’ici, vous pouvez aller vers';

  @override
  String get movimientoTelefono => 'Déplacer la vue avec le téléphone';

  @override
  String estasEn(String escena) {
    return 'Vous êtes ici : $escena';
  }

  @override
  String vista360De(String escena) {
    return 'Vue à 360° de $escena';
  }

  @override
  String get conocisteTodo => 'Vous avez fait toute la visite';

  @override
  String get cierreTexto =>
      'Vous avez vu les lieux qui font le quotidien de l’UTB. Revenez dans n’importe lequel quand vous voulez.';

  @override
  String get seguirExplorando => 'Continuer à explorer';

  @override
  String get idioma => 'Langue';

  @override
  String get idiomaDelTelefono => 'Langue du téléphone';

  @override
  String get accesibilidad => 'Accessibilité';

  @override
  String get tamanoTexto => 'Taille du texte';

  @override
  String get tamanoNormal => 'Normale';

  @override
  String get tamanoGrande => 'Grande';

  @override
  String get tamanoMuyGrande => 'Très grande';

  @override
  String get muestraTexto => 'Voici le texte à cette taille.';

  @override
  String get altoContraste => 'Contraste élevé';

  @override
  String get altoContrasteDetalle => 'Textes et contours plus marqués.';

  @override
  String get reducirMovimiento => 'Réduire les animations';

  @override
  String get reducirMovimientoDetalle =>
      'Supprime les animations, les rotations et les effets 3D.';

  @override
  String get movimientoTelefonoDetalle =>
      'Dans la visite à 360°, la vue suit les mouvements du téléphone.';

  @override
  String get subtitulosDetalle =>
      'Affiche le texte du commentaire pendant la lecture.';

  @override
  String get ajustesSistema =>
      'Ces réglages s’ajoutent à ceux d’accessibilité de votre téléphone.';
}

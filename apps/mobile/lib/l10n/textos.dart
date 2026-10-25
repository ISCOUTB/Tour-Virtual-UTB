import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'textos_de.dart';
import 'textos_en.dart';
import 'textos_es.dart';
import 'textos_fr.dart';
import 'textos_it.dart';
import 'textos_ja.dart';
import 'textos_ko.dart';
import 'textos_pt.dart';
import 'textos_tr.dart';
import 'textos_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of Textos
/// returned by `Textos.of(context)`.
///
/// Applications need to include `Textos.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/textos.dart';
///
/// return MaterialApp(
///   localizationsDelegates: Textos.localizationsDelegates,
///   supportedLocales: Textos.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the Textos.supportedLocales
/// property.
abstract class Textos {
  Textos(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static Textos of(BuildContext context) {
    return Localizations.of<Textos>(context, Textos)!;
  }

  static const LocalizationsDelegate<Textos> delegate = _TextosDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('es'),
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('pt', 'PT'),
    Locale('tr'),
    Locale('zh'),
  ];

  /// Nombre de la aplicación en el selector de tareas del sistema.
  ///
  /// In es, this message translates to:
  /// **'UTB Tour Virtual'**
  String get tituloApp;

  /// Título del módulo. En la cabecera y, en mayúsculas, en la pantalla de arranque.
  ///
  /// In es, this message translates to:
  /// **'Tour virtual'**
  String get tourVirtual;

  /// No description provided for @volver.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get volver;

  /// No description provided for @reintentar.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get reintentar;

  /// No description provided for @listo.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get listo;

  /// No description provided for @falloConexion.
  ///
  /// In es, this message translates to:
  /// **'No pudimos conectarnos. Revisa tu conexión a internet e intenta de nuevo.'**
  String get falloConexion;

  /// No description provided for @falloTiempo.
  ///
  /// In es, this message translates to:
  /// **'El servidor tardó demasiado en responder. Intenta de nuevo.'**
  String get falloTiempo;

  /// No description provided for @falloSesion.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión expiró. Vuelve a entrar para continuar.'**
  String get falloSesion;

  /// No description provided for @falloSinContenido.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay contenido disponible aquí.'**
  String get falloSinContenido;

  /// No description provided for @falloInesperado.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal. Intenta de nuevo en un momento.'**
  String get falloInesperado;

  /// Solo aparece en el modo de demostración para el equipo de desarrollo.
  ///
  /// In es, this message translates to:
  /// **'Las panorámicas solo se ven con la app conectada a la API.'**
  String get falloPanoramasSoloConApi;

  /// No description provided for @enlaceInvalido.
  ///
  /// In es, this message translates to:
  /// **'Ese enlace no es válido.'**
  String get enlaceInvalido;

  /// Nombre del recorrido cuando el servidor no envía uno.
  ///
  /// In es, this message translates to:
  /// **'Recorrido del campus'**
  String get rutaPorDefecto;

  /// No description provided for @cantidadLugares.
  ///
  /// In es, this message translates to:
  /// **'{total, plural, =1{1 lugar} other{{total} lugares}}'**
  String cantidadLugares(int total);

  /// No description provided for @titularSinLugares.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay lugares'**
  String get titularSinLugares;

  /// No description provided for @titularEmpieza.
  ///
  /// In es, this message translates to:
  /// **'Empieza tu recorrido'**
  String get titularEmpieza;

  /// No description provided for @recorridoCompleto.
  ///
  /// In es, this message translates to:
  /// **'Recorrido completo'**
  String get recorridoCompleto;

  /// No description provided for @titularAvance.
  ///
  /// In es, this message translates to:
  /// **'{total, plural, =1{Llevas {hechos} de 1 lugar} other{Llevas {hechos} de {total} lugares}}'**
  String titularAvance(int hechos, int total);

  /// No description provided for @detalleEmpieza.
  ///
  /// In es, this message translates to:
  /// **'Conoce el campus, un lugar a la vez.'**
  String get detalleEmpieza;

  /// No description provided for @detalleCompleto.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a cualquier lugar cuando quieras.'**
  String get detalleCompleto;

  /// Nombre del próximo lugar por visitar.
  ///
  /// In es, this message translates to:
  /// **'Siguiente: {nombre}'**
  String detalleSiguiente(String nombre);

  /// Lo lee el lector de pantalla en el anillo de avance.
  ///
  /// In es, this message translates to:
  /// **'{total, plural, =1{{hechos} de 1 lugar visitado} other{{hechos} de {total} lugares visitados}}'**
  String lugaresVisitados(int hechos, int total);

  /// Pestaña con la lista de paradas. Corta: comparte fila con «Mapa».
  ///
  /// In es, this message translates to:
  /// **'Recorrido'**
  String get modoRecorrido;

  /// No description provided for @modoMapa.
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get modoMapa;

  /// No description provided for @idiomaYAccesibilidad.
  ///
  /// In es, this message translates to:
  /// **'Idioma y accesibilidad'**
  String get idiomaYAccesibilidad;

  /// No description provided for @sinLugaresPublicados.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay lugares publicados en este recorrido.'**
  String get sinLugaresPublicados;

  /// Encabezado de la lista de lugares del recorrido.
  ///
  /// In es, this message translates to:
  /// **'Paradas'**
  String get paradas;

  /// No description provided for @avanceLugares.
  ///
  /// In es, this message translates to:
  /// **'{total, plural, =1{{hechos} de 1 lugar} other{{hechos} de {total} lugares}}'**
  String avanceLugares(int hechos, int total);

  /// No description provided for @conocisteLosLugares.
  ///
  /// In es, this message translates to:
  /// **'{total, plural, =1{Conociste el lugar} other{Conociste los {total} lugares}}'**
  String conocisteLosLugares(int total);

  /// No description provided for @vuelveACualquiera.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a cualquiera cuando quieras.'**
  String get vuelveACualquiera;

  /// No description provided for @volverAEmpezar.
  ///
  /// In es, this message translates to:
  /// **'Volver a empezar'**
  String get volverAEmpezar;

  /// No description provided for @primeraParada.
  ///
  /// In es, this message translates to:
  /// **'Primera parada'**
  String get primeraParada;

  /// No description provided for @empezarRecorrido.
  ///
  /// In es, this message translates to:
  /// **'Empezar recorrido'**
  String get empezarRecorrido;

  /// No description provided for @siguienteParada.
  ///
  /// In es, this message translates to:
  /// **'Siguiente parada'**
  String get siguienteParada;

  /// No description provided for @continuarRecorrido.
  ///
  /// In es, this message translates to:
  /// **'Continuar recorrido'**
  String get continuarRecorrido;

  /// No description provided for @paradaNDeTotal.
  ///
  /// In es, this message translates to:
  /// **'Parada {numero} de {total}'**
  String paradaNDeTotal(int numero, int total);

  /// No description provided for @visitado.
  ///
  /// In es, this message translates to:
  /// **'Visitado'**
  String get visitado;

  /// Se muestra en lugar de la categoría cuando un lugar no tiene una.
  ///
  /// In es, this message translates to:
  /// **'Lugar del campus'**
  String get lugarDelCampus;

  /// No description provided for @campus.
  ///
  /// In es, this message translates to:
  /// **'Campus'**
  String get campus;

  /// Lo lee el lector de pantalla: nombre del lugar y su estado.
  ///
  /// In es, this message translates to:
  /// **'{nombre}, ya visitado'**
  String yaVisitado(String nombre);

  /// Lo lee el lector de pantalla en el mapa.
  ///
  /// In es, this message translates to:
  /// **'Parada {numero}, {nombre}'**
  String paradaSemantica(int numero, String nombre);

  /// No description provided for @sugerencia.
  ///
  /// In es, this message translates to:
  /// **'Sugerencia'**
  String get sugerencia;

  /// No description provided for @sugerenciaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Ubica cada parada en el campus'**
  String get sugerenciaTitulo;

  /// No description provided for @sugerenciaTexto.
  ///
  /// In es, this message translates to:
  /// **'El mapa muestra dónde queda cada lugar y cuáles ya visitaste.'**
  String get sugerenciaTexto;

  /// No description provided for @abrirMapa.
  ///
  /// In es, this message translates to:
  /// **'Abrir el mapa'**
  String get abrirMapa;

  /// No description provided for @pieOficial.
  ///
  /// In es, this message translates to:
  /// **'Recorrido oficial de la Universidad Tecnológica de Bolívar'**
  String get pieOficial;

  /// No description provided for @datosDemostracion.
  ///
  /// In es, this message translates to:
  /// **'Datos de demostración'**
  String get datosDemostracion;

  /// Categoría de lugar: biblioteca y recursos de estudio.
  ///
  /// In es, this message translates to:
  /// **'Recursos'**
  String get categoriaRecursos;

  /// No description provided for @categoriaAcademico.
  ///
  /// In es, this message translates to:
  /// **'Académico'**
  String get categoriaAcademico;

  /// Categoría de lugar: salud, enfermería y apoyo a estudiantes.
  ///
  /// In es, this message translates to:
  /// **'Bienestar'**
  String get categoriaBienestar;

  /// Categoría de lugar: comida, tiendas y zonas comunes.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get categoriaServicios;

  /// No description provided for @categoriaDeporte.
  ///
  /// In es, this message translates to:
  /// **'Deporte'**
  String get categoriaDeporte;

  /// No description provided for @categoriaCultura.
  ///
  /// In es, this message translates to:
  /// **'Cultura'**
  String get categoriaCultura;

  /// No description provided for @categoriaAdministrativo.
  ///
  /// In es, this message translates to:
  /// **'Administrativo'**
  String get categoriaAdministrativo;

  /// No description provided for @categoriaSostenibilidad.
  ///
  /// In es, this message translates to:
  /// **'Sostenibilidad'**
  String get categoriaSostenibilidad;

  /// No description provided for @verTodoCampus.
  ///
  /// In es, this message translates to:
  /// **'Ver todo el campus'**
  String get verTodoCampus;

  /// No description provided for @acercar.
  ///
  /// In es, this message translates to:
  /// **'Acercar'**
  String get acercar;

  /// No description provided for @alejar.
  ///
  /// In es, this message translates to:
  /// **'Alejar'**
  String get alejar;

  /// No description provided for @mapaNoCargo.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar el mapa del campus.'**
  String get mapaNoCargo;

  /// No description provided for @mapaDescripcion.
  ///
  /// In es, this message translates to:
  /// **'Plano del campus. Cada parada tiene un marcador numerado y los demás lugares, un punto.'**
  String get mapaDescripcion;

  /// No description provided for @visitadosDeTotal.
  ///
  /// In es, this message translates to:
  /// **'{hechos} de {total} visitados'**
  String visitadosDeTotal(int hechos, int total);

  /// No description provided for @sinUbicacionMapa.
  ///
  /// In es, this message translates to:
  /// **'Sin ubicación en el mapa'**
  String get sinUbicacionMapa;

  /// No description provided for @masLugares.
  ///
  /// In es, this message translates to:
  /// **'Más lugares del campus'**
  String get masLugares;

  /// No description provided for @creditoOsm.
  ///
  /// In es, this message translates to:
  /// **'© colaboradores de OpenStreetMap'**
  String get creditoOsm;

  /// No description provided for @sinDescripcion.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay descripción de este lugar.'**
  String get sinDescripcion;

  /// No description provided for @verEn360.
  ///
  /// In es, this message translates to:
  /// **'Ver en 360°'**
  String get verEn360;

  /// No description provided for @sin360.
  ///
  /// In es, this message translates to:
  /// **'Este lugar todavía no tiene recorrido en 360°.'**
  String get sin360;

  /// No description provided for @audioNarrado.
  ///
  /// In es, this message translates to:
  /// **'Audio narrado'**
  String get audioNarrado;

  /// No description provided for @galeria.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get galeria;

  /// No description provided for @video.
  ///
  /// In es, this message translates to:
  /// **'Video'**
  String get video;

  /// Sección con el video en Lengua de Señas Colombiana.
  ///
  /// In es, this message translates to:
  /// **'Lengua de señas'**
  String get lenguaDeSenas;

  /// No description provided for @contenidoEnPreparacion.
  ///
  /// In es, this message translates to:
  /// **'Contenido en preparación'**
  String get contenidoEnPreparacion;

  /// Recursos que aún faltan, separados por «·». Ejemplo: «Fotos · Video».
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay: {lista}'**
  String todaviaNoHay(String lista);

  /// No description provided for @fotos.
  ///
  /// In es, this message translates to:
  /// **'Fotos'**
  String get fotos;

  /// Aviso cuando la descripción del lugar no está traducida. {idioma} es el nombre del idioma en ese idioma, por ejemplo «Español».
  ///
  /// In es, this message translates to:
  /// **'Información disponible en {idioma}'**
  String textoEnIdioma(String idioma);

  /// No description provided for @deslizaParaMirar.
  ///
  /// In es, this message translates to:
  /// **'Desliza para mirar'**
  String get deslizaParaMirar;

  /// No description provided for @fotoDelLugar.
  ///
  /// In es, this message translates to:
  /// **'Foto del lugar'**
  String get fotoDelLugar;

  /// No description provided for @fotoNDeTotal.
  ///
  /// In es, this message translates to:
  /// **'{numero} de {total}'**
  String fotoNDeTotal(int numero, int total);

  /// No description provided for @fotoNoCargo.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar esta foto.'**
  String get fotoNoCargo;

  /// No description provided for @videoNoCargo.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar el video.'**
  String get videoNoCargo;

  /// No description provided for @pausarVideo.
  ///
  /// In es, this message translates to:
  /// **'Pausar video'**
  String get pausarVideo;

  /// No description provided for @reproducirVideo.
  ///
  /// In es, this message translates to:
  /// **'Reproducir video'**
  String get reproducirVideo;

  /// No description provided for @audioSinSoporte.
  ///
  /// In es, this message translates to:
  /// **'El audio no se puede reproducir en esta plataforma.'**
  String get audioSinSoporte;

  /// No description provided for @audioNoCargo.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar el audio.'**
  String get audioNoCargo;

  /// No description provided for @pausarAudio.
  ///
  /// In es, this message translates to:
  /// **'Pausar audio narrado'**
  String get pausarAudio;

  /// No description provided for @escucharHistoria.
  ///
  /// In es, this message translates to:
  /// **'Escuchar historia'**
  String get escucharHistoria;

  /// No description provided for @escuchando.
  ///
  /// In es, this message translates to:
  /// **'Escuchando'**
  String get escuchando;

  /// No description provided for @transcripcionEnPreparacion.
  ///
  /// In es, this message translates to:
  /// **'Transcripción en preparación'**
  String get transcripcionEnPreparacion;

  /// No description provided for @leerTranscripcion.
  ///
  /// In es, this message translates to:
  /// **'Leer la transcripción'**
  String get leerTranscripcion;

  /// No description provided for @transcripcion.
  ///
  /// In es, this message translates to:
  /// **'Transcripción'**
  String get transcripcion;

  /// No description provided for @subtitulos.
  ///
  /// In es, this message translates to:
  /// **'Subtítulos'**
  String get subtitulos;

  /// {idioma} es el nombre del idioma en ese idioma, por ejemplo «Español».
  ///
  /// In es, this message translates to:
  /// **'Narración en {idioma}'**
  String narracionEn(String idioma);

  /// No description provided for @escucharEn.
  ///
  /// In es, this message translates to:
  /// **'Escuchar en'**
  String get escucharEn;

  /// Posición del audio para el lector de pantalla, por ejemplo «0:05 de 0:12».
  ///
  /// In es, this message translates to:
  /// **'{posicion} de {total}'**
  String posicionDeTotal(String posicion, String total);

  /// No description provided for @vistaPanoramicaDe.
  ///
  /// In es, this message translates to:
  /// **'Vista panorámica de {nombre}'**
  String vistaPanoramicaDe(String nombre);

  /// No description provided for @esteLugar.
  ///
  /// In es, this message translates to:
  /// **'este lugar'**
  String get esteLugar;

  /// No description provided for @deslizaParaGirar.
  ///
  /// In es, this message translates to:
  /// **'Desliza a los lados para girar'**
  String get deslizaParaGirar;

  /// No description provided for @girarIzquierda.
  ///
  /// In es, this message translates to:
  /// **'Girar a la izquierda'**
  String get girarIzquierda;

  /// No description provided for @girarDerecha.
  ///
  /// In es, this message translates to:
  /// **'Girar a la derecha'**
  String get girarDerecha;

  /// No description provided for @sinEscenas.
  ///
  /// In es, this message translates to:
  /// **'Este recorrido todavía no tiene escenas publicadas.'**
  String get sinEscenas;

  /// No description provided for @siguienteEscena.
  ///
  /// In es, this message translates to:
  /// **'Siguiente escena'**
  String get siguienteEscena;

  /// No description provided for @puntoDeInteres.
  ///
  /// In es, this message translates to:
  /// **'Punto de interés'**
  String get puntoDeInteres;

  /// Aparece sobre el nombre del destino mientras se pasa de una escena 360 a otra.
  ///
  /// In es, this message translates to:
  /// **'Caminando hacia'**
  String get caminandoHacia;

  /// No description provided for @escenaNDeTotal.
  ///
  /// In es, this message translates to:
  /// **'Escena {numero} de {total}'**
  String escenaNDeTotal(int numero, int total);

  /// No description provided for @pistaGiroscopio.
  ///
  /// In es, this message translates to:
  /// **'Mueve el teléfono o arrastra para mirar alrededor'**
  String get pistaGiroscopio;

  /// No description provided for @pistaArrastre.
  ///
  /// In es, this message translates to:
  /// **'Arrastra o usa las flechas para mirar alrededor'**
  String get pistaArrastre;

  /// No description provided for @preparando360.
  ///
  /// In es, this message translates to:
  /// **'Preparando el recorrido 360°'**
  String get preparando360;

  /// No description provided for @panoramaNoCargo.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar esta panorámica.'**
  String get panoramaNoCargo;

  /// No description provided for @avanzarSiguienteEscena.
  ///
  /// In es, this message translates to:
  /// **'Avanzar a la siguiente escena'**
  String get avanzarSiguienteEscena;

  /// No description provided for @verInformacion.
  ///
  /// In es, this message translates to:
  /// **'Ver información'**
  String get verInformacion;

  /// Botón para caminar a otra escena 360. {destino} es el nombre del lugar.
  ///
  /// In es, this message translates to:
  /// **'Ir a {destino}'**
  String irA(String destino);

  /// No description provided for @desdeAquiPuedesIr.
  ///
  /// In es, this message translates to:
  /// **'Desde aquí puedes ir a'**
  String get desdeAquiPuedesIr;

  /// No description provided for @movimientoTelefono.
  ///
  /// In es, this message translates to:
  /// **'Mover la vista con el teléfono'**
  String get movimientoTelefono;

  /// Lo anuncia el lector de pantalla al llegar a una escena 360.
  ///
  /// In es, this message translates to:
  /// **'Estás en {escena}'**
  String estasEn(String escena);

  /// No description provided for @vista360De.
  ///
  /// In es, this message translates to:
  /// **'Vista 360° de {escena}'**
  String vista360De(String escena);

  /// No description provided for @conocisteTodo.
  ///
  /// In es, this message translates to:
  /// **'Conociste todo el recorrido'**
  String get conocisteTodo;

  /// No description provided for @cierreTexto.
  ///
  /// In es, this message translates to:
  /// **'Ya viste los lugares que hacen el día a día en la UTB. Cuando quieras, vuelve a cualquiera de ellos.'**
  String get cierreTexto;

  /// No description provided for @seguirExplorando.
  ///
  /// In es, this message translates to:
  /// **'Seguir explorando'**
  String get seguirExplorando;

  /// No description provided for @idioma.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get idioma;

  /// No description provided for @idiomaDelTelefono.
  ///
  /// In es, this message translates to:
  /// **'Idioma del teléfono'**
  String get idiomaDelTelefono;

  /// No description provided for @accesibilidad.
  ///
  /// In es, this message translates to:
  /// **'Accesibilidad'**
  String get accesibilidad;

  /// No description provided for @tamanoTexto.
  ///
  /// In es, this message translates to:
  /// **'Tamaño del texto'**
  String get tamanoTexto;

  /// No description provided for @tamanoNormal.
  ///
  /// In es, this message translates to:
  /// **'Normal'**
  String get tamanoNormal;

  /// No description provided for @tamanoGrande.
  ///
  /// In es, this message translates to:
  /// **'Grande'**
  String get tamanoGrande;

  /// No description provided for @tamanoMuyGrande.
  ///
  /// In es, this message translates to:
  /// **'Muy grande'**
  String get tamanoMuyGrande;

  /// No description provided for @muestraTexto.
  ///
  /// In es, this message translates to:
  /// **'Así se lee el texto con este tamaño.'**
  String get muestraTexto;

  /// No description provided for @altoContraste.
  ///
  /// In es, this message translates to:
  /// **'Alto contraste'**
  String get altoContraste;

  /// No description provided for @altoContrasteDetalle.
  ///
  /// In es, this message translates to:
  /// **'Textos y bordes más marcados.'**
  String get altoContrasteDetalle;

  /// No description provided for @reducirMovimiento.
  ///
  /// In es, this message translates to:
  /// **'Reducir movimiento'**
  String get reducirMovimiento;

  /// No description provided for @reducirMovimientoDetalle.
  ///
  /// In es, this message translates to:
  /// **'Quita animaciones, giros y efectos 3D.'**
  String get reducirMovimientoDetalle;

  /// No description provided for @movimientoTelefonoDetalle.
  ///
  /// In es, this message translates to:
  /// **'En el recorrido 360°, la vista sigue el movimiento del teléfono.'**
  String get movimientoTelefonoDetalle;

  /// No description provided for @subtitulosDetalle.
  ///
  /// In es, this message translates to:
  /// **'Muestra el texto de la narración mientras suena.'**
  String get subtitulosDetalle;

  /// No description provided for @ajustesSistema.
  ///
  /// In es, this message translates to:
  /// **'Estos ajustes se suman a los de accesibilidad de tu teléfono.'**
  String get ajustesSistema;
}

class _TextosDelegate extends LocalizationsDelegate<Textos> {
  const _TextosDelegate();

  @override
  Future<Textos> load(Locale locale) {
    return SynchronousFuture<Textos>(lookupTextos(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'ko',
    'pt',
    'tr',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_TextosDelegate old) => false;
}

Textos lookupTextos(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'PT':
            return TextosPtPt();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return TextosDe();
    case 'en':
      return TextosEn();
    case 'es':
      return TextosEs();
    case 'fr':
      return TextosFr();
    case 'it':
      return TextosIt();
    case 'ja':
      return TextosJa();
    case 'ko':
      return TextosKo();
    case 'pt':
      return TextosPt();
    case 'tr':
      return TextosTr();
    case 'zh':
      return TextosZh();
  }

  throw FlutterError(
    'Textos.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

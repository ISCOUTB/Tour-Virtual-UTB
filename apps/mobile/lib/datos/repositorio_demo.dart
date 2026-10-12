import 'dart:convert';

import 'package:http/http.dart' as http;

import '../nucleo/configuracion.dart';
import '../nucleo/errores.dart';
import '../nucleo/idiomas.dart';
import 'modelos/modelos.dart';
import 'repositorio_contenido.dart';
import 'subtitulos.dart';

/// Contenido local para diseñar el frontend sin levantar la API.
///
/// Es una copia de `services/api/Data/ContenidoInicial.cs`, filtrada como la
/// vería un visitante externo: el puente A3-A5 queda fuera porque es solo para
/// estudiantes y docentes. No inventa nada que el seed no tenga; si el seed
/// cambia, esta copia se actualiza a mano.
///
/// Se activa con `--dart-define=DATOS=demo` y nunca en una compilación normal.
/// Con `MEDIOS_DEMO` además sirve las escenas, los hotspots y los audios del
/// seed desde esa carpeta; sin ella no hay panorámicas que mostrar.
///
/// En esa carpeta también encuentra las narraciones por idioma y sus
/// subtítulos, si están, para revisarlos en la app antes de que el backend
/// sepa guardarlos (nombres en docs/ACCESIBILIDAD.md):
///
/// ```text
/// audios/biblioteca.mp3          original en español
/// audios/biblioteca.en.mp3       narración en inglés
/// subtitulos/biblioteca.vtt      subtítulos del original
/// subtitulos/biblioteca.en.vtt   subtítulos de la narración en inglés
/// ```
class RepositorioDemo implements RepositorioContenido {
  const RepositorioDemo({this.medios = Configuracion.mediosDemo, this.cliente});

  /// URL base de los medios locales. Vacía, el demo no tiene panorámicas.
  final String medios;

  /// Para las pruebas. Nulo, cada consulta abre y cierra el suyo.
  final http.Client? cliente;

  String get _base => medios.replaceFirst(RegExp(r'/$'), '');

  /// El seed está escrito en español.
  @override
  String get idiomaContenido => idiomaOriginal.languageCode;

  /// POI → (slug de sus archivos, duración del audio en segundos).
  static const _archivos = {
    1: ('biblioteca', 10),
    3: ('enfermeria', 11),
    4: ('zona-t', 11),
    5: ('cancha-softbol', 12),
  };

  static const _pois = [
    Poi(
      id: 1,
      lugarId: 1,
      nombre: 'Biblioteca',
      categoria: 'Recursos',
      descripcion:
          'Mas que una biblioteca: concentracion, disciplina, tecnologia y '
          'construccion de suenos.',
      mapX: .4067,
      mapY: .2745,
      escenaPrincipalId: 1,
      audiencias: [Audiencia.externo, Audiencia.estudiante, Audiencia.docente],
    ),
    Poi(
      id: 3,
      lugarId: 1,
      nombre: 'Enfermeria',
      categoria: 'Bienestar',
      descripcion:
          'Servicio de atencion primaria del campus: consulta, curaciones y '
          'primeros auxilios.',
      mapX: .6186,
      mapY: .5055,
      escenaPrincipalId: 3,
      audiencias: [Audiencia.externo, Audiencia.estudiante, Audiencia.docente],
    ),
    Poi(
      id: 4,
      lugarId: 1,
      nombre: 'Zona T',
      categoria: 'Servicios',
      descripcion:
          'Zona de mesas al aire libre y a la sombra, junto al Centro '
          'Deportivo y Cultural.',
      mapX: .545,
      mapY: .555,
      escenaPrincipalId: 4,
      audiencias: [Audiencia.externo, Audiencia.estudiante, Audiencia.docente],
    ),
    Poi(
      id: 5,
      lugarId: 1,
      nombre: 'Cancha de softbol',
      categoria: 'Deporte',
      descripcion:
          'Campo abierto del area deportiva, usado para softbol y '
          'entrenamientos.',
      mapX: .5195,
      mapY: .658,
      escenaPrincipalId: 5,
      audiencias: [Audiencia.externo, Audiencia.estudiante, Audiencia.docente],
    ),
  ];

  @override
  Future<List<Poi>> obtenerPois(int lugarId) async => _pois;

  @override
  Future<PoiDetalle> obtenerPoiDetalle(int poiId) async {
    final poi = _pois.where((p) => p.id == poiId).firstOrNull;
    if (poi == null) throw const FalloSinContenido();
    final archivo = _archivos[poiId];
    if (medios.isEmpty || archivo == null) return PoiDetalle(poi: poi);

    final (slug, duracion) = archivo;
    final otros = [
      for (final idioma in idiomasUi)
        if (!mismoIdioma(idioma.locale.languageCode, 'es') ||
            idioma.locale.countryCode != null)
          idioma.locale.toLanguageTag(),
    ];

    // La original se da por hecha, como antes; el resto solo si el archivo
    // está en la carpeta.
    final (subtituloOriginal, extras) = await (
      _primeraQueExista([
        '$_base/subtitulos/$slug.vtt',
        '$_base/subtitulos/$slug.es.vtt',
      ]),
      Future.wait([for (final idioma in otros) _narracion(slug, idioma)]),
    ).wait;

    return PoiDetalle(
      poi: poi,
      medios: [
        Medio(
          id: poiId * 100,
          poiId: poiId,
          tipo: TipoMedio.audio,
          url: '$_base/audios/$slug.mp3',
          duracionSeg: duracion,
          textoAlt: 'Audio narrado de ${poi.nombre}',
          subtitulosUrl: subtituloOriginal,
        ),
        for (final (i, extra) in extras.indexed)
          if (extra case (final url, final subtitulos))
            Medio(
              id: poiId * 100 + i + 1,
              poiId: poiId,
              tipo: TipoMedio.audio,
              url: url,
              idioma: otros[i],
              subtitulosUrl: subtitulos,
            ),
      ],
    );
  }

  /// Narración en [idioma] y sus subtítulos, si el audio existe.
  Future<(String, String?)?> _narracion(String slug, String idioma) async {
    final audio = '$_base/audios/$slug.$idioma.mp3';
    if (!await _existe(audio)) return null;
    return (
      audio,
      await _primeraQueExista(['$_base/subtitulos/$slug.$idioma.vtt']),
    );
  }

  Future<String?> _primeraQueExista(List<String> urls) async {
    for (final url in urls) {
      if (await _existe(url)) return url;
    }
    return null;
  }

  Future<bool> _existe(String url) async {
    final c = cliente ?? http.Client();
    try {
      final r = await c
          .head(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      if (cliente == null) c.close();
    }
  }

  @override
  Future<Recorrido> obtenerRecorrido(int lugarId) async {
    if (medios.isEmpty) {
      throw const FalloSinContenido.soloConApi();
    }

    // Escenas y hotspots del seed. Los del puente quedan fuera, igual que
    // la API se los oculta a un visitante externo.
    Escena escena(int id, String nombre, int orden, double yaw, double pitch) {
      final (slug, _) = _archivos[id]!;
      return Escena(
        id: id,
        lugarId: 1,
        poiId: id,
        nombre: nombre,
        imagenUrl: '$_base/panoramas/$slug.jpg',
        imagenUrlBaja: '$_base/panoramas/$slug-baja.jpg',
        esEscenaPrincipal: id == 1,
        orden: orden,
        vistaInicialYaw: yaw,
        vistaInicialPitch: pitch,
      );
    }

    Hotspot salto(
      int id,
      int desde,
      double pitch,
      double yaw,
      int hacia,
      String texto,
    ) => Hotspot(
      id: id,
      escenaId: desde,
      tipo: TipoHotspot.navegacion,
      pitch: pitch,
      yaw: yaw,
      escenaDestinoId: hacia,
      etiqueta: texto,
    );

    final escenas = [
      escena(1, 'Biblioteca', 0, 152, -5),
      escena(3, 'Enfermeria', 2, -158, -6),
      escena(4, 'Zona T', 3, -55, -6),
      escena(5, 'Cancha de softbol', 4, -40, -3),
    ];
    final hotspots = [
      salto(3, 3, -8, -172, 4, 'Ir a la Zona T'),
      salto(4, 4, -4, -66, 5, 'Ir a la cancha de softbol'),
      salto(5, 4, 1, -156, 3, 'Ir a Enfermeria'),
      salto(6, 5, -2, -34, 4, 'Ir a la Zona T'),
    ];
    return Recorrido(
      escenas: escenas,
      hotspotsPorEscena: {
        for (final e in escenas)
          e.id: hotspots.where((h) => h.escenaId == e.id).toList(),
      },
    );
  }

  /// Solo los que haya en la carpeta local: el seed no trae subtítulos y el
  /// demo no los inventa.
  @override
  Future<Subtitulos> obtenerSubtitulos(String url) async {
    final c = cliente ?? http.Client();
    try {
      final r = await c.get(Uri.parse(url));
      if (r.statusCode != 200) throw const FalloSinContenido();
      return Subtitulos.leer(utf8.decode(r.bodyBytes));
    } on FalloApp {
      rethrow;
    } catch (error) {
      throw FalloDeConexion(detalle: error);
    } finally {
      if (cliente == null) c.close();
    }
  }

  @override
  Future<Ruta?> obtenerRutaActual(int lugarId) async => const Ruta(
    id: 1,
    lugarId: 1,
    nombre: 'Conoce la UTB',
    descripcion: 'Recorrido institucional para visitantes.',
    audiencia: Audiencia.externo,
  );

  /// Sin URL, el mapa usa la ilustración empaquetada.
  @override
  Future<String?> obtenerUrlMapa(int lugarId) async => null;
}

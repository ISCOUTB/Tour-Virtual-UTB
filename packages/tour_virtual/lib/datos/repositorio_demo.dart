import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'fuente_medio.dart';
import '../nucleo/errores.dart';
import '../nucleo/idiomas.dart';
import 'modelos/modelos.dart';
import 'repositorio_contenido.dart';
import 'subtitulos.dart';

/// Contenido local para diseñar el frontend sin levantar la API.
///
/// Es una copia de `services/api/Data/ContenidoInicial.cs`, con el puente
/// A3-A5 visible para todos como en la base compartida. Los lugares, su
/// lat/lng y los textos del guion de estaciones salen del catálogo de
/// `scripts/mapa_campus.py`. No inventa nada que la base no tenga; si cambia,
/// esta copia se actualiza a mano.
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
  const RepositorioDemo({this.medios = '', this.cliente});

  /// URL base de los medios locales. Vacía, el demo no tiene panorámicas.
  /// `empaquetados` toma los que van dentro de la app ([FuenteMedio]).
  final String medios;

  /// Para las pruebas. Nulo, cada consulta abre y cierra el suyo.
  final http.Client? cliente;

  String get _base => medios == FuenteMedio.empaquetados
      ? 'asset:///${FuenteMedio.carpeta}'
      : medios.replaceFirst(RegExp(r'/$'), '');

  /// El seed está escrito en español.
  @override
  String get idiomaContenido => idiomaOriginal.languageCode;

  /// POI → (slug de sus archivos, duración del audio en segundos).
  ///
  /// Las duraciones son las de las narraciones en español generadas el
  /// 2026-10-24 (scripts/narraciones). Los tres últimos no son paradas: tienen
  /// narración pero todavía no panorámica.
  static const _archivos = {
    1: ('biblioteca', 7),
    2: ('puente-a3-a5', 14),
    3: ('enfermeria', 12),
    4: ('zona-t', 12),
    5: ('cancha-softbol', 11),
    24: ('solo-cafe', 12),
    25: ('la-placita', 9),
    26: ('quantalab', 10),
  };

  /// Qué se ve en cada panorámica, para el lector de pantalla. Copia de
  /// `scripts/datos/escenas_texto_alt.json`; la API todavía no tiene la
  /// columna.
  static const _textosAlt = {
    1:
        'Vestíbulo amplio y luminoso de la biblioteca, de techo alto y piso '
        'claro. En el centro hay un mostrador de atención curvo. A la '
        'izquierda se abre un pasillo largo con estanterías y mesas de '
        'lectura; a la derecha, mesas junto a ventanales que dan a un jardín '
        'con palmeras. Al fondo a la derecha, una escalera con el letrero de '
        'salida.',
    2:
        'Pasarela elevada y techada, con barandas metálicas a los dos lados, '
        'que une dos edificios de aulas de tres pisos. Desde ella se ven, '
        'abajo, árboles frondosos, senderos y un jardín con letras formadas '
        'por arbustos, y arriba, un cielo azul con nubes.',
    3:
        'Sala de atención de la enfermería, blanca y bien iluminada. A la '
        'izquierda hay un escritorio con computador y, junto a la puerta de '
        'entrada, una pequeña sala de espera con sillas verdes. Al centro y a '
        'la derecha, cubículos separados por cortinas, uno de ellos con '
        'biombos azules, y equipos como un tanque de oxígeno.',
    4:
        'Plazoleta al aire libre a la sombra de árboles grandes y palmeras, '
        'con mesas metálicas y sillas de colores. A un lado se abre una '
        'explanada de césped; al otro, un edificio con columnas y una '
        'escalera exterior de peldaños amarillos.',
    5:
        'Campo abierto de césped seco bajo un cielo azul con nubes, rodeado '
        'de árboles. Al fondo se ve el edificio deportivo de dos pisos, con '
        'una torre de luz.',
  };

  static const _todas = [
    Audiencia.externo,
    Audiencia.estudiante,
    Audiencia.docente,
  ];

  /// Lugares de `scripts/datos/pois_campus.json`, que genera
  /// `scripts/mapa_campus.py`: los cinco con panorámica son paradas; el
  /// resto, lugares del campus sin contenido todavía.
  static const _pois = [
    Poi(
      id: 1,
      lugarId: 1,
      nombre: 'Biblioteca',
      categoria: 'Recursos',
      descripcion:
          'Más que una biblioteca: concentración, disciplina, tecnología y '
          'construcción de sueños.',
      lat: 10.3699965,
      lng: -75.4650668,
      escenaPrincipalId: 1,
      audiencias: _todas,
    ),
    Poi(
      id: 2,
      lugarId: 1,
      nombre: 'Puente A3 - A5',
      categoria: 'Academico',
      descripcion:
          'Un punto que conecta espacios, personas y recorridos dentro del '
          'campus. Cada trayecto en la UTB hace parte de una experiencia que '
          'conecta tu presente con lo que quieres construir.',
      lat: 10.3692169,
      lng: -75.4647217,
      escenaPrincipalId: 2,
      audiencias: _todas,
    ),
    Poi(
      id: 3,
      lugarId: 1,
      nombre: 'Enfermería',
      categoria: 'Bienestar',
      descripcion:
          'Bienestar y cuidado integral. Un espacio para atender tu salud, '
          'recibir orientación y recordar que cuidar de ti también hace parte'
          ' de la experiencia universitaria.',
      lat: 10.3692651,
      lng: -75.4655196,
      escenaPrincipalId: 3,
      audiencias: _todas,
    ),
    Poi(
      id: 4,
      lugarId: 1,
      nombre: 'Zona T',
      categoria: 'Servicios',
      descripcion:
          'Punto de encuentro, pausa y conexión. Un lugar para compartir con '
          'otros estudiantes, conversar y disfrutar los espacios que hacen '
          'del campus una comunidad.',
      lat: 10.3691852,
      lng: -75.4655576,
      escenaPrincipalId: 4,
      audiencias: _todas,
    ),
    Poi(
      id: 5,
      lugarId: 1,
      nombre: 'Cancha de softbol',
      categoria: 'Deporte',
      descripcion:
          'El campus también se vive en movimiento. Espacio para el deporte, '
          'la disciplina, el trabajo en equipo y las experiencias que se '
          'construyen más allá del aula.',
      lat: 10.3695823,
      lng: -75.4663148,
      escenaPrincipalId: 5,
      audiencias: _todas,
    ),
    Poi(
      id: 6,
      lugarId: 1,
      nombre: 'Edificio A1',
      categoria: 'Academico',
      lat: 10.3697646,
      lng: -75.465347,
      audiencias: _todas,
    ),
    Poi(
      id: 7,
      lugarId: 1,
      nombre: 'Edificio A2',
      categoria: 'Academico',
      lat: 10.3707763,
      lng: -75.4656241,
      audiencias: _todas,
    ),
    Poi(
      id: 8,
      lugarId: 1,
      nombre: 'Edificio A3',
      categoria: 'Academico',
      lat: 10.3692983,
      lng: -75.4648329,
      audiencias: _todas,
    ),
    Poi(
      id: 9,
      lugarId: 1,
      nombre: 'Edificio A4',
      categoria: 'Academico',
      lat: 10.3695805,
      lng: -75.4645402,
      audiencias: _todas,
    ),
    Poi(
      id: 10,
      lugarId: 1,
      nombre: 'Edificio A5',
      categoria: 'Academico',
      lat: 10.3691355,
      lng: -75.4646105,
      audiencias: _todas,
    ),
    Poi(
      id: 11,
      lugarId: 1,
      nombre: 'Edificio Alcatraz',
      categoria: 'Academico',
      lat: 10.3703807,
      lng: -75.4652636,
      audiencias: _todas,
    ),
    Poi(
      id: 12,
      lugarId: 1,
      nombre: 'Auditorio',
      categoria: 'Cultura',
      lat: 10.3705694,
      lng: -75.4657944,
      audiencias: _todas,
    ),
    Poi(
      id: 13,
      lugarId: 1,
      nombre: 'Plaza Maloca',
      categoria: 'Cultura',
      lat: 10.3700456,
      lng: -75.4657625,
      audiencias: _todas,
    ),
    Poi(
      id: 14,
      lugarId: 1,
      nombre: 'Rectoría',
      categoria: 'Administrativo',
      lat: 10.3695939,
      lng: -75.4652554,
      audiencias: _todas,
    ),
    Poi(
      id: 15,
      lugarId: 1,
      nombre: 'Laboratorio El Patio',
      categoria: 'Academico',
      lat: 10.3696815,
      lng: -75.4650578,
      audiencias: _todas,
    ),
    Poi(
      id: 16,
      lugarId: 1,
      nombre: 'Centro de Cuidado Integral (QUID)',
      categoria: 'Bienestar',
      lat: 10.3690673,
      lng: -75.4658707,
      audiencias: _todas,
    ),
    Poi(
      id: 17,
      lugarId: 1,
      nombre: 'Centro Deportivo y Cultural',
      categoria: 'Deporte',
      lat: 10.3692615,
      lng: -75.4656845,
      audiencias: _todas,
    ),
    Poi(
      id: 18,
      lugarId: 1,
      nombre: 'Cancha de fútbol',
      categoria: 'Deporte',
      lat: 10.3701542,
      lng: -75.4667058,
      audiencias: _todas,
    ),
    Poi(
      id: 19,
      lugarId: 1,
      nombre: 'Salas de estudio',
      categoria: 'Recursos',
      lat: 10.3705483,
      lng: -75.4654429,
      audiencias: _todas,
    ),
    Poi(
      id: 20,
      lugarId: 1,
      nombre: 'Cafetería',
      categoria: 'Servicios',
      lat: 10.37042,
      lng: -75.4653547,
      audiencias: _todas,
    ),
    Poi(
      id: 21,
      lugarId: 1,
      nombre: 'Tienda',
      categoria: 'Servicios',
      lat: 10.3692206,
      lng: -75.4661076,
      audiencias: _todas,
    ),
    Poi(
      id: 22,
      lugarId: 1,
      nombre: 'Cajero automático',
      categoria: 'Servicios',
      lat: 10.3705307,
      lng: -75.4659036,
      audiencias: _todas,
    ),
    Poi(
      id: 23,
      lugarId: 1,
      nombre: 'Pasillo de la conexión',
      categoria: 'Administrativo',
      lat: 10.3707567,
      lng: -75.4659942,
      audiencias: _todas,
    ),
    Poi(
      id: 24,
      lugarId: 1,
      nombre: 'Solo Café',
      categoria: 'Servicios',
      descripcion:
          'Espacio de conexión, ideas y conversaciones que también '
          'transforman la experiencia universitaria. Aquí nacen amistades, '
          'proyectos y networking.',
      lat: 10.3702285,
      lng: -75.4655508,
      audiencias: _todas,
    ),
    Poi(
      id: 25,
      lugarId: 1,
      nombre: 'La Placita',
      categoria: 'Cultura',
      descripcion:
          'Inspirada en las plazas del Caribe. Un espacio creado para '
          'compartir, desconectarse y sentirse en casa dentro de la UTB.',
      lat: 10.3704913,
      lng: -75.465484,
      audiencias: _todas,
    ),
    Poi(
      id: 26,
      lugarId: 1,
      nombre: 'QuantaLab',
      categoria: 'Academico',
      descripcion:
          'Laboratorio de analítica, IA y datos. El futuro pertenece a '
          'quienes saben interpretar información y tomar decisiones.',
      lat: 10.3690907,
      lng: -75.4646518,
      audiencias: _todas,
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
    if (FuenteMedio.esEmpaquetado(url)) return FuenteMedio.existe(url);
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

    // Escenas y hotspots del seed, con los ángulos calibrados.
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
        textoAlt: _textosAlt[id],
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
      escena(2, 'Puente A3 - A5', 1, -58, -5),
      escena(3, 'Enfermeria', 2, -158, -6),
      escena(4, 'Zona T', 3, -55, -6),
      escena(5, 'Cancha de softbol', 4, -40, -3),
    ];
    final hotspots = [
      salto(1, 1, -12, 140, 2, 'Ir al puente A3 - A5'),
      salto(2, 2, -10, -68, 1, 'Ir a la Biblioteca'),
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
    if (FuenteMedio.esEmpaquetado(url)) {
      if (!await FuenteMedio.existe(url)) throw const FalloSinContenido();
      final datos = await rootBundle.load(FuenteMedio.claveDe(url));
      return Subtitulos.leer(
        utf8.decode(
          datos.buffer.asUint8List(datos.offsetInBytes, datos.lengthInBytes),
        ),
      );
    }
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
}

import 'dart:math';
import 'dart:typed_data';

import 'api/api_client.dart';
import 'models/escena.dart';
import 'models/poi.dart';
import 'repositories/escena_repository.dart';
import 'repositories/poi_repository.dart';

/// Sube la panorámica de un POI sin dejar la base a medias.
///
/// Reglas que salen de la revisión del PR #22:
///
/// - **La escena nueva no es la principal del lugar.** `es_escena_principal`
///   elige dónde arranca el recorrido de toda la app móvil, y en el lugar ya
///   hay una (la Biblioteca). La escena propia del POI es
///   `Poi.escenaPrincipalId`, que se enlaza aparte.
/// - **Un reintento no crea otra escena.** Si la imagen no sube, la API
///   pública esconde la escena recién creada (no tiene imagen) y el POI que
///   tiene la pantalla sigue sin ella. Por eso se recuerda aquí.
/// - **Nunca se guarda lo que no se leyó.** El texto alternativo se actualiza
///   con un PUT que reescribe la escena entera; solo se hace si se conoce la
///   escena completa, para no borrar su encuadre calibrado ni su orden, y con
///   las rutas sin firmar que devolvió la subida.
class SubidaPanorama {
  SubidaPanorama({
    required EscenaRepository escenas,
    required PoiRepository pois,
  }) : _escenas = escenas,
       _pois = pois;

  final EscenaRepository _escenas;
  final PoiRepository _pois;

  /// Escenas creadas desde esta pantalla, por POI.
  final _creadas = <int, Escena>{};

  /// Aviso cuando la escena existe pero no se pudo leer.
  static const avisoSinEscena =
      'La panorámica se subió, pero el texto alternativo no se actualizó: '
      'el lugar no está visible y el panel no puede leer su escena. '
      'Actívalo y vuelve a subirla para cambiarlo.';

  /// Sube [bytes] como panorámica de [poi].
  ///
  /// [escena] es su escena tal como se pudo leer: nula si no tiene, o si la
  /// API pública no la deja ver (lugar inactivo). Devuelve los avisos para
  /// mostrar, o null si no hay ninguno.
  Future<String?> subir({
    required Poi poi,
    required Escena? escena,
    required Uint8List bytes,
    required String nombreArchivo,
    required String textoAlt,
  }) async {
    final alt = textoAlt.trim();
    final conocida = escena ?? _creadas[poi.id];
    final existente = poi.escenaPrincipalId ?? conocida?.id;

    final int escenaId;
    final bool nueva;
    if (existente == null) {
      final creada = await _escenas.crear(
        Escena(
          id: 0,
          lugarId: poi.lugarId,
          poiId: poi.id,
          nombre: poi.nombre,
          esEscenaPrincipal: false,
          orden: await _siguienteOrden(),
          textoAlt: alt,
        ),
      );
      _creadas[poi.id] = creada;
      // Se enlaza antes de subir: si la subida falla, el POI ya la tiene.
      await _pois.actualizar(poi.copyWith(escenaPrincipalId: creada.id));
      escenaId = creada.id;
      nueva = true;
    } else {
      escenaId = existente;
      nueva = false;
    }

    final subida = await _escenas.subirImagen(
      escenaId,
      bytes: bytes,
      filename: nombreArchivo,
    );
    final avisos = <String>[?subida.advertencia];

    // Una escena nueva ya se creó con su texto alternativo.
    if (!nueva) {
      if (conocida == null ||
          conocida.id != escenaId ||
          subida.imagenUrl == null) {
        avisos.add(avisoSinEscena);
      } else if ((conocida.textoAlt ?? '').trim() != alt) {
        final actualizada = await _escenas.actualizar(
          Escena(
            id: conocida.id,
            lugarId: conocida.lugarId,
            poiId: conocida.poiId ?? poi.id,
            nombre: conocida.nombre,
            imagenUrl: subida.imagenUrl,
            imagenUrlBaja: subida.imagenUrlBaja,
            esEscenaPrincipal: conocida.esEscenaPrincipal,
            orden: conocida.orden,
            vistaInicialYaw: conocida.vistaInicialYaw,
            vistaInicialPitch: conocida.vistaInicialPitch,
            textoAlt: alt,
          ),
        );
        if (_creadas.containsKey(poi.id)) _creadas[poi.id] = actualizada;
      }
    }
    return avisos.isEmpty ? null : avisos.join('\n');
  }

  /// Orden después de la última escena visible. Si no se puede leer, 0: no
  /// decide nada, porque el recorrido arranca por la principal y no por el
  /// orden.
  Future<int> _siguienteOrden() async {
    try {
      final escenas = await _escenas.listar();
      return escenas.fold<int>(-1, (m, e) => max(m, e.orden)) + 1;
    } on ApiException {
      return 0;
    }
  }
}

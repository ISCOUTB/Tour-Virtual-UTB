import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datos/modelos/modelos.dart';

/// Un piso de un edificio, con el nombre que trae el catálogo («Cuarto Piso»).
@immutable
class PisoCampus {
  const PisoCampus({required this.id, required this.nombre});

  final String id;
  final String nombre;
}

/// Un salón dentro de un espacio («401», «Lab de Fotografía»).
@immutable
class SalonCampus {
  const SalonCampus({required this.id, required this.nombre, this.poiId});

  final String id;
  final String nombre;

  /// Si el salón es un lugar del tour con entrada propia (Solo Café).
  final int? poiId;

  static final _codigo = RegExp(r'^\d{3}[A-Za-z]?$');

  /// «401» se lee mejor como «Salón 401»; un nombre propio queda igual.
  String get titulo => _codigo.hasMatch(nombre) ? 'Salón $nombre' : nombre;
}

/// Un espacio de un edificio: un grupo de salones, un laboratorio, una
/// oficina.
@immutable
class EspacioCampus {
  const EspacioCampus({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.pisos,
    required this.salones,
    this.poiId,
  });

  final String id;
  final String nombre;

  /// `salon`, `laboratorio`, `oficina`, `servicio`, `cafeteria`… Uno
  /// desconocido no falla: solo cambia el icono.
  final String tipo;

  /// Ids de los pisos que ocupa (puede ser más de uno o ninguno).
  final List<String> pisos;
  final List<SalonCampus> salones;

  /// Si el espacio es un lugar del tour con entrada propia (Enfermería).
  final int? poiId;
}

/// Un edificio o zona del campus con sus pisos y espacios.
@immutable
class EdificioCampus {
  const EdificioCampus({
    required this.id,
    required this.nombre,
    required this.poiId,
    required this.pisos,
    required this.espacios,
    this.nota,
  });

  final String id;
  final String nombre;

  /// El lugar del tour a cuya entrada guía la app.
  final int poiId;
  final List<PisoCampus> pisos;
  final List<EspacioCampus> espacios;

  /// Cuando el edificio no es un lugar del tour: «junto al Edificio Alcatraz».
  final String? nota;

  PisoCampus? piso(String id) => pisos.where((p) => p.id == id).firstOrNull;
}

/// Qué hay dentro de cada edificio y en qué piso: 81 espacios y 114 salones.
///
/// Sale del catálogo de MAPSUTB (`scripts/espacios_mapsutb.py`), integrado con
/// autorización del profesor orientador. Sus posiciones no: «Cómo llegar»
/// lleva a la entrada medida del lugar del tour al que pertenece cada
/// edificio.
@immutable
class CatalogoEspacios {
  const CatalogoEspacios({required this.edificios, this.fuente = ''});

  factory CatalogoEspacios.desdeJson(Map<String, dynamic> json) {
    PisoCampus piso(Map<String, dynamic> j) =>
        PisoCampus(id: j['id'] as String, nombre: j['nombre'] as String);
    SalonCampus salon(Map<String, dynamic> j) => SalonCampus(
      id: j['id'] as String,
      nombre: j['nombre'] as String,
      poiId: (j['poi_id'] as num?)?.toInt(),
    );
    EspacioCampus espacio(Map<String, dynamic> j) => EspacioCampus(
      id: j['id'] as String,
      nombre: j['nombre'] as String,
      tipo: j['tipo'] as String? ?? '',
      pisos: [...(j['pisos'] as List? ?? const []).cast<String>()],
      salones: [
        for (final s in (j['salones'] as List? ?? const []))
          salon(s as Map<String, dynamic>),
      ],
      poiId: (j['poi_id'] as num?)?.toInt(),
    );
    return CatalogoEspacios(
      fuente: json['fuente'] as String? ?? '',
      edificios: [
        for (final e in (json['edificios'] as List? ?? const []))
          EdificioCampus(
            id: (e as Map<String, dynamic>)['id'] as String,
            nombre: e['nombre'] as String,
            poiId: (e['poi_id'] as num).toInt(),
            nota: e['nota'] as String?,
            pisos: [
              for (final p in (e['pisos'] as List? ?? const []))
                piso(p as Map<String, dynamic>),
            ],
            espacios: [
              for (final x in (e['espacios'] as List? ?? const []))
                espacio(x as Map<String, dynamic>),
            ],
          ),
      ],
    );
  }

  static const archivo =
      'packages/tour_virtual/assets/navegacion/espacios_campus.json';

  final List<EdificioCampus> edificios;
  final String fuente;

  /// El destino de un espacio o salón por su id, para abrir «Cómo llegar»
  /// con él (`/navegar/7?espacio=a2-401`).
  DestinoBusqueda? destino(String id) {
    for (final edificio in edificios) {
      for (final espacio in edificio.espacios) {
        if (espacio.id == id) {
          return DestinoBusqueda._espacio(edificio, espacio);
        }
        for (final salon in espacio.salones) {
          if (salon.id == id) {
            return DestinoBusqueda._salon(edificio, espacio, salon);
          }
        }
      }
    }
    return null;
  }
}

enum TipoDestino { lugar, espacio, salon }

/// Un resultado del buscador: siempre lleva a un lugar del tour ([poiId]) y,
/// si es un espacio o un salón, dice en qué edificio y piso está.
@immutable
class DestinoBusqueda {
  const DestinoBusqueda._({
    required this.tipo,
    required this.poiId,
    required this.titulo,
    this.id,
    this.edificio,
    this.piso,
    this.tipoEspacio = '',
    this.lugar,
  });

  DestinoBusqueda.lugar(Poi poi)
    : this._(
        tipo: TipoDestino.lugar,
        poiId: poi.id,
        titulo: poi.nombre,
        lugar: poi,
      );

  factory DestinoBusqueda._espacio(
    EdificioCampus edificio,
    EspacioCampus espacio,
  ) => DestinoBusqueda._(
    tipo: TipoDestino.espacio,
    id: espacio.id,
    poiId: espacio.poiId ?? edificio.poiId,
    titulo: espacio.nombre,
    edificio: edificio,
    piso: _primerPiso(edificio, espacio),
    tipoEspacio: espacio.tipo,
  );

  factory DestinoBusqueda._salon(
    EdificioCampus edificio,
    EspacioCampus espacio,
    SalonCampus salon,
  ) => DestinoBusqueda._(
    tipo: TipoDestino.salon,
    id: salon.id,
    poiId: salon.poiId ?? espacio.poiId ?? edificio.poiId,
    titulo: salon.titulo,
    edificio: edificio,
    piso: _primerPiso(edificio, espacio),
    tipoEspacio: espacio.tipo,
  );

  static PisoCampus? _primerPiso(EdificioCampus e, EspacioCampus x) =>
      x.pisos.map(e.piso).nonNulls.firstOrNull;

  final TipoDestino tipo;

  /// Id del espacio o salón en el catálogo; nulo para un lugar.
  final String? id;
  final int poiId;
  final String titulo;
  final EdificioCampus? edificio;
  final PisoCampus? piso;
  final String tipoEspacio;
  final Poi? lugar;

  /// Dónde queda, en el idioma del contenido: «Edificio A2 · Cuarto Piso»,
  /// «EDA2, junto al Edificio Alcatraz». Nulo para un lugar.
  String? get donde {
    final e = edificio;
    if (e == null) return null;
    final nombre = e.nota == null ? e.nombre : '${e.nombre}, ${e.nota}';
    return piso == null ? nombre : '$nombre · ${piso!.nombre}';
  }
}

/// Índice en memoria de los lugares del tour y de los espacios y salones del
/// catálogo, para buscar por nombre o por código.
///
/// Portado del buscador de MAPSUTB (`lib/features/busqueda/indice_busqueda.dart`):
///
/// - Sin distinguir mayúsculas ni tildes, con signos como espacios.
/// - Todas las palabras de la consulta deben aparecer en el nombre o en su
///   contexto (edificio, piso, espacio), y al menos una en el nombre: «a2 401»
///   encuentra el salón 401 del A2, y «a2» no devuelve cada salón del A2.
/// - Orden: coincidencia exacta, luego por prefijo, luego el resto; a igual
///   coincidencia, lugares antes que espacios y estos antes que salones.
class IndiceBusqueda {
  IndiceBusqueda({
    required List<Poi> lugares,
    CatalogoEspacios catalogo = const CatalogoEspacios(edificios: []),
  }) {
    final nombresLugar = <int, String>{};
    for (final poi in lugares) {
      nombresLugar[poi.id] = normalizarBusqueda(poi.nombre);
      _agregar(
        DestinoBusqueda.lugar(poi),
        nombres: [poi.nombre],
        contexto: const [],
      );
    }
    for (final edificio in catalogo.edificios) {
      for (final espacio in edificio.espacios) {
        final resultado = DestinoBusqueda._espacio(edificio, espacio);
        final contexto = [
          edificio.nombre,
          edificio.id,
          ?edificio.nota,
          ?resultado.piso?.nombre,
        ];
        // «La Placita» del catálogo es el lugar «La Placita» del tour: no se
        // repite como resultado, pero sus salones sí se buscan.
        final repetido =
            nombresLugar[resultado.poiId] == normalizarBusqueda(espacio.nombre);
        if (!repetido) {
          _agregar(resultado, nombres: [espacio.nombre], contexto: contexto);
        }
        for (final salon in espacio.salones) {
          _agregar(
            DestinoBusqueda._salon(edificio, espacio, salon),
            nombres: [salon.titulo, salon.nombre],
            contexto: [...contexto, espacio.nombre],
          );
        }
      }
    }
  }

  final _entradas = <_Entrada>[];

  /// Cuántos destinos se pueden buscar.
  int get cantidad => _entradas.length;

  void _agregar(
    DestinoBusqueda resultado, {
    required List<String> nombres,
    required List<String> contexto,
  }) {
    final propios = nombres.map(normalizarBusqueda).toList();
    _entradas.add(
      _Entrada(
        resultado,
        propios: propios,
        todo: [...propios, ...contexto.map(normalizarBusqueda)].join(' '),
        orden: _entradas.length,
      ),
    );
  }

  List<DestinoBusqueda> buscar(String consulta, {int limite = 60}) {
    final q = normalizarBusqueda(consulta);
    if (q.isEmpty) return const [];
    final palabras = q.split(' ');
    final encontrados = <(int, _Entrada)>[
      for (final entrada in _entradas)
        if (entrada.coincide(palabras)) (entrada.rango(q, palabras), entrada),
    ]..sort(_comparar);
    return [for (final (_, e) in encontrados.take(limite)) e.resultado];
  }

  static int _comparar((int, _Entrada) a, (int, _Entrada) b) {
    final porRango = a.$1.compareTo(b.$1);
    if (porRango != 0) return porRango;
    final porTipo = a.$2.resultado.tipo.index.compareTo(
      b.$2.resultado.tipo.index,
    );
    if (porTipo != 0) return porTipo;
    return a.$2.orden.compareTo(b.$2.orden);
  }
}

class _Entrada {
  _Entrada(
    this.resultado, {
    required this.propios,
    required this.todo,
    required this.orden,
  });

  final DestinoBusqueda resultado;
  final List<String> propios;
  final String todo;
  final int orden;

  bool coincide(List<String> palabras) =>
      palabras.every(todo.contains) &&
      palabras.any((p) => propios.any((n) => n.contains(p)));

  /// 0 si el nombre es la consulta, 1 si empieza por ella, 2 si solo la
  /// contiene. Se compara con las palabras de la consulta que están en el
  /// nombre: en «a2 401», «a2» es el contexto y «401» el nombre, así que el
  /// salón 401 va antes que el grupo «Salones 401-408» (en MAPSUTB, al revés).
  int rango(String consulta, List<String> palabras) {
    final enNombre = palabras
        .where((p) => propios.any((n) => n.contains(p)))
        .join(' ');
    for (final c in {consulta, enNombre}) {
      if (propios.contains(c)) return 0;
    }
    for (final c in {consulta, enNombre}) {
      if (propios.any((n) => n.startsWith(c))) return 1;
    }
    return 2;
  }
}

const _sinTilde = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a', //
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e', //
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i', //
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o', //
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u', //
  'ñ': 'n', 'ç': 'c',
};

/// Minúsculas, sin tildes, signos como espacio y espacios colapsados:
/// «  Enfermería » → «enfermeria», «406 - Lab de Redes» → «406 lab de redes».
String normalizarBusqueda(String texto) {
  final b = StringBuffer();
  for (final c in texto.toLowerCase().split('')) {
    b.write(_sinTilde[c] ?? c);
  }
  return b
      .toString()
      // Tildes escritas como carácter combinante (texto en forma NFD).
      .replaceAll(RegExp('[̀-ͯ]'), '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}

/// El catálogo empaquetado. Se lee con `load`, como el grafo: en las pruebas
/// de widgets el isolate de `loadString` no termina.
final catalogoEspaciosProvider = FutureProvider<CatalogoEspacios>((ref) async {
  final datos = await rootBundle.load(CatalogoEspacios.archivo);
  final texto = utf8.decode(
    datos.buffer.asUint8List(datos.offsetInBytes, datos.lengthInBytes),
  );
  return CatalogoEspacios.desdeJson(jsonDecode(texto) as Map<String, dynamic>);
});

import '../../core/config.dart';
import '../api/api_client.dart';
import '../models/enums.dart';
import '../models/medio.dart';
import '../models/poi.dart';

abstract class PoiRepository {
  /// Lista los POI del lugar configurado.
  Future<List<Poi>> listar();

  /// POI con sus medios.
  Future<PoiDetalle> detalle(int id);

  Future<Poi> crear(Poi poi);

  /// Envía el POI completo (la API de edición es un PUT).
  Future<Poi> actualizar(Poi poi);

  Future<void> eliminar(int id);

  /// RF-13: activar / desactivar. Envía el POI completo con el nuevo estado.
  Future<Poi> cambiarEstado(Poi poi, bool activo) =>
      actualizar(poi.copyWith(activo: activo));
}

/// Implementación real contra el backend .NET.
class HttpPoiRepository extends PoiRepository {
  HttpPoiRepository(this._api, {int? lugarId})
      : _lugarId = lugarId ?? AppConfig.lugarId;

  final ApiClient _api;
  final int _lugarId;

  Map<String, dynamic> _map(Object? data) =>
      (data as Map).cast<String, dynamic>();

  @override
  Future<List<Poi>> listar() async {
    final data = await _api.get('/api/lugares/$_lugarId/pois') as List;
    return data.map((e) => Poi.fromJson(_map(e))).toList();
  }

  @override
  Future<PoiDetalle> detalle(int id) async =>
      PoiDetalle.fromJson(_map(await _api.get('/api/pois/$id')));

  @override
  Future<Poi> crear(Poi poi) async {
    final body = poi.copyWith(lugarId: _lugarId).toCreateJson();
    return Poi.fromJson(_map(await _api.post('/api/admin/pois', body)));
  }

  @override
  Future<Poi> actualizar(Poi poi) async => Poi.fromJson(
      _map(await _api.put('/api/admin/pois/${poi.id}', poi.toUpdateJson())));

  @override
  Future<void> eliminar(int id) => _api.delete('/api/admin/pois/$id');
}

/// Datos en memoria para maquetar sin backend.
/// Son los lugares reales del campus, copiados de
/// `scripts/datos/pois_campus.json` de la app móvil (mismos ids, nombres,
/// categorías, descripciones y coordenadas). Cinco tienen panorámica
/// (paradas); el resto aún no tiene descripción ni escena. Los mapX/mapY solo
/// ubican el pin en la cuadrícula de maqueta y se calculan desde lat/lng.
class MockPoiRepository extends PoiRepository {
  MockPoiRepository() {
    _pois = const [
      Poi(
        id: 1,
        lugarId: 1,
        nombre: 'Biblioteca',
        categoria: 'Recursos',
        descripcion:
            'Más que una biblioteca: concentración, disciplina, tecnología y construcción de sueños.',
        lat: 10.3699965,
        lng: -75.4650668,
        mapX: 0.716,
        mapY: 0.463,
        escenaPrincipalId: 1,
        audiencias: _todas,
      ),
      Poi(
        id: 2,
        lugarId: 1,
        nombre: 'Puente A3 - A5',
        categoria: 'Academico',
        descripcion:
            'Un punto que conecta espacios, personas y recorridos dentro del campus. Cada trayecto en la UTB hace parte de una experiencia que conecta tu presente con lo que quieres construir.',
        lat: 10.3692169,
        lng: -75.4647217,
        mapX: 0.85,
        mapY: 0.846,
        escenaPrincipalId: 2,
        audiencias: _todas,
      ),
      Poi(
        id: 3,
        lugarId: 1,
        nombre: 'Enfermería',
        categoria: 'Bienestar',
        descripcion:
            'Bienestar y cuidado integral. Un espacio para atender tu salud, recibir orientación y recordar que cuidar de ti también hace parte de la experiencia universitaria.',
        lat: 10.3692651,
        lng: -75.4655196,
        mapX: 0.54,
        mapY: 0.823,
        escenaPrincipalId: 3,
        audiencias: _todas,
      ),
      Poi(
        id: 4,
        lugarId: 1,
        nombre: 'Zona T',
        categoria: 'Servicios',
        descripcion:
            'Punto de encuentro, pausa y conexión. Un lugar para compartir con otros estudiantes, conversar y disfrutar los espacios que hacen del campus una comunidad.',
        lat: 10.3691852,
        lng: -75.4655576,
        mapX: 0.525,
        mapY: 0.862,
        escenaPrincipalId: 4,
        audiencias: _todas,
      ),
      Poi(
        id: 5,
        lugarId: 1,
        nombre: 'Cancha de softbol',
        categoria: 'Deporte',
        descripcion:
            'El campus también se vive en movimiento. Espacio para el deporte, la disciplina, el trabajo en equipo y las experiencias que se construyen más allá del aula.',
        lat: 10.3695823,
        lng: -75.4663148,
        mapX: 0.232,
        mapY: 0.667,
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
        mapX: 0.607,
        mapY: 0.577,
        audiencias: _todas,
      ),
      Poi(
        id: 7,
        lugarId: 1,
        nombre: 'Edificio A2',
        categoria: 'Academico',
        lat: 10.3707763,
        lng: -75.4656241,
        mapX: 0.5,
        mapY: 0.08,
        audiencias: _todas,
      ),
      Poi(
        id: 8,
        lugarId: 1,
        nombre: 'Edificio A3',
        categoria: 'Academico',
        lat: 10.3692983,
        lng: -75.4648329,
        mapX: 0.806,
        mapY: 0.806,
        audiencias: _todas,
      ),
      Poi(
        id: 9,
        lugarId: 1,
        nombre: 'Edificio A4',
        categoria: 'Academico',
        lat: 10.3695805,
        lng: -75.4645402,
        mapX: 0.92,
        mapY: 0.668,
        audiencias: _todas,
      ),
      Poi(
        id: 10,
        lugarId: 1,
        nombre: 'Edificio A5',
        categoria: 'Academico',
        lat: 10.3691355,
        lng: -75.4646105,
        mapX: 0.893,
        mapY: 0.886,
        audiencias: _todas,
      ),
      Poi(
        id: 11,
        lugarId: 1,
        nombre: 'Edificio Alcatraz',
        categoria: 'Academico',
        lat: 10.3703807,
        lng: -75.4652636,
        mapX: 0.639,
        mapY: 0.274,
        audiencias: _todas,
      ),
      Poi(
        id: 12,
        lugarId: 1,
        nombre: 'Auditorio',
        categoria: 'Cultura',
        lat: 10.3705694,
        lng: -75.4657944,
        mapX: 0.434,
        mapY: 0.182,
        audiencias: _todas,
      ),
      Poi(
        id: 13,
        lugarId: 1,
        nombre: 'Plaza Maloca',
        categoria: 'Cultura',
        lat: 10.3700456,
        lng: -75.4657625,
        mapX: 0.446,
        mapY: 0.439,
        audiencias: _todas,
      ),
      Poi(
        id: 14,
        lugarId: 1,
        nombre: 'Rectoría',
        categoria: 'Administrativo',
        lat: 10.3695939,
        lng: -75.4652554,
        mapX: 0.643,
        mapY: 0.661,
        audiencias: _todas,
      ),
      Poi(
        id: 15,
        lugarId: 1,
        nombre: 'Laboratorio El Patio',
        categoria: 'Academico',
        lat: 10.3696815,
        lng: -75.4650578,
        mapX: 0.719,
        mapY: 0.618,
        audiencias: _todas,
      ),
      Poi(
        id: 16,
        lugarId: 1,
        nombre: 'Centro de Cuidado Integral (QUID)',
        categoria: 'Bienestar',
        lat: 10.3690673,
        lng: -75.4658707,
        mapX: 0.404,
        mapY: 0.92,
        audiencias: _todas,
      ),
      Poi(
        id: 17,
        lugarId: 1,
        nombre: 'Centro Deportivo y Cultural',
        categoria: 'Deporte',
        lat: 10.3692615,
        lng: -75.4656845,
        mapX: 0.476,
        mapY: 0.825,
        audiencias: _todas,
      ),
      Poi(
        id: 18,
        lugarId: 1,
        nombre: 'Cancha de fútbol',
        categoria: 'Deporte',
        lat: 10.3701542,
        lng: -75.4667058,
        mapX: 0.08,
        mapY: 0.386,
        audiencias: _todas,
      ),
      Poi(
        id: 19,
        lugarId: 1,
        nombre: 'Salas de estudio',
        categoria: 'Recursos',
        lat: 10.3705483,
        lng: -75.4654429,
        mapX: 0.57,
        mapY: 0.192,
        audiencias: _todas,
      ),
      Poi(
        id: 20,
        lugarId: 1,
        nombre: 'Cafetería',
        categoria: 'Servicios',
        lat: 10.37042,
        lng: -75.4653547,
        mapX: 0.604,
        mapY: 0.255,
        audiencias: _todas,
      ),
      Poi(
        id: 21,
        lugarId: 1,
        nombre: 'Tienda',
        categoria: 'Servicios',
        lat: 10.3692206,
        lng: -75.4661076,
        mapX: 0.312,
        mapY: 0.845,
        audiencias: _todas,
      ),
      Poi(
        id: 22,
        lugarId: 1,
        nombre: 'Cajero automático',
        categoria: 'Servicios',
        lat: 10.3705307,
        lng: -75.4659036,
        mapX: 0.391,
        mapY: 0.201,
        audiencias: _todas,
      ),
      Poi(
        id: 23,
        lugarId: 1,
        nombre: 'Pasillo de la conexión',
        categoria: 'Administrativo',
        lat: 10.3707567,
        lng: -75.4659942,
        mapX: 0.356,
        mapY: 0.09,
        audiencias: _todas,
      ),
      Poi(
        id: 24,
        lugarId: 1,
        nombre: 'Solo Café',
        categoria: 'Servicios',
        descripcion:
            'Espacio de conexión, ideas y conversaciones que también transforman la experiencia universitaria. Aquí nacen amistades, proyectos y networking.',
        lat: 10.3702285,
        lng: -75.4655508,
        mapX: 0.528,
        mapY: 0.349,
        audiencias: _todas,
      ),
      Poi(
        id: 25,
        lugarId: 1,
        nombre: 'La Placita',
        categoria: 'Cultura',
        descripcion:
            'Inspirada en las plazas del Caribe. Un espacio creado para compartir, desconectarse y sentirse en casa dentro de la UTB.',
        lat: 10.3704913,
        lng: -75.465484,
        mapX: 0.554,
        mapY: 0.22,
        audiencias: _todas,
      ),
      Poi(
        id: 26,
        lugarId: 1,
        nombre: 'QuantaLab',
        categoria: 'Academico',
        descripcion:
            'Laboratorio de analítica, IA y datos. El futuro pertenece a quienes saben interpretar información y tomar decisiones.',
        lat: 10.3690907,
        lng: -75.4646518,
        mapX: 0.877,
        mapY: 0.908,
        audiencias: _todas,
      ),
    ];
  }

  static const _todas = [
    Audiencia.externo,
    Audiencia.estudiante,
    Audiencia.docente,
  ];

  /// Duración (s) de la narración en español de los lugares que ya la tienen.
  static const _duracionAudio = {
    1: 7,
    2: 14,
    3: 12,
    4: 12,
    5: 11,
    24: 12,
    25: 9,
    26: 10,
  };

  late List<Poi> _pois;
  int _nextId = 27;

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 350));

  @override
  Future<List<Poi>> listar() async {
    await _delay();
    return List.unmodifiable(_pois);
  }

  @override
  Future<PoiDetalle> detalle(int id) async {
    await _delay();
    final poi = _pois.firstWhere((p) => p.id == id,
        orElse: () => throw ApiException('POI no encontrado', statusCode: 404));
    final seg = _duracionAudio[id];
    // Solo la narración original en español, como el seed de la app. El seed
    // no trae subtítulos ni otros idiomas: no se inventan.
    return PoiDetalle(
      poi: poi,
      medios: [
        if (seg != null)
          Medio(
            id: id * 100,
            poiId: id,
            tipo: TipoMedio.audio,
            orden: 0,
            duracionSeg: seg,
            textoAlt: 'Audio narrado de ${poi.nombre}',
          ),
      ],
    );
  }

  @override
  Future<Poi> crear(Poi poi) async {
    await _delay();
    final nuevo = poi.copyWith(id: _nextId++);
    _pois = [..._pois, nuevo];
    return nuevo;
  }

  @override
  Future<Poi> actualizar(Poi poi) async {
    await _delay();
    _pois = [for (final p in _pois) p.id == poi.id ? poi : p];
    return poi;
  }

  @override
  Future<void> eliminar(int id) async {
    await _delay();
    _pois = _pois.where((p) => p.id != id).toList();
  }
}

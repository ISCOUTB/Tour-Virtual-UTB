import '../api/api_client.dart';

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

// --- Métricas (GET /api/admin/metricas) ---

class ConteoTipo {
  const ConteoTipo(this.tipo, this.eventos);
  final String tipo;
  final int eventos;
}

class VisitasDia {
  const VisitasDia(this.dia, this.visitas, this.eventos);
  final DateTime dia;
  final int visitas;
  final int eventos;
}

class PoiVisto {
  const PoiVisto(this.poiId, this.nombre, this.visitas, this.eventos);
  final int poiId;
  final String nombre;
  final int visitas;
  final int eventos;
}

class Metricas {
  const Metricas({
    required this.visitas,
    required this.eventos,
    this.porTipo = const [],
    this.porDia = const [],
    this.poisMasVistos = const [],
  });

  /// Sesiones distintas (visitantes anónimos) en el rango.
  final int visitas;
  final int eventos;
  final List<ConteoTipo> porTipo;
  final List<VisitasDia> porDia;
  final List<PoiVisto> poisMasVistos;

  int eventosDe(String tipo) =>
      porTipo.where((t) => t.tipo == tipo).fold(0, (s, t) => s + t.eventos);

  factory Metricas.fromJson(Map<String, dynamic> j) => Metricas(
        visitas: _int(j['visitas']),
        eventos: _int(j['eventos']),
        porTipo: [
          for (final e in (j['por_tipo'] as List? ?? const []))
            ConteoTipo(e['tipo'] as String, _int(e['eventos'])),
        ],
        porDia: [
          for (final e in (j['por_dia'] as List? ?? const []))
            VisitasDia(DateTime.parse(e['dia'] as String), _int(e['visitas']),
                _int(e['eventos'])),
        ],
        poisMasVistos: [
          for (final e in (j['pois_mas_vistos'] as List? ?? const []))
            PoiVisto(_int(e['poi_id']), (e['nombre'] as String?) ?? '',
                _int(e['visitas']), _int(e['eventos'])),
        ],
      );
}

// --- Actividad (GET /api/admin/actividad) ---

class Actividad {
  const Actividad({
    required this.id,
    required this.fecha,
    required this.accion,
    required this.entidad,
    this.entidadId,
    this.actorCorreo,
  });

  final int id;
  final DateTime fecha;

  /// insert, update o delete (lo que registre la tabla auditoria).
  final String accion;
  final String entidad;
  final String? entidadId;
  final String? actorCorreo;

  factory Actividad.fromJson(Map<String, dynamic> j) => Actividad(
        id: _int(j['id']),
        fecha: DateTime.parse(j['ts'] as String).toLocal(),
        accion: (j['accion'] as String?) ?? '',
        entidad: (j['entidad'] as String?) ?? '',
        entidadId: j['entidad_id']?.toString(),
        actorCorreo: j['actor_correo'] as String?,
      );
}

// --- Administradores (GET /api/admin/administradores) ---

class Perfil {
  const Perfil({
    required this.userId,
    this.correo,
    required this.rol,
    required this.verificado,
    required this.creadoEn,
  });

  final String userId;
  final String? correo;
  final String rol;
  final bool verificado;
  final DateTime creadoEn;

  factory Perfil.fromJson(Map<String, dynamic> j) => Perfil(
        userId: j['user_id'] as String,
        correo: j['correo'] as String?,
        rol: (j['rol'] as String?) ?? '',
        verificado: (j['verificado'] as bool?) ?? false,
        creadoEn: DateTime.parse(j['creado_en'] as String).toLocal(),
      );
}

String _fecha(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Lecturas del panel que no son contenido: métricas, actividad y admins.
abstract class PanelRepository {
  /// Rango en hora de Colombia, ambos días incluidos.
  Future<Metricas> metricas({required DateTime desde, required DateTime hasta});

  Future<List<Actividad>> actividad({int tamano = 10});

  /// Solo los admin; con [todos], todos los perfiles (para buscar a quién
  /// darle el rol).
  Future<List<Perfil>> administradores({bool todos = false});

  /// Da o quita el rol admin (rol: admin, externo, estudiante o docente).
  Future<Perfil> cambiarRol(String userId, String rol);
}

class HttpPanelRepository implements PanelRepository {
  HttpPanelRepository(this._api);

  final ApiClient _api;

  Map<String, dynamic> _map(Object? d) => (d as Map).cast<String, dynamic>();

  @override
  Future<Metricas> metricas(
          {required DateTime desde, required DateTime hasta}) async =>
      Metricas.fromJson(_map(await _api.get(
          '/api/admin/metricas?desde=${_fecha(desde)}&hasta=${_fecha(hasta)}')));

  @override
  Future<List<Actividad>> actividad({int tamano = 10}) async {
    final data =
        _map(await _api.get('/api/admin/actividad?pagina=1&tamano=$tamano'));
    return [
      for (final e in (data['items'] as List? ?? const []))
        Actividad.fromJson(_map(e)),
    ];
  }

  @override
  Future<List<Perfil>> administradores({bool todos = false}) async => [
        for (final e in (await _api
            .get('/api/admin/administradores${todos ? '?todos=true' : ''}')
            as List))
          Perfil.fromJson(_map(e)),
      ];

  @override
  Future<Perfil> cambiarRol(String userId, String rol) async => Perfil.fromJson(
      _map(await _api.put('/api/admin/administradores/$userId', {'rol': rol})));
}

/// Maqueta sin backend: sin cifras inventadas, todo vacío.
class MockPanelRepository implements PanelRepository {
  @override
  Future<Metricas> metricas(
          {required DateTime desde, required DateTime hasta}) async =>
      const Metricas(visitas: 0, eventos: 0);

  @override
  Future<List<Actividad>> actividad({int tamano = 10}) async => const [];

  @override
  Future<List<Perfil>> administradores({bool todos = false}) async =>
      const [];

  @override
  Future<Perfil> cambiarRol(String userId, String rol) async =>
      throw ApiException('No disponible en modo maqueta');
}

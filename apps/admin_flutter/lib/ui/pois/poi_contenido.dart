import '../../data/models/enums.dart';
import '../../data/models/escena.dart';
import '../../data/models/medio.dart';
import '../../data/models/poi.dart';

/// Escena 360° de un POI: la principal si la tiene y, si no, la primera
/// escena ligada a él.
Escena? escenaDePoi(Poi poi, List<Escena> escenas) {
  final id = poi.escenaPrincipalId;
  if (id != null) {
    for (final e in escenas) {
      if (e.id == id) return e;
    }
  }
  for (final e in escenas) {
    if (e.poiId == poi.id) return e;
  }
  return null;
}

String? _noVacia(String? s) => (s == null || s.isEmpty) ? null : s;

/// Lo que ya hay registrado de un POI: su escena 360° y sus medios.
class ContenidoPoi {
  const ContenidoPoi({this.escena, this.medios = const []});

  final Escena? escena;
  final List<Medio> medios;

  List<Medio> _de(TipoMedio tipo) =>
      medios.where((m) => m.tipo == tipo).toList()
        ..sort((a, b) => a.orden.compareTo(b.orden));

  List<Medio> get fotos => _de(TipoMedio.imagen);
  List<Medio> get videos => _de(TipoMedio.video);
  List<Medio> get audios => _de(TipoMedio.audio);

  /// Hay panorámica cargada (no solo una escena vacía).
  bool get tiene360 => _noVacia(escena?.imagenUrl) != null;

  /// Narración que muestra la app por defecto: la del idioma original.
  Medio? get audioPrincipal {
    final lista = audios;
    for (final m in lista) {
      if (m.idioma == null || m.idioma == 'es') return m;
    }
    return lista.isEmpty ? null : lista.first;
  }

  /// Imagen de portada: la panorámica (versión liviana primero) o, si no hay,
  /// la primera foto.
  String? get imagenPortada =>
      _noVacia(escena?.imagenUrlBaja) ??
      _noVacia(escena?.imagenUrl) ??
      (fotos.isEmpty ? null : _noVacia(fotos.first.url));
}

String duracionMmSs(int? seg) {
  if (seg == null) return '--:--';
  final m = (seg ~/ 60).toString().padLeft(2, '0');
  final s = (seg % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Enumeraciones del contrato de la API (schema.d.ts).
/// El backend las envía como texto en minúsculas.

enum Audiencia {
  externo,
  estudiante,
  docente;

  static Audiencia? tryParse(Object? value) {
    if (value is! String) return null;
    final v = value.trim().toLowerCase();
    for (final a in Audiencia.values) {
      if (a.name == v) return a;
    }
    return null;
  }
}

enum TipoMedio {
  imagen,
  video,
  audio;

  static TipoMedio tryParse(Object? value) {
    if (value is String) {
      final v = value.trim().toLowerCase();
      for (final t in TipoMedio.values) {
        if (t.name == v) return t;
      }
    }
    return TipoMedio.imagen;
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tour_virtual/navegacion/geo.dart';
import 'package:tour_virtual/navegacion/grafo_campus.dart';
import 'package:tour_virtual/navegacion/seguimiento.dart';
import 'package:tour_virtual/navegacion/sensores.dart';

/// Herramienta de levantamiento del campus (fase 0 del plan de realidad
/// aumentada). Es para el equipo, no para los visitantes: solo existe en la
/// app de demostración y se abre con
///
/// ```bash
/// flutter run --dart-define=LEVANTAMIENTO=true
/// ```
///
/// Mide en el campus lo que el código no puede saber:
/// - **Entradas:** de pie en la puerta, promedia el GPS 60 s.
/// - **Norte de las panorámicas:** de pie donde se tomó la foto, apuntando la
///   cámara a algo que se reconozca en ella.
/// - **Recorridos:** el rastro de una caminata, para revisar el grafo.
///
/// Todo se guarda en el teléfono y se copia como JSON para pasarlo al equipo:
/// `python -I scripts/grafo_campus.py levantamiento.json` lo incorpora. Es
/// texto de uso interno y va solo en español.
class HerramientaLevantamiento extends StatelessWidget {
  const HerramientaLevantamiento({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Levantamiento UTB',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: const Color(0xFF2047CD),
      brightness: Brightness.dark,
    ),
    home: const _Levantamiento(),
  );
}

class _Levantamiento extends StatefulWidget {
  const _Levantamiento();

  @override
  State<_Levantamiento> createState() => _LevantamientoState();
}

class _LevantamientoState extends State<_Levantamiento> {
  static const _clave = 'levantamiento.datos';
  static const _paradas = {
    1: 'Biblioteca',
    2: 'Puente A3 - A5',
    3: 'Enfermería',
    4: 'Zona T',
    5: 'Cancha de softbol',
  };

  final _ubicacion = UbicacionGps();
  // Sin declinación: se guarda el rumbo magnético crudo y la corrección se
  // aplica al procesar.
  final _brujula = RumboSensores();
  StreamSubscription<LecturaPosicion>? _subPosicion;
  StreamSubscription<LecturaRumbo>? _subRumbo;
  LecturaPosicion? _posicion;
  LecturaRumbo? _rumbo;
  String? _error;

  List<AccesoLugar> _lugares = const [];
  Map<String, dynamic> _datos = {
    'accesos': <dynamic>[],
    'nortes': <dynamic>[],
    'recorridos': <dynamic>[],
  };

  // Medición en curso.
  String? _midiendo;
  final _muestras = <LecturaPosicion>[];
  final _rumbos = <double>[];
  List<Map<String, dynamic>>? _rastro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _subPosicion?.cancel();
    _subRumbo?.cancel();
    super.dispose();
  }

  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString(_clave);
    if (guardado != null) _datos = jsonDecode(guardado) as Map<String, dynamic>;
    final crudo = await rootBundle.load(GrafoCampus.archivo);
    final grafo = GrafoCampus.desdeJson(
      jsonDecode(
            utf8.decode(
              crudo.buffer.asUint8List(
                crudo.offsetInBytes,
                crudo.lengthInBytes,
              ),
            ),
          )
          as Map<String, dynamic>,
    );
    final permiso = await _ubicacion.pedirPermiso();
    if (!mounted) return;
    setState(() {
      // Un lugar por fila; la Biblioteca aparece con sus dos entradas.
      _lugares = grafo.accesos;
      if (permiso != PermisoUbicacion.concedido) {
        _error = 'Sin permiso de ubicación ($permiso).';
      }
    });
    if (permiso != PermisoUbicacion.concedido) return;
    _subPosicion = _ubicacion.lecturas().listen((l) {
      setState(() => _posicion = l);
      if (_midiendo != null && _midiendo!.startsWith('acceso:')) {
        _muestras.add(l);
      }
      _rastro?.add({
        'lat': l.punto.lat,
        'lng': l.punto.lng,
        'precision': l.precision,
        't': DateTime.now().toIso8601String(),
      });
    });
    _subRumbo = _brujula.lecturas().listen((r) {
      setState(() => _rumbo = r);
      if (_midiendo != null && _midiendo!.startsWith('norte:')) {
        _rumbos.add(r.grados);
      }
    });
  }

  Future<void> _guardar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, jsonEncode(_datos));
  }

  Future<void> _medirAcceso(AccesoLugar acceso) async {
    setState(() {
      _midiendo = 'acceso:${acceso.nombre}';
      _muestras.clear();
    });
    await Future<void>.delayed(const Duration(seconds: 60));
    if (!mounted) return;
    // Promedio ponderado por la precisión: las lecturas buenas pesan más.
    var sLat = 0.0, sLng = 0.0, sPeso = 0.0, sPrec = 0.0;
    for (final m in _muestras) {
      final peso = 1 / (m.precision * m.precision);
      sLat += m.punto.lat * peso;
      sLng += m.punto.lng * peso;
      sPeso += peso;
      sPrec += m.precision;
    }
    setState(() => _midiendo = null);
    if (_muestras.isEmpty) return;
    final medida = {
      'poi_id': acceso.poiId,
      'nombre': acceso.nombre,
      'lat': sLat / sPeso,
      'lng': sLng / sPeso,
      'precision': double.parse((sPrec / _muestras.length).toStringAsFixed(1)),
      'lecturas': _muestras.length,
      'fecha': DateTime.now().toIso8601String(),
      'distancia_al_estimado_m': distanciaMetros(
        PuntoGeo(sLat / sPeso, sLng / sPeso),
        acceso.punto,
      ).round(),
    };
    setState(() => (_datos['accesos'] as List).add(medida));
    await _guardar();
  }

  Future<void> _medirNorte(int poiId, String objeto) async {
    setState(() {
      _midiendo = 'norte:$poiId';
      _rumbos.clear();
    });
    await Future<void>.delayed(const Duration(seconds: 4));
    if (!mounted) return;
    setState(() => _midiendo = null);
    if (_rumbos.isEmpty) return;
    // Media circular: promediar 359° y 1° tiene que dar 0°, no 180°.
    var x = 0.0, y = 0.0;
    for (final g in _rumbos) {
      x += _cos(g);
      y += _sin(g);
    }
    final rumbo = normalizarGrados(_atan2(y, x));
    setState(() {
      (_datos['nortes'] as List).add({
        'poi_id': poiId,
        'objeto': objeto,
        'rumbo_magnetico': double.parse(rumbo.toStringAsFixed(1)),
        'lecturas': _rumbos.length,
        'lat': _posicion?.punto.lat,
        'lng': _posicion?.punto.lng,
        'fecha': DateTime.now().toIso8601String(),
      });
    });
    await _guardar();
  }

  void _alternarRastro() {
    if (_rastro == null) {
      setState(() => _rastro = []);
      return;
    }
    final rastro = _rastro!;
    setState(() {
      _rastro = null;
      (_datos['recorridos'] as List).add({
        'fecha': DateTime.now().toIso8601String(),
        'puntos': rastro,
      });
    });
    _guardar();
  }

  Future<void> _copiar() async {
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(_datos)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copiado. Pégalo en un chat o un correo para el equipo.'),
      ),
    );
  }

  Future<void> _pedirObjeto(int poiId) async {
    final control = TextEditingController();
    final objeto = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Norte de ${_paradas[poiId]}'),
        content: TextField(
          controller: control,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '¿A qué apuntas? (algo que se vea en la panorámica)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, control.text),
            child: const Text('Medir 4 s'),
          ),
        ],
      ),
    );
    if (objeto != null && objeto.trim().isNotEmpty) {
      await _medirNorte(poiId, objeto.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _posicion;
    final r = _rumbo;
    final accesos = (_datos['accesos'] as List).cast<Map<String, dynamic>>();
    final nortes = (_datos['nortes'] as List).cast<Map<String, dynamic>>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Levantamiento del campus'),
        actions: [
          IconButton(
            onPressed: _copiar,
            tooltip: 'Copiar JSON',
            icon: const Icon(Icons.copy_all_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          Card(
            child: ListTile(
              leading: const Icon(Icons.gps_fixed_rounded),
              title: Text(
                p == null
                    ? 'Esperando GPS…'
                    : '${p.punto.lat.toStringAsFixed(6)}, '
                          '${p.punto.lng.toStringAsFixed(6)}',
              ),
              subtitle: Text(
                [
                  if (p != null) '±${p.precision.toStringAsFixed(1)} m',
                  if (r != null)
                    'brújula ${r.grados.toStringAsFixed(0)}°'
                        '${r.descalibrada ? ' (¡calibra en 8!)' : ''}',
                  if (_midiendo != null)
                    'midiendo… ${_muestras.length + _rumbos.length}',
                ].join(' · '),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Entradas: párate en la puerta, al aire libre, y toca. Son 60 s '
            'quieto. Repite otro día: si las dos quedan a menos de 5 m, vale.',
          ),
          for (final a in _lugares)
            ListTile(
              dense: true,
              title: Text(a.nombre),
              subtitle: Text(
                [
                  if (a.poiId <= 5) 'parada',
                  ...accesos
                      .where((m) => m['nombre'] == a.nombre)
                      .map(
                        (m) =>
                            '±${m['precision']} m, a '
                            '${m['distancia_al_estimado_m']} m del estimado',
                      ),
                ].join(' · '),
              ),
              trailing: FilledButton.tonal(
                onPressed: _midiendo == null ? () => _medirAcceso(a) : null,
                child: const Text('Medir'),
              ),
            ),
          const Divider(height: 32),
          const Text(
            'Norte de cada panorámica: párate donde se tomó la foto, apunta la '
            'cámara a algo reconocible en ella (una puerta, una columna) y '
            'escribe qué es.',
          ),
          for (final entrada in _paradas.entries)
            ListTile(
              dense: true,
              title: Text(entrada.value),
              subtitle: Text(
                nortes
                    .where((n) => n['poi_id'] == entrada.key)
                    .map((n) => '${n['rumbo_magnetico']}° → ${n['objeto']}')
                    .join(' · '),
              ),
              trailing: FilledButton.tonal(
                onPressed: _midiendo == null
                    ? () => _pedirObjeto(entrada.key)
                    : null,
                child: const Text('Medir'),
              ),
            ),
          const Divider(height: 32),
          SwitchListTile(
            value: _rastro != null,
            onChanged: (_) => _alternarRastro(),
            title: const Text('Grabar un recorrido'),
            subtitle: Text(
              _rastro == null
                  ? '${(_datos['recorridos'] as List).length} guardados'
                  : '${_rastro!.length} puntos',
            ),
          ),
        ],
      ),
    );
  }
}

double _cos(double grados) => math.cos(grados * math.pi / 180);
double _sin(double grados) => math.sin(grados * math.pi / 180);
double _atan2(double y, double x) => math.atan2(y, x) * 180 / math.pi;

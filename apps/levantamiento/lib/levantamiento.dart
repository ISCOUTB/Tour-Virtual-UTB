import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tour_virtual/navegacion/geo.dart';
import 'package:tour_virtual/navegacion/grafo_campus.dart';
import 'package:tour_virtual/navegacion/pantalla_activa.dart';
import 'package:tour_virtual/navegacion/seguimiento.dart';
import 'package:tour_virtual/navegacion/sensores.dart';

import 'datos_levantamiento.dart';

/// App de levantamiento del campus (fase 0 del plan de realidad aumentada).
/// Es para el equipo, no para los visitantes, y va solo en español.
///
/// Mide en el campus lo que el código no puede saber, en seis pestañas:
/// - **Entradas:** de pie en la puerta, promedia el GPS 60 s. Dice si la
///   entrada ya pasa el criterio (dos días, 5 m).
/// - **Tramos:** marca el tramo del grafo donde estás: tipo, escalones,
///   techo. Graba los caminos que faltan.
/// - **Norte:** el rumbo de algo que se ve en cada panorámica.
/// - **Brújula:** apuntando a lo largo de un camino recto, mide el error de
///   la brújula contra el mapa (RNF-27) y la declinación.
/// - **Guía:** camina hasta una parada con la misma lógica que la app y anota
///   dónde da la llegada, los giros y los recálculos.
/// - **Datos:** el resumen y el JSON para el equipo.
///
/// Todo se guarda en el teléfono. El JSON se copia y se pasa a
/// `python -I scripts/grafo_campus.py --informe levantamiento.json`.
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

/// Las cinco paradas del recorrido: las que tienen panorámica.
const _paradas = {
  1: 'Biblioteca',
  2: 'Puente A3 - A5',
  3: 'Enfermería',
  4: 'Zona T',
  5: 'Cancha de softbol',
};

const _tiposTramo = ['sendero', 'pasillo', 'rampa', 'escalera', 'via'];

/// Una medida de 60 s a 2 s por lectura da unas 30. Con menos de esto, la
/// pantalla se apagó o el GPS se cortó: no vale.
const _lecturasMinimas = 20;

class _LevantamientoState extends State<_Levantamiento>
    with WidgetsBindingObserver {
  static const _clave = 'levantamiento.datos';

  final _ubicacion = UbicacionGps();
  // Sin declinación: se guarda el rumbo magnético crudo y el geográfico se
  // calcula con la del grafo, así una declinación corregida no invalida lo
  // medido.
  final _brujula = RumboSensores();
  StreamSubscription<LecturaPosicion>? _subPosicion;
  StreamSubscription<LecturaRumbo>? _subRumbo;
  LecturaPosicion? _posicion;
  LecturaRumbo? _rumbo;
  String? _error;
  final _pantalla = PantallaActiva();
  var _enPrimerPlano = true;
  var _sesion = 0;
  Future<void> _cancelacion = Future<void>.value();

  GrafoCampus? _grafo;
  Json _datos = normalizarDatos(null);
  final _medidor = TextEditingController();

  // Medición en curso: muestras durante unos segundos.
  String? _midiendo;
  var _restante = 0;
  Timer? _reloj;
  Completer<bool>? _finMedida;
  final _muestras = <LecturaPosicion>[];
  final _rumbos = <double>[];
  final _inclinaciones = <double>[];
  var _descalibradaAlMedir = false;

  // Recorrido grabándose.
  List<Json>? _rastro;
  var _etiquetaRastro = '';

  // Prueba de la guía.
  RegistroPrueba? _prueba;
  var _sinEscaleras = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pausarSensores();
    _reloj?.cancel();
    if (_finMedida case final fin? when !fin.isCompleted) fin.complete(false);
    _medidor.dispose();
    super.dispose();
  }

  void _pausarSensores() {
    _sesion++;
    _cancelacion = Future.wait<void>([
      _cancelacion,
      if (_subPosicion != null) _subPosicion!.cancel(),
      if (_subRumbo != null) _subRumbo!.cancel(),
    ]).then((_) {});
    _subPosicion = null;
    _subRumbo = null;
    _posicion = null;
    _rumbo = null;
    unawaited(_pantalla.cambiar(false));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    // Un diálogo de permisos causa `inactive`, sin salir de la app.
    if (estado == AppLifecycleState.inactive) return;
    final estabaActiva = _enPrimerPlano;
    _enPrimerPlano = estado == AppLifecycleState.resumed;
    if (!_enPrimerPlano) {
      if (_midiendo != null) {
        _terminarMedida(false);
        _avisar('Medición interrumpida al salir de la app: repítela.');
      }
      if (_rastro != null) unawaited(_alternarRastro());
      _pausarSensores();
    } else if (!estabaActiva && _grafo != null) {
      unawaited(_escuchar());
    }
  }

  double get _declinacion => _grafo?.declinacion ?? 0;

  /// Rumbo geográfico de la brújula ahora, o nulo.
  double? get _rumboGeografico => switch (_rumbo) {
    final r? => normalizarGrados(r.grados + _declinacion),
    null => null,
  };

  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString(_clave);
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
          as Json,
    );
    if (!mounted) return;
    setState(() {
      _grafo = grafo;
      if (guardado != null) {
        _datos = normalizarDatos(jsonDecode(guardado) as Json);
      }
      _medidor.text = _datos['medidor'] as String? ?? '';
    });
    await _escuchar();
  }

  Future<void> _escuchar() async {
    final sesion = ++_sesion;
    final permiso = await _ubicacion.pedirPermiso();
    if (!mounted || !_enPrimerPlano || sesion != _sesion) return;
    if (permiso != PermisoUbicacion.concedido) {
      setState(() {
        _error = switch (permiso) {
          PermisoUbicacion.servicioApagado =>
            'La ubicación del teléfono está apagada.',
          PermisoUbicacion.denegadoSiempre =>
            'Sin permiso de ubicación: dalo en los ajustes del teléfono.',
          _ => 'Sin permiso de ubicación.',
        };
      });
      return;
    }
    setState(() => _error = null);
    await _subPosicion?.cancel();
    await _subRumbo?.cancel();
    await _cancelacion;
    if (!mounted || !_enPrimerPlano || sesion != _sesion) return;
    unawaited(_pantalla.cambiar(true));
    _subPosicion = _ubicacion.lecturas().listen(
      _alLeerPosicion,
      onError: (Object e) {
        if (mounted) setState(() => _error = 'GPS: $e');
      },
    );
    _subRumbo = _brujula.lecturas().listen((r) {
      if (!mounted || !_enPrimerPlano || sesion != _sesion) return;
      if (_midiendo != null) {
        _rumbos.add(r.grados);
        _inclinaciones.add(r.inclinacion);
        if (r.descalibrada) _descalibradaAlMedir = true;
      }
      final antes = _rumbo;
      // 20 lecturas por segundo: solo se repinta si cambió algo que se vea.
      if (antes == null ||
          diferenciaAngular(antes.grados, r.grados).abs() >= 1 ||
          (antes.inclinacion - r.inclinacion).abs() >= 2 ||
          antes.descalibrada != r.descalibrada) {
        if (mounted) setState(() => _rumbo = r);
      }
    }, onError: (Object e) => debugPrint('Brújula: $e'));
  }

  void _alLeerPosicion(LecturaPosicion l) {
    if (!mounted || !_enPrimerPlano) return;
    if (_midiendo != null) _muestras.add(l);
    _rastro?.add({...posicionJson(l), 't': DateTime.now().toIso8601String()});
    final prueba = _prueba;
    if (prueba != null) {
      final antes = prueba.llegadaApp;
      final maniobraAntes = prueba.maniobra;
      prueba.lectura(l);
      if (antes == null && prueba.llegadaApp != null) {
        HapticFeedback.heavyImpact();
      } else if (prueba.maniobra != maniobraAntes) {
        HapticFeedback.selectionClick();
      }
    }
    setState(() => _posicion = l);
  }

  Future<void> _guardar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, jsonEncode(_datos));
  }

  Future<void> _agregar(String lista, Json registro) async {
    (_datos[lista] as List).add(registro);
    if (mounted) setState(() {});
    await _guardar();
  }

  String get _quien => (_datos['medidor'] as String? ?? '').trim();

  Json get _comun => {
    'fecha': DateTime.now().toIso8601String(),
    if (_quien.isNotEmpty) 'medidor': _quien,
  };

  void _avisar(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(texto), duration: const Duration(seconds: 6)),
      );
  }

  /// Junta muestras del GPS y de la brújula durante [segundos]. Falso si se
  /// canceló.
  Future<bool> _medir(String etiqueta, int segundos) {
    _muestras.clear();
    _rumbos.clear();
    _inclinaciones.clear();
    _descalibradaAlMedir = false;
    final fin = Completer<bool>();
    _finMedida = fin;
    setState(() {
      _midiendo = etiqueta;
      _restante = segundos;
    });
    _reloj = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _restante--);
      if (_restante <= 0) _terminarMedida(true);
    });
    return fin.future;
  }

  void _terminarMedida(bool completa) {
    _reloj?.cancel();
    _reloj = null;
    if (mounted) setState(() => _midiendo = null);
    final fin = _finMedida;
    _finMedida = null;
    if (fin != null && !fin.isCompleted) fin.complete(completa);
  }

  Future<String?> _pedirTexto(
    String titulo,
    String etiqueta, {
    String inicial = '',
    String accion = 'Aceptar',
    TextInputType teclado = TextInputType.text,
  }) async {
    final control = TextEditingController(text: inicial);
    final texto = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: control,
          autofocus: true,
          keyboardType: teclado,
          decoration: InputDecoration(labelText: etiqueta),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, control.text),
            child: Text(accion),
          ),
        ],
      ),
    );
    // Sin dispose: el diálogo aún lo usa mientras se cierra. Es un objeto
    // pequeño y lo recoge el recolector.
    return texto;
  }

  Future<bool> _confirmar(String titulo, String texto, String accion) async {
    final si = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(accion),
          ),
        ],
      ),
    );
    return si ?? false;
  }

  // --- Entradas -----------------------------------------------------------

  /// Las entradas del grafo y las nuevas que se hayan medido.
  List<({int poiId, String nombre, PuntoGeo? estimado})> get _entradas {
    final grafo = _grafo;
    if (grafo == null) return const [];
    final lista = <({int poiId, String nombre, PuntoGeo? estimado})>[
      for (final a in grafo.accesos)
        (poiId: a.poiId, nombre: a.nombre, estimado: a.punto),
    ];
    for (final m in (_datos['accesos'] as List).cast<Json>()) {
      final poiId = (m['poi_id'] as num).toInt();
      final nombre = m['nombre'] as String? ?? '';
      if (!lista.any((e) => e.poiId == poiId && e.nombre == nombre)) {
        lista.add((poiId: poiId, nombre: nombre, estimado: null));
      }
    }
    return lista;
  }

  Future<void> _medirAcceso(
    int poiId,
    String nombre,
    PuntoGeo? estimado,
  ) async {
    if (!await _medir('Entrada: $nombre', 60)) return;
    final r = promedioLecturas(_muestras);
    if (r == null || r.usadas < _lecturasMinimas) {
      _avisar(
        'Solo ${r?.usadas ?? 0} lecturas buenas: no vale. ¿Se apagó la '
        'pantalla o estás bajo techo? Repite al aire libre.',
      );
      return;
    }
    await _agregar('accesos', {
      'poi_id': poiId,
      'nombre': nombre,
      'lat': r.punto.lat,
      'lng': r.punto.lng,
      'precision': (r.precision * 10).round() / 10,
      'lecturas': r.usadas,
      'descartadas': r.descartadas,
      if (estimado != null)
        'distancia_al_estimado_m': distanciaMetros(r.punto, estimado).round(),
      ..._comun,
    });
    final evaluacion = evaluarAcceso(medidasDe(_datos, poiId, nombre));
    _avisar(
      'Guardada: ±${r.precision.toStringAsFixed(1)} m. '
      '${evaluacion.estado == EstadoAcceso.aceptado ? 'Entrada aceptada.' : evaluacion.motivo}',
    );
  }

  Future<void> _entradaNueva() async {
    final grafo = _grafo;
    if (grafo == null) return;
    final lugares = {
      for (final a in grafo.accesos.where((a) => a.principal))
        a.poiId: a.nombre,
    };
    final poiId = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('¿De qué lugar es la entrada?'),
        children: [
          for (final e in lugares.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, e.key),
              child: Text(e.value),
            ),
        ],
      ),
    );
    if (poiId == null || !mounted) return;
    final nombre = await _pedirTexto(
      'Entrada nueva de ${lugares[poiId]}',
      'Nombre (p. ej. «${lugares[poiId]}, puerta norte»)',
      inicial: '${lugares[poiId]}, ',
      accion: 'Medir 60 s',
    );
    if (nombre == null || nombre.trim().isEmpty) return;
    await _medirAcceso(poiId, nombre.trim(), null);
  }

  Future<void> _verMedidas(int poiId, String nombre) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, actualizar) {
          final medidas = medidasDe(_datos, poiId, nombre);
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text(nombre, style: Theme.of(context).textTheme.titleMedium),
              Text(evaluarAcceso(medidas).motivo),
              if (medidas.isEmpty) const Text('Sin medidas.'),
              for (final m in medidas)
                ListTile(
                  dense: true,
                  title: Text(
                    '${(m['fecha'] as String).substring(0, 16).replaceFirst('T', ' ')}'
                    ' · ±${m['precision']} m',
                  ),
                  subtitle: Text(
                    [
                      '${m['lecturas']} lecturas',
                      if (m['distancia_al_estimado_m'] != null)
                        'a ${m['distancia_al_estimado_m']} m del estimado',
                      if (m['medidor'] != null) '${m['medidor']}',
                    ].join(' · '),
                  ),
                  trailing: IconButton(
                    tooltip: 'Borrar esta medida',
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () async {
                      final si = await _confirmar(
                        'Borrar la medida',
                        'Solo si fue un error (otro sitio, mala señal).',
                        'Borrar',
                      );
                      if (!si) return;
                      setState(() => (_datos['accesos'] as List).remove(m));
                      actualizar(() {});
                      await _guardar();
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _pestanaEntradas() {
    final entradas = _entradas;
    final evaluaciones = [
      for (final e in entradas)
        evaluarAcceso(medidasDe(_datos, e.poiId, e.nombre)),
    ];
    final aceptadas = evaluaciones
        .where((e) => e.estado == EstadoAcceso.aceptado)
        .length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Párate donde la persona llega de verdad (la puerta, no el centro '
          'del edificio), al aire libre, y toca «Medir». Son 60 s quieto con '
          'la pantalla encendida. Repite otro día: la entrada vale cuando dos '
          'medidas de días distintos, con ±5 m o mejor, quedan a 5 m o menos.',
        ),
        const SizedBox(height: 8),
        Text(
          '$aceptadas de ${entradas.length} entradas aceptadas',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (var i = 0; i < entradas.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _iconoAcceso(evaluaciones[i].estado),
            title: Text(
              '${entradas[i].nombre}'
              '${_paradas.containsKey(entradas[i].poiId) ? ' · parada' : ''}'
              '${entradas[i].estimado == null ? ' · nueva' : ''}',
            ),
            subtitle: Text(evaluaciones[i].motivo),
            onTap: () => _verMedidas(entradas[i].poiId, entradas[i].nombre),
            trailing: FilledButton.tonal(
              onPressed: _midiendo == null && _posicion != null
                  ? () => _medirAcceso(
                      entradas[i].poiId,
                      entradas[i].nombre,
                      entradas[i].estimado,
                    )
                  : null,
              child: const Text('Medir'),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _midiendo == null && _posicion != null
              ? _entradaNueva
              : null,
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('Entrada que no está en la lista'),
        ),
      ],
    );
  }

  static Widget _iconoAcceso(EstadoAcceso estado) => switch (estado) {
    EstadoAcceso.aceptado => const Icon(
      Icons.check_circle_rounded,
      color: Colors.greenAccent,
    ),
    EstadoAcceso.sinConfirmar => const Icon(
      Icons.timelapse_rounded,
      color: Colors.amberAccent,
    ),
    EstadoAcceso.sinUtiles => const Icon(
      Icons.error_outline_rounded,
      color: Colors.redAccent,
    ),
    EstadoAcceso.sinMedir => const Icon(Icons.radio_button_unchecked_rounded),
  };

  // --- Tramos -------------------------------------------------------------

  Future<void> _marcarTramo(TramoCercano cercano, LecturaPosicion l) async {
    final t = cercano.tramo;
    final marca = marcaDe(_datos, t);
    var tipo = marca?['tipo'] as String? ?? t.tipo.name;
    if (!_tiposTramo.contains(tipo)) tipo = 'sendero';
    var escalones = marca?['escalones'] as bool? ?? t.escalones;
    var techado = marca?['techado'] as bool? ?? t.techado;
    final nota = TextEditingController(text: marca?['nota'] as String? ?? '');
    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, actualizar) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tramo ${t.a}–${t.b} (${t.metros.round()} m)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text('Lo que ves aquí, en todo el tramo:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final opcion in _tiposTramo)
                    ChoiceChip(
                      label: Text(opcion),
                      selected: tipo == opcion,
                      onSelected: (_) => actualizar(() {
                        tipo = opcion;
                        if (opcion == 'escalera') escalones = true;
                        if (opcion == 'rampa') escalones = false;
                      }),
                    ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: escalones,
                onChanged: (v) => actualizar(() => escalones = v),
                title: const Text('Tiene escalones'),
                subtitle: const Text(
                  'Aunque sea uno: la ruta «sin escaleras» lo evita.',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: techado,
                onChanged: (v) => actualizar(() => techado = v),
                title: const Text('Techado'),
                subtitle: const Text('Bajo techo el GPS empeora.'),
              ),
              TextField(
                controller: nota,
                decoration: const InputDecoration(
                  labelText: 'Nota (opcional)',
                  hintText: 'p. ej. «rampa solo en la mitad sur»',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Guardar tramo'),
              ),
            ],
          ),
        ),
      ),
    );
    final textoNota = nota.text.trim();
    if (guardar != true) return;
    await _agregar('tramos', {
      'a': t.a,
      'b': t.b,
      // El centro del tramo evita confundir dos caminos cuando la persona
      // está justo en su cruce; los identificadores pueden cambiar.
      'lat': (_grafo!.nodos[t.a]!.lat + _grafo!.nodos[t.b]!.lat) / 2,
      'lng': (_grafo!.nodos[t.a]!.lng + _grafo!.nodos[t.b]!.lng) / 2,
      'tipo': tipo,
      'escalones': escalones,
      'techado': techado,
      if (textoNota.isNotEmpty) 'nota': textoNota,
      'precision': (l.precision * 10).round() / 10,
      ..._comun,
    });
    _avisar('Tramo ${t.a}–${t.b} guardado.');
  }

  Future<void> _alternarRastro() async {
    final rastro = _rastro;
    if (rastro == null) {
      final etiqueta = await _pedirTexto(
        'Grabar un recorrido',
        '¿Qué es? (p. ej. «puente A3–A5», «pasillo techado A1»)',
        accion: 'Grabar',
      );
      if (etiqueta == null) return;
      setState(() {
        _etiquetaRastro = etiqueta.trim();
        _rastro = [];
      });
      return;
    }
    setState(() => _rastro = null);
    if (rastro.length < 2) {
      _avisar('Sin puntos suficientes: no se guardó.');
      return;
    }
    await _agregar('recorridos', {
      'etiqueta': _etiquetaRastro,
      'puntos': rastro,
      ..._comun,
    });
    _avisar('Recorrido guardado (${rastro.length} puntos).');
  }

  Widget _pestanaTramos() {
    final grafo = _grafo, p = _posicion;
    final cercano = (grafo == null || p == null)
        ? null
        : tramoCercano(grafo, p.punto);
    final textos = Theme.of(context).textTheme;
    final marcas = (_datos['tramos'] as List).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Camina los caminos del campus. En cada tramo, marca si es sendero, '
          'pasillo, rampa, escalera o vía, si tiene escalones y si es '
          'techado. OSM no lo sabe y la ruta «sin escaleras» depende de esto.',
        ),
        const SizedBox(height: 12),
        if (cercano == null || p == null)
          const Text('Esperando GPS…')
        else ...[
          Text(
            'Tramo más cercano: ${cercano.tramo.a}–${cercano.tramo.b}',
            style: textos.titleMedium,
          ),
          Text(
            '${cercano.tramo.tipo.name} · ${cercano.tramo.metros.round()} m · '
            'a ${cercano.metros.toStringAsFixed(1)} m de ti'
            '${cercano.tramo.escalones ? ' · con escalones' : ''}'
            '${cercano.tramo.techado ? ' · techado' : ''}',
          ),
          if (marcaDe(_datos, cercano.tramo) case final m?)
            Text(
              'Ya marcado: ${m['tipo']}'
              '${m['escalones'] == true ? ', escalones' : ''}'
              '${m['techado'] == true ? ', techado' : ''}',
              style: const TextStyle(color: Colors.greenAccent),
            ),
          if (cercano.metros > distanciaMaximaMarcaTramo)
            Text(
              'Estás a ${cercano.metros.round()} m del tramo más cercano. Si '
              'por aquí hay un camino, falta en el mapa: grábalo abajo como '
              'recorrido.',
              style: const TextStyle(color: Colors.amberAccent),
            ),
          if (p.precision > 10)
            Text(
              'Precisión ±${p.precision.round()} m: espera a tener ±10 m o '
              'mejor para no marcar el tramo equivocado.',
              style: const TextStyle(color: Colors.amberAccent),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed:
                cercano.metros <= distanciaMaximaMarcaTramo && p.precision <= 10
                ? () => _marcarTramo(cercano, p)
                : null,
            icon: const Icon(Icons.edit_road_rounded),
            label: const Text('Marcar este tramo'),
          ),
        ],
        const SizedBox(height: 4),
        Text('$marcas tramos marcados'),
        const Divider(height: 32),
        const Text(
          'Un camino que falta (el puente A3–A5, un pasillo techado, una '
          'entrada): grábalo de punta a punta. Luego se agrega en '
          'OpenStreetMap y el script lo recoge.',
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _rastro != null,
          onChanged: (_) => _alternarRastro(),
          title: Text(
            _rastro == null
                ? 'Grabar un recorrido'
                : 'Grabando: $_etiquetaRastro',
          ),
          subtitle: Text(
            _rastro == null
                ? '${(_datos['recorridos'] as List).length} guardados'
                : '${_rastro!.length} puntos',
          ),
        ),
      ],
    );
  }

  // --- Norte de las panorámicas -------------------------------------------

  /// Con el teléfono vertical la brújula da el rumbo de la cámara; acostado,
  /// el de la parte de arriba. Para medir algo con la cámara, vertical.
  bool _verticalAlMedir() {
    if (_inclinaciones.isEmpty) return false;
    final media =
        _inclinaciones.reduce((a, b) => a + b) / _inclinaciones.length;
    return media.abs() <= 35;
  }

  Future<void> _medirNorte(int poiId) async {
    final objeto = await _pedirTexto(
      'Norte de ${_paradas[poiId]}',
      '¿A qué apuntas? (algo que se vea en la panorámica)',
      accion: 'Siguiente',
    );
    if (objeto == null || objeto.trim().isEmpty || !mounted) return;
    final yawTexto = await _pedirTexto(
      'Yaw del objeto en la panorámica',
      'Grados, si ya lo sabes. Si no, déjalo vacío y se completa en el JSON.',
      accion: 'Medir 4 s',
      teclado: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
    );
    if (yawTexto == null) return;
    if (!await _medir('Norte: ${_paradas[poiId]}', 4)) return;
    if (_rumbos.isEmpty) {
      _avisar('La brújula no dio lecturas.');
      return;
    }
    if (!_verticalAlMedir()) {
      _avisar(
        'Sostén el teléfono vertical, como para tomar una foto, y repite.',
      );
      return;
    }
    final magnetico = mediaCircular(_rumbos);
    final yaw = double.tryParse(yawTexto.trim().replaceAll(',', '.'));
    final p = _posicion;
    await _agregar('nortes', {
      'poi_id': poiId,
      'objeto': objeto.trim(),
      'rumbo_magnetico': (magnetico * 10).round() / 10,
      'declinacion': _declinacion,
      'rumbo_geografico':
          (normalizarGrados(magnetico + _declinacion) * 10).round() / 10,
      'yaw_objeto': yaw,
      'lecturas': _rumbos.length,
      'descalibrada': _descalibradaAlMedir,
      if (p != null) ...posicionJson(p),
      ..._comun,
    });
    _avisar(
      _descalibradaAlMedir
          ? 'Guardado, pero la brújula pidió calibrarse: mueve el teléfono en '
                'forma de 8 y repite.'
          : 'Guardado: ${magnetico.toStringAsFixed(0)}° magnético.',
    );
  }

  Widget _pestanaNorte() {
    final nortes = (_datos['nortes'] as List).cast<Json>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Párate exactamente donde se tomó cada panorámica. Apunta la cámara, '
          'con el teléfono vertical, a algo que se reconozca en la foto (una '
          'puerta, una columna, una esquina) y escribe qué es. Mide dos o tres '
          'objetos distintos por parada.',
        ),
        for (final entrada in _paradas.entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(entrada.value),
            subtitle: Text(
              nortes
                  .where((n) => n['poi_id'] == entrada.key)
                  .map(
                    (n) =>
                        '${n['rumbo_magnetico']}° → ${n['objeto']}'
                        '${n['yaw_objeto'] == null ? '' : ' (yaw ${n['yaw_objeto']}°)'}',
                  )
                  .join('\n'),
            ),
            trailing: FilledButton.tonal(
              onPressed: _midiendo == null
                  ? () => _medirNorte(entrada.key)
                  : null,
              child: const Text('Medir'),
            ),
          ),
      ],
    );
  }

  // --- Brújula ------------------------------------------------------------

  Future<void> _comprobarBrujula(TramoCercano cercano) async {
    if (!await _medir('Brújula', 4)) return;
    if (_rumbos.isEmpty) {
      _avisar('La brújula no dio lecturas.');
      return;
    }
    if (!_verticalAlMedir()) {
      _avisar(
        'Sostén el teléfono vertical, con la cámara mirando a lo largo del '
        'camino, y repite.',
      );
      return;
    }
    final magnetico = mediaCircular(_rumbos);
    final geografico = normalizarGrados(magnetico + _declinacion);
    final error = errorBrujula(cercano.rumbo, geografico);
    final p = _posicion;
    await _agregar('brujula', {
      'a': cercano.tramo.a,
      'b': cercano.tramo.b,
      'rumbo_tramo': (cercano.rumbo * 10).round() / 10,
      'rumbo_magnetico': (magnetico * 10).round() / 10,
      'declinacion': _declinacion,
      'rumbo_brujula': (geografico * 10).round() / 10,
      'error': (error * 10).round() / 10,
      'descalibrada': _descalibradaAlMedir,
      'lecturas': _rumbos.length,
      if (p != null) ...posicionJson(p),
      ..._comun,
    });
    _avisar(
      'Error: ${error.toStringAsFixed(1)}°'
      '${error.abs() > errorRumboMaximo ? ' (más de 10°)' : ''}'
      '${_descalibradaAlMedir ? '. La brújula pidió calibrarse.' : ''}',
    );
  }

  Widget _pestanaBrujula() {
    final grafo = _grafo, p = _posicion;
    final cercano = (grafo == null || p == null)
        ? null
        : tramoCercano(grafo, p.punto);
    final ahora = _rumboGeografico;
    final errores = [
      for (final b in (_datos['brujula'] as List).cast<Json>())
        (b['error'] as num).toDouble(),
    ];
    final resumen = resumirBrujula(errores);
    final String? impide;
    if (cercano == null || p == null) {
      impide = 'Esperando GPS…';
    } else if (cercano.tramo.metros < largoMinimoTramoBrujula) {
      impide =
          'Este tramo mide ${cercano.tramo.metros.round()} m: busca uno '
          'recto de ${largoMinimoTramoBrujula.round()} m o más.';
    } else if (cercano.metros > distanciaMaximaTramoBrujula) {
      impide = 'Estás a ${cercano.metros.round()} m del camino: párate encima.';
    } else if (p.precision > 8) {
      impide = 'Precisión ±${p.precision.round()} m: espera a ±8 m o mejor.';
    } else {
      impide = null;
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Mide cuánto se equivoca la brújula (RNF-27 pide 10° o menos). '
          'Párate sobre un camino recto, lejos de carros, rejas y columnas de '
          'metal, y apunta la cámara a lo largo del camino, hacia cualquiera '
          'de los dos lados. Haz al menos 8 en sitios distintos.',
        ),
        const SizedBox(height: 12),
        if (cercano != null)
          Text(
            'Camino: ${cercano.rumbo.toStringAsFixed(0)}° / '
            '${normalizarGrados(cercano.rumbo + 180).toStringAsFixed(0)}° · '
            '${cercano.tramo.metros.round()} m',
          ),
        if (ahora != null && cercano != null)
          Text(
            'Brújula ahora: ${ahora.toStringAsFixed(0)}° → error '
            '${errorBrujula(cercano.rumbo, ahora).toStringAsFixed(0)}°',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        if (impide != null)
          Text(impide, style: const TextStyle(color: Colors.amberAccent)),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: impide == null && _midiendo == null && cercano != null
              ? () => _comprobarBrujula(cercano)
              : null,
          icon: const Icon(Icons.explore_rounded),
          label: const Text('Comprobar (4 s)'),
        ),
        const SizedBox(height: 16),
        if (resumen == null)
          Text('${errores.length} comprobaciones')
        else ...[
          Text(
            '${resumen.comprobaciones} comprobaciones · sesgo '
            '${resumen.sesgo.toStringAsFixed(1)}°',
          ),
          Text(
            'Error tras corregir el sesgo: p95 '
            '${resumen.p95.toStringAsFixed(1)}°, máximo '
            '${resumen.maximo.toStringAsFixed(1)}° → RNF-27 '
            '${resumen.cumple ? 'cumple' : 'NO cumple'}',
            style: TextStyle(
              color: resumen.cumple ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
          Text(
            'Declinación sugerida: '
            '${(_declinacion - resumen.sesgo).toStringAsFixed(1)}° '
            '(hoy $_declinacion°)',
          ),
        ],
      ],
    );
  }

  // --- Prueba de la guía --------------------------------------------------

  void _empezarPrueba(int poiId) {
    final grafo = _grafo, p = _posicion;
    if (grafo == null || p == null) return;
    if (p.precision > 20) {
      _avisar('Precisión ±${p.precision.round()} m: espera a ±20 m o mejor.');
      return;
    }
    final prueba = RegistroPrueba.iniciar(
      grafo,
      poiId,
      p,
      sinEscaleras: _sinEscaleras,
    );
    if (prueba == null) {
      _avisar('No hay ruta desde aquí.');
      return;
    }
    setState(() => _prueba = prueba);
  }

  Future<void> _indicacionMala() async {
    final p = _posicion, prueba = _prueba;
    if (p == null || prueba == null) return;
    final nota = await _pedirTexto(
      'Indicación equivocada',
      '¿Qué pasa? (p. ej. «dice derecha y el camino va a la izquierda»)',
      accion: 'Anotar',
    );
    if (nota == null) return;
    setState(() => prueba.marcarIndicacionMala(p, nota: nota.trim()));
  }

  Future<void> _enLaPuerta() async {
    final p = _posicion, prueba = _prueba;
    if (p == null || prueba == null) return;
    if (p.precision > precisionAceptable) {
      _avisar(
        'Espera a tener precisión de ±5 m o mejor para marcar la puerta.',
      );
      return;
    }
    prueba.marcarPuerta(p);
    setState(() => _prueba = null);
    await _agregar('pruebas', prueba.toJson());
    final error = prueba.errorLlegada;
    _avisar(
      error == null
          ? 'La app nunca dio la llegada: la prueba no pasa.'
          : 'La app dio la llegada a ${error.toStringAsFixed(1)} m de la '
                'puerta: ${prueba.paso ? 'pasa' : 'no pasa'}.',
    );
  }

  Future<void> _cancelarPrueba() async {
    if (!await _confirmar(
      'Cancelar la prueba',
      'No se guarda nada de esta prueba.',
      'Cancelar prueba',
    )) {
      return;
    }
    setState(() => _prueba = null);
  }

  static String _textoManiobra(Maniobra? m) {
    if (m == null) return 'Buscando señal…';
    final metros = m.metros.round();
    if (m.llegada) return 'Llegando: $metros m';
    return switch (m.giro) {
      Giro.recto => 'Sigue recto $metros m',
      Giro.derecha => 'En $metros m, gira a la derecha',
      Giro.izquierda => 'En $metros m, gira a la izquierda',
      Giro.ligeraDerecha => 'En $metros m, ligeramente a la derecha',
      Giro.ligeraIzquierda => 'En $metros m, ligeramente a la izquierda',
      Giro.vuelta => 'Da la vuelta',
    };
  }

  Widget _pestanaGuia() {
    final prueba = _prueba;
    final textos = Theme.of(context).textTheme;
    final pruebas = (_datos['pruebas'] as List).cast<Json>();
    if (prueba == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Camina hasta cada parada siguiendo esta guía, que usa la misma '
            'lógica que la app (ruta, radio de 10 m, desvíos). Sal desde '
            'sitios distintos: la portería, otra parada, un edificio. Al '
            'llegar a la puerta real, toca «Estoy en la puerta».',
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _sinEscaleras,
            onChanged: (v) => setState(() => _sinEscaleras = v),
            title: const Text('Ruta sin escaleras'),
          ),
          for (final entrada in _paradas.entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entrada.value),
              subtitle: Text(
                pruebas
                    .where((x) => x['poi_id'] == entrada.key)
                    .map(
                      (x) =>
                          '${x['paso'] == true ? '✓' : '✗'} '
                          '${x['error_llegada_m'] == null ? 'sin llegada' : '${x['error_llegada_m']} m'}'
                          '${x['sin_escaleras'] == true ? ', sin escaleras' : ''}',
                    )
                    .join(' · '),
              ),
              trailing: FilledButton.tonal(
                onPressed: _posicion == null
                    ? null
                    : () => _empezarPrueba(entrada.key),
                child: const Text('Empezar'),
              ),
            ),
        ],
      );
    }
    final s = prueba.seguimiento;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Hacia ${prueba.destino.nombre}', style: textos.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.estado == EstadoSeguimiento.senalDebil
                      ? 'Señal débil'
                      : _textoManiobra(prueba.maniobra),
                  style: textos.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Faltan ${s.metrosRestantes.round()} m · punto '
                  '${s.objetivo} de ${s.ruta.puntos.length} · ${s.estado.name}',
                ),
                Text(
                  '${prueba.recalculos} recálculos · '
                  '${prueba.indicacionesMalas} indicaciones marcadas',
                ),
              ],
            ),
          ),
        ),
        if (prueba.llegadaApp != null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'La app ya dio la llegada aquí. Sigue hasta la puerta real y '
              'toca «Estoy en la puerta».',
              style: TextStyle(color: Colors.greenAccent),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _indicacionMala,
          icon: const Icon(Icons.report_outlined),
          label: const Text('Indicación equivocada'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _enLaPuerta,
          icon: const Icon(Icons.door_front_door_outlined),
          label: const Text('Estoy en la puerta'),
        ),
        TextButton(
          onPressed: _cancelarPrueba,
          child: const Text('Cancelar prueba'),
        ),
      ],
    );
  }

  // --- Datos --------------------------------------------------------------

  Future<void> _copiar() async {
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(_datos)),
    );
    _avisar(
      'Copiado. Pégalo en un archivo levantamiento-<nombre>-<fecha>.json y '
      'pásalo al equipo.',
    );
  }

  Future<void> _borrarTodo() async {
    if (!await _confirmar(
      'Borrar todo',
      'Se pierde todo lo medido en este teléfono. Cópialo antes.',
      'Borrar todo',
    )) {
      return;
    }
    setState(() {
      _datos = normalizarDatos({'medidor': _quien});
    });
    await _guardar();
  }

  Widget _pestanaDatos() {
    final entradas = _entradas;
    final aceptadas = entradas
        .where(
          (e) =>
              evaluarAcceso(medidasDe(_datos, e.poiId, e.nombre)).estado ==
              EstadoAcceso.aceptado,
        )
        .length;
    final nortes = (_datos['nortes'] as List).cast<Json>();
    final paradasConNorte = _paradas.keys
        .where(
          (id) =>
              nortes
                  .where(
                    (n) =>
                        n['poi_id'] == id &&
                        n['yaw_objeto'] is num &&
                        n['descalibrada'] != true,
                  )
                  .map((n) => n['objeto'])
                  .toSet()
                  .length >=
              2,
        )
        .length;
    final pruebas = (_datos['pruebas'] as List).cast<Json>();
    final paradasProbadas = _paradas.keys
        .where(
          (id) => pruebas.any((x) => x['poi_id'] == id && x['paso'] == true),
        )
        .length;
    final brujula = (_datos['brujula'] as List).length;
    final filas = <(bool, String)>[
      (
        aceptadas == entradas.length,
        'Entradas aceptadas: $aceptadas de ${entradas.length}',
      ),
      (
        paradasConNorte == _paradas.length,
        'Panorámicas con norte: $paradasConNorte de ${_paradas.length}',
      ),
      (
        (_datos['tramos'] as List).isNotEmpty,
        'Tramos marcados: ${(_datos['tramos'] as List).length}',
      ),
      (brujula >= 8, 'Comprobaciones de brújula: $brujula de 8'),
      (
        paradasProbadas == _paradas.length,
        'Paradas con una prueba de la guía que pasa: $paradasProbadas de '
            '${_paradas.length}',
      ),
      (
        (_datos['recorridos'] as List).isNotEmpty,
        'Recorridos grabados: ${(_datos['recorridos'] as List).length}',
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _medidor,
          decoration: const InputDecoration(
            labelText: 'Quién mide',
            helperText:
                'Va en cada medida, para juntar los de varios teléfonos.',
          ),
          onChanged: (v) {
            _datos['medidor'] = v.trim();
            _guardar();
          },
        ),
        const SizedBox(height: 16),
        for (final (hecho, texto) in filas)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              hecho
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: hecho ? Colors.greenAccent : null,
            ),
            title: Text(texto),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _copiar,
          icon: const Icon(Icons.copy_all_rounded),
          label: const Text('Copiar el JSON para el equipo'),
        ),
        const SizedBox(height: 8),
        const Text(
          'En el computador: python -I scripts/grafo_campus.py --informe '
          'levantamiento-*.json muestra qué falta; sin --informe, actualiza el '
          'grafo de la app.',
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: _borrarTodo,
          icon: const Icon(Icons.delete_forever_outlined),
          label: const Text('Borrar todo lo medido'),
        ),
      ],
    );
  }

  // --- Estructura ---------------------------------------------------------

  Widget _estado() {
    final p = _posicion, r = _rumboGeografico;
    final color = p == null
        ? null
        : p.precision <= precisionAceptable
        ? Colors.greenAccent
        : p.precision <= 10
        ? Colors.amberAccent
        : Colors.redAccent;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  TextButton(
                    onPressed: _escuchar,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            Row(
              children: [
                Icon(Icons.gps_fixed_rounded, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [
                      if (p == null)
                        'Esperando GPS…'
                      else
                        '±${p.precision.toStringAsFixed(1)} m',
                      if (r != null) 'brújula ${r.toStringAsFixed(0)}°',
                      if (_rumbo?.descalibrada ?? false) '¡calibra en 8!',
                      if (_rastro != null) 'grabando',
                    ].join(' · '),
                  ),
                ),
              ],
            ),
            if (_midiendo != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$_midiendo: $_restante s · ${_muestras.length} '
                      'lecturas GPS · no te muevas',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _terminarMedida(false),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_grafo == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Levantamiento del campus'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Entradas'),
              Tab(text: 'Tramos'),
              Tab(text: 'Norte'),
              Tab(text: 'Brújula'),
              Tab(text: 'Guía'),
              Tab(text: 'Datos'),
            ],
          ),
        ),
        body: Column(
          children: [
            _estado(),
            Expanded(
              child: TabBarView(
                children: [
                  _pestanaEntradas(),
                  _pestanaTramos(),
                  _pestanaNorte(),
                  _pestanaBrujula(),
                  _pestanaGuia(),
                  _pestanaDatos(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

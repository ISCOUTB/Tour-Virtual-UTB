part of 'pantalla_navegacion.dart';

// Modo campo de la guía: diagnóstico y correcciones hechas en el campus.
//
// Es una herramienta del equipo para la prueba en la universidad, no del
// visitante: solo existe con `--dart-define=CAMPO=true` y sus textos van en
// español, como los de la app de levantamiento, en vez de en los .arb.

/// Con peor precisión, una lectura no entra en un promedio.
const _precisionUtil = 15.0;

/// Segundos quieto para marcar una puerta.
const _segundosPuerta = 10;

extension _Campo on _GuiaState {
  CorreccionesNotifier get _correcciones =>
      ref.read(correccionesCampoProvider.notifier);

  String? get _autor => _correcciones.autor;

  PuntoGeo? get _aqui => (_posicionCampo ?? _seguimiento?.ultima)?.punto;

  void _alLeerCampo(LecturaPosicion l) {
    _posicionCampo = l;
    for (final oyente in [..._oyentesCampo]) {
      oyente(l);
    }
    final trazo = _trazo;
    if (trazo != null && l.precision <= _precisionUtil) {
      // Un punto cada 3 m: más seguido solo graba el ruido de estar quieto.
      if (trazo.isEmpty || distanciaMetros(trazo.last, l.punto) >= 3) {
        _refrescar(() => trazo.add(l.punto));
      }
    }
    if (_fase == _Fase.llegada && mounted) _refrescar(() {});
  }

  /// El tramo de la ruta más cercano a la posición: el que se va a corregir,
  /// con sus extremos en el grafo (no el pedazo que recorre la ruta).
  ({TramoCampus tramo, PuntoGeo desde, PuntoGeo hasta, double rumbo})?
  _tramoActual() {
    final ruta = _seguimiento?.ruta, aqui = _aqui;
    if (ruta == null || aqui == null || ruta.tramos.isEmpty) return null;
    var mejor = 0;
    var distancia = double.infinity;
    for (var i = 0; i < ruta.puntos.length - 1; i++) {
      final d = proyectarEnTramo(aqui, ruta.puntos[i], ruta.puntos[i + 1]);
      if (d.metros < distancia) {
        distancia = d.metros;
        mejor = i;
      }
    }
    final tramo = ruta.tramos[mejor];
    final desde = widget.grafo.nodos[tramo.a],
        hasta = widget.grafo.nodos[tramo.b];
    if (desde == null || hasta == null) return null;
    return (
      tramo: tramo,
      desde: desde,
      hasta: hasta,
      // En el sentido de la ruta, para calibrar la brújula.
      rumbo: rumboGrados(ruta.puntos[mejor], ruta.puntos[mejor + 1]),
    );
  }

  void _avisarCampo(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(texto), duration: const Duration(seconds: 5)),
      );
  }

  /// Confirmación abajo y sin oscurecer: el tramo resaltado del plano tiene
  /// que verse mientras se decide. Un diálogo al centro lo tapaba.
  Future<bool> _confirmarSobrePlano(
    String titulo,
    String texto, {
    String accion = 'Aplicar',
  }) async =>
      await showModalBottomSheet<bool>(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(titulo, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(texto),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(accion),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ) ??
      false;

  Future<bool> _confirmarCampo(
    String titulo,
    String texto, {
    String accion = 'Aplicar',
  }) async =>
      await showDialog<bool>(
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
      ) ??
      false;

  /// Promedia el GPS durante [_segundosPuerta] segundos, quieto. Pesa cada
  /// lectura por su precisión. Nulo si se canceló o no hubo señal útil.
  Future<({PuntoGeo punto, double precision})?> _medirAqui(
    String titulo,
  ) async {
    final muestras = <LecturaPosicion>[];
    void oyente(LecturaPosicion l) {
      if (l.precision <= _precisionUtil) muestras.add(l);
    }

    _oyentesCampo.add(oyente);
    final completa = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogoMedicion(
        titulo: titulo,
        segundos: _segundosPuerta,
        muestras: () => muestras,
      ),
    );
    _oyentesCampo.remove(oyente);
    if (completa != true) return null;
    if (muestras.length < 3) {
      _avisarCampo(
        'Solo ${muestras.length} lecturas con ±${_precisionUtil.round()} m o '
        'mejor. Busca cielo abierto y repite.',
      );
      return null;
    }
    var pesos = 0.0, lat = 0.0, lng = 0.0, precision = 0.0;
    for (final m in muestras) {
      final w = 1 / (m.precision * m.precision);
      pesos += w;
      lat += w * m.punto.lat;
      lng += w * m.punto.lng;
      precision += w * m.precision;
    }
    return (
      punto: PuntoGeo(lat / pesos, lng / pesos),
      precision: precision / pesos,
    );
  }

  /// «Estoy en la puerta»: mide la puerta real, anota la prueba y, si la
  /// entrada de la guía está lejos, ofrece moverla aquí.
  Future<void> _estoyEnLaPuerta() async {
    final destino = _seguimiento?.ruta.destino;
    if (destino == null) return;
    final medida = await _medirAqui('Quieto en la puerta real');
    if (medida == null || !mounted) return;
    final prueba = CorreccionPrueba(
      id: nuevoIdCorreccion(),
      fecha: DateTime.now(),
      autor: _autor,
      poiId: widget.poi.id,
      puerta: medida.punto,
      destino: destino.punto,
      llegadaApp: _llegadaApp,
    );
    _correcciones.agregar(prueba);
    // Con dos entradas, la ruta puede ir a la otra: se compara con la más
    // cercana a donde está la persona.
    final cercana = _entradasPorCercania(medida.punto).first;
    final error = distanciaMetros(cercana.punto, medida.punto);
    final llegada = _llegadaApp == null
        ? 'La guía no había dado la llegada.'
        : 'La guía dio la llegada a '
              '${distanciaMetros(_llegadaApp!, medida.punto).round()} m de aquí.';
    final mover = await _confirmarCampo(
      error <= 3 ? 'La entrada está bien' : 'Entrada a ${error.round()} m',
      'La entrada «${cercana.nombre}» de la guía está a ${error.round()} m '
      'de donde estás (±${medida.precision.round()} m). $llegada\n\n'
      '¿Mover una entrada aquí?',
      accion: 'Mover aquí',
    );
    if (!mover || !mounted) return;
    await _guardarEntrada(medida.punto, medida.precision);
  }

  List<AccesoLugar> _entradasPorCercania(PuntoGeo punto) =>
      widget.grafo.accesosDe(widget.poi.id)..sort(
        (a, b) => distanciaMetros(
          a.punto,
          punto,
        ).compareTo(distanciaMetros(b.punto, punto)),
      );

  /// Mueve la entrada que elija la persona (la más cercana primero) o
  /// agrega una nueva. Con una sola entrada no pregunta.
  Future<void> _guardarEntrada(PuntoGeo punto, double precision) async {
    final entradas = _entradasPorCercania(punto);
    String? nombre;
    if (entradas.length == 1) {
      nombre = entradas.single.nombre;
    } else {
      nombre = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('¿Qué entrada es esta?'),
          children: [
            for (final e in entradas)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, e.nombre),
                child: Text(
                  '${e.nombre} · hoy a ${distanciaMetros(e.punto, punto).round()} m',
                ),
              ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Es otra entrada, nueva'),
            ),
          ],
        ),
      );
      if (nombre == '' && mounted) {
        nombre = await _pedirNombreEntrada(entradas.length + 1);
      }
    }
    if (nombre == null || nombre.isEmpty || !mounted) return;
    _correcciones.agregar(
      CorreccionEntrada(
        id: nuevoIdCorreccion(),
        fecha: DateTime.now(),
        autor: _autor,
        poiId: widget.poi.id,
        nombre: nombre,
        punto: punto,
        precision: precision,
      ),
    );
    _avisarCampo('Entrada «$nombre» en este punto. Ruta recalculada.');
  }

  Future<String?> _pedirNombreEntrada(int numero) async {
    final control = TextEditingController(
      text: '${widget.poi.nombre}, entrada $numero',
    );
    final nombre = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Entrada nueva'),
        content: TextField(
          controller: control,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, control.text.trim()),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    control.dispose();
    return nombre;
  }

  Future<void> _moverEntrada() async {
    if (_seguimiento == null) return;
    final medida = await _medirAqui('Quieto en la puerta real');
    if (medida == null || !mounted) return;
    await _guardarEntrada(medida.punto, medida.precision);
  }

  Future<void> _corregirTramo({bool? escalones, bool? bloqueado}) async {
    final actual = _tramoActual();
    if (actual == null) {
      _avisarCampo('Sin ruta o sin posición: no hay tramo que corregir.');
      return;
    }
    _refrescar(() => _resaltado = [actual.desde, actual.hasta]);
    final que = bloqueado == true
        ? 'no se puede pasar'
        : escalones == true
        ? 'tiene escalones'
        : 'no tiene escalones';
    final ok = await _confirmarSobrePlano(
      'Tramo en naranja',
      'Tramo de ${actual.tramo.metros.round()} m '
          '(${actual.tramo.tipo.name}${actual.tramo.escalones ? ', con escalones' : ''}). '
          '¿Marcar que $que?',
    );
    if (mounted) _refrescar(() => _resaltado = const []);
    if (!ok) return;
    _correcciones.agregar(
      CorreccionTramo(
        id: nuevoIdCorreccion(),
        fecha: DateTime.now(),
        autor: _autor,
        desde: actual.desde,
        hasta: actual.hasta,
        bloqueado: bloqueado,
        escalones: escalones,
      ),
    );
    _avisarCampo('Tramo corregido. Ruta recalculada.');
  }

  void _empezarGrabacion() {
    final aqui = _aqui;
    _refrescar(() => _trazo = [?aqui]);
    _avisarCampo(
      'Grabando. Camina el camino que falta, de un camino del mapa a otro, '
      'y toca «Terminar camino».',
    );
  }

  Future<void> _terminarGrabacion() async {
    final trazo = _trazo;
    if (trazo == null) return;
    _refrescar(() => _trazo = null);
    final puntos = simplificarTrazo(trazo, 2);
    var metros = 0.0;
    for (var i = 0; i < puntos.length - 1; i++) {
      metros += distanciaMetros(puntos[i], puntos[i + 1]);
    }
    if (puntos.length < 2 || metros < 8) {
      _avisarCampo('Camino de ${metros.round()} m: muy corto, no se guarda.');
      return;
    }
    final escalones = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Camino de ${metros.round()} m'),
        content: const Text(
          'Se une a los caminos del mapa por sus dos puntas. ¿Tiene escalones?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Descartar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Con escalones'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Sin escalones'),
          ),
        ],
      ),
    );
    if (escalones == null) return;
    _correcciones.agregar(
      CorreccionCamino(
        id: nuevoIdCorreccion(),
        fecha: DateTime.now(),
        autor: _autor,
        puntos: puntos,
        escalones: escalones,
      ),
    );
    _avisarCampo('Camino agregado. Ruta recalculada.');
  }

  /// La flecha apunta mal: con la cámara hacia donde sigue el camino, la
  /// diferencia con el rumbo del tramo es el ajuste de la brújula.
  Future<void> _calibrarBrujula() async {
    final actual = _tramoActual(), brujula = _rumbo;
    if (actual == null || brujula == null) {
      _avisarCampo('Hace falta la ruta y la brújula para calibrar.');
      return;
    }
    if (brujula.descalibrada) {
      _avisarCampo(
        'Hay metal cerca o la brújula necesita el ocho: aléjate y repite.',
      );
      return;
    }
    _refrescar(() => _resaltado = [actual.desde, actual.hasta]);
    final ok = await _confirmarSobrePlano(
      'Calibrar la brújula',
      'Párate sobre el tramo naranja, con el teléfono vertical y la cámara '
          'apuntando hacia donde sigue la ruta, lejos de rejas y carros. '
          'Luego toca «Calibrar».',
      accion: 'Calibrar',
    );
    if (mounted) _refrescar(() => _resaltado = const []);
    final ahora = _rumbo;
    if (!ok || ahora == null || !mounted) return;
    final delta = diferenciaAngular(ahora.grados, actual.rumbo);
    final total = ref.read(correccionesCampoProvider).ajusteBrujula + delta;
    if (delta.abs() > 40 &&
        !await _confirmarCampo(
          'Diferencia de ${delta.round()}°',
          'Es mucho para una brújula: puede que no apuntaras al camino o que '
              'haya metal cerca. ¿Aplicarla de todos modos?',
        )) {
      return;
    }
    _correcciones.agregar(
      CorreccionBrujula(
        id: nuevoIdCorreccion(),
        fecha: DateTime.now(),
        autor: _autor,
        grados: normalizarAjuste(total),
      ),
    );
    _avisarCampo(
      'Brújula corregida ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}° '
      '(ajuste total ${normalizarAjuste(total).toStringAsFixed(1)}°).',
    );
  }

  /// Estricto, amplio o el rango mundial, en ese orden.
  void _cambiarDetector() {
    final actual = ref.read(correccionesCampoProvider).magnetico;
    final siguiente = switch (actual?.tolerancia) {
      null when actual == null => 0.6,
      0.35 => 0.6,
      0.6 => null,
      _ => 0.35,
    };
    _correcciones.agregar(
      CorreccionMagnetico(
        id: nuevoIdCorreccion(),
        fecha: DateTime.now(),
        autor: _autor,
        tolerancia: siguiente,
      ),
    );
    _avisarCampo('Detector de metal: ${_nombreTolerancia(siguiente)}.');
  }

  void _cambiarRadio(double metros) {
    _correcciones.agregar(
      CorreccionRadio(
        id: nuevoIdCorreccion(),
        fecha: DateTime.now(),
        autor: _autor,
        metros: metros,
      ),
    );
  }

  Future<void> _anotar() async {
    final control = TextEditingController();
    final texto = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anotar un problema'),
        content: TextField(
          controller: control,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Qué pasa aquí',
            hintText: '«Dice derecha y el camino va a la izquierda»',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, control.text.trim()),
            child: const Text('Anotar'),
          ),
        ],
      ),
    );
    control.dispose();
    if (texto == null || texto.isEmpty) return;
    _correcciones.agregar(
      CorreccionNota(
        id: nuevoIdCorreccion(),
        fecha: DateTime.now(),
        autor: _autor,
        texto: texto,
        punto: _aqui,
        poiId: widget.poi.id,
      ),
    );
    _avisarCampo('Anotado con la posición.');
  }

  Future<void> _abrirCorrecciones() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _HojaCorrecciones(
        guiando: _seguimiento != null,
        grabando: _trazo != null,
        alMoverEntrada: _moverEntrada,
        alMarcarTramo: _corregirTramo,
        alGrabar: _empezarGrabacion,
        alCalibrar: _calibrarBrujula,
        alCambiarRadio: _cambiarRadio,
        alCambiarDetector: _cambiarDetector,
        alAnotar: _anotar,
      ),
    );
  }
}

String _nombreTolerancia(double? tolerancia) => switch (tolerancia) {
  null => 'apagado (rango mundial 20-75 µT)',
  final t =>
    '${t == toleranciaCampo ? 'estricto' : 'amplio'} '
        '(33 µT ±${(t * 100).round()} %)',
};

/// Junta las lecturas del GPS con cuenta atrás.
class _DialogoMedicion extends StatefulWidget {
  const _DialogoMedicion({
    required this.titulo,
    required this.segundos,
    required this.muestras,
  });

  final String titulo;
  final int segundos;
  final List<LecturaPosicion> Function() muestras;

  @override
  State<_DialogoMedicion> createState() => _DialogoMedicionState();
}

class _DialogoMedicionState extends State<_DialogoMedicion> {
  late var _restante = widget.segundos;
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _reloj = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _restante--);
      if (_restante <= 0) {
        t.cancel();
        Navigator.pop(context, true);
      }
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final muestras = widget.muestras();
    final mejor = muestras.isEmpty
        ? null
        : muestras.map((m) => m.precision).reduce((a, b) => a < b ? a : b);
    return AlertDialog(
      title: Text(widget.titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: 1 - _restante / widget.segundos,
            minHeight: 6,
          ),
          const SizedBox(height: 14),
          Text(
            'No te muevas: $_restante s\n'
            '${muestras.length} lecturas útiles'
            '${mejor == null ? '' : ' · mejor ±${mejor.round()} m'}',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

/// La barra del modo campo bajo la guía: diagnóstico y las dos acciones de
/// siempre.
class _BarraCampo extends ConsumerWidget {
  const _BarraCampo({required this.guia});

  final _GuiaState guia;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final correcciones = ref.watch(correccionesCampoProvider);
    final textos = Theme.of(context).textTheme;
    final posicion = guia._posicionCampo ?? guia._seguimiento?.ultima;
    final seguimiento = guia._seguimiento;
    final rumbo = rumboNavegacion(posicion, guia._rumbo);
    final fuenteRumbo = rumbo == null
        ? 'sin rumbo'
        : (posicion?.rumbo != null && (posicion?.velocidad ?? 0) > 0.6)
        ? 'rumbo GPS'
        : 'brújula';
    final destino = seguimiento?.ruta.destino;
    final aPuerta = (posicion == null || destino == null)
        ? null
        : distanciaMetros(posicion.punto, destino.punto);
    final tramo = guia._tramoActual()?.tramo;
    final trazo = guia._trazo;
    final ajuste = correcciones.ajusteBrujula;

    final intensidad = guia._rumbo?.intensidad;
    final linea = [
      if (posicion != null) '±${posicion.precision.round()} m',
      fuenteRumbo,
      if (intensidad != null) 'campo ${intensidad.round()} µT',
      if (ajuste != 0) 'ajuste ${ajuste.toStringAsFixed(1)}°',
      'radio ${guia.widget.radioLlegada.round()} m',
      if (aPuerta != null) 'puerta a ${aPuerta.round()} m',
      if (tramo != null)
        '${tramo.tipo.name}${tramo.escalones ? '+escalones' : ''}',
      '${correcciones.vigentes.length} corr.',
    ].join(' · ');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColoresUtb.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColoresUtb.naranja.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'MODO CAMPO · $linea',
              style: textos.labelSmall?.copyWith(color: ColoresUtb.naranja),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (trazo != null)
                  FilledButton.icon(
                    onPressed: guia._terminarGrabacion,
                    style: FilledButton.styleFrom(
                      backgroundColor: ColoresUtb.naranja,
                    ),
                    icon: const Icon(Icons.stop_rounded),
                    label: Text('Terminar camino (${trazo.length} pts)'),
                  ),
                if (seguimiento != null)
                  OutlinedButton.icon(
                    onPressed: guia._estoyEnLaPuerta,
                    icon: const Icon(Icons.door_front_door_outlined),
                    label: const Text('Estoy en la puerta'),
                  ),
                FilledButton.tonalIcon(
                  onPressed: guia._abrirCorrecciones,
                  icon: const Icon(Icons.build_rounded),
                  label: const Text('Corregir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Todas las correcciones: qué corregir aquí, la lista de lo corregido y
/// pasarlas a otro teléfono.
class _HojaCorrecciones extends ConsumerWidget {
  const _HojaCorrecciones({
    required this.guiando,
    required this.grabando,
    required this.alMoverEntrada,
    required this.alMarcarTramo,
    required this.alGrabar,
    required this.alCalibrar,
    required this.alCambiarRadio,
    required this.alCambiarDetector,
    required this.alAnotar,
  });

  final bool guiando;
  final bool grabando;
  final Future<void> Function() alMoverEntrada;
  final Future<void> Function({bool? escalones, bool? bloqueado}) alMarcarTramo;
  final VoidCallback alGrabar;
  final Future<void> Function() alCalibrar;
  final void Function(double) alCambiarRadio;
  final VoidCallback alCambiarDetector;
  final Future<void> Function() alAnotar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final correcciones = ref.watch(correccionesCampoProvider);
    final radio = correcciones.radioLlegada ?? SeguimientoRuta.radioPorDefecto;
    final magnetico = correcciones.magnetico;
    final detector = magnetico == null ? toleranciaCampo : magnetico.tolerancia;
    // Cierra la hoja y luego hace la acción: sus diálogos van sobre la guía,
    // que es donde se ve el tramo resaltado.
    VoidCallback cerrarY(void Function() accion) => () {
      Navigator.pop(context);
      accion();
    };

    Widget opcion(
      IconData icono,
      String titulo,
      String detalle,
      VoidCallback? accion,
    ) => ListTile(
      leading: Icon(icono, color: ColoresUtb.naranja),
      title: Text(titulo),
      subtitle: Text(detalle),
      onTap: accion,
      enabled: accion != null,
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Corregir la guía aquí', style: textos.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'Cada corrección cambia la ruta al momento y queda en este '
              'teléfono. Cópialas al grupo para que los demás las peguen.',
            ),
            const SizedBox(height: 8),
            opcion(
              Icons.door_front_door_outlined,
              'La puerta real es aquí',
              'Párate en la puerta: promedia el GPS 10 s y mueve la entrada.',
              guiando ? cerrarY(alMoverEntrada) : null,
            ),
            opcion(
              Icons.block_rounded,
              'Por este tramo no se puede pasar',
              'Cerrado, privado o no existe. La ruta lo evita.',
              guiando ? cerrarY(() => alMarcarTramo(bloqueado: true)) : null,
            ),
            opcion(
              Icons.stairs_rounded,
              'Este tramo tiene escalones',
              'La ruta sin escaleras lo evita.',
              guiando ? cerrarY(() => alMarcarTramo(escalones: true)) : null,
            ),
            opcion(
              Icons.accessible_rounded,
              'Este tramo no tiene escalones',
              'Quita la marca: las rampas sin escalones cuentan como sendero.',
              guiando ? cerrarY(() => alMarcarTramo(escalones: false)) : null,
            ),
            opcion(
              Icons.route_rounded,
              'Grabar un camino que falta',
              'Camínalo de un camino del mapa a otro; se une por sus puntas.',
              grabando ? null : cerrarY(alGrabar),
            ),
            opcion(
              Icons.explore_rounded,
              'La flecha apunta mal',
              'Calibra la brújula apuntando hacia donde sigue el camino.',
              guiando ? cerrarY(alCalibrar) : null,
            ),
            opcion(
              Icons.edit_note_rounded,
              'Anotar un problema',
              'Para corregirlo después, con la posición.',
              cerrarY(alAnotar),
            ),
            ListTile(
              leading: const Icon(
                Icons.adjust_rounded,
                color: ColoresUtb.naranja,
              ),
              title: Text('Radio de llegada: ${radio.round()} m'),
              subtitle: const Text('El del plan es 10 m (AD-03).'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Menos',
                    onPressed: radio <= 4
                        ? null
                        : () => alCambiarRadio(radio - 2),
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  IconButton(
                    tooltip: 'Más',
                    onPressed: radio >= 30
                        ? null
                        : () => alCambiarRadio(radio + 2),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.sensors_rounded,
                color: ColoresUtb.naranja,
              ),
              title: Text('Detector de metal: ${_nombreTolerancia(detector)}'),
              subtitle: const Text(
                'Si la flecha desaparece estando quieto con el teléfono '
                'calibrado, prueba «amplio». Toca para cambiar.',
              ),
              onTap: alCambiarDetector,
            ),
            const Divider(height: 24),
            const _ListaCorrecciones(),
          ],
        ),
      ),
    );
  }
}

/// Lo corregido en este teléfono y lo importado, con deshacer, copiar y
/// pegar.
class _ListaCorrecciones extends ConsumerStatefulWidget {
  const _ListaCorrecciones();

  @override
  ConsumerState<_ListaCorrecciones> createState() => _ListaCorreccionesState();
}

class _ListaCorreccionesState extends ConsumerState<_ListaCorrecciones> {
  late final _autor = TextEditingController(
    text: ref.read(correccionesCampoProvider.notifier).autor ?? '',
  );

  @override
  void dispose() {
    _autor.dispose();
    super.dispose();
  }

  /// Dentro de la hoja: un SnackBar quedaba detrás de ella y no se veía.
  String? _mensaje;

  void _avisar(String texto) => setState(() => _mensaje = texto);

  Future<void> _copiar() async {
    final texto = ref.read(correccionesCampoProvider).exportar();
    await Clipboard.setData(ClipboardData(text: texto));
    _avisar('Copiadas. Pégalas en el grupo; los demás tocan «Pegar».');
  }

  Future<void> _pegar() async {
    final datos = await Clipboard.getData(Clipboard.kTextPlain);
    final otras = CorreccionesCampo.importar(datos?.text ?? '');
    if (otras == null) {
      _avisar('El portapapeles no tiene correcciones de la guía.');
      return;
    }
    final nuevas = ref.read(correccionesCampoProvider.notifier).importar(otras);
    _avisar(
      nuevas == 0 ? 'Ya estaban todas.' : '$nuevas nuevas. Ruta recalculada.',
    );
  }

  static String _resumen(Correccion c) => switch (c) {
    CorreccionEntrada(:final nombre, :final precision) =>
      'Entrada «$nombre» movida'
          '${precision == null ? '' : ' (±${precision.round()} m)'}',
    CorreccionTramo(:final bloqueado, :final escalones) =>
      bloqueado == true
          ? 'Tramo cerrado'
          : escalones == true
          ? 'Tramo con escalones'
          : 'Tramo sin escalones',
    CorreccionCamino(:final metros, :final escalones) =>
      'Camino nuevo de ${metros.round()} m${escalones ? ', con escalones' : ''}',
    CorreccionBrujula(:final grados) =>
      'Brújula: ajuste ${grados.toStringAsFixed(1)}°',
    CorreccionRadio(:final metros) => 'Radio de llegada: ${metros.round()} m',
    CorreccionMagnetico(:final tolerancia) =>
      'Detector de metal: ${_nombreTolerancia(tolerancia)}',
    CorreccionPrueba(:final errorEntrada, :final llegadaApp) =>
      'Prueba: entrada a ${errorEntrada.round()} m'
          '${llegadaApp == null ? ', sin llegada' : ''}',
    CorreccionNota(:final texto) => 'Nota: $texto',
  };

  @override
  Widget build(BuildContext context) {
    final correcciones = ref.watch(correccionesCampoProvider);
    final textos = Theme.of(context).textTheme;
    final vigentes = correcciones.vigentes.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _autor,
          decoration: const InputDecoration(
            labelText: 'Quién corrige',
            helperText: 'Va en cada corrección.',
          ),
          onChanged: ref.read(correccionesCampoProvider.notifier).cambiarAutor,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: correcciones.lista.isEmpty ? null : _copiar,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copiar'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pegar,
                icon: const Icon(Icons.paste_rounded),
                label: const Text('Pegar'),
              ),
            ),
          ],
        ),
        if (_mensaje case final m?)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                m,
                style: textos.bodyMedium?.copyWith(color: ColoresUtb.naranja),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text('Correcciones (${vigentes.length})', style: textos.titleMedium),
        if (vigentes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Ninguna todavía.'),
          ),
        for (final c in vigentes)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(_resumen(c)),
            subtitle: Text(
              '${c.fecha.hour.toString().padLeft(2, '0')}:'
              '${c.fecha.minute.toString().padLeft(2, '0')}'
              '${c.autor == null ? '' : ' · ${c.autor}'}',
            ),
            trailing: IconButton(
              tooltip: 'Deshacer',
              icon: const Icon(Icons.undo_rounded),
              onPressed: () =>
                  ref.read(correccionesCampoProvider.notifier).anular(c.id),
            ),
          ),
      ],
    );
  }
}

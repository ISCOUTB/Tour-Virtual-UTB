part of 'pantalla_navegacion.dart';

// Modo campo de la guía: corregir en el campus lo que salga mal.
//
// Herramienta del equipo para la prueba en la universidad, no del visitante:
// solo existe con `--dart-define=CAMPO=true` y sus textos van en español,
// como los de la app de levantamiento, en vez de en los .arb.
//
// Pensado para usarse caminando y sin leer instrucciones: se dice qué está
// mal en palabras de la calle («por aquí no se pasa»), se aplica al momento
// y se puede deshacer. Sin diálogos de confirmación: el aviso de abajo trae
// «Deshacer», y el tramo afectado se ve en naranja en el plano.

/// Con peor precisión, una lectura no entra en un promedio.
const _precisionUtil = 15.0;

/// Segundos quieto para marcar una puerta.
const _segundosPuerta = 10;

/// A esta distancia o menos, la entrada de la guía ya estaba bien.
const _entradaBien = 4.0;

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

  /// El tramo por el que la guía te está mandando ahora: el que lleva al
  /// próximo punto de la ruta, con sus extremos en el grafo (no el pedazo
  /// que recorre la ruta). Antes era el más cercano a la posición, y justo
  /// después de una esquina era el que quedaba atrás: «por aquí no se pasa»
  /// cerraba el camino ya recorrido.
  ({TramoCampus tramo, PuntoGeo desde, PuntoGeo hasta, double rumbo})?
  _tramoActual() {
    final seguimiento = _seguimiento;
    final ruta = seguimiento?.ruta;
    if (seguimiento == null || ruta == null || ruta.tramos.isEmpty) {
      return null;
    }
    final i = (seguimiento.objetivo - 1).clamp(0, ruta.tramos.length - 1);
    final tramo = ruta.tramos[i];
    final desde = widget.grafo.nodos[tramo.a],
        hasta = widget.grafo.nodos[tramo.b];
    if (desde == null || hasta == null) return null;
    return (
      tramo: tramo,
      desde: desde,
      hasta: hasta,
      // En el sentido de la ruta, para calibrar la brújula.
      rumbo: rumboGrados(ruta.puntos[i], ruta.puntos[i + 1]),
    );
  }

  /// Aplica [c] y lo dice abajo con «Deshacer». [resaltar] se ve en naranja
  /// en el plano mientras dura el aviso.
  void _hecho(
    Correccion c,
    String texto, {
    List<PuntoGeo> resaltar = const [],
  }) {
    _correcciones.agregar(c);
    if (!mounted) return;
    _refrescar(() => _resaltado = resaltar);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          margin: _sobreLaBarra(),
          // Con acción, Flutter lo deja fijo hasta tocarlo: tapaba la barra.
          persist: false,
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => _correcciones.anular(c.id),
          ),
        ),
      );
    Future<void>.delayed(const Duration(seconds: 6), () {
      if (mounted && _resaltado == resaltar) {
        _refrescar(() => _resaltado = const []);
      }
    });
  }

  void _avisarCampo(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          margin: _sobreLaBarra(),
        ),
      );
  }

  /// Los avisos flotan sobre la barra de campo: abajo tapaban «Corregir» y
  /// no se podía corregir otra cosa seguido.
  EdgeInsets _sobreLaBarra() => EdgeInsets.fromLTRB(
    16,
    0,
    16,
    MediaQuery.paddingOf(context).bottom + 12 + 76,
  );

  /// Promedia el GPS durante [_segundosPuerta] segundos, quieto. Pesa cada
  /// lectura por su precisión. Nulo si se canceló o no hubo señal útil.
  Future<({PuntoGeo punto, double precision})?> _medirAqui() async {
    final muestras = <LecturaPosicion>[];
    void oyente(LecturaPosicion l) {
      if (l.precision <= _precisionUtil) muestras.add(l);
    }

    _oyentesCampo.add(oyente);
    final completa = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _DialogoMedicion(segundos: _segundosPuerta, muestras: () => muestras),
    );
    _oyentesCampo.remove(oyente);
    if (completa != true) return null;
    if (muestras.length < 3) {
      _avisarCampo(
        'GPS débil (${muestras.length} lecturas buenas). Sal a cielo abierto '
        'y vuelve a intentarlo.',
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

  List<AccesoLugar> _entradasPorCercania(PuntoGeo punto) =>
      widget.grafo.accesosDe(widget.poi.id)..sort(
        (a, b) => distanciaMetros(
          a.punto,
          punto,
        ).compareTo(distanciaMetros(b.punto, punto)),
      );

  /// «Estoy en la puerta»: mide la puerta real y mueve allí la entrada más
  /// cercana del lugar. Si ya estaba bien, solo lo anota. Siempre queda la
  /// prueba (RF-29): dónde estaba la puerta y dónde dio la llegada la guía.
  Future<void> _estoyEnLaPuerta() async {
    final medida = await _medirAqui();
    if (medida == null || !mounted) return;
    final destino = _seguimiento?.ruta.destino;
    if (destino != null) {
      _correcciones.agregar(
        CorreccionPrueba(
          id: nuevoIdCorreccion(),
          fecha: DateTime.now(),
          autor: _autor,
          poiId: widget.poi.id,
          puerta: medida.punto,
          destino: destino.punto,
          llegadaApp: _llegadaApp,
        ),
      );
    }
    // Con dos entradas la ruta puede ir a la otra: se mueve la más cercana a
    // donde está la persona, no la de la ruta.
    final cercana = _entradasPorCercania(medida.punto).first;
    final error = distanciaMetros(cercana.punto, medida.punto);
    if (error <= _entradaBien) {
      _avisarCampo(
        'La entrada «${cercana.nombre}» estaba bien (a ${error.round()} m). '
        'Anotado.',
      );
      return;
    }
    _hecho(
      CorreccionEntrada(
        id: nuevoIdCorreccion(),
        fecha: DateTime.now(),
        autor: _autor,
        poiId: widget.poi.id,
        nombre: cercana.nombre,
        punto: medida.punto,
        precision: medida.precision,
      ),
      'Entrada «${cercana.nombre}» movida ${error.round()} m hasta aquí.',
    );
  }

  /// Una entrada más del lugar en este punto (la guía irá a la más cercana).
  Future<void> _otraEntrada() async {
    final medida = await _medirAqui();
    if (medida == null || !mounted) return;
    final numero = widget.grafo.accesosDe(widget.poi.id).length + 1;
    _hecho(
      CorreccionEntrada(
        id: nuevoIdCorreccion(),
        fecha: DateTime.now(),
        autor: _autor,
        poiId: widget.poi.id,
        nombre: '${widget.poi.nombre}, entrada $numero',
        punto: medida.punto,
        precision: medida.precision,
      ),
      'Entrada nueva de ${widget.poi.nombre} aquí.',
    );
  }

  void _corregirTramo({bool? escalones, bool? bloqueado}) {
    final actual = _tramoActual();
    if (actual == null) {
      _avisarCampo('Todavía no hay ruta ni posición: espera a que guíe.');
      return;
    }
    _hecho(
      CorreccionTramo(
        id: nuevoIdCorreccion(),
        fecha: DateTime.now(),
        autor: _autor,
        desde: actual.desde,
        hasta: actual.hasta,
        bloqueado: bloqueado,
        escalones: escalones,
      ),
      switch ((bloqueado, escalones)) {
        (true, _) =>
          'Tramo de ${actual.tramo.metros.round()} m cerrado. '
              'Busco otro camino.',
        (_, true) => 'Tramo con escalones. «Sin escaleras» lo evitará.',
        _ => 'Tramo sin escalones.',
      },
      resaltar: [actual.desde, actual.hasta],
    );
  }

  void _empezarGrabacion() {
    final aqui = _aqui;
    _refrescar(() => _trazo = [?aqui]);
  }

  void _cancelarGrabacion() => _refrescar(() => _trazo = null);

  void _terminarGrabacion() {
    final trazo = _trazo;
    if (trazo == null) return;
    _refrescar(() => _trazo = null);
    final puntos = simplificarTrazo(trazo, 2);
    var metros = 0.0;
    for (var i = 0; i < puntos.length - 1; i++) {
      metros += distanciaMetros(puntos[i], puntos[i + 1]);
    }
    if (puntos.length < 2 || metros < 8) {
      _avisarCampo('Camino de ${metros.round()} m: muy corto, no se guardó.');
      return;
    }
    // Sin escalones por defecto, que es lo común: si los tiene, «Aquí hay
    // escaleras» sobre ese tramo.
    _hecho(
      CorreccionCamino(
        id: nuevoIdCorreccion(),
        fecha: DateTime.now(),
        autor: _autor,
        puntos: puntos,
      ),
      'Camino nuevo de ${metros.round()} m. La guía ya lo usa.',
      resaltar: puntos,
    );
  }

  /// La flecha apunta mal: con la cámara hacia donde sigue el camino, la
  /// diferencia con el rumbo del tramo es el ajuste de la brújula.
  Future<void> _calibrarBrujula() async {
    final actual = _tramoActual();
    if (actual == null || _rumbo == null) {
      _avisarCampo('Hace falta estar guiando, con la brújula, para esto.');
      return;
    }
    _refrescar(() => _resaltado = [actual.desde, actual.hasta]);
    // Abajo y sin oscurecer: la línea naranja del plano tiene que verse.
    final listo = await showModalBottomSheet<bool>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Apunta hacia donde sigue el camino',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                'Sobre la línea naranja, con el teléfono vertical y la cámara '
                'mirando hacia donde hay que seguir. Lejos de rejas y carros.',
              ),
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
                    child: const Text('Listo'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) _refrescar(() => _resaltado = const []);
    final ahora = _rumbo;
    if (listo != true || ahora == null || !mounted) return;
    if (ahora.descalibrada) {
      final ut = ahora.intensidad?.round();
      _avisarCampo(
        'La brújula marca ${ut ?? '?'} µT y aquí lo normal es 33: hay metal '
        'cerca o falta calibrarla. Aléjate, dibuja un ocho con el teléfono y '
        'repite. Si sigue igual, en Corregir → Más pon el detector en «amplio».',
      );
      return;
    }
    final delta = diferenciaAngular(ahora.grados, actual.rumbo);
    final total = normalizarAjuste(
      ref.read(correccionesCampoProvider).ajusteBrujula + delta,
    );
    _hecho(
      CorreccionBrujula(
        id: nuevoIdCorreccion(),
        fecha: DateTime.now(),
        autor: _autor,
        grados: total,
      ),
      delta.abs() > 40
          ? 'Flecha girada ${delta.round()}°. Es mucho: si no apuntabas al '
                'camino, deshazlo.'
          : 'Flecha corregida ${delta.round()}°.',
    );
  }

  void _cambiarRadio(double metros) => _correcciones.agregar(
    CorreccionRadio(
      id: nuevoIdCorreccion(),
      fecha: DateTime.now(),
      autor: _autor,
      metros: metros,
    ),
  );

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
  }

  Future<void> _anotar() async {
    final control = TextEditingController();
    final texto = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Qué pasa aquí?'),
        content: TextField(
          controller: control,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
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
    _hecho(
      CorreccionNota(
        id: nuevoIdCorreccion(),
        fecha: DateTime.now(),
        autor: _autor,
        texto: texto,
        punto: _aqui,
        poiId: widget.poi.id,
      ),
      'Anotado aquí.',
    );
  }

  Future<void> _abrirCorrecciones() async {
    final accion = await showModalBottomSheet<VoidCallback>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _HojaCorrecciones(
        guiando: _seguimiento != null,
        alCambiarRadio: _cambiarRadio,
        alCambiarDetector: _cambiarDetector,
        acciones: (
          puerta: _estoyEnLaPuerta,
          otraEntrada: _otraEntrada,
          cerrado: () => _corregirTramo(bloqueado: true),
          camino: _empezarGrabacion,
          flecha: _calibrarBrujula,
          escaleras: () => _corregirTramo(escalones: true),
          sinEscaleras: () => _corregirTramo(escalones: false),
          nota: _anotar,
        ),
      ),
    );
    // La acción va después de cerrar la hoja: lo que muestra (el tramo en
    // naranja, la medida) tiene que verse sobre la guía. Se espera a que la
    // hoja termine de bajar; si no, subía el panel siguiente encima de ella.
    if (accion == null) return;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) accion();
  }
}

/// Las acciones de la hoja. Cada una se hace con la hoja ya cerrada.
typedef _AccionesCampo = ({
  VoidCallback puerta,
  VoidCallback otraEntrada,
  VoidCallback cerrado,
  VoidCallback camino,
  VoidCallback flecha,
  VoidCallback escaleras,
  VoidCallback sinEscaleras,
  VoidCallback nota,
});

String _nombreTolerancia(double? tolerancia) => switch (tolerancia) {
  null => 'apagado',
  final t =>
    '${t == toleranciaCampo ? 'estricto' : 'amplio'} (±${(t * 100).round()} %)',
};

/// Junta las lecturas del GPS con cuenta atrás.
class _DialogoMedicion extends StatefulWidget {
  const _DialogoMedicion({required this.segundos, required this.muestras});

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
      title: const Text('Quieto en la puerta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: 1 - _restante / widget.segundos,
            minHeight: 6,
          ),
          const SizedBox(height: 14),
          Text(
            '$_restante s · ${muestras.length} lecturas'
            '${mejor == null ? '' : ' · ±${mejor.round()} m'}',
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

/// Abajo de la guía: una línea de diagnóstico y un solo botón. Mientras se
/// graba un camino, en vez del botón, «Listo» y «Cancelar».
class _BarraCampo extends ConsumerWidget {
  const _BarraCampo({required this.guia});

  final _GuiaState guia;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final correcciones = ref.watch(correccionesCampoProvider);
    final ensayo = ref.watch(ensayoCampoProvider);
    final textos = Theme.of(context).textTheme;
    final posicion = guia._posicionCampo ?? guia._seguimiento?.ultima;
    final destino = guia._seguimiento?.ruta.destino;
    final brujula = guia._rumbo;
    final rumbo = rumboNavegacion(posicion, brujula);
    final intensidad = brujula?.intensidad;
    final fuente = rumbo != null
        ? (posicion?.rumbo != null && (posicion?.velocidad ?? 0) > 0.6)
              ? 'flecha por GPS'
              : 'flecha por brújula'
        : (brujula?.descalibrada ?? false)
        ? 'brújula con interferencia${intensidad == null ? '' : ' (${intensidad.round()} µT, normal 33)'}'
        : 'sin flecha';
    final trazo = guia._trazo;

    final String linea;
    if (trazo != null) {
      var metros = 0.0;
      for (var i = 0; i < trazo.length - 1; i++) {
        metros += distanciaMetros(trazo[i], trazo[i + 1]);
      }
      linea =
          'Grabando: ${metros.round()} m. Llega a otro camino y toca Listo.';
    } else if (guia._fase
        case _Fase.intro ||
            _Fase.pidiendo ||
            _Fase.fueraDelCampus ||
            _Fase.sinRuta) {
      linea = ensayo
          ? 'ENSAYO: la posición caminará sola por la ruta.'
          : 'Lejos del campus, ensaya con Corregir → Más → Ensayo.';
    } else if (guia._fase == _Fase.llegada) {
      linea =
          '¿No es la puerta? Camina hasta la real y toca Corregir → Estoy en '
          'la puerta.';
    } else {
      linea = [
        if (ensayo) 'ENSAYO',
        if (posicion != null) 'GPS ±${posicion.precision.round()} m',
        fuente,
        if (intensidad != null && !(brujula?.descalibrada ?? false))
          '${intensidad.round()} µT',
        if (posicion != null && destino != null)
          'puerta a ${distanciaMetros(posicion.punto, destino.punto).round()} m',
        if (correcciones.vigentes.length case final n when n > 0)
          n == 1 ? '1 corrección' : '$n correcciones',
      ].join(' · ');
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColoresUtb.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColoresUtb.naranja.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                linea,
                style: textos.labelMedium?.copyWith(color: ColoresUtb.naranja),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (trazo != null) ...[
              TextButton(
                onPressed: guia._cancelarGrabacion,
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: guia._terminarGrabacion,
                style: FilledButton.styleFrom(
                  backgroundColor: ColoresUtb.naranja,
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Listo'),
              ),
            ] else
              FilledButton.icon(
                onPressed: guia._abrirCorrecciones,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                icon: const Icon(Icons.build_rounded),
                label: const Text('Corregir'),
              ),
          ],
        ),
      ),
    );
  }
}

/// «¿Qué está mal?»: seis botones grandes en palabras de la calle y, plegado
/// en «Más», lo de configurar y compartir.
class _HojaCorrecciones extends ConsumerWidget {
  const _HojaCorrecciones({
    required this.guiando,
    required this.acciones,
    required this.alCambiarRadio,
    required this.alCambiarDetector,
  });

  final bool guiando;
  final _AccionesCampo acciones;
  final void Function(double) alCambiarRadio;
  final VoidCallback alCambiarDetector;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    // Cierra la hoja y entrega la acción a la guía.
    VoidCallback? cerrarY(VoidCallback accion, {bool exigeRuta = true}) =>
        exigeRuta && !guiando ? null : () => Navigator.pop(context, accion);

    final botones = [
      (
        Icons.door_front_door_rounded,
        'Estoy en la puerta',
        'Mueve la entrada aquí',
        cerrarY(acciones.puerta),
      ),
      (
        Icons.block_rounded,
        'Por aquí no se pasa',
        'Cerrado o no existe',
        cerrarY(acciones.cerrado),
      ),
      (
        Icons.alt_route_rounded,
        'Hay un camino mejor',
        'Grábalo caminándolo',
        cerrarY(acciones.camino, exigeRuta: false),
      ),
      (
        Icons.explore_rounded,
        'La flecha apunta mal',
        'Calibra la brújula',
        cerrarY(acciones.flecha),
      ),
      (
        Icons.stairs_rounded,
        'Aquí hay escaleras',
        'En el tramo actual',
        cerrarY(acciones.escaleras),
      ),
      (
        Icons.accessible_rounded,
        'Aquí no hay escaleras',
        'En el tramo actual',
        cerrarY(acciones.sinEscaleras),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('¿Qué está mal?', style: textos.headlineSmall),
          if (!guiando) ...[
            const SizedBox(height: 4),
            Text(
              'Casi todo se activa cuando la guía ya te está llevando.',
              style: textos.bodyMedium,
            ),
          ],
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              for (final (icono, titulo, detalle, accion) in botones)
                _BotonCampo(
                  icono: icono,
                  titulo: titulo,
                  detalle: detalle,
                  alTocar: accion,
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: cerrarY(acciones.nota, exigeRuta: false),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Otra cosa: anotarla'),
          ),
          const SizedBox(height: 4),
          _Mas(
            guiando: guiando,
            otraEntrada: cerrarY(acciones.otraEntrada),
            alCambiarRadio: alCambiarRadio,
            alCambiarDetector: alCambiarDetector,
          ),
        ],
      ),
    );
  }
}

class _BotonCampo extends StatelessWidget {
  const _BotonCampo({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.alTocar,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final activo = alTocar != null;
    return Material(
      color: ColoresUtb.superficieElevada,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: alTocar,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: activo ? 1 : 0.4,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icono, size: 30, color: ColoresUtb.naranja),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: textos.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      detalle,
                      style: textos.bodySmall?.copyWith(
                        color: ColoresUtb.textoSecundario,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Plegado: quién corrige, enviar y recibir, ensayo, ajustes finos y la
/// lista para deshacer.
class _Mas extends ConsumerStatefulWidget {
  const _Mas({
    required this.guiando,
    required this.otraEntrada,
    required this.alCambiarRadio,
    required this.alCambiarDetector,
  });

  final bool guiando;
  final VoidCallback? otraEntrada;
  final void Function(double) alCambiarRadio;
  final VoidCallback alCambiarDetector;

  @override
  ConsumerState<_Mas> createState() => _MasState();
}

class _MasState extends ConsumerState<_Mas> {
  late final _autor = TextEditingController(
    text: ref.read(correccionesCampoProvider.notifier).autor ?? '',
  );

  /// Dentro de la hoja: un SnackBar quedaba detrás de ella y no se veía.
  String? _mensaje;

  @override
  void dispose() {
    _autor.dispose();
    super.dispose();
  }

  void _avisar(String texto) => setState(() => _mensaje = texto);

  Future<void> _enviar() async {
    await Clipboard.setData(
      ClipboardData(text: ref.read(correccionesCampoProvider).exportar()),
    );
    _avisar(
      'Copiadas. Pégalas en el grupo; en los otros teléfonos, copia el '
      'mensaje y toca «Recibir».',
    );
  }

  Future<void> _recibir() async {
    final datos = await Clipboard.getData(Clipboard.kTextPlain);
    final otras = CorreccionesCampo.importar(datos?.text ?? '');
    if (otras == null) {
      _avisar('Copia primero el mensaje con las correcciones.');
      return;
    }
    final nuevas = ref.read(correccionesCampoProvider.notifier).importar(otras);
    _avisar(
      nuevas == 0 ? 'Ya las tenías todas.' : '$nuevas nuevas, ya aplicadas.',
    );
  }

  static String _resumen(Correccion c) => switch (c) {
    CorreccionEntrada(:final nombre) => 'Entrada «$nombre» movida',
    CorreccionTramo(:final bloqueado, :final escalones) =>
      bloqueado == true
          ? 'Tramo cerrado'
          : escalones == true
          ? 'Tramo con escalones'
          : 'Tramo sin escalones',
    CorreccionCamino(:final metros, :final escalones) =>
      'Camino nuevo de ${metros.round()} m${escalones ? ', con escalones' : ''}',
    CorreccionBrujula(:final grados) =>
      'Flecha: ajuste ${grados.toStringAsFixed(1)}°',
    CorreccionRadio(:final metros) => 'Radio de llegada: ${metros.round()} m',
    CorreccionMagnetico(:final tolerancia) =>
      'Detector de metal: ${_nombreTolerancia(tolerancia)}',
    CorreccionPrueba(:final errorEntrada, :final llegadaApp) =>
      'Prueba: puerta a ${errorEntrada.round()} m'
          '${llegadaApp == null ? ', sin llegada' : ''}',
    CorreccionNota(:final texto) => 'Nota: $texto',
  };

  @override
  Widget build(BuildContext context) {
    final correcciones = ref.watch(correccionesCampoProvider);
    final notifier = ref.read(correccionesCampoProvider.notifier);
    final ensayo = ref.watch(ensayoCampoProvider);
    final textos = Theme.of(context).textTheme;
    final radio = correcciones.radioLlegada ?? SeguimientoRuta.radioPorDefecto;
    final magnetico = correcciones.magnetico;
    final detector = magnetico == null ? toleranciaCampo : magnetico.tolerancia;
    final vigentes = correcciones.vigentes.reversed.toList();

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: Text(
        'Más: compartir, ajustes y deshacer',
        style: textos.titleSmall,
      ),
      children: [
        TextField(
          controller: _autor,
          decoration: const InputDecoration(labelText: 'Quién corrige'),
          onChanged: notifier.cambiarAutor,
        ),
        const SizedBox(height: 12),
        if (ensayo)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'En el ensayo las correcciones se aplican para practicar, pero '
              'no se guardan ni se envían.',
              style: textos.bodyMedium?.copyWith(color: ColoresUtb.naranja),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: correcciones.lista.isEmpty || ensayo
                    ? null
                    : _enviar,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Enviar'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: ensayo ? null : _recibir,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Recibir'),
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
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: ensayo,
          onChanged: (v) {
            ref.read(ensayoCampoProvider.notifier).state = v;
            Navigator.pop(context);
          },
          title: const Text('Ensayo lejos del campus'),
          subtitle: const Text(
            'La posición camina sola por la ruta; brújula y cámara son las '
            'reales. Lo que corrijas no se guarda. Se apaga al cerrar la app.',
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.add_location_alt_rounded),
          title: const Text('Otra entrada del lugar aquí'),
          subtitle: const Text('Una puerta que la guía no conocía.'),
          enabled: widget.otraEntrada != null,
          onTap: widget.otraEntrada,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.adjust_rounded),
          title: Text('Llega a ${radio.round()} m de la puerta'),
          subtitle: const Text('El plan dice 10 m.'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Menos',
                onPressed: radio <= 4
                    ? null
                    : () => widget.alCambiarRadio(radio - 2),
                icon: const Icon(Icons.remove_rounded),
              ),
              IconButton(
                tooltip: 'Más',
                onPressed: radio >= 30
                    ? null
                    : () => widget.alCambiarRadio(radio + 2),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.sensors_rounded),
          title: Text('Detector de metal: ${_nombreTolerancia(detector)}'),
          subtitle: const Text(
            'Si la flecha desaparece quieto con la brújula calibrada, '
            'prueba «amplio». Toca para cambiar.',
          ),
          onTap: widget.alCambiarDetector,
        ),
        const Divider(height: 20),
        Text('Hechas (${vigentes.length})', style: textos.titleSmall),
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
              onPressed: () => notifier.anular(c.id),
            ),
          ),
      ],
    );
  }
}

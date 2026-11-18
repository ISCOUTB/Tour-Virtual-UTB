import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/api/api_client.dart';
import '../../data/models/enums.dart';
import '../../data/models/escena.dart';
import '../../data/models/idiomas.dart';
import '../../data/models/medio.dart';
import '../../data/models/poi.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/reglas.dart';
import '../mapa/mapa_campus.dart';
import '../widgets/common.dart';
import '../widgets/imagen_red.dart';
import 'contenido_edicion.dart';
import 'poi_contenido.dart';
import 'poi_vista_previa.dart';

/// C.2 Crear / editar POI: formulario, ubicación en el mapa y vista previa
/// en la app móvil. La foto 360° y demás multimedia se suben en el área D.
class PoiFormScreen extends StatefulWidget {
  const PoiFormScreen({super.key, this.poiId});

  /// null = crear un POI nuevo.
  final int? poiId;

  @override
  State<PoiFormScreen> createState() => _PoiFormScreenState();
}

class _PoiFormScreenState extends State<PoiFormScreen> {
  static const List<String> _categoriasBase = AppColors.categoriasCampus;

  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  final _latitud = TextEditingController();
  final _longitud = TextEditingController();

  List<Poi> _todos = const [];
  List<Medio> _medios = const [];
  Escena? _escena;
  List<Escena> _escenas = const [];

  // Modo edición de «Contenido del lugar».
  bool _editandoContenido = false;
  bool _escenaBorrada = false;
  // Eliminaciones pendientes: se aplican recién al pulsar «Guardar cambios».
  final Set<int> _mediosPorEliminar = {};
  bool _escenaPorEliminar = false;

  bool get _hayEliminaciones =>
      _mediosPorEliminar.isNotEmpty || _escenaPorEliminar;

  /// Lo que quedará del lugar si se guarda ahora (sin lo marcado).
  ContenidoPoi get _contenidoFinal => ContenidoPoi(
    escena: _escenaPorEliminar ? null : _escena,
    medios: [
      for (final m in _medios)
        if (!_mediosPorEliminar.contains(m.id)) m,
    ],
  );

  Poi? _original;
  String? _categoria;
  String? _errorCategoria;
  bool _activo = false; // Propuesta de la guía: inactivo al crear.

  bool _cargando = true;
  bool _guardando = false;
  bool _modificado = false;
  String? _errorCarga;

  // La API actual solo guarda la posición del pin (mapX, mapY); lat/lng son
  // de solo lectura. En modo maqueta se pueden editar para ver el diseño.
  bool get _coordenadasEditables =>
      AppConfig.useMockData || AppConfig.backendCamposNuevos;

  bool get _esEdicion => widget.poiId != null;

  @override
  void initState() {
    super.initState();
    for (final c in [_nombre, _descripcion, _latitud, _longitud]) {
      c.addListener(_alCambiar);
    }
    _cargar();
  }

  @override
  void dispose() {
    for (final c in [_nombre, _descripcion, _latitud, _longitud]) {
      c.removeListener(_alCambiar);
      c.dispose();
    }
    super.dispose();
  }

  void _alCambiar() {
    if (_cargando) return;
    setState(() => _modificado = true);
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });
    try {
      final todos = await poiRepository.listar();
      Poi? original;
      if (_esEdicion) {
        for (final p in todos) {
          if (p.id == widget.poiId) original = p;
        }
        if (original == null) {
          throw Exception('No se encontró el POI ${widget.poiId}.');
        }
      }
      if (!mounted) return;
      _todos = todos;
      _original = original;
      if (original != null) {
        // El contenido es opcional: si falla, el formulario sigue funcionando.
        // Cada lectura va aparte: un POI inactivo no tiene detalle público,
        // pero su escena sí debe verse.
        try {
          _medios = (await poiRepository.detalle(original.id)).medios;
        } catch (_) {}
        try {
          _escenas = await escenaRepository.listar();
          _escena = escenaDePoi(original, _escenas);
        } catch (_) {}
      }
      if (!mounted) return;
      if (original != null) {
        _nombre.text = original.nombre;
        _descripcion.text = original.descripcion ?? '';
        _latitud.text = original.lat?.toStringAsFixed(7) ?? '';
        _longitud.text = original.lng?.toStringAsFixed(7) ?? '';
        _categoria = original.categoria;
        _activo = original.activo;
      }
      setState(() {
        _cargando = false;
        _modificado = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorCarga = '$e';
        _cargando = false;
      });
    }
  }

  List<String> get _categorias {
    final set = <String>{..._categoriasBase};
    for (final p in _todos) {
      final c = p.categoria;
      if (c != null && c.isNotEmpty) set.add(c);
    }
    return set.toList();
  }

  String? _validarNombre(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'El nombre es obligatorio';
    if (t.length < 3) return 'Mínimo 3 caracteres';
    if (t.length > 80) return 'Máximo 80 caracteres';
    return null;
  }

  String? _validarDescripcion(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'La descripción es obligatoria';
    return null;
  }

  String? _validarCoordenada(String? v, double min, double max) {
    if (!_coordenadasEditables) return null;
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Obligatorio';
    final n = double.tryParse(t.replaceAll(',', '.'));
    if (n == null) return 'Escribe un número decimal';
    if (n < min || n > max) return 'Debe estar entre $min y $max';
    return null;
  }

  Future<void> _cancelar() async {
    if (_modificado) {
      final salir = await confirmDialog(
        context,
        title: 'Hay cambios sin guardar',
        message: 'Si sales ahora, se perderán los cambios del formulario.',
        confirmLabel: 'Salir sin guardar',
        danger: true,
      );
      if (!salir || !mounted) return;
    }
    context.go('/pois');
  }

  Future<void> _guardar() async {
    final formularioValido = _formKey.currentState!.validate();
    if (_categoria == null) {
      setState(() => _errorCategoria = 'Selecciona una categoría');
    }
    if (!formularioValido || _categoria == null) return;

    final original = _original;
    if (original != null &&
        original.activo &&
        !_activo &&
        !puedeDesactivar(_todos, original)) {
      showToast(
        context,
        'No se puede desactivar el último POI activo.',
        error: true,
      );
      return;
    }

    if (_hayEliminaciones) {
      final n = _mediosPorEliminar.length;
      final partes = [
        if (n > 0) '$n ${n == 1 ? 'archivo' : 'archivos'}',
        if (_escenaPorEliminar) 'la escena 360°',
      ].join(' y ');
      final seguir = await confirmDialog(
        context,
        title: 'Se eliminará contenido',
        message:
            'Al guardar se borrarán definitivamente $partes. '
            'Esto no se puede deshacer.',
        confirmLabel: 'Guardar y eliminar',
        danger: true,
      );
      if (!seguir || !mounted) return;
    }

    setState(() => _guardando = true);
    try {
      final base =
          original ?? Poi(id: 0, lugarId: AppConfig.lugarId, nombre: '');
      final poi = base.copyWith(
        nombre: _nombre.text.trim(),
        categoria: _categoria,
        descripcion: _descripcion.text.trim(),
        lat: double.tryParse(_latitud.text.trim().replaceAll(',', '.')),
        lng: double.tryParse(_longitud.text.trim().replaceAll(',', '.')),
        activo: _activo,
      );
      if (original == null) {
        await poiRepository.crear(poi);
      } else {
        await poiRepository.actualizar(poi);
      }
      final errores = await _aplicarEliminaciones();
      if (!mounted) return;
      if (errores.isNotEmpty) {
        setState(() => _guardando = false);
        showToast(
          context,
          'El POI se guardó, pero no se pudo eliminar todo: ${errores.first}',
          error: true,
        );
        return;
      }
      showToast(context, 'Cambios guardados');
      context.go('/pois');
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      showToast(context, 'No se pudo guardar. $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const ScrollPage(
        child: Column(
          children: [
            SkeletonBox(height: 60),
            SizedBox(height: 16),
            SkeletonBox(height: 420),
          ],
        ),
      );
    }
    if (_errorCarga != null) {
      return ScrollPage(
        child: ErrorCard(message: _errorCarga!, onRetry: _cargar),
      );
    }

    final titulo = _esEdicion ? 'Editar POI' : 'Nuevo POI';
    return Column(
      children: [
        Expanded(
          child: ScrollPage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: _cancelar,
                      child: const Text('Gestión de POIs'),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _esEdicion && _original != null
                            ? 'Editar ${_original!.nombre}'
                            : 'Nuevo POI',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                PageHeader(
                  icon: Icons.edit_location_alt_outlined,
                  title: titulo,
                  subtitle: 'Completa los datos del punto de interés',
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final formulario = _tarjetaFormulario();
                    final lateral = Column(
                      children: [
                        _tarjetaMapa(),
                        if (_esEdicion) ...[
                          const SizedBox(height: 16),
                          _tarjetaContenido(),
                        ],
                        const SizedBox(height: 16),
                        _tarjetaVistaPrevia(),
                      ],
                    );
                    if (constraints.maxWidth >= 1100) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: formulario),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: lateral),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        formulario,
                        const SizedBox(height: 16),
                        lateral,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        SaveBar(
          children: [
            OutlinedButton(
              onPressed: _guardando ? null : _cancelar,
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar cambios'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tarjetaFormulario() {
    final largo = _descripcion.text.length;
    return AppCard(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del POI',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombre,
              validator: _validarNombre,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            DropdownMenu<String>(
              initialSelection: _categoria,
              expandedInsets: EdgeInsets.zero,
              label: const Text('Categoría'),
              errorText: _errorCategoria,
              dropdownMenuEntries: [
                for (final c in _categorias)
                  DropdownMenuEntry<String>(value: c, label: c),
              ],
              onSelected: (v) => setState(() {
                _categoria = v;
                _errorCategoria = null;
                _modificado = true;
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcion,
              validator: _validarDescripcion,
              maxLength: 500,
              minLines: 4,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: 'Descripción',
                alignLabelWithHint: true,
                counterText: '$largo / 500',
                counterStyle: TextStyle(
                  color: largo >= 500
                      ? AppColors.danger
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitud,
                    readOnly: !_coordenadasEditables,
                    validator: (v) => _validarCoordenada(v, -90, 90),
                    decoration: InputDecoration(
                      labelText: 'Latitud',
                      helperText: _coordenadasEditables ? null : 'Solo lectura',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _longitud,
                    readOnly: !_coordenadasEditables,
                    validator: (v) => _validarCoordenada(v, -180, 180),
                    decoration: InputDecoration(
                      labelText: 'Longitud',
                      helperText: _coordenadasEditables ? null : 'Solo lectura',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Switch(
                  value: _activo,
                  onChanged: (v) => setState(() {
                    _activo = v;
                    _modificado = true;
                  }),
                ),
                const SizedBox(width: 10),
                Text(
                  _activo ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    color: _activo
                        ? AppColors.success
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (double, double)? get _pinActual {
    final lat = double.tryParse(_latitud.text.trim().replaceAll(',', '.'));
    final lng = double.tryParse(_longitud.text.trim().replaceAll(',', '.'));
    if (lat == null || lng == null) return null;
    return (lat, lng);
  }

  Widget _tarjetaMapa() {
    final pin = _pinActual;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ubicación en el mapa',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _coordenadasEditables
                ? 'Haz clic o arrastra sobre el plano para colocar el pin. '
                      'Los demás lugares del campus aparecen como puntos.'
                : 'Posición actual del lugar. La API aún no permite editar '
                      'lat/lng (pendiente en el backend).',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          MapaCampus(
            pois: _todos.where((p) => p.id != widget.poiId).toList(),
            pinNuevo: pin,
            alColocar: _coordenadasEditables
                ? (lat, lng) {
                    _latitud.text = lat.toStringAsFixed(7);
                    _longitud.text = lng.toStringAsFixed(7);
                  }
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            pin == null
                ? 'Sin ubicación en el mapa: la app lista el lugar pero no lo '
                      'dibuja.'
                : 'Pin: ${pin.$1.toStringAsFixed(6)}, '
                      '${pin.$2.toStringAsFixed(6)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _duracion(int? seg) {
    if (seg == null) return '';
    final m = seg ~/ 60, s = seg % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _agregarNarracion() async {
    final usados = {
      for (final m in _medios)
        if (m.tipo == TipoMedio.audio) m.idioma ?? idiomaOriginal,
    };
    final disponibles = {
      for (final e in idiomasContenido.entries)
        if (e.key != 'csn' && !usados.contains(e.key)) e.key: e.value,
    };
    if (disponibles.isEmpty) {
      showToast(context, 'Ya hay una narración en cada idioma.');
      return;
    }
    var elegido = disponibles.keys.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Agregar narración'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Elige el idioma hablado. Cada narración lleva sus '
                  'subtítulos (.vtt) en el mismo idioma.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                SelectBox<String>(
                  width: 320,
                  value: elegido,
                  items: disponibles,
                  onChanged: (v) => setLocal(() => elegido = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    // La subida (audio + .vtt + idioma) se hace en Subir Multimedia.
    context.go('/multimedia?poi=${widget.poiId}');
  }

  /// Abre Subir Multimedia (donde ya se edita o reemplaza cada archivo) en la
  /// pestaña que corresponde: panorama, fotos, video o audio.
  Future<void> _irAMultimedia(String tipo) async {
    if (_modificado) {
      final seguir = await confirmDialog(
        context,
        title: 'Hay cambios sin guardar',
        message:
            'Si abres Subir Multimedia ahora, se perderán los cambios '
            'del formulario.',
        confirmLabel: 'Continuar',
      );
      if (!seguir || !mounted) return;
    }
    context.go('/multimedia?poi=${widget.poiId}&tipo=$tipo');
  }

  void _marcarMedio(Medio m) => setState(() {
    _mediosPorEliminar.add(m.id);
    _modificado = true;
  });

  void _deshacerMedio(Medio m) =>
      setState(() => _mediosPorEliminar.remove(m.id));

  void _marcarEscena() => setState(() {
    _escenaPorEliminar = true;
    _modificado = true;
  });

  void _deshacerEscena() => setState(() => _escenaPorEliminar = false);

  /// Borra de verdad lo marcado. Devuelve los errores (vacío si todo salió
  /// bien); lo que sí se borró sale de las listas y de las marcas.
  Future<List<String>> _aplicarEliminaciones() async {
    final errores = <String>[];
    for (final id in _mediosPorEliminar.toList()) {
      try {
        await medioRepository.eliminar(id);
        _medios = _medios.where((m) => m.id != id).toList();
        _mediosPorEliminar.remove(id);
      } catch (e) {
        errores.add(e is ApiException ? e.message : '$e');
      }
    }
    final escena = _escena;
    if (_escenaPorEliminar && escena != null) {
      try {
        await escenaRepository.eliminar(escena.id);
        _escenas = _escenas.where((x) => x.id != escena.id).toList();
        _escena = null;
        _escenaBorrada = true;
        _escenaPorEliminar = false;
      } catch (e) {
        errores.add(e is ApiException ? e.message : '$e');
      }
    }
    return errores;
  }

  Widget _contenidoEscena(Escena escena, String alt) {
    final sinPanoramica = escena.imagenUrl == null || escena.imagenUrl!.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${escena.nombre ?? 'Escena ${escena.id}'} · vista inicial '
          '${escena.vistaInicialYaw?.toStringAsFixed(0) ?? '—'}° / '
          '${escena.vistaInicialPitch?.toStringAsFixed(0) ?? '—'}°',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (escena.imagenUrlBaja != null || escena.imagenUrl != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: ImagenRed(
                url: (escena.imagenUrlBaja?.isNotEmpty ?? false)
                    ? escena.imagenUrlBaja
                    : escena.imagenUrl,
                alternativo: Container(
                  color: AppColors.border,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.threesixty,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            StatusBadge(
              sinPanoramica ? 'Sin panorámica cargada' : 'Panorámica cargada',
              color: sinPanoramica ? AppColors.warning : AppColors.success,
            ),
            StatusBadge(
              alt.isEmpty ? 'Falta texto alternativo' : 'Texto alternativo',
              color: alt.isEmpty ? AppColors.danger : AppColors.success,
            ),
          ],
        ),
        if (alt.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            alt,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _tarjetaContenido() {
    final escena = _escena;
    final audios = _medios.where((m) => m.tipo == TipoMedio.audio).toList();
    final alt = escena?.textoAlt?.trim() ?? '';
    final editando = _editandoContenido;
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        end: editando ? const Color(0xFF3D63E0) : AppColors.border,
      ),
      duration: const Duration(milliseconds: 250),
      builder: (context, color, hijo) =>
          AppCard(borderColor: color, child: hijo!),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Contenido del lugar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: editando
                      ? ElevatedButton.icon(
                          key: const ValueKey('listo'),
                          onPressed: () =>
                              setState(() => _editandoContenido = false),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Listo'),
                        )
                      : OutlinedButton.icon(
                          key: const ValueKey('editar'),
                          onPressed: () =>
                              setState(() => _editandoContenido = true),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Editar'),
                        ),
                ),
              ],
            ),
            AvisoModoEdicion(visible: editando),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Escena 360°',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                AccionesEdicion(
                  visible: editando && escena != null,
                  marcado: _escenaPorEliminar,
                  onDeshacer: _deshacerEscena,
                  onEditar: () => _irAMultimedia('panorama'),
                  onEliminar: _marcarEscena,
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (escena == null &&
                (_escenaBorrada || _original?.escenaPrincipalId == null))
              const Text(
                'Sin escena: el lugar se ve en el mapa y en «Más lugares», '
                'sin número, hasta que tenga su panorámica.',
                style: TextStyle(fontSize: 13),
              )
            else if (escena == null)
              const Text(
                'No se pudo leer la escena.',
                style: TextStyle(fontSize: 13),
              )
            else
              AnimatedOpacity(
                opacity: _escenaPorEliminar ? 0.5 : 1,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_escenaPorEliminar)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: StatusBadge(
                          'Se eliminará al guardar',
                          color: AppColors.danger,
                        ),
                      ),
                    _contenidoEscena(escena, alt),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Fotos y videos',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            _galeria(editando),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Narraciones por idioma',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _agregarNarracion,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (audios.isEmpty)
              const Text(
                'Sin narración todavía.',
                style: TextStyle(fontSize: 13),
              )
            else
              for (final m in audios)
                AnimatedOpacity(
                  opacity: _mediosPorEliminar.contains(m.id) ? 0.5 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.graphic_eq,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${nombreDeIdioma(m.idioma)}'
                            '${m.duracionSeg == null ? '' : ' · ${_duracion(m.duracionSeg)}'}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              decoration: _mediosPorEliminar.contains(m.id)
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (_mediosPorEliminar.contains(m.id))
                          const StatusBadge(
                            'Se eliminará al guardar',
                            color: AppColors.danger,
                          )
                        else
                          StatusBadge(
                            m.subtitulosUrl == null
                                ? 'Sin subtítulos'
                                : 'Con subtítulos',
                            color: m.subtitulosUrl == null
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                        AccionesEdicion(
                          visible: editando,
                          marcado: _mediosPorEliminar.contains(m.id),
                          onDeshacer: () => _deshacerMedio(m),
                          onEditar: () => _irAMultimedia('audio'),
                          onEliminar: () => _marcarMedio(m),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 10),
            const Text(
              'Una narración no se publica sin sus subtítulos (.vtt), ni una '
              'escena sin texto alternativo (WCAG 2.2 AA). Los archivos se '
              'suben en Subir Multimedia.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// Fotos y videos ya guardados del lugar. En modo edición cada miniatura
  /// muestra su lápiz y su papelera; lo marcado se oscurece hasta guardar.
  Widget _galeria(bool editando) {
    final contenido = ContenidoPoi(escena: _escena, medios: _medios);
    final items = [...contenido.fotos, ...contenido.videos];
    if (items.isEmpty) {
      return const Text(
        'Sin fotos ni videos todavía.',
        style: TextStyle(fontSize: 13),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in items)
          Tooltip(
            message: _mediosPorEliminar.contains(m.id)
                ? 'Se eliminará al guardar'
                : (m.textoAlt?.isNotEmpty ?? false)
                ? m.textoAlt!
                : (m.tipo == TipoMedio.video ? 'Video' : 'Foto'),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 96,
                height: 68,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (m.tipo == TipoMedio.video)
                      Container(
                        color: AppColors.border,
                        alignment: Alignment.center,
                        child: const Icon(Icons.play_circle_outline),
                      )
                    else
                      ImagenRed(
                        url: m.url,
                        alternativo: Container(
                          color: AppColors.border,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: _mediosPorEliminar.contains(m.id) ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            color: const Color(0xB3000000),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: AccionesEdicion(
                        compacto: true,
                        visible: editando,
                        marcado: _mediosPorEliminar.contains(m.id),
                        onDeshacer: () => _deshacerMedio(m),
                        onEditar: () => _irAMultimedia(
                          m.tipo == TipoMedio.video ? 'video' : 'fotos',
                        ),
                        onEliminar: () => _marcarMedio(m),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Posición del lugar en el recorrido: «Parada N de M», como en la app.
  (int?, int?) _parada() {
    final lista = _escenas.where((e) => e.poiId != null).toList()
      ..sort((a, b) => a.orden.compareTo(b.orden));
    if (lista.isEmpty) return (null, null);
    final actual = _escena;
    if (actual == null) return (null, lista.length);
    final i = lista.indexWhere((e) => e.id == actual.id);
    return (i < 0 ? null : i + 1, lista.length);
  }

  Widget _tarjetaVistaPrevia() {
    final (parada, total) = _parada();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vista previa en la app móvil',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Así se ve el lugar en el teléfono, con lo que está registrado '
            'y lo que escribes en el formulario.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Center(
            child: PoiVistaPreviaMovil(
              nombre: _nombre.text,
              descripcion: _descripcion.text,
              categoria: _categoria,
              contenido: _contenidoFinal,
              parada: parada,
              totalParadas: total,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: StatusBadge(
              _activo ? 'Activo' : 'Inactivo',
              color: _activo ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

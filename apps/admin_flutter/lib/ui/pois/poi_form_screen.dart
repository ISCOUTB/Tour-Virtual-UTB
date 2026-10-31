import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/enums.dart';
import '../../data/models/escena.dart';
import '../../data/models/idiomas.dart';
import '../../data/models/medio.dart';
import '../../data/models/poi.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/reglas.dart';
import '../mapa/mapa_campus.dart';
import '../widgets/common.dart';

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
        try {
          _medios = (await poiRepository.detalle(original.id)).medios;
          final id = original.escenaPrincipalId;
          if (id != null) {
            for (final e in await escenaRepository.listar()) {
              if (e.id == id) _escena = e;
            }
          }
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
      showToast(context, 'No se puede desactivar el último POI activo.',
          error: true);
      return;
    }

    setState(() => _guardando = true);
    try {
      final base = original ??
          Poi(id: 0, lugarId: AppConfig.lugarId, nombre: '');
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
      if (!mounted) return;
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
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textSecondary),
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
                      children: [formulario, const SizedBox(height: 16), lateral],
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
                      helperText:
                          _coordenadasEditables ? null : 'Solo lectura',
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
                      helperText:
                          _coordenadasEditables ? null : 'Solo lectura',
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
                    color:
                        _activo ? AppColors.success : AppColors.textSecondary,
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
                color: AppColors.textSecondary, fontSize: 13),
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
    showToast(
      context,
      'La carga del audio en ${nombreDeIdioma(elegido)} se activa al '
      'conectar el servicio de archivos.',
    );
  }

  Widget _tarjetaContenido() {
    final escena = _escena;
    final audios = _medios.where((m) => m.tipo == TipoMedio.audio).toList();
    final alt = escena?.textoAlt?.trim() ?? '';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contenido del lugar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text('Escena 360°',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          if (_original?.escenaPrincipalId == null)
            const Text(
              'Sin escena: el lugar se ve en el mapa y en «Más lugares», sin '
              'número, hasta que tenga su panorámica.',
              style: TextStyle(fontSize: 13),
            )
          else if (escena == null)
            const Text('No se pudo leer la escena.',
                style: TextStyle(fontSize: 13))
          else ...[
            Text(
              '${escena.nombre ?? 'Escena ${escena.id}'} · vista inicial '
              '${escena.vistaInicialYaw?.toStringAsFixed(0) ?? '—'}° / '
              '${escena.vistaInicialPitch?.toStringAsFixed(0) ?? '—'}°',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                StatusBadge(
                  escena.imagenUrl == null || escena.imagenUrl!.isEmpty
                      ? 'Sin panorámica cargada'
                      : 'Panorámica cargada',
                  color: escena.imagenUrl == null || escena.imagenUrl!.isEmpty
                      ? AppColors.warning
                      : AppColors.success,
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
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text('Narraciones por idioma',
                    style: TextStyle(color: AppColors.textSecondary)),
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
            const Text('Sin narración todavía.',
                style: TextStyle(fontSize: 13))
          else
            for (final m in audios)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.graphic_eq,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${nombreDeIdioma(m.idioma)}'
                        '${m.duracionSeg == null ? '' : ' · ${_duracion(m.duracionSeg)}'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusBadge(
                      m.subtitulosUrl == null
                          ? 'Sin subtítulos'
                          : 'Con subtítulos',
                      color: m.subtitulosUrl == null
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 10),
          const Text(
            'Una narración no se publica sin sus subtítulos (.vtt), ni una '
            'escena sin texto alternativo (WCAG 2.2 AA). El backend aún no '
            'guarda idioma, subtítulos ni texto alternativo.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaVistaPrevia() {
    final nombre = _nombre.text.trim();
    final descripcion = _descripcion.text.trim();
    final color = AppColors.categoria(_categoria);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vista previa en la app móvil',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Center(
            child: PhoneFrame(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    height: 150,
                    color: AppColors.primary.withValues(alpha: 0.25),
                    child: const Stack(
                      children: [
                        Center(child: Icon(Icons.threesixty, size: 44)),
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: StatusBadge('360°', color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre.isEmpty ? 'Nombre del POI' : nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (_categoria != null)
                          StatusBadge(_categoria!, color: color),
                        const SizedBox(height: 10),
                        Text(
                          descripcion.isEmpty
                              ? 'La descripción aparecerá aquí.'
                              : descripcion,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Icon(Icons.place_outlined,
                                size: 14, color: AppColors.textSecondary),
                            SizedBox(width: 4),
                            Text(
                              'Ver en el mapa',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        StatusBadge(
                          _activo ? 'Activo' : 'Inactivo',
                          color: _activo
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

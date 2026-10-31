import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/poi.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/reglas.dart';
import '../widgets/common.dart';
import 'delete_poi_dialog.dart';

enum _Orden { recientes, antiguos, nombre }

/// C.1 Lista de POIs: búsqueda, filtros, orden, paginación, activar/desactivar
/// y acceso a editar o eliminar.
class PoisListScreen extends StatefulWidget {
  const PoisListScreen({super.key, this.estadoInicial});

  /// 'activos' o 'inactivos' (viene de la tarjeta del Inicio).
  final String? estadoInicial;

  @override
  State<PoisListScreen> createState() => _PoisListScreenState();
}

class _PoisListScreenState extends State<PoisListScreen> {
  static const double _anchoMinimo = 1040;

  List<Poi> _pois = const [];
  Map<int, String> _miniaturas = const {};
  bool _cargando = true;
  String? _error;

  String _consulta = '';
  String _estado = 'todos';
  String _categoria = 'todas';
  _Orden _orden = _Orden.recientes;
  int _pagina = 0;
  int _porPagina = 5;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _estado = _estadoDesde(widget.estadoInicial);
    _cargar();
  }

  @override
  void didUpdateWidget(covariant PoisListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.estadoInicial != widget.estadoInicial) {
      setState(() {
        _estado = _estadoDesde(widget.estadoInicial);
        _pagina = 0;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  String _estadoDesde(String? valor) =>
      (valor == 'activos' || valor == 'inactivos') ? valor! : 'todos';

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final pois = await poiRepository.listar();
      final miniaturas = <int, String>{};
      try {
        final escenas = await escenaRepository.listar();
        for (final e in escenas) {
          final url = e.imagenUrlBaja ?? e.imagenUrl;
          if (url != null && url.isNotEmpty) miniaturas[e.id] = url;
        }
      } catch (_) {
        // Las miniaturas son opcionales: si fallan, se muestra un marcador.
      }
      if (!mounted) return;
      setState(() {
        _pois = pois;
        _miniaturas = miniaturas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _cargando = false;
      });
    }
  }

  void _alBuscar(String texto) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _consulta = texto;
        _pagina = 0;
      });
    });
  }

  void _limpiarFiltros() {
    setState(() {
      _consulta = '';
      _estado = 'todos';
      _categoria = 'todas';
      _pagina = 0;
    });
  }

  List<String> get _categorias {
    final set = <String>{};
    for (final p in _pois) {
      final c = p.categoria;
      if (c != null && c.isNotEmpty) set.add(c);
    }
    return set.toList()..sort();
  }

  List<Poi> get _filtrados {
    final q = _consulta.trim().toLowerCase();
    final lista = _pois.where((p) {
      if (_estado == 'activos' && !p.activo) return false;
      if (_estado == 'inactivos' && p.activo) return false;
      if (_categoria != 'todas' && p.categoria != _categoria) return false;
      if (q.isNotEmpty &&
          !(p.nombre.toLowerCase().contains(q) || '${p.id}'.contains(q))) {
        return false;
      }
      return true;
    }).toList();
    switch (_orden) {
      case _Orden.recientes:
        lista.sort((a, b) => b.id.compareTo(a.id));
      case _Orden.antiguos:
        lista.sort((a, b) => a.id.compareTo(b.id));
      case _Orden.nombre:
        lista.sort(
          (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
        );
    }
    return lista;
  }

  void _reemplazar(Poi nuevo) {
    setState(() {
      _pois = [for (final p in _pois) p.id == nuevo.id ? nuevo : p];
    });
  }

  Future<void> _cambiarEstado(Poi poi, bool activo) async {
    if (!activo && !puedeDesactivar(_pois, poi)) {
      showToast(context, 'No se puede desactivar el último POI activo.',
          error: true);
      return;
    }
    final anterior = poi;
    _reemplazar(poi.copyWith(activo: activo));
    try {
      await poiRepository.cambiarEstado(poi, activo);
      if (!mounted) return;
      showToast(context, 'Cambios guardados');
    } catch (e) {
      if (!mounted) return;
      _reemplazar(anterior);
      showToast(context, 'No se pudo cambiar el estado. $e', error: true);
    }
  }

  Future<void> _eliminar(Poi poi) async {
    if (poi.activo && !puedeDesactivar(_pois, poi)) {
      showToast(context, 'No se puede eliminar el último POI activo.',
          error: true);
      return;
    }
    final resultado = await showDeletePoiDialog(context, poi);
    if (!mounted || resultado == null) return;
    if (resultado == DeleteChoice.eliminado) {
      setState(() {
        _pois = _pois.where((p) => p.id != poi.id).toList();
      });
      showToast(context, 'POI eliminado');
    } else {
      await _cambiarEstado(poi, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activos = _pois.where((p) => p.activo).length;
    return ScrollPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            icon: Icons.location_on_outlined,
            title: 'Gestión de Puntos de Interés',
            subtitle: 'Administra los POIs del tour virtual',
            trailing: ElevatedButton.icon(
              onPressed: () => context.go('/pois/nuevo'),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo POI'),
            ),
          ),
          const SizedBox(height: 20),
          if (!_cargando && _error == null)
            Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge(
                'POIs Activos: $activos / Total: ${_pois.length}',
                color: AppColors.success,
              ),
            ),
          const SizedBox(height: 16),
          _barraHerramientas(),
          const SizedBox(height: 16),
          _contenido(),
        ],
      ),
    );
  }

  Widget _barraHerramientas() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 320,
          height: 46,
          child: TextField(
            onChanged: _alBuscar,
            decoration: const InputDecoration(
              hintText: 'Buscar por nombre o ID',
              prefixIcon: Icon(Icons.search),
              contentPadding: EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        SelectBox<String>(
          prefix: 'Estado',
          value: _estado,
          items: const {
            'todos': 'Todos',
            'activos': 'Activos',
            'inactivos': 'Inactivos',
          },
          onChanged: (v) => setState(() {
            _estado = v;
            _pagina = 0;
          }),
        ),
        SelectBox<String>(
          prefix: 'Categoría',
          value: _categorias.contains(_categoria) ? _categoria : 'todas',
          items: {
            'todas': 'Todas',
            for (final c in _categorias) c: c,
          },
          onChanged: (v) => setState(() {
            _categoria = v;
            _pagina = 0;
          }),
        ),
        SelectBox<_Orden>(
          prefix: 'Ordenar por',
          value: _orden,
          items: const {
            _Orden.recientes: 'Más recientes',
            _Orden.antiguos: 'Más antiguos',
            _Orden.nombre: 'Nombre (A-Z)',
          },
          onChanged: (v) => setState(() {
            _orden = v;
            _pagina = 0;
          }),
        ),
      ],
    );
  }

  Widget _contenido() {
    if (_cargando) {
      return Column(
        children: [
          for (var i = 0; i < 5; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: SkeletonBox(height: 64),
            ),
        ],
      );
    }
    if (_error != null) {
      return ErrorCard(message: _error!, onRetry: _cargar);
    }
    if (_pois.isEmpty) {
      return AppCard(
        child: EmptyState(
          message: 'Aún no hay POIs. Crea el primero',
          icon: Icons.location_off_outlined,
          actionLabel: 'Nuevo POI',
          onAction: () => context.go('/pois/nuevo'),
        ),
      );
    }
    final filtrados = _filtrados;
    if (filtrados.isEmpty) {
      return AppCard(
        child: EmptyState(
          message: 'No se encontraron POIs con esos filtros',
          icon: Icons.search_off,
          actionLabel: 'Limpiar filtros',
          onAction: _limpiarFiltros,
        ),
      );
    }

    final paginas = (filtrados.length / _porPagina).ceil();
    final pagina = _pagina >= paginas ? paginas - 1 : _pagina;
    final inicio = pagina * _porPagina;
    final fin = (inicio + _porPagina) > filtrados.length
        ? filtrados.length
        : inicio + _porPagina;
    final visibles = filtrados.sublist(inicio, fin);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final ancho = constraints.maxWidth < _anchoMinimo
                  ? _anchoMinimo
                  : constraints.maxWidth;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: ancho,
                  child: Column(
                    children: [
                      const _EncabezadoTabla(),
                      for (final poi in visibles)
                        _FilaPoi(
                          poi: poi,
                          miniatura: _miniaturas[poi.escenaPrincipalId],
                          onEditar: () => context.go('/pois/${poi.id}/editar'),
                          onEliminar: () => _eliminar(poi),
                          onEstado: (v) => _cambiarEstado(poi, v),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _pie(
              total: filtrados.length,
              inicio: inicio,
              fin: fin,
              paginas: paginas,
              pagina: pagina,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pie({
    required int total,
    required int inicio,
    required int fin,
    required int paginas,
    required int pagina,
  }) {
    // Ventana de hasta 5 números de página alrededor de la actual.
    var desde = pagina - 2;
    if (desde < 0) desde = 0;
    var hasta = desde + 5;
    if (hasta > paginas) {
      hasta = paginas;
      desde = hasta - 5 < 0 ? 0 : hasta - 5;
    }
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 8,
      spacing: 16,
      children: [
        Text(
          'Mostrando ${inicio + 1}-$fin de $total',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Anterior',
              onPressed:
                  pagina > 0 ? () => setState(() => _pagina = pagina - 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            for (var i = desde; i < hasta; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _pagina = i),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == pagina ? AppColors.primary : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${i + 1}'),
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Siguiente',
              onPressed: pagina < paginas - 1
                  ? () => setState(() => _pagina = pagina + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        SelectBox<int>(
          prefix: 'Por página',
          value: _porPagina,
          items: const {5: '5', 10: '10', 20: '20'},
          onChanged: (v) => setState(() {
            _porPagina = v;
            _pagina = 0;
          }),
        ),
      ],
    );
  }
}

class _EncabezadoTabla extends StatelessWidget {
  const _EncabezadoTabla();

  @override
  Widget build(BuildContext context) {
    const estilo = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 16),
          SizedBox(width: 56, child: Text('ID', style: estilo)),
          SizedBox(width: 128, child: Text('VISTA 360°', style: estilo)),
          Expanded(flex: 3, child: Text('NOMBRE', style: estilo)),
          Expanded(flex: 4, child: Text('DESCRIPCIÓN', style: estilo)),
          SizedBox(width: 160, child: Text('COORDENADAS', style: estilo)),
          SizedBox(width: 140, child: Text('ESTADO', style: estilo)),
          SizedBox(width: 100, child: Text('ACCIONES', style: estilo)),
          SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _FilaPoi extends StatelessWidget {
  const _FilaPoi({
    required this.poi,
    required this.miniatura,
    required this.onEditar,
    required this.onEliminar,
    required this.onEstado,
  });

  final Poi poi;
  final String? miniatura;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final ValueChanged<bool> onEstado;

  String get _coordenadas {
    if (poi.lat != null && poi.lng != null) {
      return '${poi.lat!.toStringAsFixed(4)}, ${poi.lng!.toStringAsFixed(4)}';
    }
    if (poi.mapX != null && poi.mapY != null) {
      return 'Mapa: ${poi.mapX!.toStringAsFixed(2)}, '
          '${poi.mapY!.toStringAsFixed(2)}';
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoria(poi.categoria);
    return InkWell(
      onTap: onEditar,
      hoverColor: AppColors.primary.withValues(alpha: 0.06),
      child: Container(
        height: 80,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Container(width: 4, color: color),
            const SizedBox(width: 12),
            SizedBox(width: 56, child: Text('${poi.id}')),
            SizedBox(
              width: 128,
              child: _Miniatura(
                url: miniatura,
                tiene360: poi.escenaPrincipalId != null,
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poi.nombre,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    if (poi.categoria != null)
                      StatusBadge(poi.categoria!, color: color),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  poi.descripcion ?? '—',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            SizedBox(
              width: 160,
              child: Text(
                _coordenadas,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            SizedBox(
              width: 140,
              child: Row(
                children: [
                  Switch(value: poi.activo, onChanged: onEstado),
                  const SizedBox(width: 6),
                  Text(
                    poi.activo ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      fontSize: 13,
                      color: poi.activo
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 100,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    onPressed: onEditar,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  ),
                  IconButton(
                    tooltip: 'Eliminar',
                    onPressed: onEliminar,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.url, required this.tiene360});

  final String? url;
  final bool tiene360;

  Widget _marcador() => Container(
        color: AppColors.border,
        alignment: Alignment.center,
        child: Icon(
          tiene360 ? Icons.threesixty : Icons.image_not_supported_outlined,
          color: AppColors.textSecondary,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final u = url;
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 104,
        height: 56,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (u != null && u.startsWith('http'))
                Image.network(
                  u,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => _marcador(),
                )
              else
                _marcador(),
              if (tiene360)
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '360°',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

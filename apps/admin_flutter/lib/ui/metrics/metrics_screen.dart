import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/repositories.dart';
import '../widgets/common.dart';

/// E.1 Panel de métricas.
///
/// Lee GET /api/admin/metricas, que resume la tabla `eventos` de Supabase
/// (migración 0003). Los visitantes son anónimos: «visitas» son sesiones
/// distintas, no personas.
class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  int _dias = 7;
  late Future<Metricas> _futuro;

  static const List<(String, String, IconData)> _kpis = [
    ('Aperturas del mapa', 'virtual_map_open', Icons.map_outlined),
    ('Escenas 360° vistas', 'scene_viewed', Icons.threesixty),
    ('Hotspots tocados', 'hotspot_tapped', Icons.touch_app_outlined),
    ('Medios reproducidos', 'poi_media_played', Icons.play_circle_outline),
    ('Recorridos completados', 'tour_completed', Icons.flag_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    final hoy = DateTime.now();
    _futuro = panelRepository.metricas(
      desde: hoy.subtract(Duration(days: _dias - 1)),
      hasta: hoy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            icon: Icons.bar_chart,
            title: 'Métricas y Analítica',
            subtitle: 'Conoce el uso y rendimiento del tour virtual',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: [
              for (final d in const [7, 30, 90])
                ChoiceChip(
                  label: Text('Últimos $d días'),
                  selected: _dias == d,
                  selectedColor: AppColors.primary,
                  onSelected: (_) => setState(() {
                    _dias = d;
                    _cargar();
                  }),
                ),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<Metricas>(
            future: _futuro,
            builder: (context, snap) {
              if (snap.hasError) {
                return ErrorCard(
                  message: 'No se pudieron cargar las métricas: ${snap.error}',
                  onRetry: () => setState(_cargar),
                );
              }
              if (!snap.hasData) return const SkeletonBox(height: 400);
              return _contenido(snap.data!);
            },
          ),
        ],
      ),
    );
  }

  Widget _contenido(Metricas m) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 16.0;
            final columnas = constraints.maxWidth >= 1100
                ? 6
                : constraints.maxWidth >= 700
                    ? 3
                    : 2;
            final ancho =
                (constraints.maxWidth - gap * (columnas - 1)) / columnas;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: ancho,
                  height: 130,
                  child: _Kpi('Visitas', m.visitas, Icons.people_outline,
                      'sesiones distintas'),
                ),
                for (final (titulo, evento, icono) in _kpis)
                  SizedBox(
                    width: ancho,
                    height: 130,
                    child: _Kpi(titulo, m.eventosDe(evento), icono, evento),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Visitas por día',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (m.eventos == 0)
                const EmptyState(message: 'Sin datos de uso en este rango')
              else
                _GraficaDias(m.porDia),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lugares más visitados',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (m.poisMasVistos.isEmpty)
                const EmptyState(message: 'Sin datos de uso en este rango')
              else
                for (final (i, p) in m.poisMasVistos.indexed)
                  _FilaPoi(i + 1, p, m.poisMasVistos.first.visitas),
            ],
          ),
        ),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.titulo, this.valor, this.icono, this.detalle);

  final String titulo;
  final int valor;
  final IconData icono;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$valor',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            detalle,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barras simples, sin dependencias: una por día, alto según visitas.
class _GraficaDias extends StatelessWidget {
  const _GraficaDias(this.dias);

  final List<VisitasDia> dias;

  @override
  Widget build(BuildContext context) {
    final max = dias.fold<int>(1, (m, d) => d.visitas > m ? d.visitas : m);
    final etiquetaCada = (dias.length / 10).ceil().clamp(1, 1000);
    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, d) in dias.indexed)
            Expanded(
              child: Tooltip(
                message:
                    '${d.dia.day}/${d.dia.month}: ${d.visitas} visitas, '
                    '${d.eventos} eventos',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 160 * d.visitas / max,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 16,
                        child: i % etiquetaCada == 0
                            ? Text(
                                '${d.dia.day}/${d.dia.month}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilaPoi extends StatelessWidget {
  const _FilaPoi(this.puesto, this.poi, this.maxVisitas);

  final int puesto;
  final PoiVisto poi;
  final int maxVisitas;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('$puesto',
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          SizedBox(
            width: 220,
            child: Text(poi.nombre, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: maxVisitas == 0 ? 0 : poi.visitas / maxVisitas,
                minHeight: 8,
                color: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              '${poi.visitas} visitas',
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

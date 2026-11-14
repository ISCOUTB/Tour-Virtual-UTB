import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/common.dart';

/// E.1 Panel de métricas.
///
/// Los indicadores son los que ya registra la app en la tabla `eventos` de
/// Supabase (migración 0003): virtual_map_open, scene_viewed, hotspot_tapped,
/// poi_media_played y tour_completed. La API actual no tiene ningún endpoint
/// que los lea, así que aquí no se muestra ninguna cifra: se evita inventarlas.
/// Cuando exista el endpoint, cada tarjeta recibirá su valor real.
class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  int _dias = 7;

  static const List<_Kpi> _kpis = [
    _Kpi('Aperturas del mapa', 'virtual_map_open', Icons.map_outlined),
    _Kpi('Escenas 360° vistas', 'scene_viewed', Icons.threesixty),
    _Kpi('Hotspots tocados', 'hotspot_tapped', Icons.touch_app_outlined),
    _Kpi('Medios reproducidos', 'poi_media_played',
        Icons.play_circle_outline),
    _Kpi('Recorridos completados', 'tour_completed', Icons.flag_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return ScrollPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            icon: Icons.bar_chart,
            title: 'Métricas y Analítica',
            subtitle: 'Conoce el uso y rendimiento del tour virtual',
            trailing: OutlinedButton.icon(
              onPressed: () => showToast(
                context,
                'La exportación se activa al conectar el servicio de analítica.',
              ),
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Exportar CSV'),
            ),
          ),
          const SizedBox(height: 20),
          const SampleDataBanner(
            'Sin datos: la app ya registra estos eventos en la base, pero la '
            'API todavía no tiene un endpoint para consultarlos. Los '
            'visitantes son anónimos (sesión sin identificar a la persona) y '
            'los eventos se conservan 12 meses.',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: [
              for (final d in const [7, 30])
                ChoiceChip(
                  label: Text('Últimos $d días'),
                  selected: _dias == d,
                  selectedColor: AppColors.primary,
                  onSelected: (_) => setState(() => _dias = d),
                ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 16.0;
              final columnas = constraints.maxWidth >= 1100
                  ? 5
                  : constraints.maxWidth >= 700
                      ? 3
                      : 2;
              final ancho =
                  (constraints.maxWidth - gap * (columnas - 1)) / columnas;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final k in _kpis)
                    SizedBox(width: ancho, height: 140, child: k),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visitas por día',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                EmptyState(message: 'Sin datos de uso todavía'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lugares más visitados',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                EmptyState(message: 'Sin datos de uso todavía'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.titulo, this.evento, this.icono);

  final String titulo;

  /// Nombre del evento en la tabla `eventos`.
  final String evento;
  final IconData icono;

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
          const Text(
            '—',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            evento,
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

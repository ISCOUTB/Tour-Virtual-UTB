import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/poi.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/reglas.dart';
import '../widgets/common.dart';

/// B.1 Resumen general. Todas las cifras salen de la lista de POIs.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Poi>> _future;

  @override
  void initState() {
    super.initState();
    _future = poiRepository.listar();
  }

  void _reload() {
    setState(() {
      _future = poiRepository.listar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScrollPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            icon: Icons.home_outlined,
            title: 'Inicio',
            subtitle: 'Resumen general del Tour Virtual UTB',
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<Poi>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const _DashboardSkeleton();
              }
              if (snapshot.hasError) {
                return ErrorCard(
                  message: '${snapshot.error}',
                  onRetry: _reload,
                );
              }
              return _DashboardContent(pois: snapshot.data ?? const []);
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 168)),
            SizedBox(width: 16),
            Expanded(child: SkeletonBox(height: 168)),
            SizedBox(width: 16),
            Expanded(child: SkeletonBox(height: 168)),
            SizedBox(width: 16),
            Expanded(child: SkeletonBox(height: 168)),
          ],
        ),
        SizedBox(height: 24),
        SkeletonBox(height: 220),
      ],
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.pois});

  final List<Poi> pois;

  String _faltante(Poi poi) {
    final partes = <String>[];
    if (poi.escenaPrincipalId == null) partes.add('Foto 360°');
    if (poi.descripcion == null || poi.descripcion!.trim().isEmpty) {
      partes.add('Descripción');
    }
    return partes.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final total = pois.length;
    final activos = pois.where((p) => p.activo).length;
    final porcentaje = total == 0 ? 0 : (activos * 100 / total).round();
    final con360 = pois.where((p) => p.escenaPrincipalId != null).length;
    final pendientes = pois.where((p) => !poiCompleto(p)).toList();

    final tarjetas = <Widget>[
      _MetricCard(
        icon: Icons.location_on_outlined,
        color: AppColors.primary,
        title: 'POIs activos',
        value: '$activos/$total',
        subtitle: '$porcentaje% activos',
        progress: total == 0 ? 0.0 : activos / total,
        onTap: () => context.go('/pois?estado=activos'),
      ),
      _MetricCard(
        icon: Icons.trending_up,
        color: AppColors.success,
        title: 'Visitas esta semana',
        value: '—',
        subtitle: 'Sin datos: falta el servicio de analítica',
        onTap: () => context.go('/metricas'),
      ),
      _MetricCard(
        icon: Icons.threesixty,
        color: AppColors.purple,
        title: 'Escenas 360° cargadas',
        value: '$con360',
        subtitle: 'de $total POIs',
        onTap: () => context.go('/pois'),
      ),
      _MetricCard(
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        title: 'Contenido pendiente',
        value: '${pendientes.length}',
        subtitle: 'POIs requieren atención',
        onTap: () => context.go('/pois'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 16.0;
            final columnas = constraints.maxWidth >= 1000 ? 4 : 2;
            final ancho = (constraints.maxWidth - gap * (columnas - 1)) / columnas;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final tarjeta in tarjetas)
                  SizedBox(width: ancho, height: 168, child: tarjeta),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final acciones = _QuickActionsCard();
            final actividad = const _ActivityCard();
            if (constraints.maxWidth >= 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: acciones),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: actividad),
                ],
              );
            }
            return Column(
              children: [acciones, const SizedBox(height: 16), actividad],
            );
          },
        ),
        const SizedBox(height: 24),
        _AttentionCard(pois: pendientes, faltante: _faltante),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.onTap,
    this.progress,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback onTap;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
                ],
              ),
              const Spacer(),
              Text(title, style: const TextStyle(color: AppColors.textSecondary)),
              Text(
                value,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              // Siempre se reserva el alto de la barra para que los títulos de
              // todas las tarjetas queden a la misma altura.
              if (progress == null)
                const SizedBox(height: 14)
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      color: color,
                    ),
                  ),
                ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Acciones rápidas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gestiona tu contenido de forma ágil',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.go('/pois/nuevo'),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo POI'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.go('/multimedia'),
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Subir multimedia'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.go('/metricas'),
            icon: const Icon(Icons.bar_chart),
            label: const Text('Ver métricas'),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem {
  const _ActivityItem(this.icon, this.texto, this.detalle, this.tiempo);

  final IconData icon;
  final String texto;
  final String detalle;
  final String tiempo;
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard();

  // La API actual no tiene registro de auditoría (la tabla `auditoria` existe
  // en Supabase pero ningún endpoint la expone). Hasta entonces no se muestra
  // actividad inventada.
  @override
  Widget build(BuildContext context) {
    const items = <_ActivityItem>[];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actividad reciente',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Últimos cambios en el sistema',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const EmptyState(
              message: 'Sin actividad: el registro de cambios aún no está disponible')
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.texto,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            item.detalle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item.tiempo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.pois, required this.faltante});

  final List<Poi> pois;
  final String Function(Poi) faltante;

  @override
  Widget build(BuildContext context) {
    final visibles = pois.take(5).toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'POIs que necesitan atención',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (pois.length > 5)
                TextButton(
                  onPressed: () => context.go('/pois'),
                  child: const Text('Ver todos'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (visibles.isEmpty)
            const EmptyState(
              message: 'Todo el contenido está completo',
              icon: Icons.check_circle_outline,
            )
          else
            for (final poi in visibles)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        poi.nombre,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        faltante(poi),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const StatusBadge('En preparación', color: AppColors.warning),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () => context.go('/multimedia?poi=${poi.id}'),
                      child: const Text('Completar'),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

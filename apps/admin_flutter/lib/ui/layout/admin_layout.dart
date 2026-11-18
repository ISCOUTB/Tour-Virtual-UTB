import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_state.dart';
import '../../core/theme/app_theme.dart';

class _NavItem {
  const _NavItem(this.label, this.icon, this.selectedIcon, this.path, this.prefix);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
  final String prefix;
}

const List<_NavItem> _items = [
  _NavItem('Inicio', Icons.home_outlined, Icons.home, '/inicio', '/inicio'),
  _NavItem('Gestión de POIs', Icons.location_on_outlined, Icons.location_on,
      '/pois', '/pois'),
  _NavItem('Subir Multimedia', Icons.cloud_upload_outlined, Icons.cloud_upload,
      '/multimedia', '/multimedia'),
  _NavItem('Métricas y Analítica', Icons.bar_chart_outlined, Icons.bar_chart,
      '/metricas', '/metricas'),
  _NavItem('Configuración', Icons.settings_outlined, Icons.settings,
      '/configuracion/cuenta', '/configuracion'),
];

/// Estructura común: barra superior fija + menú lateral persistente +
/// área de contenido (guía, sección 3.1). Bajo 1280 px el menú muestra
/// solo íconos.
class AdminLayout extends StatelessWidget {
  const AdminLayout({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final extended = MediaQuery.sizeOf(context).width >= 1280;
    return Scaffold(
      body: Column(
        children: [
          const _TopBar(),
          Expanded(
            child: Row(
              children: [
                _Sidebar(location: location, extended: extended),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.border,
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.background],
        ),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: ListenableBuilder(
        listenable: authState,
        builder: (context, _) {
          return Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_circle_outlined, size: 26),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Bienvenido, ${authState.nombre}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo_utb.png',
                    height: 30,
                    errorBuilder: (context, error, stack) => const Text(
                      'UTB',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const Text(
                    '  |  Tour Virtual',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: authState.cerrarSesion,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Cerrar sesión'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.location, required this.extended});

  final String location;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: extended ? 248 : 76,
      color: AppColors.background,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (final item in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _SidebarItem(
                item: item,
                selected: location.startsWith(item.prefix),
                extended: extended,
              ),
            ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.extended,
  });

  final _NavItem item;
  final bool selected;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.textSecondary;
    final content = Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.go(item.path),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: extended ? 14 : 0,
            vertical: 13,
          ),
          child: extended
              ? Row(
                  children: [
                    Icon(selected ? item.selectedIcon : item.icon,
                        color: color, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Icon(selected ? item.selectedIcon : item.icon,
                      color: color, size: 22),
                ),
        ),
      ),
    );
    return extended ? content : Tooltip(message: item.label, child: content);
  }
}

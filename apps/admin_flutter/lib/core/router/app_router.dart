import 'package:go_router/go_router.dart';

import '../../ui/auth/login_screen.dart';
import '../../ui/dashboard/dashboard_screen.dart';
import '../../ui/layout/admin_layout.dart';
import '../../ui/metrics/metrics_screen.dart';
import '../../ui/multimedia/multimedia_screen.dart';
import '../../ui/pois/poi_form_screen.dart';
import '../../ui/pois/pois_list_screen.dart';
import '../../ui/settings/settings_screens.dart';
import '../auth/auth_state.dart';

/// Rutas del panel (guía, sección 2). Todas, salvo /login, exigen sesión.
final GoRouter appRouter = GoRouter(
  initialLocation: '/inicio',
  refreshListenable: authState,
  redirect: (context, state) {
    final enLogin = state.uri.path == '/login';
    if (!authState.signedIn) return enLogin ? null : '/login';
    if (enLogin) return '/inicio';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          AdminLayout(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/inicio',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/pois',
          builder: (context, state) => PoisListScreen(
            estadoInicial: state.uri.queryParameters['estado'],
          ),
        ),
        GoRoute(
          path: '/pois/nuevo',
          builder: (context, state) => const PoiFormScreen(),
        ),
        GoRoute(
          path: '/pois/:id/editar',
          builder: (context, state) => PoiFormScreen(
            poiId: int.tryParse(state.pathParameters['id'] ?? ''),
          ),
        ),
        GoRoute(
          path: '/multimedia',
          builder: (context, state) => MultimediaScreen(
            poiIdInicial: int.tryParse(state.uri.queryParameters['poi'] ?? ''),
          ),
        ),
        GoRoute(
          path: '/metricas',
          builder: (context, state) => const MetricsScreen(),
        ),
        GoRoute(
          path: '/configuracion/cuenta',
          builder: (context, state) =>
              const ConfigShell(activa: 0, child: CuentaTab()),
        ),
        GoRoute(
          path: '/configuracion/administradores',
          builder: (context, state) =>
              const ConfigShell(activa: 1, child: AdministradoresTab()),
        ),
        // «Apariencia del tour» (AparienciaTab) queda fuera del panel: no
        // hay backend que la guarde ni la app la lee. Decisión del equipo
        // (15/11/2026). El código sigue en settings_screens.dart.
        GoRoute(
          path: '/configuracion/apariencia',
          redirect: (context, state) => '/configuracion/cuenta',
        ),
        GoRoute(
          path: '/configuracion/seguridad',
          builder: (context, state) =>
              const ConfigShell(activa: 2, child: SeguridadTab()),
        ),
      ],
    ),
  ],
);

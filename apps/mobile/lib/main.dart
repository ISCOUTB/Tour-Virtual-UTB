import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'datos/modelos/modelos.dart';
import 'datos/proveedores.dart';
import 'nucleo/configuracion.dart';
import 'nucleo/rutas.dart';
import 'ui/vista_async.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await inicializarSupabase();
  runApp(const ProviderScope(child: UtbVirtualApp()));
}

class UtbVirtualApp extends StatefulWidget {
  const UtbVirtualApp({super.key, this.enrutador});

  /// Permite inyectar un router propio en las pruebas.
  final GoRouter? enrutador;

  @override
  State<UtbVirtualApp> createState() => _UtbVirtualAppState();
}

class _UtbVirtualAppState extends State<UtbVirtualApp> {
  late final GoRouter _enrutador = widget.enrutador ?? crearEnrutador();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'UTB Tour Virtual',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFD8D9DB),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F2B55)),
      ),
      routerConfig: _enrutador,
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  void _onPoiTap(Poi poi) {
    context.push(
      Rutas.haciaRecorrido(poi.lugarId, escenaId: poi.escenaPrincipalId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _TopBar()
                .animate()
                .fadeIn(duration: 360.ms)
                .slideY(begin: -0.5, end: 0, duration: 420.ms),
            Expanded(
              child: AnimatedSwitcher(
                duration: 320.ms,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.03),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildBody(),
              ),
            ),
            _buildBottomNavigation(context)
                .animate()
                .fadeIn(duration: 420.ms)
                .slideY(begin: 0.3, end: 0, duration: 420.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        final pois = ref.watch(poisProvider(Configuracion.lugarPorDefecto));

        return Container(
          key: const ValueKey('explorar'),
          // El render trae su propio fondo claro que llega hasta los bordes,
          // asi que el gris del resto de la app dibujaria una costura alrededor
          // del mapa. Aqui la superficie es la ilustracion misma.
          color: Colors.white,
          child: VistaAsync<List<Poi>>(
            valor: pois,
            alReintentar: () =>
                ref.invalidate(poisProvider(Configuracion.lugarPorDefecto)),
            enDatos: (lista) => _MapaCampus(
              pois: lista,
              alTocarPoi: _onPoiTap,
            ).animate().fadeIn(duration: 420.ms),
          ),
        );
      case 1:
        return const _PagePlaceholder(
          key: ValueKey('recorrido'),
          assetPath: 'android/app/src/assets/recorrido.png',
          title: 'Recorrido inmersivo',
          message:
              'Siguiente etapa: vista 360 en primera persona con hotspots.',
        );
      default:
        return const _PagePlaceholder(
          key: ValueKey('perfil'),
          assetPath: 'android/app/src/assets/perfil.png',
          title: 'Perfil y progreso',
          message: 'Aqui mostraremos avance del tour y POI visitados.',
        );
    }
  }

  Widget _buildBottomNavigation(BuildContext context) {
    const selectedNavColor = Color(0xFF093AD8);
    const navItems = [
      _NavItem(
        label: 'Explorar',
        assetPath: 'android/app/src/assets/explorar.png',
      ),
      _NavItem(
        label: 'Recorrido',
        assetPath: 'android/app/src/assets/recorrido.png',
      ),
      _NavItem(label: 'Perfil', assetPath: 'android/app/src/assets/perfil.png'),
    ];

    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x22000000))),
      ),
      padding: EdgeInsets.only(bottom: max(8, safeBottom)),
      child: Row(
        children: List.generate(navItems.length, (index) {
          final item = navItems[index];
          final isSelected = index == _selectedIndex;

          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedIndex = index),
              child: SizedBox(
                height: 78,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: 260.ms,
                      curve: Curves.easeOut,
                      width: isSelected ? 52 : 0,
                      height: 3,
                      margin: const EdgeInsets.only(top: 2, bottom: 8),
                      decoration: BoxDecoration(
                        color: selectedNavColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Semantics(
                      label: item.label,
                      child: Opacity(
                        opacity: isSelected ? 1 : 0.95,
                        child: TweenAnimationBuilder<Color?>(
                          tween: ColorTween(
                            begin: const Color(0xFF1F2B55),
                            end: isSelected
                                ? selectedNavColor
                                : const Color(0xFF1F2B55),
                          ),
                          duration: 220.ms,
                          builder: (context, tintColor, child) {
                            return ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                tintColor ?? const Color(0xFF1F2B55),
                                BlendMode.srcIn,
                              ),
                              child: child,
                            );
                          },
                          child: Image.asset(
                            item.assetPath,
                            height: 48,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      color: const Color(0xFF1F2B55),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: Image.asset(
              'android/app/src/assets/back.png',
              width: 26,
              height: 26,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Image.asset(
                'android/app/src/assets/logo.png',
                height: 38,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PagePlaceholder extends StatelessWidget {
  final String assetPath;
  final String title;
  final String message;

  const _PagePlaceholder({
    super.key,
    required this.assetPath,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFD8D9DB),
      width: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child:
              Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(assetPath, width: 118, fit: BoxFit.contain),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  )
                  .animate()
                  .fadeIn(duration: 280.ms)
                  .slideY(begin: 0.04, end: 0, duration: 280.ms),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final String assetPath;

  const _NavItem({required this.label, required this.assetPath});
}

/// Mapa isometrico del campus con los marcadores de puntos de interes.
///
/// El render entregado por la universidad mide 4096x2304. El lienzo tiene que
/// respetar esa proporcion: mientras fue cuadrado, toda coordenada normalizada
/// caia desplazada en vertical.
class _MapaCampus extends StatefulWidget {
  const _MapaCampus({required this.pois, required this.alTocarPoi});

  final List<Poi> pois;
  final void Function(Poi) alTocarPoi;

  @override
  State<_MapaCampus> createState() => _MapaCampusState();
}

class _MapaCampusState extends State<_MapaCampus> {
  static const _rutaMapa = 'android/app/src/assets/mapa_campus.webp';
  static const double _relacion = 4096 / 2304;

  /// El lienzo se dibuja mas ancho que la ventana para que el zoom inicial
  /// muestre los edificios a un tamano legible, en vez del campus entero en
  /// miniatura. Es un mapa apaisado dentro de una pantalla vertical.
  static const double _amplitud = 1.9;

  final _controlador = TransformationController();
  bool _encuadrado = false;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  /// Centra la vista sobre los POI la primera vez que se conoce el tamano.
  ///
  /// El campus ocupa una franja diagonal y deja mucho margen vacio alrededor,
  /// asi que centrar en el conjunto de puntos encuadra mejor que centrar en la
  /// imagen.
  void _encuadrar(Size ventana, Size lienzo) {
    if (_encuadrado || ventana.isEmpty) return;
    _encuadrado = true;

    var focoX = 0.5;
    var focoY = 0.5;
    final ubicables = widget.pois.where((p) => p.tienePosicionEnMapa).toList();
    if (ubicables.isNotEmpty) {
      final xs = ubicables.map((p) => p.mapX!);
      final ys = ubicables.map((p) => p.mapY!);
      focoX = (xs.reduce(min) + xs.reduce(max)) / 2;
      focoY = (ys.reduce(min) + ys.reduce(max)) / 2;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controlador.value = Matrix4.identity()
        ..translateByDouble(
          ventana.width / 2 - focoX * lienzo.width,
          ventana.height / 2 - focoY * lienzo.height,
          0,
          1,
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = restricciones.maxWidth * _amplitud;
        final lienzo = Size(ancho, ancho / _relacion);
        _encuadrar(restricciones.biggest, lienzo);

        return InteractiveViewer(
          transformationController: _controlador,
          constrained: false,
          minScale: 0.4,
          maxScale: 2.6,
          boundaryMargin: EdgeInsets.symmetric(
            horizontal: restricciones.maxWidth,
            vertical: restricciones.maxHeight,
          ),
          child: SizedBox(
            width: lienzo.width,
            height: lienzo.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    _rutaMapa,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.medium,
                    // Decodificar los 4096 px completos costaria unos 38 MB de
                    // memoria. A 2560 sigue nitido hasta el zoom maximo y baja
                    // a unos 15 MB, que es lo que tolera la gama baja.
                    cacheWidth: 2560,
                  ),
                ),
                ..._marcadores(lienzo),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _marcadores(Size lienzo) {
    final ubicables = widget.pois.where((p) => p.tienePosicionEnMapa).toList();

    return [
      for (final (indice, poi) in ubicables.indexed)
        Positioned(
          // El pin ancla por su punta inferior, no por su centro.
          left: poi.mapX! * lienzo.width - 22,
          top: poi.mapY! * lienzo.height - 42,
          child: Semantics(
            button: true,
            label: poi.nombre,
            child: GestureDetector(
              onTap: () => widget.alTocarPoi(poi),
              child: _PoiMarker(index: indice),
            ),
          ),
        ),
    ];
  }
}

class _PoiMarker extends StatelessWidget {
  final int index;

  const _PoiMarker({required this.index});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 56,
      child:
          Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  IgnorePointer(
                    child:
                        Container(
                              width: 34,
                              height: 34,
                              margin: const EdgeInsets.only(top: 9),
                              decoration: const BoxDecoration(
                                color: Color(0x5539D353),
                                shape: BoxShape.circle,
                              ),
                            )
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .scale(
                              begin: const Offset(0.55, 0.55),
                              end: const Offset(1.6, 1.6),
                              duration: 1300.ms,
                              curve: Curves.easeOut,
                            )
                            .fadeOut(begin: 0.78, duration: 1300.ms),
                  ),
                  Icon(
                    Icons.location_on_rounded,
                    size: 36,
                    color: const Color(0xFF41DC4D),
                    shadows: const [
                      Shadow(color: Color(0xAA5FFF70), blurRadius: 12),
                    ],
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 13),
                    decoration: const BoxDecoration(
                      color: Color(0xFF17723A),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              )
              .animate(delay: (index * 120).ms)
              .fadeIn(duration: 280.ms)
              .scale(
                begin: const Offset(0.2, 0.2),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
                duration: 520.ms,
              ),
    );
  }
}

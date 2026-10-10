import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'datos/modelos/modelos.dart';
import 'datos/proveedores.dart';
import 'nucleo/configuracion.dart';
import 'nucleo/rutas.dart';
import 'ui/ficha_poi.dart';
import 'ui/pestana_recorrido.dart';
import 'ui/vista_async.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await inicializarBackend();
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

  void _onPoiTap(Poi poi, int totalPois) {
    abrirPoi(context, ref, poi: poi, totalPois: totalPois);
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
              alTocarPoi: (poi) => _onPoiTap(poi, lista.length),
            ).animate().fadeIn(duration: 420.ms),
          ),
        );
      case 1:
        return const PestanaRecorrido(key: ValueKey('recorrido'));
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

  static const double _escalaMaxima = 2.6;

  final _controlador = TransformationController();
  bool _encuadrado = false;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  /// Escala por debajo de la cual el lienzo deja de cubrir el visor.
  ///
  /// Por debajo de ella aparecen bandas vacias: no son margen de la
  /// ilustracion sino lienzo que se queda corto, y es lo que se veia arriba y
  /// abajo del campus en una pantalla vertical.
  ///
  /// Un lienzo degenerado daria NaN, y `minScale` en NaN tumba el visor. En
  /// ese caso se cae a 1.0, que no escala nada.
  static double _escalaDeCobertura(Size ventana, Size lienzo) {
    if (lienzo.width <= 0 || lienzo.height <= 0) return 1;
    final cobertura = max(
      ventana.width / lienzo.width,
      ventana.height / lienzo.height,
    );
    return cobertura.isFinite && cobertura > 0 ? cobertura : 1;
  }

  /// Encuadra la vista sobre los POI la primera vez que se conoce el tamano.
  ///
  /// El encuadre se calcula a partir de los puntos y no de la imagen. La
  /// ilustracion trae su propio margen claro alrededor del campus, asi que
  /// centrarla dejaba bandas vacias que se comian mas de un cuarto de una
  /// pantalla vertical. Ajustando a la caja de los POI el margen queda fuera
  /// solo, sea cual sea el asset que entregue la universidad.
  void _encuadrar(Size ventana, Size lienzo) {
    if (_encuadrado || ventana.isEmpty) return;
    _encuadrado = true;

    final ubicables = widget.pois.where((p) => p.tienePosicionEnMapa).toList();

    // Caja de los POI en coordenadas del lienzo, con holgura para que ninguno
    // quede pegado al borde ni bajo la barra inferior.
    var izq = 0.0, arr = 0.0;
    var der = lienzo.width, aba = lienzo.height;
    if (ubicables.isNotEmpty) {
      final xs = ubicables.map((p) => p.mapX! * lienzo.width);
      final ys = ubicables.map((p) => p.mapY! * lienzo.height);
      const holgura = 90.0;
      izq = xs.reduce(min) - holgura;
      der = xs.reduce(max) + holgura;
      arr = ys.reduce(min) - holgura;
      aba = ys.reduce(max) + holgura;
    }

    final anchoCaja = max(der - izq, 1.0);
    final altoCaja = max(aba - arr, 1.0);

    // Ajustar a la caja de los POI puede pedir menos zoom del que hace falta
    // para tapar el visor, y entonces el encuadre arranca con una banda vacia.
    // La cobertura manda sobre el ajuste.
    final escala = min(
      ventana.width / anchoCaja,
      ventana.height / altoCaja,
    ).clamp(_escalaDeCobertura(ventana, lienzo), _escalaMaxima);

    final centroX = (izq + der) / 2;
    final centroY = (arr + aba) / 2;

    // Centrar en la caja puede sacar la camara del lienzo cuando los POI
    // quedan contra un borde. Se empuja de vuelta adentro: InteractiveViewer
    // no corrige la matriz que se le asigna, solo los gestos posteriores.
    final anchoVisible = lienzo.width * escala;
    final altoVisible = lienzo.height * escala;
    final dx = (ventana.width / 2 - centroX * escala).clamp(
      ventana.width - anchoVisible,
      0.0,
    );
    final dy = (ventana.height / 2 - centroY * escala).clamp(
      ventana.height - altoVisible,
      0.0,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controlador.value = Matrix4.identity()
        ..translateByDouble(dx, dy, 0, 1)
        ..scaleByDouble(escala, escala, 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        // El lienzo tiene que cubrir la ventana por los dos lados. Calculado
        // solo desde el ancho, un mapa apaisado dentro de una pantalla vertical
        // queda mas bajo que el area disponible y flota entre dos bandas
        // vacias que ocupaban mas de un cuarto de la pantalla.
        final ancho = max(
          restricciones.maxWidth * _amplitud,
          restricciones.maxHeight * _relacion,
        );
        final lienzo = Size(ancho, ancho / _relacion);
        _encuadrar(restricciones.biggest, lienzo);

        return InteractiveViewer(
          transformationController: _controlador,
          constrained: false,
          // El tope de alejamiento es la cobertura: mas atras solo hay vacio.
          // El campus es apaisado y la pantalla vertical, asi que verlo entero
          // de una vez obligaria a dejar entrar ese vacio; se recorre
          // arrastrando.
          minScale: _escalaDeCobertura(restricciones.biggest, lienzo),
          maxScale: _escalaMaxima,
          // Sin margen el visor no puede salirse del lienzo, que es lo que
          // mantiene el margen de la ilustracion fuera de cuadro.
          boundaryMargin: EdgeInsets.zero,
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
          left: poi.mapX! * lienzo.width - _PoiMarker.ancho / 2,
          top: poi.mapY! * lienzo.height - _PoiMarker.alto + 8,
          child: Semantics(
            button: true,
            label: poi.nombre,
            child: GestureDetector(
              // Sin `opaque` el toque solo lo absorbe el glifo pintado y el
              // resto de la caja queda muerto: eran 36 dp reales frente a los
              // 48 que exige Material.
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.alTocarPoi(poi),
              child: _PoiMarker(index: indice),
            ),
          ),
        ),
    ];
  }
}

class _PoiMarker extends StatelessWidget {
  /// Caja tactil. Material exige 48 dp como minimo en ambos ejes.
  static const double ancho = 56;
  static const double alto = 64;

  /// El verde anterior daba 1,11:1 sobre el cesped del render: invisible justo
  /// encima de las zonas verdes del campus. Este teja mide 3,73:1 en el peor de
  /// los fondos del mapa, cumple el minimo de 3:1 para elementos graficos y
  /// pertenece a la paleta de la propia ilustracion.
  static const Color relleno = Color(0xFF8C2F12);

  final int index;

  const _PoiMarker({required this.index});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      height: alto,
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
                                color: Color(0x448C2F12),
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
                  // El reborde blanco separa el pin del fondo sea cual sea:
                  // techos claros, cesped o asfalto.
                  Icon(
                    Icons.location_on_rounded,
                    size: 42,
                    color: Colors.white,
                  ),
                  Icon(
                    Icons.location_on_rounded,
                    size: 36,
                    color: relleno,
                    shadows: const [
                      Shadow(color: Color(0x55000000), blurRadius: 6),
                    ],
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 13),
                    decoration: const BoxDecoration(
                      color: Colors.white,
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

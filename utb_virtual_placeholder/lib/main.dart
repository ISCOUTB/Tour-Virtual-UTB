import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

void main() {
  runApp(const UtbVirtualApp());
}

class UtbVirtualApp extends StatelessWidget {
  const UtbVirtualApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UTB Virtual',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFD8D9DB),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F2B55)),
      ),
      home: const HomeScreen(),
    );
  }
}

class CampusPoi {
  final String title;
  final String category;
  final Offset normalizedOffset;

  const CampusPoi({
    required this.title,
    required this.category,
    required this.normalizedOffset,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _mapViewportSize = 330;
  static const double _mapCanvasSize = 560;

  final TransformationController _mapController = TransformationController();
  int _selectedIndex = 0;
  Offset? _tapPulsePosition;
  late final List<CampusPoi> _pois;

  @override
  void initState() {
    super.initState();
    _pois = _buildRandomPois();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialOffset = -(_mapCanvasSize - _mapViewportSize) / 2;
      _mapController.value = Matrix4.identity()
        ..translate(initialOffset, initialOffset);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<CampusPoi> _buildRandomPois() {
    const titles = [
      'Zona de comidas',
      'Murales UTB',
      'Salones representativos',
      'Biblioteca',
      'Bienestar universitario',
    ];
    const categories = [
      'Servicios',
      'Cultura',
      'Academico',
      'Recursos',
      'Comunidad',
    ];

    final random = Random();
    final usedOffsets = <Offset>[];

    return List.generate(titles.length, (index) {
      final offset = _generatePoiOffset(random, usedOffsets);
      usedOffsets.add(offset);
      return CampusPoi(
        title: titles[index],
        category: categories[index],
        normalizedOffset: offset,
      );
    });
  }

  Offset _generatePoiOffset(Random random, List<Offset> usedOffsets) {
    for (var attempt = 0; attempt < 70; attempt++) {
      final candidate = Offset(
        0.18 + random.nextDouble() * 0.64,
        0.18 + random.nextDouble() * 0.64,
      );

      final isFarEnough = usedOffsets.every(
        (existing) => (existing - candidate).distance > 0.14,
      );

      if (isFarEnough) {
        return candidate;
      }
    }

    return Offset(
      0.22 + random.nextDouble() * 0.56,
      0.22 + random.nextDouble() * 0.56,
    );
  }

  void _onMapTap(Offset localPosition) {
    final normalized = Offset(
      (localPosition.dx / _mapCanvasSize).clamp(0.0, 1.0),
      (localPosition.dy / _mapCanvasSize).clamp(0.0, 1.0),
    );

    setState(() => _tapPulsePosition = normalized);

    Future.delayed(900.ms, () {
      if (!mounted || _tapPulsePosition != normalized) {
        return;
      }
      setState(() => _tapPulsePosition = null);
    });

    final approxLat = 10.99 + normalized.dy * 0.01;
    final approxLng = -74.79 + normalized.dx * 0.01;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: 1200.ms,
          content: Text(
            'Toque en mapa (mock): ${approxLat.toStringAsFixed(4)}, ${approxLng.toStringAsFixed(4)}',
          ),
        ),
      );
  }

  void _onPoiTap(CampusPoi poi) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                poi.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                poi.category,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF2F4A84),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Hotspot activo en el mapa placeholder. Aqui conectaremos la ficha completa con multimedia del recorrido inmersivo.',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Entendido'),
              ),
            ],
          ),
        );
      },
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
        return Container(
          key: const ValueKey('explorar'),
          color: const Color(0xFFD8D9DB),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: _buildInteractiveMap()
                  .animate()
                  .fadeIn(duration: 520.ms)
                  .scale(
                    begin: const Offset(0.96, 0.96),
                    end: const Offset(1, 1),
                    duration: 520.ms,
                    curve: Curves.easeOutBack,
                  ),
            ),
          ),
        );
      case 1:
        return const _PagePlaceholder(
          key: ValueKey('recorrido'),
          assetPath: 'android/app/src/assets/recorrido.png',
          title: 'Recorrido inmersivo',
          message: 'Siguiente etapa: vista 360 en primera persona con hotspots.',
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

  Widget _buildInteractiveMap() {
    return Container(
      width: _mapViewportSize,
      height: _mapViewportSize,
      decoration: BoxDecoration(
        color: const Color(0xFFECECEB),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: InteractiveViewer(
        transformationController: _mapController,
        minScale: 0.55,
        maxScale: 3.4,
        constrained: false,
        boundaryMargin: const EdgeInsets.all(260),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _onMapTap(details.localPosition),
          child: SizedBox(
            width: _mapCanvasSize,
            height: _mapCanvasSize,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CampusPlaceholderPainter(),
                  ),
                ),
                ..._buildPoiMarkers(),
                if (_tapPulsePosition != null)
                  Positioned(
                    left: _tapPulsePosition!.dx * _mapCanvasSize - 24,
                    top: _tapPulsePosition!.dy * _mapCanvasSize - 24,
                    child: const _TapPulse(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPoiMarkers() {
    return List.generate(_pois.length, (index) {
      final poi = _pois[index];

      return Positioned(
        left: poi.normalizedOffset.dx * _mapCanvasSize - 22,
        top: poi.normalizedOffset.dy * _mapCanvasSize - 42,
        child: GestureDetector(
          onTap: () => _onPoiTap(poi),
          child: _PoiMarker(index: index),
        ),
      );
    });
  }

  Widget _buildBottomNavigation(BuildContext context) {
    const selectedNavColor = Color(0xFF093AD8);
    const navItems = [
      _NavItem(label: 'Explorar', assetPath: 'android/app/src/assets/explorar.png'),
      _NavItem(label: 'Recorrido', assetPath: 'android/app/src/assets/recorrido.png'),
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
                            end: isSelected ? selectedNavColor : const Color(0xFF1F2B55),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(assetPath, width: 118, fit: BoxFit.contain),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
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

class _PoiMarker extends StatelessWidget {
  final int index;

  const _PoiMarker({required this.index});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 56,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          IgnorePointer(
            child: Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(top: 9),
              decoration: const BoxDecoration(
                color: Color(0x5539D353),
                shape: BoxShape.circle,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
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
              Shadow(
                color: Color(0xAA5FFF70),
                blurRadius: 12,
              ),
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

class _TapPulse extends StatelessWidget {
  const _TapPulse();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x88106AC0), width: 3),
        ),
      )
          .animate()
          .scale(
            begin: const Offset(0.2, 0.2),
            end: const Offset(1.4, 1.4),
            duration: 380.ms,
            curve: Curves.easeOut,
          )
          .fadeOut(duration: 380.ms),
    );
  }
}

class _CampusPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = const Color(0xFFF1F2EF);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final islandPath = Path()
      ..moveTo(size.width * 0.14, size.height * 0.24)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.05,
        size.width * 0.54,
        size.height * 0.10,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.16,
        size.width * 0.91,
        size.height * 0.34,
      )
      ..quadraticBezierTo(
        size.width * 0.95,
        size.height * 0.55,
        size.width * 0.85,
        size.height * 0.72,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.91,
        size.width * 0.50,
        size.height * 0.92,
      )
      ..quadraticBezierTo(
        size.width * 0.27,
        size.height * 0.90,
        size.width * 0.13,
        size.height * 0.71,
      )
      ..quadraticBezierTo(
        size.width * 0.04,
        size.height * 0.54,
        size.width * 0.14,
        size.height * 0.24,
      )
      ..close();

    final islandFill = Paint()..color = const Color(0xFFC8DDB8);
    canvas.drawPath(islandPath, islandFill);
    canvas.drawPath(
      islandPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xFF8BA37F),
    );

    final random = Random(11);
    for (var i = 0; i < 170; i++) {
      final x = size.width * random.nextDouble();
      final y = size.height * random.nextDouble();
      final point = Offset(x, y);

      if (!islandPath.contains(point)) {
        continue;
      }

      final radius = 1.6 + random.nextDouble() * 1.3;
      final treePaint = Paint()
        ..color = Color.lerp(
              const Color(0xFF4D7C47),
              const Color(0xFF739E6C),
              random.nextDouble(),
            ) ??
            const Color(0xFF5F8B58);
      canvas.drawCircle(point, radius, treePaint);
    }

    final roadMain = Path()
      ..moveTo(size.width * 0.20, size.height * 0.16)
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height * 0.31,
        size.width * 0.52,
        size.height * 0.42,
      )
      ..quadraticBezierTo(
        size.width * 0.65,
        size.height * 0.48,
        size.width * 0.74,
        size.height * 0.67,
      );

    final roadSecondary = Path()
      ..moveTo(size.width * 0.23, size.height * 0.60)
      ..quadraticBezierTo(
        size.width * 0.41,
        size.height * 0.53,
        size.width * 0.58,
        size.height * 0.62,
      )
      ..quadraticBezierTo(
        size.width * 0.69,
        size.height * 0.68,
        size.width * 0.82,
        size.height * 0.60,
      );

    final roadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.046
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF5A5A5F);

    final lanePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.013
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFD7D9DA);

    canvas.drawPath(roadMain, roadPaint);
    canvas.drawPath(roadSecondary, roadPaint);
    canvas.drawPath(roadMain, lanePaint);
    canvas.drawPath(roadSecondary, lanePaint);

    final fieldRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.61,
        size.height * 0.28,
        size.width * 0.19,
        size.height * 0.21,
      ),
      const Radius.circular(9),
    );
    canvas.drawRRect(fieldRect, Paint()..color = const Color(0xFFA9D18E));

    final fieldLinePaint = Paint()
      ..color = const Color(0x88FFFFFF)
      ..strokeWidth = 2;
    for (var i = 1; i < 6; i++) {
      final y = size.height * (0.28 + i * 0.035);
      canvas.drawLine(
        Offset(size.width * 0.62, y),
        Offset(size.width * 0.79, y),
        fieldLinePaint,
      );
    }

    _drawBuilding(
      canvas,
      size,
      leftFactor: 0.18,
      topFactor: 0.26,
      widthFactor: 0.14,
      heightFactor: 0.08,
      angle: -0.27,
      color: const Color(0xFFBC5843),
    );
    _drawBuilding(
      canvas,
      size,
      leftFactor: 0.28,
      topFactor: 0.52,
      widthFactor: 0.10,
      heightFactor: 0.07,
      angle: -0.12,
      color: const Color(0xFFBF6E4B),
    );
    _drawBuilding(
      canvas,
      size,
      leftFactor: 0.43,
      topFactor: 0.57,
      widthFactor: 0.12,
      heightFactor: 0.09,
      angle: -0.08,
      color: const Color(0xFFBE7B4E),
    );
    _drawBuilding(
      canvas,
      size,
      leftFactor: 0.44,
      topFactor: 0.36,
      widthFactor: 0.12,
      heightFactor: 0.10,
      angle: 0.08,
      color: const Color(0xFFD7D9D8),
    );
    _drawBuilding(
      canvas,
      size,
      leftFactor: 0.52,
      topFactor: 0.34,
      widthFactor: 0.09,
      heightFactor: 0.07,
      angle: 0.24,
      color: const Color(0xFF7EA2C8),
    );
    _drawBuilding(
      canvas,
      size,
      leftFactor: 0.57,
      topFactor: 0.52,
      widthFactor: 0.13,
      heightFactor: 0.10,
      angle: 0.16,
      color: const Color(0xFFDF9A50),
    );
  }

  void _drawBuilding(
    Canvas canvas,
    Size size, {
    required double leftFactor,
    required double topFactor,
    required double widthFactor,
    required double heightFactor,
    required double angle,
    required Color color,
  }) {
    final rect = Rect.fromLTWH(
      size.width * leftFactor,
      size.height * topFactor,
      size.width * widthFactor,
      size.height * heightFactor,
    );

    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(angle);

    final centeredRect = Rect.fromCenter(
      center: Offset.zero,
      width: rect.width,
      height: rect.height,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(centeredRect, const Radius.circular(4)),
      Paint()..color = color,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(centeredRect, const Radius.circular(4)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x55000000),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CampusPlaceholderPainter oldDelegate) => false;
}

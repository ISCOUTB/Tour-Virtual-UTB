import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'nucleo/rutas.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      context.go(Rutas.inicio);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D4AA7),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'android/app/src/assets/logo.png',
              height: 40,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              'Universidad Tecnológica de Bolívar',
              style: GoogleFonts.familjenGrotesk(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 32),
            _LoadingDots(controller: _controller),
          ],
        ),
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  final AnimationController controller;

  const _LoadingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (controller.value + delay) % 1.0;
            final scale = 0.5 + (value * 0.5);

            return Transform.scale(
              scale: scale,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

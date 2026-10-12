import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'datos/proveedores.dart';
import 'l10n/textos.dart';
import 'nucleo/configuracion.dart';
import 'nucleo/idiomas.dart';
import 'nucleo/movimiento.dart';
import 'nucleo/rutas.dart';
import 'nucleo/tema.dart';
import 'ui/comunes/fondos.dart';

/// Pantalla de arranque, la misma de la app UTB: marino profundo, luces
/// desenfocadas y el logo institucional.
///
/// Antes esperaba 4 s fijos sin cargar nada. Ahora pide los lugares en cuanto
/// aparece y sale cuando llegan, con un mínimo para que la revelación se lea
/// y un tope para no retener a nadie si la red no responde. Un toque la salta.
class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  static const _minimo = Duration(milliseconds: 1500);
  static const _tope = Duration(milliseconds: 3200);

  final _reloj = Stopwatch()..start();
  final _temporizadores = <Timer>[];
  var _salio = false;

  @override
  void initState() {
    super.initState();
    _temporizadores.add(Timer(_tope, _salir));
    ref.listenManual(poisProvider(Configuracion.lugarPorDefecto), (_, valor) {
      if (valor.isLoading) return;
      final resta = _minimo - _reloj.elapsed;
      if (resta <= Duration.zero) {
        _salir();
      } else {
        _temporizadores.add(Timer(resta, _salir));
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    for (final t in _temporizadores) {
      t.cancel();
    }
    super.dispose();
  }

  void _salir() {
    if (_salio || !mounted) return;
    _salio = true;
    context.go(Rutas.inicio);
  }

  @override
  Widget build(BuildContext context) {
    final animar = !sinMovimiento(context);
    final ancho = MediaQuery.sizeOf(context).width;

    Widget logo = Image.asset(
      'android/app/src/assets/logo_utb.png',
      width: (ancho * 0.66).clamp(200.0, 320.0),
      semanticLabel: 'Universidad Tecnológica de Bolívar',
      // El logo es material institucional y puede no estar en una copia
      // recién clonada; sin él, el nombre escrito ocupa su lugar.
      errorBuilder: (context, error, pila) => Text(
        'Universidad Tecnológica de Bolívar',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
    Widget nombre = Text(
      mayusculasDe(context, Textos.of(context).tourVirtual),
      style: estiloSobretitulo(
        color: Colors.white.withValues(alpha: 0.72),
      ).copyWith(fontSize: 13, letterSpacing: 4),
    );

    if (animar) {
      logo = logo
          .animate()
          .fadeIn(duration: 700.ms, curve: Movimiento.salida)
          .scale(
            begin: const Offset(0.94, 0.94),
            end: const Offset(1, 1),
            duration: 900.ms,
            curve: Movimiento.salidaFuerte,
          );
      nombre = nombre
          .animate(delay: 450.ms)
          .fadeIn(duration: 600.ms)
          .slideY(begin: 0.4, end: 0, curve: Movimiento.salida);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: ColoresUtb.arranqueBorde,
      ),
      child: Scaffold(
        backgroundColor: ColoresUtb.arranqueBorde,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _salir,
          child: FondoArranque(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [logo, const SizedBox(height: 26), nombre],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

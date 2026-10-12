import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'datos/preferencias.dart';
import 'datos/proveedores.dart';
import 'l10n/textos.dart';
import 'nucleo/rutas.dart';
import 'nucleo/tema.dart';

export 'ui/inicio/pantalla_tour.dart' show HomeScreen;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // De borde a borde, como la app UTB: la cabecera azul pasa por debajo de la
  // barra de estado.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await inicializarBackend();
  final preferencias = await cargarPreferencias();
  runApp(
    ProviderScope(
      overrides: [
        preferenciasInicialesProvider.overrideWithValue(preferencias),
      ],
      child: const UtbVirtualApp(),
    ),
  );
}

class UtbVirtualApp extends ConsumerStatefulWidget {
  const UtbVirtualApp({super.key, this.enrutador});

  /// Permite inyectar un router propio en las pruebas.
  final GoRouter? enrutador;

  @override
  ConsumerState<UtbVirtualApp> createState() => _UtbVirtualAppState();
}

class _UtbVirtualAppState extends ConsumerState<UtbVirtualApp>
    with WidgetsBindingObserver {
  late final GoRouter _enrutador = widget.enrutador ?? crearEnrutador();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Quien cambia el idioma del teléfono con el módulo abierto lo ve cambiar
  /// sin reiniciar, salvo que haya elegido otro dentro del módulo.
  @override
  void didChangeLocales(List<Locale>? locales) =>
      ref.invalidate(idiomasDelTelefonoProvider);

  @override
  Widget build(BuildContext context) {
    final preferencias = ref.watch(preferenciasProvider);
    // Un solo tema oscuro: es el de la app anfitriona, y el módulo no tiene
    // modo claro que ofrecer sin inventarlo. El alto contraste llega por dos
    // caminos: el ajuste del módulo elige `theme`, y «aumentar contraste» del
    // sistema hace que MaterialApp use `highContrastDarkTheme`.
    final tema = temaUtb(altoContraste: preferencias.altoContraste);
    final contraste = temaUtb(altoContraste: true);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => Textos.of(context).tituloApp,
      locale: ref.watch(idiomaProvider),
      supportedLocales: Textos.supportedLocales,
      localizationsDelegates: Textos.localizationsDelegates,
      theme: tema,
      darkTheme: tema,
      highContrastTheme: contraste,
      highContrastDarkTheme: contraste,
      themeMode: ThemeMode.dark,
      builder: (context, hijo) => MediaQuery(
        data: ajustarMediaQuery(MediaQuery.of(context), preferencias),
        child: hijo ?? const SizedBox.shrink(),
      ),
      routerConfig: _enrutador,
    );
  }
}

/// Suma los ajustes del módulo a los del sistema.
///
/// «Reducir movimiento» se vuelve `disableAnimations`, que es lo que consulta
/// `sinMovimiento()` en cada efecto: así un solo interruptor apaga todos. El
/// tamaño del texto se multiplica con el del sistema.
MediaQueryData ajustarMediaQuery(MediaQueryData base, Preferencias p) =>
    base.copyWith(
      textScaler: p.tamanoTexto == TamanoTexto.normal
          ? base.textScaler
          : EscalaConAumento(base.textScaler, p.tamanoTexto.factor),
      disableAnimations: base.disableAnimations || p.reducirMovimiento,
      highContrast: base.highContrast || p.altoContraste,
    );

/// Escala del sistema multiplicada por el aumento del módulo.
///
/// El total no pasa del 200 %, la escala que el módulo garantiza sin cortar
/// contenido. Si el sistema ya pide más, se respeta lo del sistema: el
/// aumento del módulo nunca reduce.
@immutable
class EscalaConAumento extends TextScaler {
  const EscalaConAumento(this.sistema, this.factor);

  final TextScaler sistema;
  final double factor;

  @override
  double scale(double fontSize) {
    final delSistema = sistema.scale(fontSize);
    return math.max(delSistema, math.min(delSistema * factor, fontSize * 2));
  }

  @override
  @Deprecated('Usar scale().')
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is EscalaConAumento &&
      other.sistema == sistema &&
      other.factor == factor;

  @override
  int get hashCode => Object.hash(sistema, factor);
}

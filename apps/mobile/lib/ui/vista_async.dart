import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../nucleo/errores.dart';

/// Presenta un [AsyncValue] cubriendo los tres estados.
///
/// Existe para que ninguna pantalla vuelva a mostrar un vacio silencioso cuando
/// falla la red: el error siempre se ve y, cuando tiene sentido, se puede
/// reintentar.
class VistaAsync<T> extends StatelessWidget {
  const VistaAsync({
    super.key,
    required this.valor,
    required this.enDatos,
    required this.alReintentar,
    this.enCarga,
    this.sobreFondoOscuro = false,
  });

  final AsyncValue<T> valor;
  final Widget Function(T datos) enDatos;
  final VoidCallback alReintentar;
  final Widget? enCarga;

  /// Ajusta el contraste cuando se dibuja sobre el visor 360, que es negro.
  final bool sobreFondoOscuro;

  @override
  Widget build(BuildContext context) {
    return valor.when(
      data: enDatos,
      loading: () => enCarga ?? _Cargando(sobreFondoOscuro: sobreFondoOscuro),
      error: (error, _) => _Error(
        fallo: traducirFallo(error),
        alReintentar: alReintentar,
        sobreFondoOscuro: sobreFondoOscuro,
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando({required this.sobreFondoOscuro});

  final bool sobreFondoOscuro;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: sobreFondoOscuro ? Colors.white : null,
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({
    required this.fallo,
    required this.alReintentar,
    required this.sobreFondoOscuro,
  });

  final FalloApp fallo;
  final VoidCallback alReintentar;
  final bool sobreFondoOscuro;

  @override
  Widget build(BuildContext context) {
    final colorTexto = sobreFondoOscuro ? Colors.white : null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              fallo is FalloSinContenido
                  ? Icons.inbox_outlined
                  : Icons.wifi_off_rounded,
              size: 44,
              color: colorTexto ?? Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 14),
            Text(
              fallo.mensaje,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: colorTexto),
            ),
            if (fallo.esReintentable) ...[
              const SizedBox(height: 18),
              FilledButton.tonalIcon(
                onPressed: alReintentar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

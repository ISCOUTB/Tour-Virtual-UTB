import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/textos.dart';
import '../nucleo/errores.dart';
import '../nucleo/tema.dart';

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
  });

  final AsyncValue<T> valor;
  final Widget Function(T datos) enDatos;
  final VoidCallback alReintentar;
  final Widget? enCarga;

  @override
  Widget build(BuildContext context) {
    return valor.when(
      data: enDatos,
      loading: () =>
          enCarga ??
          const Center(
            child: CircularProgressIndicator(color: ColoresUtb.azulClaro),
          ),
      error: (error, _) => Center(
        child: VistaError(
          fallo: traducirFallo(error),
          alReintentar: alReintentar,
        ),
      ),
    );
  }
}

/// Mensaje de fallo con salida.
class VistaError extends StatelessWidget {
  const VistaError({
    super.key,
    required this.fallo,
    required this.alReintentar,
  });

  final FalloApp fallo;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final txt = Textos.of(context);
    final sinContenido = fallo is FalloSinContenido;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MedidasUtb.margen,
        vertical: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: ColoresUtb.fondoInfo,
              shape: BoxShape.circle,
              border: Border.all(color: ColoresUtb.borde),
            ),
            child: Icon(
              sinContenido ? Icons.inbox_outlined : Icons.wifi_off_rounded,
              size: 28,
              color: ColoresUtb.azulInfo,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              fallo.mensaje(txt),
              textAlign: TextAlign.center,
              style: textos.bodyLarge,
            ),
          ),
          if (fallo.esReintentable) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: alReintentar,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(txt.reintentar),
            ),
          ],
        ],
      ),
    );
  }
}

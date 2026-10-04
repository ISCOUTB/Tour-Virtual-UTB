import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datos/modelos/modelos.dart';
import '../datos/progreso.dart';
import '../datos/proveedores.dart';
import '../nucleo/configuracion.dart';
import 'ficha_poi.dart';
import 'vista_async.dart';

/// Superficie del recorrido guiado (RF-19, RF-20, RF-21).
///
/// Antes esta pestaña era un marcador de posición mientras el único camino al
/// visor 360 era acertar a un punto sin rótulo en el mapa: la pestaña que
/// llevaba el nombre del producto le decía al usuario que eso aún no existía.
/// Ahora responde a las tres preguntas que el mapa no contesta —cuántos
/// lugares hay, cuáles son y cuáles ya vi— y ofrece un punto de partida.
class PestanaRecorrido extends ConsumerWidget {
  const PestanaRecorrido({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pois = ref.watch(poisProvider(Configuracion.lugarPorDefecto));

    return VistaAsync<List<Poi>>(
      valor: pois,
      alReintentar: () =>
          ref.invalidate(poisProvider(Configuracion.lugarPorDefecto)),
      enDatos: (lista) => _Lista(pois: lista),
    );
  }
}

class _Lista extends ConsumerWidget {
  const _Lista({required this.pois});

  final List<Poi> pois;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitados = ref.watch(progresoProvider);
    final tema = Theme.of(context);

    if (pois.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Todavía no hay lugares publicados en este recorrido.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final hechos = pois.where((p) => visitados.contains(p.id)).length;
    final completo = hechos == pois.length;
    final siguiente = pois.firstWhere(
      (p) => !visitados.contains(p.id),
      orElse: () => pois.first,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text(
          completo ? 'Recorrido completo' : 'Conoce el campus',
          style: tema.textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          '$hechos de ${pois.length} lugares',
          style: tema.textTheme.bodyMedium?.copyWith(
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: hechos / pois.length,
            minHeight: 8,
            backgroundColor: tema.colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 22),

        FilledButton.icon(
          onPressed: () {
            // «Volver a empezar» no reiniciaba nada: abría el primer lugar y
            // el recorrido seguía marcado como completo.
            if (completo) ref.read(progresoProvider.notifier).reiniciar();
            abrirPoi(context, ref, poi: siguiente, totalPois: pois.length);
          },
          icon: Icon(
            completo ? Icons.replay_rounded : Icons.play_arrow_rounded,
          ),
          label: Text(
            completo
                ? 'Volver a empezar'
                : hechos == 0
                ? 'Empezar recorrido'
                : 'Continuar recorrido',
          ),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),

        const SizedBox(height: 26),
        for (final poi in pois) ...[
          _Fila(
            poi: poi,
            visitado: visitados.contains(poi.id),
            alTocar: () =>
                abrirPoi(context, ref, poi: poi, totalPois: pois.length),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.poi,
    required this.visitado,
    required this.alTocar,
  });

  final Poi poi;
  final bool visitado;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Semantics(
      button: true,
      // El estado se anuncia en la etiqueta: un lector de pantalla no ve el
      // icono de visto.
      label: visitado ? '${poi.nombre}, ya visitado' : poi.nombre,
      child: Material(
        color: tema.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: alTocar,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  visitado ? Icons.check_circle_rounded : Icons.place_outlined,
                  color: visitado
                      ? tema.colorScheme.primary
                      : tema.colorScheme.outline,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(poi.nombre, style: tema.textTheme.titleMedium),
                      if (poi.categoria != null)
                        Text(
                          poi.categoria!,
                          style: tema.textTheme.bodySmall?.copyWith(
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: tema.colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

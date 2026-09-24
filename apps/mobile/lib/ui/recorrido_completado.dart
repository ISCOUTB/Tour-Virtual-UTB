import 'package:flutter/material.dart';

/// Cierre del recorrido (RF-20).
///
/// El KPI declarado es que el usuario complete los cinco POI, y hasta ahora la
/// aplicación no reconocía ese momento de ninguna forma: terminaba en lo último
/// que hubiera tocado el usuario, que con el contenido actual suele ser un
/// error de panorámica.
Future<void> mostrarRecorridoCompletado(BuildContext context) {
  final tema = Theme.of(context);

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // Sin esto la hoja queda limitada a una fraccion de la pantalla y el
    // contenido desborda en pantallas cortas o con el texto del sistema
    // ampliado, que es justo lo que WCAG obliga a soportar.
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        28,
        8,
        28,
        36 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.celebration_rounded,
            size: 56,
            color: tema.colorScheme.primary,
          ),
          const SizedBox(height: 18),
          Text(
            'Conociste todo el recorrido',
            style: tema.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Ya viste los lugares que hacen el día a día en la UTB. '
            'Cuando quieras, vuelve a cualquiera de ellos.',
            style: tema.textTheme.bodyLarge?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 26),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Seguir explorando'),
          ),
        ],
      ),
    ),
  );
}

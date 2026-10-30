import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/textos.dart';
import '../nucleo/movimiento.dart';
import '../nucleo/tema.dart';
import 'comunes/anillo_progreso.dart';

/// Cierre del recorrido (RF-20).
///
/// El KPI declarado es que el usuario complete los cinco POI, y hasta ahora la
/// aplicación no reconocía ese momento de ninguna forma. Aquí el anillo de
/// avance —el mismo de la cabecera— termina de llenarse en verde, como el
/// promedio aprobado en la app UTB.
Future<void> mostrarRecorridoCompletado(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    // Sin esto la hoja queda limitada a una fraccion de la pantalla y el
    // contenido desborda en pantallas cortas o con el texto del sistema
    // ampliado, que es justo lo que WCAG obliga a soportar.
    isScrollControlled: true,
    builder: (context) => const _Cierre(),
  );
}

class _Cierre extends StatelessWidget {
  const _Cierre();

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final txt = Textos.of(context);
    final animar = !sinMovimiento(context);

    Widget palomita = const Icon(
      Icons.check_rounded,
      size: 52,
      color: ColoresUtb.verde,
    );
    if (animar) {
      palomita = palomita
          .animate(delay: 650.ms)
          .scale(
            begin: const Offset(0.3, 0.3),
            end: const Offset(1, 1),
            duration: 420.ms,
            curve: Curves.easeOutBack,
          )
          .fadeIn(duration: 160.ms);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        28,
        8,
        28,
        32 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: txt.recorridoCompleto,
            excludeSemantics: true,
            child: AnilloProgreso(
              valor: 1,
              tamano: 128,
              grosor: 11,
              color: ColoresUtb.verde,
              child: palomita,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            txt.conocisteTodo,
            style: textos.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            txt.cierreTexto,
            style: textos.bodyLarge?.copyWith(
              color: PaletaUtb.de(context).textoSecundario,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
            child: Text(txt.seguirExplorando),
          ),
        ],
      ),
    );
  }
}

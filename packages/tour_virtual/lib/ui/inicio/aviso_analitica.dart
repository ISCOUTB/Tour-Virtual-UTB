import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/analitica.dart';
import '../../datos/preferencias.dart';
import '../../l10n/textos.dart';
import '../../nucleo/tema.dart';
import '../comunes/componentes.dart';

/// Pregunta una sola vez si se pueden enviar estadísticas de uso anónimas.
///
/// Va en la lista del recorrido, después de las paradas: la persona ya vio de
/// qué va el tour antes de que se le pida nada, y el aviso no tapa ninguna
/// parada. Aceptar y rechazar pesan lo mismo, y rechazar no tiene castigo:
/// el tour funciona igual. Hasta que contesta, ningún evento sale del
/// teléfono (ver `datos/analitica.dart`).
class AvisoAnalitica extends ConsumerWidget {
  const AvisoAnalitica({super.key});

  /// Si hay que mostrarlo: el módulo decide y la persona aún no contestó.
  static bool visible(WidgetRef ref) =>
      ref.watch(analiticaEnElModuloProvider) &&
      ref.watch(preferenciasProvider.select((p) => p.analitica)) == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txt = Textos.of(context);
    final textos = Theme.of(context).textTheme;
    final paleta = PaletaUtb.de(context);

    void contestar(bool acepta) {
      ref.read(preferenciasProvider.notifier).cambiarAnalitica(acepta);
      // El aviso desaparece y el foco del lector de pantalla se queda sin
      // sitio: se dice qué pasó y dónde cambiarlo (WCAG 4.1.3).
      SemanticsService.sendAnnouncement(
        View.of(context),
        txt.analiticaGuardada(txt.idiomaYAccesibilidad),
        Directionality.of(context),
      );
    }

    return TarjetaUtb(
      radio: 22,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChipEtiqueta(
            texto: txt.privacidad,
            icono: Icons.privacy_tip_outlined,
          ),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(txt.analiticaTitulo, style: textos.titleMedium),
          ),
          const SizedBox(height: 6),
          Text(
            txt.analiticaTexto(txt.idiomaYAccesibilidad),
            style: textos.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
          const SizedBox(height: 16),
          // Lado a lado si caben; uno sobre otro con letra grande o en
          // idiomas largos, sin cortar ninguno.
          OverflowBar(
            spacing: 10,
            overflowSpacing: 10,
            overflowAlignment: OverflowBarAlignment.end,
            alignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => contestar(false),
                child: Text(txt.analiticaRechazar),
              ),
              OutlinedButton(
                onPressed: () => contestar(true),
                child: Text(txt.analiticaAceptar),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

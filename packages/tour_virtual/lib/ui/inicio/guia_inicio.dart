import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../l10n/textos.dart';
import '../../nucleo/movimiento.dart';
import '../../nucleo/tema.dart';
import '../comunes/fondos.dart';
import '../comunes/ilustracion_max.dart';

/// Bienvenida de Max: sale la primera vez que se abre el módulo y desde los
/// ajustes, para volver a verla.
///
/// Corta a propósito. Tres ideas (360, mapa, audio en tu idioma) y dos
/// salidas: empezar ya por la primera parada, que es llegar cuanto antes a lo
/// que vale la pena, o cerrar y explorar. No bloquea nada: se cierra también
/// deslizando o tocando fuera.
///
/// Devuelve verdadero si se eligió empezar el recorrido.
Future<bool> mostrarGuiaInicio(BuildContext context) async {
  final empezar = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _GuiaInicio(),
  );
  return empezar ?? false;
}

class _GuiaInicio extends StatelessWidget {
  const _GuiaInicio();

  /// Alto del panel azul; Max mide más y asoma por encima.
  static const _altoPanel = 196.0;
  static const _altoMax = 252.0;

  @override
  Widget build(BuildContext context) {
    final txt = Textos.of(context);
    final textos = Theme.of(context).textTheme;
    final paleta = PaletaUtb.de(context);
    final abajo = MediaQuery.paddingOf(context).bottom;
    final animar = !sinMovimiento(context);

    Widget max = const IlustracionMax(
      pose: PoseMax.frente,
      alto: _altoMax,
      sombra: true,
    );
    if (animar) {
      max = max
          .animate()
          .fadeIn(duration: Movimiento.medio, curve: Movimiento.salida)
          .slideY(
            begin: 0.06,
            end: 0,
            duration: Movimiento.largo,
            curve: Movimiento.salidaFuerte,
          );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        MedidasUtb.margen,
        0,
        MedidasUtb.margen,
        24 + abajo,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _altoMax + 8,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _altoPanel,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(
                      Radius.circular(MedidasUtb.radioTarjeta),
                    ),
                    child: FondoCabeceraUtb(radioInferior: 0),
                  ),
                ),
                Positioned(bottom: 0, child: max),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Semantics(
            header: true,
            child: Text(txt.guiaTitulo, style: textos.headlineSmall),
          ),
          const SizedBox(height: 6),
          Text(
            txt.guiaTexto,
            style: textos.bodyLarge?.copyWith(color: paleta.textoSecundario),
          ),
          const SizedBox(height: 20),
          _Idea(icono: Icons.threesixty_rounded, texto: txt.guia360),
          _Idea(icono: Icons.map_outlined, texto: txt.guiaMapa),
          _Idea(icono: Icons.headphones_rounded, texto: txt.guiaAudio),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
            child: Text(txt.guiaEmpezar),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(txt.guiaExplorar),
          ),
        ],
      ),
    );
  }
}

class _Idea extends StatelessWidget {
  const _Idea({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: ColoresUtb.indicador,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 21, color: ColoresUtb.azulClaro),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(texto, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

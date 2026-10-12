import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../l10n/textos.dart';
import '../../nucleo/idiomas.dart';
import '../../nucleo/tema.dart';
import '../comunes/anillo_progreso.dart';
import '../comunes/componentes.dart';
import '../comunes/fondos.dart';

/// Lo que la cabecera cuenta del recorrido. Es un registro para que dos
/// resúmenes iguales se comparen iguales y la cabecera no se reconstruya sin
/// motivo al desplazar.
typedef ResumenTour = ({
  String sobretitulo,
  String titular,
  String? detalle,
  int hechos,
  int total,
});

/// Cabecera azul del módulo, con el colapso de Agenda y Notas.
///
/// Desplegada muestra el título grande arriba y, abajo, el estado del
/// recorrido con su anillo. Al desplazar se encoge hasta la barra compacta: el
/// título pasa de 34 a 22 sp en el mismo sitio y el anillo sube a la esquina,
/// de modo que el avance sigue a la vista también en el mapa.
///
/// Las alturas crecen con el texto del sistema: con letra al 200 % el bloque
/// inferior no cabía en los 276 dp de diseño y se cortaba (WCAG 1.4.4).
class CabeceraTour extends SliverPersistentHeaderDelegate {
  CabeceraTour({
    required this.arriba,
    required this.resumen,
    required this.alVolver,
    required this.alAjustes,
    this.escala = TextScaler.noScaling,
  });

  /// Alto de la barra de estado.
  final double arriba;

  /// Nulo mientras cargan los lugares.
  final ResumenTour? resumen;

  /// Nulo cuando el módulo es la raíz y no hay a dónde volver: una flecha que
  /// no hace nada fue uno de los defectos del diseño anterior.
  final VoidCallback? alVolver;

  /// Abre los ajustes de idioma y accesibilidad.
  final VoidCallback alAjustes;

  /// Escala del texto activa, para dimensionar la cabecera.
  final TextScaler escala;

  /// Alto de la barra compacta: cabe el título de 22 sp escalado.
  double get altoCompacto => math.max(64, escala.scale(22) + 22);

  /// Fila del título grande desplegado.
  double get _filaExpandida => math.max(64, escala.scale(34) + 12);

  /// Bloque inferior: sobretítulo, titular de dos líneas y detalle.
  static double _bloque(TextScaler e) =>
      e.scale(12.5) * 1.2 + 8 + e.scale(24) * 1.2 * 2 + 5 + e.scale(14.5) * 1.4;

  double get altoExpandido =>
      276 +
      (_bloque(escala) - _bloque(TextScaler.noScaling)) +
      (_filaExpandida - 64);

  @override
  double get minExtent => arriba + altoCompacto;

  @override
  double get maxExtent => arriba + altoExpandido;

  /// Desplazamiento que colapsa la cabecera por completo.
  double get rango => maxExtent - minExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final t = rango <= 0 ? 1.0 : (shrinkOffset / rango).clamp(0.0, 1.0);
    return _Cabecera(t: t, delegado: this);
  }

  @override
  bool shouldRebuild(CabeceraTour old) =>
      old.arriba != arriba ||
      old.resumen != resumen ||
      old.escala != escala ||
      (old.alVolver == null) != (alVolver == null);
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.t, required this.delegado});

  final double t;
  final CabeceraTour delegado;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final txt = Textos.of(context);
    final ancho = MediaQuery.sizeOf(context).width;
    final arriba = delegado.arriba;
    final alVolver = delegado.alVolver;

    // Los dos títulos se cruzan en una franja corta del colapso: con un
    // cruce largo se veían los dos a medias y el título parecía desdoblado.
    final cruce = Curves.easeInOut.transform(((t - 0.47) / 0.08).clamp(0, 1));
    // El bloque inferior se va pronto: a medio colapso quedaba translúcido
    // bajo el título y ensuciaba la cabecera.
    final bloque = (1 - t * 3.2).clamp(0.0, 1.0);
    final izquierda = alVolver == null ? MedidasUtb.margen : 60.0;
    final altoFila = lerpDouble(
      delegado._filaExpandida,
      delegado.altoCompacto,
      t,
    )!;

    final r = delegado.resumen;
    final anillo = (1 - (t - 0.55) / 0.25).clamp(0.0, 1.0);
    final pildora = ((t - 0.72) / 0.28).clamp(0.0, 1.0);
    final diametro = lerpDouble(76, 34, t)!;
    final centroAnillo = Offset(
      ancho - MedidasUtb.margen - diametro / 2,
      lerpDouble(
        arriba + delegado.altoExpandido - 62,
        arriba + delegado.altoCompacto / 2,
        t,
      )!,
    );
    // A la derecha de la barra van el botón de idioma y, plegada, la píldora
    // del avance; el título se queda con el resto.
    final derechaTitulo = lerpDouble(_BotonAjustes.ancho + 20, 176, t)!;

    return FondoCabeceraUtb(
      radioInferior: lerpDouble(
        MedidasUtb.radioCabecera,
        MedidasUtb.radioCabeceraCompacta,
        t,
      )!,
      // Ocupa todo el alto que da el sliver. Calcularlo aparte con lerp daba
      // una diferencia de 1e-14 con la geometría del sliver, y Flutter la
      // rechaza como pintura más corta que el espacio reservado.
      child: SizedBox.expand(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (alVolver != null)
              Positioned(
                left: 6,
                top: arriba + (delegado.altoCompacto - 48) / 2,
                child: IconButton(
                  onPressed: alVolver,
                  tooltip: txt.volver,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: ColoresUtb.texto,
                ),
              ),

            Positioned(
              left: izquierda,
              right: derechaTitulo,
              top: arriba,
              height: altoFila,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                // Un título traducido más largo, o la letra al 200 %, se
                // encoge para caber en vez de cortarse.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Stack(
                    children: [
                      Opacity(
                        opacity: 1 - cruce,
                        child: Transform.scale(
                          scale: lerpDouble(1, 22 / 34, t)!,
                          alignment: AlignmentDirectional.centerStart,
                          child: Semantics(
                            header: true,
                            child: Text(
                              txt.tourVirtual,
                              // Mismo interlineado en ambos: así las cajas
                              // escaladas coinciden y solo cambia el peso.
                              style: textos.displaySmall?.copyWith(height: 1),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: cruce,
                        child: Transform.scale(
                          scale: lerpDouble(34 / 22, 1, t)!,
                          alignment: AlignmentDirectional.centerStart,
                          child: ExcludeSemantics(
                            child: Text(
                              txt.tourVirtual,
                              style: textos.headlineSmall?.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                                height: 1,
                                letterSpacing: -0.4 * 22 / 34,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              right: 10,
              top: arriba + (delegado.altoCompacto - MedidasUtb.toque) / 2,
              child: _BotonAjustes(alTocar: delegado.alAjustes),
            ),

            if (bloque > 0)
              Positioned(
                left: MedidasUtb.margen,
                right: MedidasUtb.margen + 76 + 16,
                bottom: 26,
                child: Opacity(
                  opacity: bloque,
                  child: Transform.translate(
                    offset: Offset(0, -t * 28),
                    child: r == null ? const _BloqueCargando() : _Bloque(r),
                  ),
                ),
              ),

            // El anillo sube hacia la esquina mientras se encoge y, ya en la
            // barra compacta, cede el sitio a una píldora con la cifra: un
            // anillo parcial sin número, a ese tamaño, se leía como un
            // indicador de carga.
            if (r != null && r.total > 0 && anillo > 0)
              Positioned(
                left: centroAnillo.dx - diametro / 2,
                top: centroAnillo.dy - diametro / 2,
                width: diametro,
                height: diametro,
                child: Opacity(
                  opacity: anillo,
                  child: Semantics(
                    label: txt.lugaresVisitados(r.hechos, r.total),
                    excludeSemantics: true,
                    // La cifra es parte de un gráfico de 76 dp: crece hasta
                    // donde cabe en el anillo, y el lector de pantalla la
                    // recibe entera por la etiqueta.
                    child: MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.3,
                      child: AnilloProgreso(
                        valor: r.hechos / r.total,
                        tamano: diametro,
                        grosor: lerpDouble(7, 3.5, t)!,
                        color: ColoresUtb.texto,
                        colorPista: Colors.white.withValues(alpha: 0.2),
                        child: Opacity(
                          opacity: (1 - t * 2.2).clamp(0.0, 1.0),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: '${r.hechos}'),
                                TextSpan(
                                  text: '/${r.total}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                            style: textos.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            if (r != null && r.total > 0 && pildora > 0)
              Positioned(
                right: _BotonAjustes.ancho + 18,
                top: arriba,
                height: delegado.altoCompacto,
                child: Opacity(
                  opacity: pildora,
                  child: Center(child: _PildoraAvance(r)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Idioma y accesibilidad: un globo con el código del idioma activo.
///
/// Es lo primero que busca quien no lee español, así que no depende de
/// leer: el globo y «ES» se reconocen en cualquier idioma.
class _BotonAjustes extends StatelessWidget {
  const _BotonAjustes({required this.alTocar});

  static const ancho = 76.0;

  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final txt = Textos.of(context);
    final idioma = Localizations.localeOf(context);
    final contraste = PaletaUtb.de(context).altoContraste;

    return Tooltip(
      message: txt.idiomaYAccesibilidad,
      child: Semantics(
        button: true,
        label:
            '${txt.idiomaYAccesibilidad}, '
            '${nombreDeIdioma(idioma.toLanguageTag())}',
        onTap: alTocar,
        excludeSemantics: true,
        child: InkWell(
          onTap: alTocar,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            width: ancho,
            height: MedidasUtb.toque,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: contraste ? 0.26 : 0.16,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: contraste ? 0.8 : 0.22,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(9, 6, 11, 6),
                  child: MediaQuery.withNoTextScaling(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.language_rounded,
                          size: 18,
                          color: ColoresUtb.texto,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          idioma.languageCode.toUpperCase(),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PildoraAvance extends StatelessWidget {
  const _PildoraAvance(this.r);

  final ResumenTour r;

  @override
  Widget build(BuildContext context) {
    final completo = r.hechos == r.total;
    return Semantics(
      label: Textos.of(context).lugaresVisitados(r.hechos, r.total),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 5, 11, 5),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  completo ? Icons.verified_rounded : Icons.place_rounded,
                  size: 15,
                  color: ColoresUtb.texto,
                ),
                const SizedBox(width: 5),
                Text(
                  '${r.hechos}/${r.total}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bloque extends StatelessWidget {
  const _Bloque(this.r);

  final ResumenTour r;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final paleta = PaletaUtb.de(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          mayusculasDe(context, r.sobretitulo),
          style: estiloSobretitulo(
            color: paleta.altoContraste
                ? ColoresUtb.texto
                : Colors.white.withValues(alpha: 0.86),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          r.titular,
          style: textos.headlineSmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (r.detalle != null) ...[
          const SizedBox(height: 5),
          Text(
            r.detalle!,
            style: textos.bodyMedium?.copyWith(color: paleta.textoSobreAzul),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _BloqueCargando extends StatelessWidget {
  const _BloqueCargando();

  @override
  Widget build(BuildContext context) {
    final claro = Colors.white.withValues(alpha: 0.14);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        BloqueEsqueleto(ancho: 150, alto: 12, radio: 6, color: claro),
        const SizedBox(height: 12),
        BloqueEsqueleto(ancho: 220, alto: 24, radio: 8, color: claro),
        const SizedBox(height: 10),
        BloqueEsqueleto(ancho: 180, alto: 14, radio: 7, color: claro),
      ],
    );
  }
}

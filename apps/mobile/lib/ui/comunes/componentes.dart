import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/proveedores.dart';
import '../../l10n/textos.dart';
import '../../nucleo/idiomas.dart';
import '../../nucleo/movimiento.dart';
import '../../nucleo/tema.dart';

/// Tarjeta grafito de la app UTB: esquinas amplias, borde casi invisible y un
/// leve hundimiento al presionar.
class TarjetaUtb extends StatefulWidget {
  const TarjetaUtb({
    super.key,
    required this.child,
    this.alTocar,
    this.padding = const EdgeInsets.all(20),
    this.color = ColoresUtb.superficie,
    this.radio = MedidasUtb.radioTarjeta,
    this.colorBorde,
  });

  final Widget child;
  final VoidCallback? alTocar;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radio;

  /// Nulo: el borde de la paleta, que en alto contraste se vuelve visible.
  final Color? colorBorde;

  @override
  State<TarjetaUtb> createState() => _TarjetaUtbState();
}

class _TarjetaUtbState extends State<TarjetaUtb> {
  var _presionada = false;

  @override
  Widget build(BuildContext context) {
    final paleta = PaletaUtb.de(context);
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(widget.radio),
      side: BorderSide(
        color: paleta.altoContraste
            ? paleta.borde
            : widget.colorBorde ?? paleta.borde,
      ),
    );

    final contenido = Padding(padding: widget.padding, child: widget.child);

    return AnimatedScale(
      scale: _presionada && !sinMovimiento(context) ? 0.982 : 1,
      duration: Movimiento.corto,
      curve: Movimiento.salida,
      child: Material(
        color: widget.color,
        shape: forma,
        clipBehavior: Clip.antiAlias,
        child: widget.alTocar == null
            ? contenido
            : InkWell(
                onTap: widget.alTocar,
                onHighlightChanged: (v) => setState(() => _presionada = v),
                child: contenido,
              ),
      ),
    );
  }
}

/// Botón translúcido sobre superficies azules («Mostrar carnet»).
class BotonVidrio extends StatelessWidget {
  const BotonVidrio({
    super.key,
    required this.etiqueta,
    required this.alTocar,
    this.icono,
  });

  final String etiqueta;

  /// Nulo cuando el botón solo dibuja la acción de un contenedor que ya
  /// responde al toque entero: así no hay dos objetivos con la misma acción
  /// para el lector de pantalla ni para el teclado.
  final VoidCallback? alTocar;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final contraste = PaletaUtb.de(context).altoContraste;
    final cuerpo = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: MedidasUtb.toque),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icono != null) ...[
              Icon(icono, size: 20, color: ColoresUtb.texto),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                etiqueta,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: ShapeDecoration(
          color: Colors.white.withValues(alpha: contraste ? 0.24 : 0.16),
          shape: StadiumBorder(
            side: BorderSide(
              color: Colors.white.withValues(alpha: contraste ? 0.8 : 0.26),
              width: contraste ? 1.5 : 1,
            ),
          ),
        ),
        child: alTocar == null
            ? cuerpo
            : InkWell(onTap: alTocar, child: cuerpo),
      ),
    );
  }
}

/// Botón redondo para flotar sobre imágenes y sobre el visor 360.
class BotonCircular extends StatelessWidget {
  const BotonCircular({
    super.key,
    required this.icono,
    required this.etiqueta,
    required this.alTocar,
    this.tamano = MedidasUtb.toque,
    this.activo,
  });

  final IconData icono;

  /// Se anuncia al lector de pantalla y aparece como tooltip.
  final String etiqueta;
  final VoidCallback alTocar;
  final double tamano;

  /// Para los botones que encienden y apagan algo: el lector de pantalla
  /// anuncia el estado y el botón se rellena de azul cuando está activo.
  final bool? activo;

  @override
  Widget build(BuildContext context) {
    final paleta = PaletaUtb.de(context);
    final encendido = activo ?? false;
    return Tooltip(
      message: etiqueta,
      child: Semantics(
        button: true,
        toggled: activo,
        label: etiqueta,
        // Con excludeSemantics la acción del InkWell no llega al lector de
        // pantalla: sin este onTap, el doble toque de TalkBack o VoiceOver
        // anunciaba «botón» y no hacía nada.
        onTap: alTocar,
        excludeSemantics: true,
        child: Material(
          // Sobre cielo o paredes claras del visor 360, la mitad de
          // opacidad se perdía.
          color: encendido
              ? ColoresUtb.azul
              : Colors.black.withValues(
                  alpha: paleta.altoContraste ? 0.85 : 0.6,
                ),
          shape: CircleBorder(
            side: BorderSide(
              color: Colors.white.withValues(
                alpha: paleta.altoContraste ? 0.85 : 0.2,
              ),
              width: paleta.altoContraste ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: alTocar,
            child: SizedBox.square(
              dimension: tamano,
              child: Icon(icono, color: ColoresUtb.texto, size: tamano * 0.46),
            ),
          ),
        ),
      ),
    );
  }
}

/// Encabezado de sección: «Noticias», «Lunes 12».
class CabeceraSeccion extends StatelessWidget {
  const CabeceraSeccion({super.key, required this.titulo, this.subtitulo});

  final String titulo;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: tema.headlineSmall),
          if (subtitulo != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitulo!,
              style: tema.bodyMedium?.copyWith(
                color: PaletaUtb.de(context).textoSecundario,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Recuadro informativo azul («En curso · 30 % evaluado»).
///
/// Es la forma en que el módulo dice que algo falta o todavía no existe: el
/// usuario lo lee como información y no como un error.
class RecuadroInfo extends StatelessWidget {
  const RecuadroInfo({
    super.key,
    required this.icono,
    required this.texto,
    this.encabezado,
    this.accion,
  });

  final IconData icono;
  final String texto;
  final String? encabezado;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final paleta = PaletaUtb.de(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColoresUtb.fondoInfo,
        borderRadius: BorderRadius.circular(18),
        border: paleta.altoContraste
            ? Border.all(color: paleta.bordeFuerte)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icono, size: 20, color: ColoresUtb.azulInfo),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (encabezado != null) ...[
                    Text(
                      encabezado!,
                      style: tema.labelMedium?.copyWith(
                        color: paleta.altoContraste
                            ? ColoresUtb.texto
                            : ColoresUtb.azulInfo,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                  Text(
                    texto,
                    style: tema.bodyMedium?.copyWith(
                      color: ColoresUtb.texto,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            ?accion,
          ],
        ),
      ),
    );
  }
}

/// Píldora de categoría («✦ SUGERENCIA»).
class ChipEtiqueta extends StatelessWidget {
  const ChipEtiqueta({
    super.key,
    required this.texto,
    this.icono,
    this.color = ColoresUtb.azulInfo,
  });

  final String texto;
  final IconData? icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icono != null) ...[
              Icon(icono, size: 15, color: color),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                mayusculasDe(context, texto),
                style: estiloSobretitulo(color: color).copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloque gris de carga, con un barrido de luz.
class BloqueEsqueleto extends StatelessWidget {
  const BloqueEsqueleto({
    super.key,
    this.ancho,
    required this.alto,
    this.radio = 12,
    this.color = ColoresUtb.superficie,
  });

  final double? ancho;
  final double alto;
  final double radio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bloque = Container(
      width: ancho,
      height: alto,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radio),
      ),
    );
    if (sinMovimiento(context)) return bloque;
    return bloque
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1500.ms,
          color: Colors.white.withValues(alpha: 0.06),
        );
  }
}

/// Texto que viene del servidor (nombres, descripciones) y no de los ARB.
///
/// Mientras el servidor no traduzca, ese texto está en español aunque la
/// interfaz esté en otro idioma. Aquí se marca con su idioma: el lector de
/// pantalla cambia de voz para leerlo (WCAG 3.1.2) y el motor de texto elige
/// la letra adecuada, que en una interfaz en japonés o coreano importa.
class TextoDeContenido extends ConsumerWidget {
  const TextoDeContenido(
    this.texto, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String texto;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etiqueta = ref.watch(repositorioContenidoProvider).idiomaContenido;
    final idioma = localeDeEtiqueta(etiqueta);
    final visible = Text(
      texto,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      locale: idioma,
    );

    final ui = Localizations.localeOf(context);
    if (mismoIdioma(etiqueta, ui.languageCode)) return visible;
    return Semantics(
      attributedLabel: atribuirIdioma(texto, idioma),
      excludeSemantics: true,
      child: visible,
    );
  }
}

/// Etiqueta del lector de pantalla en el idioma de la interfaz que incluye
/// un texto del servidor, como «Parada 1, Biblioteca, ya visitado».
///
/// Si el contenido está en otro idioma, solo ese tramo se marca con el suyo:
/// el lector dice la frase con la voz de la interfaz y el nombre con la del
/// contenido.
class SemanticaConContenido extends ConsumerWidget {
  const SemanticaConContenido({
    super.key,
    required this.etiqueta,
    required this.contenido,
    required this.child,
    this.boton = false,
    this.alTocar,
    this.pistaAlTocar,
  });

  final String etiqueta;
  final String contenido;
  final Widget child;
  final bool boton;
  final VoidCallback? alTocar;

  /// Qué hace el toque: el lector de pantalla dice «toca dos veces para…».
  final String? pistaAlTocar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etiquetaContenido = ref
        .watch(repositorioContenidoProvider)
        .idiomaContenido;
    final ui = Localizations.localeOf(context);
    final inicio = etiqueta.indexOf(contenido);
    final marcar =
        !mismoIdioma(etiquetaContenido, ui.languageCode) &&
        contenido.isNotEmpty &&
        inicio >= 0;

    return Semantics(
      button: boton,
      label: marcar ? null : etiqueta,
      attributedLabel: marcar
          ? AttributedString(
              etiqueta,
              attributes: [
                LocaleStringAttribute(
                  range: TextRange(
                    start: inicio,
                    end: inicio + contenido.length,
                  ),
                  locale: localeDeEtiqueta(etiquetaContenido),
                ),
              ],
            )
          : null,
      onTap: alTocar,
      onTapHint: alTocar == null ? null : pistaAlTocar,
      excludeSemantics: true,
      child: child,
    );
  }
}

/// Etiqueta para el lector de pantalla con el idioma marcado.
AttributedString atribuirIdioma(String texto, Locale idioma) =>
    AttributedString(
      texto,
      attributes: [
        if (texto.isNotEmpty)
          LocaleStringAttribute(
            range: TextRange(start: 0, end: texto.length),
            locale: idioma,
          ),
      ],
    );

/// Color e icono de cada categoría de lugar.
///
/// Los colores son los puntos de materia de la Agenda de la anfitriona, de
/// modo que una categoría se lee igual que una asignatura: por su punto.
class EstiloCategoria {
  const EstiloCategoria(this.color, this.icono, [this._clave]);

  final Color color;
  final IconData icono;
  final String? _clave;

  static EstiloCategoria de(String? categoria) {
    return switch (_normalizar(categoria)) {
      'recursos' || 'biblioteca' => const EstiloCategoria(
        ColoresUtb.azulClaro,
        Icons.local_library_rounded,
        'recursos',
      ),
      'academico' => const EstiloCategoria(
        ColoresUtb.amarillo,
        Icons.school_rounded,
        'academico',
      ),
      'bienestar' || 'salud' => const EstiloCategoria(
        ColoresUtb.verde,
        Icons.health_and_safety_rounded,
        'bienestar',
      ),
      'servicios' || 'comida' => const EstiloCategoria(
        ColoresUtb.naranja,
        Icons.storefront_rounded,
        'servicios',
      ),
      'deporte' || 'deportes' => const EstiloCategoria(
        ColoresUtb.morado,
        Icons.sports_rounded,
        'deporte',
      ),
      _ => const EstiloCategoria(ColoresUtb.azulClaro, Icons.place_rounded),
    };
  }

  /// Nombre de la categoría en el idioma de la interfaz.
  ///
  /// Las categorías son un conjunto cerrado que la app ya reconoce por su
  /// color, así que se traducen aquí aunque el servidor las envíe en español.
  /// Una categoría nueva se muestra tal como llega.
  static String nombre(Textos txt, String categoria) =>
      switch (de(categoria)._clave) {
        'recursos' => txt.categoriaRecursos,
        'academico' => txt.categoriaAcademico,
        'bienestar' => txt.categoriaBienestar,
        'servicios' => txt.categoriaServicios,
        'deporte' => txt.categoriaDeporte,
        _ => categoria,
      };

  static String _normalizar(String? texto) {
    const tildes = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u'};
    final bajo = (texto ?? '').trim().toLowerCase();
    return bajo.split('').map((c) => tildes[c] ?? c).join();
  }
}

/// Número de parada con dos cifras, como las horas de la Agenda.
String numeroParada(int numero) => numero.toString().padLeft(2, '0');

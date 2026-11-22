part of 'pantalla_navegacion.dart';

// Piezas visuales de «Cómo llegar», con el lenguaje de la app UTB
// (DESIGN.md): cabecera azul con arcos, tarjetas grafito, tarjeta destacada,
// recuadro informativo, anillo de avance y la postal del lugar.

/// Cabecera azul de la guía: a dónde vas y, mientras guía, cuánto falta.
class _CabeceraGuia extends StatelessWidget {
  const _CabeceraGuia({
    required this.poi,
    required this.numero,
    required this.total,
    required this.sobretitulo,
    required this.alVolver,
    this.avance,
    this.metrosRestantes,
    this.pose,
  });

  final Poi poi;

  /// Número de parada, o nulo si el lugar no es una parada.
  final int? numero;
  final int total;
  final String sobretitulo;
  final VoidCallback alVolver;

  /// Entre 0 y 1 mientras guía: lo recorrido de la ruta.
  final double? avance;
  final int? metrosRestantes;

  /// Max a la derecha cuando no hay anillo.
  final PoseMax? pose;

  @override
  Widget build(BuildContext context) {
    final txt = Textos.of(context);
    final textos = Theme.of(context).textTheme;
    final paleta = PaletaUtb.de(context);
    final arriba = MediaQuery.paddingOf(context).top;
    final estilo = EstiloCategoria.de(poi.categoria);
    final categoria = poi.categoria == null
        ? null
        : EstiloCategoria.nombre(txt, poi.categoria!);
    final detalle = [
      ?categoria,
      if (numero != null) txt.paradaNDeTotal(numero!, total),
    ].join(' · ');
    final letraGrande = MediaQuery.textScalerOf(context).scale(10) > 15;

    final derecha = switch ((avance, pose)) {
      (final v?, _) => Semantics(
        label: metrosRestantes == null
            ? null
            : txt.navFaltan(
                metrosRestantes!,
                (metrosRestantes! / 1.2 / 60).ceil().clamp(1, 99),
              ),
        excludeSemantics: true,
        child: AnilloProgreso(
          valor: v,
          tamano: 76,
          child: metrosRestantes == null
              ? null
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$metrosRestantes',
                      textScaler: TextScaler.noScaling,
                      style: textos.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Text(
                      'm',
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        fontFamily: familiaLetra,
                        fontSize: 12,
                        color: ColoresUtb.textoSobreAzul,
                      ),
                    ),
                  ],
                ),
        ),
      ),
      (_, final p?) => ExcludeSemantics(
        child: IlustracionMax(pose: p, alto: 104),
      ),
      _ => null,
    };

    return FondoCabeceraUtb(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          MedidasUtb.margen,
          arriba + 8,
          MedidasUtb.margen,
          22,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BotonVolverVidrio(etiqueta: txt.volver, alTocar: alVolver),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    label: txt.navTitulo(poi.nombre),
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mayusculasDe(context, sobretitulo),
                          style: estiloSobretitulo(
                            color: paleta.altoContraste
                                ? ColoresUtb.texto
                                : Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextoDeContenido(
                          poi.nombre,
                          style: textos.headlineMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (detalle.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                estilo.icono,
                                size: 16,
                                color: ColoresUtb.textoSobreAzul,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  detalle,
                                  style: textos.bodyMedium?.copyWith(
                                    color: ColoresUtb.textoSobreAzul,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (derecha != null && !letraGrande) ...[
                  const SizedBox(width: 12),
                  derecha,
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Volver, en vidrio sobre la cabecera azul (el circular negro es para
/// flotar sobre fotos).
class _BotonVolverVidrio extends StatelessWidget {
  const _BotonVolverVidrio({required this.etiqueta, required this.alTocar});

  final String etiqueta;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final contraste = PaletaUtb.de(context).altoContraste;
    return Tooltip(
      message: etiqueta,
      child: Semantics(
        button: true,
        label: etiqueta,
        onTap: alTocar,
        excludeSemantics: true,
        child: Material(
          color: Colors.white.withValues(alpha: contraste ? 0.24 : 0.16),
          shape: CircleBorder(
            side: BorderSide(
              color: Colors.white.withValues(alpha: contraste ? 0.8 : 0.26),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: alTocar,
            child: const SizedBox.square(
              dimension: MedidasUtb.toque,
              child: Icon(Icons.arrow_back_rounded, color: ColoresUtb.texto),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta destacada (gradiente diagonal, arcos, resplandor), como la de la
/// próxima parada en inicio.
class _TarjetaDestacada extends StatelessWidget {
  const _TarjetaDestacada({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MedidasUtb.radioHoja),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColoresUtb.destacadaInicio,
            Color(0xFF1C3FAE),
            ColoresUtb.destacadaFin,
          ],
          stops: [0, 0.5, 1],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: ColoresUtb.azul.withValues(alpha: 0.3),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MedidasUtb.radioHoja),
        child: CustomPaint(
          painter: const _ArcosTarjeta(),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _ArcosTarjeta extends CustomPainter {
  const _ArcosTarjeta();

  @override
  void paint(Canvas canvas, Size size) => pintarArcos(canvas, size);

  @override
  bool shouldRepaint(_ArcosTarjeta old) => false;
}

/// Antes de empezar: cómo funciona la guía, en tres líneas.
class _TarjetaComoFunciona extends StatelessWidget {
  const _TarjetaComoFunciona({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    final txt = Textos.of(context);
    final textos = Theme.of(context).textTheme;
    final paleta = PaletaUtb.de(context);
    Widget idea(IconData icono, String texto) => Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColoresUtb.azulClaro.withValues(alpha: 0.14),
            ),
            child: Icon(icono, size: 20, color: ColoresUtb.azulClaro),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                texto,
                style: textos.bodyMedium?.copyWith(
                  color: paleta.textoSecundario,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return TarjetaUtb(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: textos.titleLarge),
          idea(Icons.route_rounded, txt.navIdeaRuta),
          idea(Icons.photo_camera_rounded, txt.navIdeaCamara),
          idea(Icons.lock_outline_rounded, txt.navPermisoTexto),
        ],
      ),
    );
  }
}

/// «Sin escaleras», con su explicación, en tarjeta compacta.
class _InterruptorEscaleras extends StatelessWidget {
  const _InterruptorEscaleras({
    required this.valor,
    required this.alCambiar,
    this.compacto = false,
  });

  final bool valor;
  final ValueChanged<bool> alCambiar;

  /// Durante la guía: sin la explicación, para dejarle sitio al plano.
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final txt = Textos.of(context);
    final textos = Theme.of(context).textTheme;
    final paleta = PaletaUtb.de(context);
    return SwitchListTile(
      value: valor,
      onChanged: alCambiar,
      contentPadding: EdgeInsets.zero,
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ColoresUtb.azulClaro.withValues(alpha: 0.14),
        ),
        child: const Icon(
          Icons.accessible_rounded,
          size: 22,
          color: ColoresUtb.azulClaro,
        ),
      ),
      title: Text(txt.navSinEscaleras, style: textos.titleSmall),
      subtitle: compacto
          ? null
          : Text(
              txt.navSinEscalerasDetalle,
              style: textos.bodySmall?.copyWith(color: paleta.textoSecundario),
            ),
    );
  }
}

/// La panorámica del destino, que se mira con el dedo: para reconocer el
/// lugar antes de salir y, si no se puede guiar, para conocerlo igual.
class _PostalDestino extends StatelessWidget {
  const _PostalDestino({
    required this.escena,
    required this.poi,
    required this.numero,
  });

  final Escena escena;
  final Poi poi;
  final int? numero;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MedidasUtb.radioTarjeta),
        child: PostalEscena(
          escena: escena,
          estilo: EstiloCategoria.de(poi.categoria),
          numero: numero,
          interactiva: true,
        ),
      ),
    );
  }
}

/// Un estado fuera del recorrido: sin permiso, GPS apagado, sin ruta, fuera
/// del campus. Se lee como información, no como error (recuadro informativo),
/// con la postal del lugar debajo.
class _EstadoGuia extends StatelessWidget {
  const _EstadoGuia({
    required this.icono,
    required this.texto,
    required this.principal,
    this.secundaria,
    this.postal,
  });

  final IconData icono;
  final String texto;
  final (String, VoidCallback?) principal;
  final (String, VoidCallback)? secundaria;
  final Widget? postal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 20),
            children: [
              RecuadroInfo(icono: icono, texto: texto),
              if (postal != null) ...[const SizedBox(height: 16), postal!],
            ],
          ),
        ),
        _Acciones(principal: principal, secundaria: secundaria),
      ],
    );
  }
}

/// El botón lleno principal, abajo, y uno de texto bajo él.
class _Acciones extends StatelessWidget {
  const _Acciones({required this.principal, this.secundaria});

  final (String, VoidCallback?) principal;
  final (String, VoidCallback)? secundaria;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        FilledButton(
          onPressed: principal.$2,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(principal.$1),
        ),
        if (secundaria case (final etiqueta, final accion)) ...[
          const SizedBox(height: 4),
          TextButton(onPressed: accion, child: Text(etiqueta)),
        ],
      ],
    );
  }
}

/// Al llegar, la siguiente parada del recorrido con su «Cómo llegar».
class _TarjetaSiguiente extends StatelessWidget {
  const _TarjetaSiguiente({required this.poi, required this.alIr});

  final Poi poi;
  final VoidCallback alIr;

  @override
  Widget build(BuildContext context) {
    final txt = Textos.of(context);
    final textos = Theme.of(context).textTheme;
    final paleta = PaletaUtb.de(context);
    return SemanticaConContenido(
      etiqueta: '${txt.siguienteParada}: ${poi.nombre}',
      contenido: poi.nombre,
      boton: true,
      alTocar: alIr,
      pistaAlTocar: txt.comoLlegar,
      child: _TarjetaDestacada(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mayusculasDe(context, txt.siguienteParada),
                    style: estiloSobretitulo(
                      color: paleta.altoContraste
                          ? ColoresUtb.texto
                          : Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    poi.nombre,
                    style: textos.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            BotonVidrio(
              etiqueta: txt.comoLlegar,
              icono: Icons.directions_walk_rounded,
              alTocar: null,
            ),
          ],
        ),
      ),
    );
  }
}

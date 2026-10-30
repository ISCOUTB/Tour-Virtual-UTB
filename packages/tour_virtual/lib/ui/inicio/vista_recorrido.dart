import 'dart:math' as math;
import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/modelos/modelos.dart';
import '../../datos/progreso.dart';
import '../../datos/proveedores.dart';
import '../../l10n/textos.dart';
import '../../configuracion_tour.dart';
import '../../nucleo/idiomas.dart';
import '../../nucleo/movimiento.dart';
import '../../nucleo/tema.dart';
import '../comunes/componentes.dart';
import '../comunes/fondos.dart';
import '../comunes/inclinable.dart';
import '../ficha_poi.dart';
import '../postal_escena.dart';

/// Contenido de «Recorrido» (RF-19, RF-20, RF-21).
///
/// Responde lo que el mapa no contesta —cuántos lugares hay, cuáles son,
/// cuáles ya vi y por dónde sigo— con la gramática de la Agenda de la app UTB:
/// una tarjeta destacada arriba y una línea de tiempo de paradas debajo.
///
/// Debajo van los demás lugares del campus. Es también la forma de llegar a
/// ellos sin el mapa: allí solo se pueden tocar de cerca, y los que aún no
/// tienen posición no aparecen.
class ListaRecorrido extends ConsumerWidget {
  const ListaRecorrido({
    super.key,
    required this.pois,
    this.otros = const [],
    required this.alAbrirMapa,
  });

  /// Las paradas, con panorámica.
  final List<Poi> pois;

  /// Los demás lugares del campus.
  final List<Poi> otros;
  final VoidCallback alAbrirMapa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitados = ref.watch(progresoProvider);
    final abajo = MediaQuery.paddingOf(context).bottom;
    final txt = Textos.of(context);

    void abrir(Poi poi) => abrirPoi(context, ref, poi: poi, pois: pois);

    final masLugares = [
      if (otros.isNotEmpty) ...[
        const SizedBox(height: 34),
        CabeceraSeccion(
          titulo: txt.masLugares,
          subtitulo: txt.cantidadLugares(otros.length),
        ),
        const SizedBox(height: 14),
        for (final poi in otros)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FilaLugar(poi: poi, alTocar: () => abrir(poi)),
          ),
      ],
    ];

    if (pois.isEmpty) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(
          MedidasUtb.margen,
          MedidasUtb.margen,
          MedidasUtb.margen,
          28 + abajo,
        ),
        sliver: SliverList.list(
          children: [
            RecuadroInfo(
              icono: Icons.inbox_outlined,
              texto: txt.sinLugaresPublicados,
            ),
            ...masLugares,
          ],
        ),
      );
    }

    final hechos = pois.where((p) => visitados.contains(p.id)).length;
    final completo = hechos == pois.length;
    final indiceSiguiente = completo
        ? 0
        : pois.indexWhere((p) => !visitados.contains(p.id));

    final animar = !sinMovimiento(context);
    Widget entrada(Widget hijo, int orden) {
      if (!animar) return hijo;
      return hijo
          .animate(delay: (30 + orden * 55).ms)
          .fadeIn(duration: 360.ms, curve: Movimiento.salida)
          .slideY(
            begin: 0.07,
            end: 0,
            duration: 440.ms,
            curve: Movimiento.salida,
          );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        MedidasUtb.margen,
        2,
        MedidasUtb.margen,
        28 + abajo,
      ),
      sliver: SliverList.list(
        children: [
          entrada(
            TarjetaSiguiente(
              poi: pois[indiceSiguiente],
              numero: indiceSiguiente + 1,
              total: pois.length,
              hechos: hechos,
              alTocar: () {
                // «Volver a empezar» tiene que reiniciar de verdad: antes
                // abría el primer lugar y el recorrido seguía completo.
                if (completo) ref.read(progresoProvider.notifier).reiniciar();
                abrir(pois[indiceSiguiente]);
              },
            ),
            0,
          ),
          const SizedBox(height: 30),
          entrada(
            CabeceraSeccion(
              titulo: txt.paradas,
              subtitulo: txt.avanceLugares(hechos, pois.length),
            ),
            1,
          ),
          const SizedBox(height: 18),
          for (final (i, poi) in pois.indexed)
            entrada(
              FilaParada(
                poi: poi,
                numero: i + 1,
                visitado: visitados.contains(poi.id),
                esSiguiente: !completo && i == indiceSiguiente,
                esPrimera: i == 0,
                esUltima: i == pois.length - 1,
                alTocar: () => abrir(poi),
              ),
              2 + i,
            ),
          const SizedBox(height: 22),
          entrada(TarjetaSugerencia(alAbrirMapa: alAbrirMapa), pois.length + 2),
          ...masLugares,
          const SizedBox(height: 34),
          const _Pie(),
        ],
      ),
    );
  }
}

/// Esqueleto de la lista mientras llegan los lugares.
class ListaRecorridoCargando extends StatelessWidget {
  const ListaRecorridoCargando({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        MedidasUtb.margen,
        2,
        MedidasUtb.margen,
        28,
      ),
      sliver: SliverList.list(
        children: [
          const BloqueEsqueleto(alto: 214, radio: 28),
          const SizedBox(height: 30),
          const BloqueEsqueleto(ancho: 130, alto: 26, radio: 8),
          const SizedBox(height: 10),
          const BloqueEsqueleto(ancho: 110, alto: 14, radio: 7),
          const SizedBox(height: 22),
          for (var i = 0; i < 3; i++) ...[
            const Padding(
              padding: EdgeInsets.only(left: 32),
              child: BloqueEsqueleto(alto: 104, radio: 22),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// Tarjeta azul de la siguiente parada, hermana de «Tu carnet digital».
///
/// A la derecha, una postal de la panorámica del lugar en perspectiva, como el
/// carnet de la anfitriona; se inclina hacia el dedo.
class TarjetaSiguiente extends ConsumerWidget {
  const TarjetaSiguiente({
    super.key,
    required this.poi,
    required this.numero,
    required this.total,
    required this.hechos,
    required this.alTocar,
  });

  final Poi poi;
  final int numero;
  final int total;
  final int hechos;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final txt = Textos.of(context);
    final paleta = PaletaUtb.de(context);
    final completo = hechos == total;
    final estilo = EstiloCategoria.de(poi.categoria);
    final escena = completo ? null : escenaPrincipalDe(ref, poi);
    // Con letra grande la postal sube encima del texto: a su lado, el título
    // quedaba en una columna de 190 dp y se partía letra por letra.
    final letraGrande = MediaQuery.textScalerOf(context).scale(10) > 13.5;

    final (sobretitulo, titulo, detalle, accion, icono) = switch (hechos) {
      _ when completo => (
        txt.recorridoCompleto,
        txt.conocisteLosLugares(total),
        txt.vuelveACualquiera,
        txt.volverAEmpezar,
        Icons.replay_rounded,
      ),
      0 => (
        txt.primeraParada,
        poi.nombre,
        _detalle(txt),
        txt.empezarRecorrido,
        Icons.play_arrow_rounded,
      ),
      _ => (
        txt.siguienteParada,
        poi.nombre,
        _detalle(txt),
        txt.continuarRecorrido,
        Icons.arrow_forward_rounded,
      ),
    };

    final postal = _Postal(
      escena: escena,
      estilo: estilo,
      numero: completo ? null : numero,
      completo: completo,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
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
      // Toda la tarjeta responde, no solo el botón, como el carnet de la app
      // UTB: es un objetivo grande para la acción principal del módulo. Para
      // el lector de pantalla y el teclado es un solo botón, que dice qué
      // lugar es y qué hace; el botón translúcido solo lo dibuja.
      child: SemanticaConContenido(
        etiqueta: '$sobretitulo: $titulo. $detalle',
        contenido: titulo,
        boton: true,
        alTocar: alTocar,
        pistaAlTocar: accion,
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: alTocar,
            child: Stack(
              children: [
                const Positioned.fill(child: CustomPaint(painter: _Arcos())),
                if (!letraGrande)
                  Positioned(
                    right: 16,
                    top: 24,
                    width: 140,
                    height: 100,
                    child: postal,
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (letraGrande) ...[
                        SizedBox(width: 140, height: 100, child: postal),
                        const SizedBox(height: 20),
                      ],
                      Padding(
                        padding: EdgeInsets.only(right: letraGrande ? 0 : 150),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mayusculasDe(context, sobretitulo),
                              style: estiloSobretitulo(
                                color: paleta.altoContraste
                                    ? ColoresUtb.texto
                                    : Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              titulo,
                              style: textos.headlineMedium,
                              maxLines: letraGrande ? null : 3,
                              overflow: letraGrande
                                  ? null
                                  : TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              detalle,
                              style: textos.bodyMedium?.copyWith(
                                color: paleta.textoSobreAzul,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      BotonVidrio(
                        etiqueta: accion,
                        icono: icono,
                        alTocar: null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _detalle(Textos txt) {
    final categoria = poi.categoria;
    final parada = txt.paradaNDeTotal(numero, total);
    return categoria == null
        ? parada
        : '$parada · ${EstiloCategoria.nombre(txt, categoria)}';
  }
}

class _Postal extends StatelessWidget {
  const _Postal({
    required this.escena,
    required this.estilo,
    required this.numero,
    required this.completo,
  });

  final Escena? escena;
  final EstiloCategoria estilo;
  final int? numero;
  final bool completo;

  @override
  Widget build(BuildContext context) {
    const radio = 16.0;

    final cara = completo
        ? const FondoCabeceraUtb(
            radioInferior: 0,
            child: Center(
              child: Icon(
                Icons.verified_rounded,
                size: 44,
                color: ColoresUtb.texto,
              ),
            ),
          )
        : PostalEscena(
            escena: escena,
            estilo: estilo,
            numero: numero,
            campoVision: 120,
          );

    final postal = Inclinable(
      reposo: const Pose3D(x: 0.16, y: -0.52, z: -0.06),
      maximo: 0.24,
      radio: BorderRadius.circular(radio),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radio),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 18,
                  offset: Offset(-6, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radio - 3),
              child: SizedBox.expand(child: cara),
            ),
          ),
          if (escena != null)
            Positioned(
              right: -10,
              top: -12,
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.threesixty_rounded,
                  size: 20,
                  color: ColoresUtb.azul,
                ),
              ),
            ),
        ],
      ),
    );

    if (sinMovimiento(context)) return ExcludeSemantics(child: postal);

    // Entra girando desde el canto, como una carta que se voltea.
    return ExcludeSemantics(
      child: postal
          .animate(delay: 120.ms)
          .fadeIn(duration: 260.ms)
          .custom(
            duration: 900.ms,
            curve: Movimiento.salidaFuerte,
            builder: (context, v, hijo) => Transform(
              alignment: Alignment.centerRight,
              transform: Matrix4.identity()
                ..setEntry(3, 2, Movimiento.perspectiva)
                ..rotateY((1 - v) * -math.pi / 2.4),
              child: hijo,
            ),
          ),
    );
  }
}

class _Arcos extends CustomPainter {
  const _Arcos();

  @override
  void paint(Canvas canvas, Size size) => pintarArcos(
    canvas,
    size,
    opacidad: 0.75,
    centro: Offset(size.width * 1.15, size.height * 1.2),
  );

  @override
  bool shouldRepaint(_Arcos old) => false;
}

/// Una parada de la línea de tiempo, como una clase en la Agenda.
class FilaParada extends StatelessWidget {
  const FilaParada({
    super.key,
    required this.poi,
    required this.numero,
    required this.visitado,
    required this.esSiguiente,
    required this.esPrimera,
    required this.esUltima,
    required this.alTocar,
  });

  final Poi poi;
  final int numero;
  final bool visitado;
  final bool esSiguiente;
  final bool esPrimera;
  final bool esUltima;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final txt = Textos.of(context);
    final paleta = PaletaUtb.de(context);
    final estilo = EstiloCategoria.de(poi.categoria);
    final categoria = poi.categoria == null
        ? null
        : EstiloCategoria.nombre(txt, poi.categoria!);
    // La columna del número crece con el texto: con 44 dp fijos, «01» al
    // 200 % se partía en dos líneas.
    final anchoNumero = max(
      44.0,
      MediaQuery.textScalerOf(context).scale(21) * 1.6,
    );

    final tarjeta = TarjetaUtb(
      padding: EdgeInsets.zero,
      radio: 22,
      alTocar: alTocar,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: ColoredBox(color: estilo.color),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: anchoNumero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        numeroParada(numero),
                        style: textos.titleLarge?.copyWith(
                          color: ColoresUtb.azulClaro,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (visitado) ...[
                        const SizedBox(height: 6),
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: ColoresUtb.verde,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(poi.nombre, style: textos.titleMedium),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            estilo.icono,
                            size: 16,
                            color: paleta.textoSecundario,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              visitado
                                  ? '${txt.visitado} · '
                                        '${categoria ?? txt.campus}'
                                  : categoria ?? txt.lugarDelCampus,
                              style: textos.bodyMedium?.copyWith(
                                color: paleta.textoSecundario,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (poi.descripcion case final texto?) ...[
                        const SizedBox(height: 8),
                        TextoDeContenido(
                          texto,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textos.bodySmall?.copyWith(
                            color: paleta.textoTenue,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: paleta.textoTerciario,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: CustomPaint(
              painter: _Riel(
                visitado: visitado,
                esSiguiente: esSiguiente,
                esPrimera: esPrimera,
                esUltima: esUltima,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: esUltima ? 0 : 12),
              // El estado va en la etiqueta: un lector de pantalla no ve la
              // palomita verde.
              child: SemanticaConContenido(
                etiqueta: _etiqueta(txt, categoria),
                contenido: poi.nombre,
                boton: true,
                alTocar: alTocar,
                child: tarjeta,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on FilaParada {
  String _etiqueta(Textos txt, String? categoria) {
    final parada = txt.paradaSemantica(numero, poi.nombre);
    final conCategoria = categoria == null ? parada : '$parada, $categoria';
    return visitado ? txt.yaVisitado(conCategoria) : conCategoria;
  }
}

/// Lugar del campus que no es parada: sin número ni riel, porque no forma
/// parte del orden del recorrido ni cuenta para el avance.
class FilaLugar extends StatelessWidget {
  const FilaLugar({super.key, required this.poi, required this.alTocar});

  final Poi poi;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final txt = Textos.of(context);
    final paleta = PaletaUtb.de(context);
    final estilo = EstiloCategoria.de(poi.categoria);
    final categoria = poi.categoria == null
        ? null
        : EstiloCategoria.nombre(txt, poi.categoria!);
    final detalle = [
      categoria ?? txt.lugarDelCampus,
      if (!poi.tienePosicionEnMapa) txt.sinUbicacionMapa,
    ].join(' · ');

    return SemanticaConContenido(
      etiqueta: categoria == null ? poi.nombre : '${poi.nombre}, $categoria',
      contenido: poi.nombre,
      boton: true,
      alTocar: alTocar,
      child: TarjetaUtb(
        radio: 22,
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        alTocar: alTocar,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: estilo.color.withValues(alpha: 0.16),
              ),
              child: Icon(estilo.icono, size: 20, color: estilo.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextoDeContenido(poi.nombre, style: textos.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    detalle,
                    style: textos.bodyMedium?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: paleta.textoTerciario),
          ],
        ),
      ),
    );
  }
}

class _Riel extends CustomPainter {
  const _Riel({
    required this.visitado,
    required this.esSiguiente,
    required this.esPrimera,
    required this.esUltima,
  });

  final bool visitado;
  final bool esSiguiente;
  final bool esPrimera;
  final bool esUltima;

  static const _alturaPunto = 30.0;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final linea = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(x, esPrimera ? _alturaPunto : 0),
      Offset(x, esUltima ? _alturaPunto : size.height),
      linea,
    );

    final centro = Offset(x, _alturaPunto);
    if (visitado) {
      canvas.drawCircle(centro, 5.5, Paint()..color = ColoresUtb.azulClaro);
    } else if (esSiguiente) {
      canvas.drawCircle(
        centro,
        10,
        Paint()..color = ColoresUtb.azulClaro.withValues(alpha: 0.2),
      );
      canvas.drawCircle(centro, 5.5, Paint()..color = ColoresUtb.fondo);
      canvas.drawCircle(
        centro,
        5.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = ColoresUtb.azulClaro,
      );
    } else {
      canvas.drawCircle(centro, 5, Paint()..color = ColoresUtb.fondo);
      canvas.drawCircle(
        centro,
        5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFF3E7D80),
      );
    }
  }

  @override
  bool shouldRepaint(_Riel old) =>
      old.visitado != visitado ||
      old.esSiguiente != esSiguiente ||
      old.esPrimera != esPrimera ||
      old.esUltima != esUltima;
}

/// Tarjeta punteada de sugerencia, como «Eventos después de clases».
class TarjetaSugerencia extends StatelessWidget {
  const TarjetaSugerencia({super.key, required this.alAbrirMapa});

  final VoidCallback alAbrirMapa;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final txt = Textos.of(context);
    final paleta = PaletaUtb.de(context);
    const radio = 22.0;

    return CustomPaint(
      painter: _BordePunteado(
        radio: radio,
        color: paleta.altoContraste
            ? paleta.bordeFuerte
            : const Color(0xFF3B5378),
      ),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radio),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alAbrirMapa,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChipEtiqueta(
                  texto: txt.sugerencia,
                  icono: Icons.auto_awesome_rounded,
                ),
                const SizedBox(height: 12),
                Text(txt.sugerenciaTitulo, style: textos.titleMedium),
                const SizedBox(height: 6),
                Text(
                  txt.sugerenciaTexto,
                  style: textos.bodyMedium?.copyWith(
                    color: paleta.textoSecundario,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: MedidasUtb.toque,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          txt.abrirMapa,
                          style: textos.labelLarge?.copyWith(
                            color: ColoresUtb.azulClaro,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: ColoresUtb.azulClaro,
                      ),
                    ],
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

class _BordePunteado extends CustomPainter {
  const _BordePunteado({required this.radio, required this.color});

  final double radio;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final contorno = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.75),
          Radius.circular(radio),
        ),
      );
    final pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color;

    const trazo = 7.0;
    const hueco = 5.0;
    for (final metrica in contorno.computeMetrics()) {
      for (var d = 0.0; d < metrica.length; d += trazo + hueco) {
        canvas.drawPath(metrica.extractPath(d, d + trazo), pincel);
      }
    }
  }

  @override
  bool shouldRepaint(_BordePunteado old) =>
      old.radio != radio || old.color != color;
}

class _Pie extends ConsumerWidget {
  const _Pie();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txt = Textos.of(context);
    // Contenido de prueba y no de la base: se dice, para no confundirlo.
    final esLocal = ref.watch(configuracionTourProvider).esLocal;
    return Column(
      children: [
        Text(
          txt.pieOficial,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: PaletaUtb.de(context).textoTenue,
          ),
        ),
        if (esLocal) ...[
          const SizedBox(height: 10),
          ChipEtiqueta(
            texto: txt.datosDemostracion,
            icono: Icons.science_outlined,
            color: ColoresUtb.amarillo,
          ),
        ],
      ],
    );
  }
}

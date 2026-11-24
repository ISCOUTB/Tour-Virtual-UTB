import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../datos/modelos/modelos.dart';
import '../../l10n/textos.dart';
import '../../nucleo/movimiento.dart';
import '../../navegacion/espacios.dart';
import '../../navegacion/grafo_campus.dart';
import '../../nucleo/rutas.dart';
import '../../nucleo/tema.dart';
import '../comunes/componentes.dart';
import '../ficha_poi.dart';

/// El icono de un tipo de espacio del catálogo (`salon`, `laboratorio`…).
IconData iconoEspacio(String tipo) {
  final t = tipo.toLowerCase();
  if (t.contains('lab')) return Icons.science_rounded;
  if (t.contains('ofic')) return Icons.business_center_rounded;
  if (t.contains('cafe')) return Icons.local_cafe_rounded;
  if (t.contains('audit')) return Icons.theater_comedy_rounded;
  if (t.contains('salon') || t.contains('aula')) {
    return Icons.meeting_room_rounded;
  }
  return Icons.room_service_rounded;
}

/// «¿A dónde vas?»: un campo dentro de la lista del tour que busca lugares,
/// salones, laboratorios y oficinas, y muestra los resultados debajo, en la
/// misma lista. No abre otra pantalla.
///
/// Un lugar abre su ficha; un salón u oficina abre «Cómo llegar» hasta la
/// entrada de su edificio, que dice en qué piso está. El catálogo de espacios
/// viene de MAPSUTB (ver [CatalogoEspacios]).
class BuscadorDestinos extends ConsumerStatefulWidget {
  const BuscadorDestinos({
    super.key,
    required this.lugares,
    required this.paradas,
  });

  /// Todos los lugares del tour.
  final List<Poi> lugares;

  /// Las paradas, para numerar la ficha que se abra.
  final List<Poi> paradas;

  @override
  ConsumerState<BuscadorDestinos> createState() => _BuscadorDestinosState();
}

class _BuscadorDestinosState extends ConsumerState<BuscadorDestinos>
    with WidgetsBindingObserver {
  final _texto = TextEditingController();
  final _foco = FocusNode();
  IndiceBusqueda? _indice;
  (List<Poi>, CatalogoEspacios?)? _base;
  Timer? _subir;

  /// Cuántos resultados se ven sin pedir más: la lista sigue debajo.
  static const _visibles = 6;
  var _todos = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foco.addListener(_alEnfocar);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subir?.cancel();
    _foco.removeListener(_alEnfocar);
    _texto.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _alEnfocar() {
    if (_foco.hasFocus) _programarSubida();
  }

  /// El teclado cambia el tamaño de la ventana mientras se abre.
  @override
  void didChangeMetrics() {
    if (_foco.hasFocus) _programarSubida();
  }

  /// Al tocar el campo, la lista sube hasta dejarlo arriba: si no, el teclado
  /// tapaba los resultados, que salen debajo. Se espera a que la ventana deje
  /// de cambiar de tamaño: en el Xiaomi de pruebas, el teclado tarda más de
  /// 350 ms en abrirse y el desplazamiento quedaba corto.
  void _programarSubida() {
    _subir?.cancel();
    _subir = Timer(const Duration(milliseconds: 180), () {
      if (!mounted || !_foco.hasFocus) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.02,
        duration: sinMovimiento(context) ? Duration.zero : Movimiento.medio,
        curve: Movimiento.salida,
      );
    });
  }

  IndiceBusqueda _indiceDe(CatalogoEspacios? catalogo) {
    final base = (widget.lugares, catalogo);
    if (_indice == null || _base != base) {
      _base = base;
      _indice = IndiceBusqueda(
        lugares: widget.lugares,
        catalogo: catalogo ?? const CatalogoEspacios(edificios: []),
      );
    }
    return _indice!;
  }

  void _abrir(DestinoBusqueda d) {
    _foco.unfocus();
    final lugar = d.lugar;
    if (lugar != null) {
      abrirPoi(context, ref, poi: lugar, pois: widget.paradas);
    } else {
      context.push(Rutas.haciaNavegacion(d.poiId, espacio: d.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final txt = Textos.of(context);
    final textos = Theme.of(context).textTheme;
    final paleta = PaletaUtb.de(context);
    final catalogo = ref.watch(catalogoEspaciosProvider).valueOrNull;
    final grafo = ref.watch(grafoCampusProvider).valueOrNull;
    final consulta = _texto.text;
    final resultados = consulta.trim().isEmpty
        ? const <DestinoBusqueda>[]
        : [
            for (final d in _indiceDe(catalogo).buscar(consulta))
              // Un salón solo sirve si su edificio tiene entrada en la guía.
              if (d.lugar != null || (grafo?.tieneAcceso(d.poiId) ?? false)) d,
          ];
    final mostrados = _todos ? resultados : resultados.take(_visibles).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _texto,
          focusNode: _foco,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() => _todos = false),
          style: textos.bodyLarge,
          decoration: InputDecoration(
            labelText: txt.buscarTitulo,
            hintText: txt.buscarPista,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            filled: true,
            fillColor: ColoresUtb.superficie,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: consulta.isEmpty
                ? null
                : IconButton(
                    tooltip: txt.buscarBorrar,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() {
                      _texto.clear();
                      _todos = false;
                    }),
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide(color: paleta.bordeFuerte),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide(color: paleta.bordeFuerte),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(
                color: ColoresUtb.azulClaro,
                width: 1.6,
              ),
            ),
          ),
        ),
        if (consulta.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Semantics(
            liveRegion: true,
            child: resultados.isEmpty
                ? RecuadroInfo(
                    icono: Icons.search_off_rounded,
                    texto: txt.buscarSinResultados(consulta.trim()),
                  )
                : const SizedBox.shrink(),
          ),
          for (final d in mostrados)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FilaResultado(destino: d, alTocar: () => _abrir(d)),
            ),
          if (!_todos && resultados.length > _visibles)
            TextButton(
              onPressed: () => setState(() => _todos = true),
              child: Text(txt.buscarVerTodos(resultados.length)),
            ),
          if (resultados.any((d) => d.lugar == null))
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4),
              child: Text(
                txt.buscarCredito,
                style: textos.bodySmall?.copyWith(color: paleta.textoTerciario),
              ),
            ),
        ],
      ],
    );
  }
}

class _FilaResultado extends StatelessWidget {
  const _FilaResultado({required this.destino, required this.alTocar});

  final DestinoBusqueda destino;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final txt = Textos.of(context);
    final textos = Theme.of(context).textTheme;
    final paleta = PaletaUtb.de(context);
    final lugar = destino.lugar;
    final estilo = lugar == null ? null : EstiloCategoria.de(lugar.categoria);
    final color = estilo?.color ?? ColoresUtb.azulClaro;
    final icono = estilo?.icono ?? iconoEspacio(destino.tipoEspacio);
    final detalle = lugar == null
        ? destino.donde
        : (lugar.categoria == null
              ? txt.lugarDelCampus
              : EstiloCategoria.nombre(txt, lugar.categoria!));

    return SemanticaConContenido(
      etiqueta: [destino.titulo, ?detalle].join(', '),
      contenido: destino.titulo,
      boton: true,
      alTocar: alTocar,
      pistaAlTocar: lugar == null ? txt.buscarComoLlegar : null,
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
                color: color.withValues(alpha: 0.16),
              ),
              child: Icon(icono, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextoDeContenido(destino.titulo, style: textos.titleMedium),
                  if (detalle != null) ...[
                    const SizedBox(height: 3),
                    lugar == null
                        ? TextoDeContenido(
                            detalle,
                            style: textos.bodyMedium?.copyWith(
                              color: paleta.textoSecundario,
                            ),
                          )
                        : Text(
                            detalle,
                            style: textos.bodyMedium?.copyWith(
                              color: paleta.textoSecundario,
                            ),
                          ),
                  ],
                ],
              ),
            ),
            Icon(
              lugar == null
                  ? Icons.directions_walk_rounded
                  : Icons.chevron_right_rounded,
              color: lugar == null
                  ? ColoresUtb.azulClaro
                  : paleta.textoTerciario,
            ),
          ],
        ),
      ),
    );
  }
}

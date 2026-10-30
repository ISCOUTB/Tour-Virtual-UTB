import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/preferencias.dart';
import '../../l10n/textos.dart';
import '../../nucleo/idiomas.dart';
import '../../nucleo/movimiento.dart';
import '../../nucleo/tema.dart';
import '../comunes/componentes.dart';

/// Ajustes de idioma y accesibilidad del módulo.
///
/// Todo se aplica al instante y detrás de la hoja: al elegir otro idioma o
/// un texto más grande, la propia hoja cambia, que es la mejor vista previa.
Future<void> mostrarAjustes(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, control) => _Ajustes(control: control),
    ),
  );
}

class _Ajustes extends ConsumerWidget {
  const _Ajustes({required this.control});

  final ScrollController control;

  /// Valor del grupo de radios para «idioma del teléfono».
  static const _delTelefono = 'telefono';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txt = Textos.of(context);
    final textos = Theme.of(context).textTheme;
    final paleta = PaletaUtb.de(context);
    final p = ref.watch(preferenciasProvider);
    final ajustes = ref.read(preferenciasProvider.notifier);
    final abajo = MediaQuery.paddingOf(context).bottom;
    final delTelefono = resolverIdioma(ref.watch(idiomasDelTelefonoProvider));

    Widget seccion(String titulo) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 26, 4, 10),
      child: Semantics(
        header: true,
        child: Text(
          mayusculasDe(context, titulo),
          style: estiloSobretitulo(color: paleta.textoSecundario),
        ),
      ),
    );

    Widget interruptor({
      required String titulo,
      required String detalle,
      required bool valor,
      required ValueChanged<bool> alCambiar,
      required IconData icono,
    }) => SwitchListTile(
      value: valor,
      onChanged: alCambiar,
      secondary: Icon(icono, color: ColoresUtb.azulClaro),
      title: Text(titulo, style: textos.titleSmall),
      subtitle: Text(
        detalle,
        style: textos.bodySmall?.copyWith(color: paleta.textoSecundario),
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
    );

    return ListView(
      controller: control,
      padding: EdgeInsets.fromLTRB(
        MedidasUtb.margen,
        0,
        MedidasUtb.margen,
        28 + abajo,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(txt.idiomaYAccesibilidad, style: textos.headlineSmall),
        ),

        seccion(txt.idioma),
        _Grupo(
          child: RadioGroup<String>(
            groupValue: p.idioma?.toLanguageTag() ?? _delTelefono,
            onChanged: (valor) {
              if (valor == null) return;
              ajustes.cambiarIdioma(
                valor == _delTelefono ? null : localeDeEtiqueta(valor),
              );
            },
            child: Column(
              children: [
                _OpcionIdioma(
                  valor: _delTelefono,
                  titulo: Text(txt.idiomaDelTelefono, style: textos.titleSmall),
                  detalle: _NombreIdioma(
                    delTelefono,
                    style: textos.bodySmall?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                  ),
                  icono: Icons.smartphone_rounded,
                ),
                for (final idioma in idiomasUi) ...[
                  const Divider(indent: 16, endIndent: 16),
                  _OpcionIdioma(
                    valor: idioma.locale.toLanguageTag(),
                    titulo: _NombreIdioma(
                      idioma.locale,
                      style: textos.titleSmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        seccion(txt.accesibilidad),
        _Grupo(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.format_size_rounded,
                      color: ColoresUtb.azulClaro,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(txt.tamanoTexto, style: textos.titleSmall),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SelectorTamano(
                  valor: p.tamanoTexto,
                  alCambiar: ajustes.cambiarTamanoTexto,
                ),
                const SizedBox(height: 12),
                Text(
                  txt.muestraTexto,
                  style: textos.bodyLarge?.copyWith(
                    color: paleta.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Grupo(
          child: Column(
            children: [
              interruptor(
                titulo: txt.altoContraste,
                detalle: txt.altoContrasteDetalle,
                valor: p.altoContraste,
                alCambiar: ajustes.cambiarAltoContraste,
                icono: Icons.contrast_rounded,
              ),
              const Divider(indent: 16, endIndent: 16),
              interruptor(
                titulo: txt.reducirMovimiento,
                detalle: txt.reducirMovimientoDetalle,
                valor: p.reducirMovimiento,
                alCambiar: ajustes.cambiarReducirMovimiento,
                icono: Icons.motion_photos_off_outlined,
              ),
              const Divider(indent: 16, endIndent: 16),
              interruptor(
                titulo: txt.subtitulos,
                detalle: txt.subtitulosDetalle,
                valor: p.subtitulos,
                alCambiar: ajustes.cambiarSubtitulos,
                icono: Icons.closed_caption_outlined,
              ),
              if (hayGiroscopio) ...[
                const Divider(indent: 16, endIndent: 16),
                interruptor(
                  titulo: txt.movimientoTelefono,
                  detalle: txt.movimientoTelefonoDetalle,
                  valor: p.movimientoTelefono,
                  alCambiar: ajustes.cambiarMovimientoTelefono,
                  icono: Icons.screen_rotation_alt_rounded,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            txt.ajustesSistema,
            style: textos.bodySmall?.copyWith(color: paleta.textoTenue),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          child: Text(txt.listo),
        ),
      ],
    );
  }
}

/// Bloque de opciones sobre grafito, como los ajustes de la anfitriona.
class _Grupo extends StatelessWidget {
  const _Grupo({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      TarjetaUtb(padding: EdgeInsets.zero, radio: 22, child: child);
}

class _OpcionIdioma extends StatelessWidget {
  const _OpcionIdioma({
    required this.valor,
    required this.titulo,
    this.detalle,
    this.icono,
  });

  final String valor;
  final Widget titulo;
  final Widget? detalle;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      value: valor,
      title: titulo,
      subtitle: detalle,
      secondary: icono == null
          ? null
          : Icon(icono, color: ColoresUtb.azulClaro),
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
    );
  }
}

/// Nombre de un idioma escrito en ese idioma y pronunciado con su voz: el
/// lector de pantalla dice «Deutsch» en alemán, no deletreado en español.
class _NombreIdioma extends StatelessWidget {
  const _NombreIdioma(this.locale, {this.style});

  final Locale locale;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final nombre =
        idiomasUi.where((i) => i.locale == locale).firstOrNull?.nombre ??
        nombreDeIdioma(locale.toLanguageTag());
    return Semantics(
      attributedLabel: atribuirIdioma(nombre, locale),
      excludeSemantics: true,
      child: Text(nombre, style: style, locale: locale),
    );
  }
}

/// «A A A» de tres tamaños: se entiende sin leer el idioma activo.
class _SelectorTamano extends StatelessWidget {
  const _SelectorTamano({required this.valor, required this.alCambiar});

  final TamanoTexto valor;
  final ValueChanged<TamanoTexto> alCambiar;

  @override
  Widget build(BuildContext context) {
    final txt = Textos.of(context);

    ButtonSegment<TamanoTexto> segmento(
      TamanoTexto tamano,
      String nombre,
      double letra,
    ) => ButtonSegment(
      value: tamano,
      tooltip: nombre,
      label: Semantics(
        label: nombre,
        excludeSemantics: true,
        // La «A» muestra el tamaño relativo; no crece con el ajuste, o las
        // tres acabarían iguales de grandes y sin caber.
        child: MediaQuery.withNoTextScaling(
          child: Text(
            'A',
            style: TextStyle(
              fontSize: letra,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ),
    );

    return SegmentedButton<TamanoTexto>(
      segments: [
        segmento(TamanoTexto.normal, txt.tamanoNormal, 15),
        segmento(TamanoTexto.grande, txt.tamanoGrande, 20),
        segmento(TamanoTexto.muyGrande, txt.tamanoMuyGrande, 25),
      ],
      selected: {valor},
      showSelectedIcon: false,
      onSelectionChanged: (s) => alCambiar(s.first),
      expandedInsets: EdgeInsets.zero,
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

const _azulClaro = Color(0xFF7FA6F0);

/// Lápiz y papelera de un elemento. Entran con animación cuando [visible]
/// pasa a verdadero (modo edición) y salen igual al volver a falso.
///
/// Si el elemento está [marcado] para eliminar, en su lugar se ofrece
/// «Deshacer», y esa opción se mantiene aunque se salga del modo edición.
///
/// Con [compacto] son botones redondos pensados para ir sobre una miniatura
/// (dentro de un `Positioned`).
class AccionesEdicion extends StatelessWidget {
  const AccionesEdicion({
    super.key,
    required this.visible,
    required this.onEditar,
    required this.onEliminar,
    this.marcado = false,
    this.onDeshacer,
    this.compacto = false,
  });

  final bool visible;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final bool marcado;
  final VoidCallback? onDeshacer;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final mostrar = visible || marcado;
    if (compacto) {
      return IgnorePointer(
        ignoring: !mostrar,
        child: AnimatedScale(
          scale: mostrar ? 1 : 0.6,
          alignment: Alignment.topRight,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: mostrar ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: marcado
                  ? [
                      _BotonRedondo(
                        icono: Icons.undo,
                        tooltip: 'Deshacer',
                        color: Colors.white,
                        onTap: onDeshacer ?? () {},
                      ),
                    ]
                  : [
                      _BotonRedondo(
                        icono: Icons.edit_outlined,
                        tooltip: 'Editar',
                        color: Colors.white,
                        onTap: onEditar,
                      ),
                      const SizedBox(width: 4),
                      _BotonRedondo(
                        icono: Icons.delete_outline,
                        tooltip: 'Eliminar',
                        color: AppColors.danger,
                        onTap: onEliminar,
                      ),
                    ],
            ),
          ),
        ),
      );
    }
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerRight,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: !mostrar
            ? const SizedBox.shrink(key: ValueKey('sin-acciones'))
            : marcado
            ? TextButton.icon(
                key: const ValueKey('deshacer'),
                onPressed: onDeshacer,
                icon: const Icon(Icons.undo, size: 16),
                label: const Text('Deshacer'),
              )
            : Row(
                key: const ValueKey('acciones'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    visualDensity: VisualDensity.compact,
                    onPressed: onEditar,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Eliminar',
                    visualDensity: VisualDensity.compact,
                    onPressed: onEliminar,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BotonRedondo extends StatelessWidget {
  const _BotonRedondo({
    required this.icono,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icono;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xE6121317),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 26,
            height: 26,
            child: Icon(icono, size: 15, color: color),
          ),
        ),
      ),
    );
  }
}

/// Aviso que se despliega al entrar al modo edición.
class AvisoModoEdicion extends StatelessWidget {
  const AvisoModoEdicion({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: visible
          ? Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.45),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.edit_note, size: 18, color: _azulClaro),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Modo edición: el lápiz abre Subir Multimedia para '
                        'reemplazar o corregir el archivo; la papelera lo '
                        'marca para eliminar y se borra al pulsar «Guardar '
                        'cambios». Hasta entonces puedes deshacerlo.',
                        style: TextStyle(fontSize: 12, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox(width: double.infinity, height: 0),
    );
  }
}

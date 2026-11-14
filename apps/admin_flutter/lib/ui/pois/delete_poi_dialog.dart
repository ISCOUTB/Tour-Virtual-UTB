import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/poi.dart';
import '../../data/repositories/repositories.dart';

enum DeleteChoice { eliminado, desactivar }

/// C.3 Confirmar eliminación. Devuelve null si se cancela.
Future<DeleteChoice?> showDeletePoiDialog(BuildContext context, Poi poi) {
  return showDialog<DeleteChoice>(
    context: context,
    builder: (context) => _DeletePoiDialog(poi: poi),
  );
}

class _DeletePoiDialog extends StatefulWidget {
  const _DeletePoiDialog({required this.poi});

  final Poi poi;

  @override
  State<_DeletePoiDialog> createState() => _DeletePoiDialogState();
}

class _DeletePoiDialogState extends State<_DeletePoiDialog> {
  final _nombre = TextEditingController();
  bool _eliminando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nombre.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  // Endurecimiento propuesto por la guía: el botón se habilita solo cuando
  // el nombre escrito coincide exactamente.
  bool get _coincide => _nombre.text.trim() == widget.poi.nombre.trim();

  Future<void> _eliminar() async {
    setState(() {
      _eliminando = true;
      _error = null;
    });
    try {
      await poiRepository.eliminar(widget.poi.id);
      if (!mounted) return;
      Navigator.of(context).pop(DeleteChoice.eliminado);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _eliminando = false;
        _error = 'No se pudo eliminar el POI. $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '¿Eliminar el POI ${widget.poi.nombre}?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta acción es permanente y desaparecerá del mapa de la app '
              'móvil.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nombre,
              enabled: !_eliminando,
              decoration: InputDecoration(
                labelText: 'Escribe el nombre del POI para confirmar',
                hintText: widget.poi.nombre,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _eliminando
                    ? null
                    : () => Navigator.of(context).pop(DeleteChoice.desactivar),
                child: const Text('Mejor desactivarlo'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _eliminando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: (_coincide && !_eliminando) ? _eliminar : null,
          child: _eliminando
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Sí, eliminar'),
        ),
      ],
    );
  }
}

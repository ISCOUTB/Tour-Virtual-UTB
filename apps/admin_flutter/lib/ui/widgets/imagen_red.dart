import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Imagen de red con marcador de respaldo.
///
/// La API entrega las imágenes con URL firmada (https). Si la URL falta, no es
/// http(s) o la descarga falla, se muestra [alternativo] en su lugar.
class ImagenRed extends StatelessWidget {
  const ImagenRed({
    super.key,
    required this.url,
    required this.alternativo,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final Widget alternativo;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || !u.startsWith('http')) return alternativo;
    return Image.network(
      u,
      fit: fit,
      errorBuilder: (context, error, stack) => alternativo,
      loadingBuilder: (context, child, progreso) =>
          progreso == null ? child : Container(color: AppColors.border),
    );
  }
}

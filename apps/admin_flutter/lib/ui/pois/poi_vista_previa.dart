import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/enums.dart';
import '../widgets/common.dart';
import '../widgets/imagen_red.dart';
import 'poi_contenido.dart';

/// Vista previa de un lugar tal como lo muestra la app móvil: hoja inferior
/// con la panorámica, categoría y parada, título, descripción, botón «Ver en
/// 360°», audio narrado y aviso de contenido en preparación.
///
/// Todo sale de lo registrado ([contenido]) y de lo que se escribe en el
/// formulario; no hay texto ni imágenes de ejemplo.
class PoiVistaPreviaMovil extends StatelessWidget {
  const PoiVistaPreviaMovil({
    super.key,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.contenido,
    this.parada,
    this.totalParadas,
  });

  final String nombre;
  final String descripcion;
  final String? categoria;
  final ContenidoPoi contenido;
  final int? parada;
  final int? totalParadas;

  static const _hoja = Color(0xFF121317);
  static const _azulInfo = Color(0xFF7FA6F0);
  static const _fondoInfo = Color(0xFF1F3040);

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      width: 300,
      height: 620,
      child: Stack(
        children: [
          Positioned.fill(child: _cabecera()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: 84,
            child: _hojaInferior(),
          ),
        ],
      ),
    );
  }

  Widget _cabecera() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF15318F), Color(0xFF0E2161), Color(0xFF081B45)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
      child: const Row(
        children: [
          Icon(Icons.arrow_back, size: 18, color: Colors.white38),
          SizedBox(width: 10),
          Text(
            'Tour virtual',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hojaInferior() {
    final texto = descripcion.trim();
    final titulo = nombre.trim();
    final etiqueta = [
      if (categoria != null && categoria!.isNotEmpty)
        categoria!.toUpperCase(),
      if (parada != null && totalParadas != null)
        'PARADA $parada DE $totalParadas',
    ].join(' · ');

    return Container(
      decoration: const BoxDecoration(
        color: _hoja,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _imagen(),
                  const SizedBox(height: 12),
                  if (etiqueta.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.widgets_rounded,
                          size: 13,
                          color: AppColors.categoria(categoria),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            etiqueta,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Text(
                    titulo.isEmpty ? 'Nombre del lugar' : titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 22,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: titulo.isEmpty ? Colors.white38 : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    texto.isEmpty ? 'La descripción aparecerá aquí.' : texto,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: texto.isEmpty ? Colors.white38 : Colors.white70,
                    ),
                  ),
                  if (contenido.tiene360) ...[
                    const SizedBox(height: 14),
                    _botonVer360(),
                  ],
                  if (contenido.audioPrincipal != null) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Audio narrado',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _tarjetaAudio(contenido.audioPrincipal!.duracionSeg),
                  ],
                  const SizedBox(height: 14),
                  if (contenido.fotos.isEmpty && contenido.videos.isEmpty)
                    _avisoEnPreparacion()
                  else
                    _galeria(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagen() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImagenRed(url: contenido.imagenPortada, alternativo: _sinImagen()),
            if (contenido.tiene360)
              Positioned(
                left: 8,
                bottom: 8,
                child: _chip(Icons.touch_app_outlined, 'Desliza para mirar'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sinImagen() {
    return Container(
      color: const Color(0xFF1A1E29),
      alignment: Alignment.center,
      child: Icon(
        contenido.escena != null
            ? Icons.threesixty
            : Icons.image_not_supported_outlined,
        size: 34,
        color: Colors.white24,
      ),
    );
  }

  Widget _chip(IconData icono, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonVer360() {
    return Container(
      height: 38,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.threesixty, size: 16, color: Colors.white),
          SizedBox(width: 6),
          Text(
            'Ver en 360°',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaAudio(int? segundos) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF17181C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2C31)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Escuchar historia',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '00:00 / ${duracionMmSs(segundos)}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Container(height: 2, color: Colors.white24),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avisoEnPreparacion() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _fondoInfo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hourglass_top_rounded, size: 16, color: _azulInfo),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contenido en preparación',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _azulInfo,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Aún no hay fotos ni video de este lugar.',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fotos y videos registrados (hasta seis; el resto se resume en «+N»).
  Widget _galeria() {
    final fotos = contenido.fotos;
    final videos = contenido.videos;
    const maximo = 6;
    final total = fotos.length + videos.length;
    final mostrados = [...fotos, ...videos].take(maximo).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fotos y video',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final m in mostrados)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 82,
                  height: 58,
                  child: m.tipo == TipoMedio.video
                      ? _tileVideo()
                      : ImagenRed(url: m.url, alternativo: _tileFoto()),
                ),
              ),
            if (total > maximo)
              Container(
                width: 82,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF17181C),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A2C31)),
                ),
                child: Text(
                  '+${total - maximo}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _tileFoto() => Container(
        color: const Color(0xFF1A1E29),
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: Colors.white24),
      );

  Widget _tileVideo() => Container(
        color: const Color(0xFF1A1E29),
        alignment: Alignment.center,
        child: const Icon(Icons.play_circle_outline, color: Colors.white54),
      );
}

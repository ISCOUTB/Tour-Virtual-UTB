import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/api/api_client.dart';
import '../../data/models/enums.dart';
import '../../data/models/escena.dart';
import '../../data/models/idiomas.dart';
import '../../data/models/medio.dart';
import '../../data/models/poi.dart';
import '../../data/repositories/repositories.dart';
import '../../data/subida_panorama.dart';
import '../../domain/reglas.dart';
import '../widgets/common.dart';

/// D.1 Subir contenido de un POI.
///
/// Sube de verdad al backend:
/// - Foto 360°: POST /api/admin/escenas/{id}/imagen. Si el POI no tiene
///   escena, se crea y se marca como su escena principal.
/// - Fotos, video y audio: POST /api/admin/pois/{poiId}/medios, con texto
///   alternativo (imágenes), idioma y subtítulos .vtt (audio y video).
/// Reglas del SRS: no hay imagen sin texto alternativo ni narración sin
/// subtítulos.
class MultimediaScreen extends StatefulWidget {
  const MultimediaScreen({super.key, this.poiIdInicial, this.tipoInicial});

  final int? poiIdInicial;

  /// Pestaña con la que abre: panorama, fotos, video o audio.
  final String? tipoInicial;

  @override
  State<MultimediaScreen> createState() => _MultimediaScreenState();
}

enum _Pestana {
  panorama('Foto 360°', Icons.threesixty, ['jpg', 'jpeg', 'png', 'webp']),
  fotos('Fotos', Icons.photo_library_outlined, ['jpg', 'jpeg', 'png', 'webp']),
  video('Video', Icons.videocam_outlined, ['mp4', 'm4v', 'mov', 'webm']),
  audio('Audio narrado', Icons.audiotrack_outlined, [
    'mp3',
    'm4a',
    'aac',
    'ogg',
    'wav',
  ]);

  const _Pestana(this.etiqueta, this.icono, this.extensiones);

  final String etiqueta;
  final IconData icono;
  final List<String> extensiones;

  TipoMedio get tipo => switch (this) {
    _Pestana.video => TipoMedio.video,
    _Pestana.audio => TipoMedio.audio,
    _ => TipoMedio.imagen,
  };

  /// La panorámica la reduce el servidor, así que admite hasta 50 MB.
  int get maxBytes =>
      this == _Pestana.panorama ? 50 * 1024 * 1024 : maxBytesPara(tipo);

  bool get llevaSubtitulos => tipo != TipoMedio.imagen;
  bool get llevaTextoAlt => tipo == TipoMedio.imagen;
}

/// Archivo elegido, ya leído en memoria (en web no hay ruta de disco).
class _Elegido {
  const _Elegido(this.name, this.bytes);

  final String name;
  final Uint8List bytes;

  int get size => bytes.length;
}

/// Abre el selector (file_picker 13) y lee el archivo. Null si se cancela.
Future<_Elegido?> _elegir(List<String> extensiones) async {
  final f = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: extensiones,
  );
  if (f == null) return null;
  return _Elegido(f.name, await f.readAsBytes());
}

class _MultimediaScreenState extends State<MultimediaScreen> {
  late Future<List<Poi>> _futuroPois;
  int? _poiId;
  _Pestana _pestana = _Pestana.panorama;

  // Contenido actual del POI elegido.
  Future<(PoiDetalle, Escena?)>? _futuroContenido;

  // Formulario de subida.
  _Elegido? _archivo;
  _Elegido? _vtt;
  final _textoAlt = TextEditingController();
  String _idioma = idiomaOriginal;
  bool _subiendo = false;

  /// Sección 7 de arquitectura: las panorámicas no se publican con rostros
  /// reconocibles. El panel no difumina; pide confirmarlo antes de subir.
  bool _sinRostros = false;

  /// El POI no sale en los endpoints públicos (inactivo u oculto): no se
  /// puede leer lo que ya tiene cargado.
  bool _sinDetalle = false;

  /// Recuerda las escenas que crea, para que un reintento no cree otra.
  final _panorama = SubidaPanorama(
    escenas: escenaRepository,
    pois: poiRepository,
  );

  @override
  void initState() {
    super.initState();
    _poiId = widget.poiIdInicial;
    final inicial = _Pestana.values.asNameMap()[widget.tipoInicial];
    if (inicial != null) _pestana = inicial;
    _futuroPois = poiRepository.listar();
    if (_poiId != null) _cargarContenido();
  }

  @override
  void didUpdateWidget(covariant MultimediaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.poiIdInicial != widget.poiIdInicial &&
        widget.poiIdInicial != null) {
      setState(() {
        _poiId = widget.poiIdInicial;
        _cargarContenido();
      });
    }
  }

  @override
  void dispose() {
    _textoAlt.dispose();
    super.dispose();
  }

  void _cargarContenido() {
    final id = _poiId;
    if (id == null) {
      _futuroContenido = null;
      return;
    }
    _futuroContenido = () async {
      PoiDetalle detalle;
      try {
        detalle = await poiRepository.detalle(id);
        _sinDetalle = false;
      } on ApiException catch (e) {
        // GET /api/pois/{id} es público y esconde los lugares inactivos o
        // sin audiencias. Mientras no haya un GET de administración, se
        // trabaja con el POI de la lista de admin y sin su contenido.
        if (e.statusCode != 404) rethrow;
        final todos = await poiRepository.listar();
        final poi = todos.where((p) => p.id == id).firstOrNull;
        if (poi == null) rethrow;
        detalle = PoiDetalle(poi: poi);
        _sinDetalle = true;
      }
      Escena? escena;
      final escenaId = detalle.poi.escenaPrincipalId;
      if (escenaId != null) {
        final escenas = await escenaRepository.listar();
        escena = escenas.where((e) => e.id == escenaId).firstOrNull;
      }
      return (detalle, escena);
    }();
  }

  void _limpiarFormulario() {
    _archivo = null;
    _vtt = null;
    _textoAlt.clear();
    _idioma = idiomaOriginal;
    _sinRostros = false;
  }

  // ---------------------------------------------------------------- archivos

  Future<void> _elegirArchivo() async {
    if (_poiId == null) {
      showToast(
        context,
        'Selecciona un POI destino antes de subir.',
        error: true,
      );
      return;
    }
    final f = await _elegir(_pestana.extensiones);
    if (f == null || !mounted) return;
    if (f.size > _pestana.maxBytes) {
      showToast(
        context,
        'El archivo pesa ${(f.size / 1048576).toStringAsFixed(1)} MB; el '
        'máximo para ${_pestana.etiqueta.toLowerCase()} es '
        '${_pestana.maxBytes ~/ 1048576} MB.',
        error: true,
      );
      return;
    }
    setState(() => _archivo = f);
  }

  Future<void> _elegirVtt() async {
    final f = await _elegir(const ['vtt']);
    if (f == null || !mounted) return;
    final inicio = String.fromCharCodes(
      f.bytes.take(16),
    ).replaceFirst('﻿', '').replaceFirst('ï»¿', '');
    if (!inicio.startsWith('WEBVTT')) {
      showToast(
        context,
        'Ese archivo no es WebVTT: la primera línea debe ser WEBVTT.',
        error: true,
      );
      return;
    }
    setState(() => _vtt = f);
  }

  /// Mensaje de lo que falta para poder subir, o null si está completo.
  String? _faltante(List<Medio> medios) {
    if (_archivo == null) return 'Elige un archivo';
    if (_pestana.llevaTextoAlt && _textoAlt.text.trim().isEmpty) {
      return 'Escribe el texto alternativo';
    }
    if (_pestana == _Pestana.panorama && !_sinRostros) {
      return 'Confirma que no hay rostros reconocibles';
    }
    if (_pestana.llevaSubtitulos && _vtt == null) {
      return 'Adjunta los subtítulos (.vtt)';
    }
    if (_pestana == _Pestana.audio &&
        medios.any(
          (m) =>
              m.tipo == TipoMedio.audio &&
              (m.idioma ?? idiomaOriginal) == _idioma,
        )) {
      return 'Ya hay una narración en ${nombreDeIdioma(_idioma)}';
    }
    return null;
  }

  // ------------------------------------------------------------------ subir

  Future<void> _subir(PoiDetalle detalle, Escena? escena) async {
    final archivo = ArchivoSubida('Archivo', _archivo!.bytes, _archivo!.name);
    setState(() => _subiendo = true);
    try {
      if (_pestana == _Pestana.panorama) {
        final advertencia = await _panorama.subir(
          poi: detalle.poi,
          escena: escena,
          bytes: archivo.bytes,
          nombreArchivo: archivo.nombre,
          textoAlt: _textoAlt.text,
        );
        if (advertencia != null && mounted) {
          showToast(context, advertencia, error: true);
        }
      } else {
        final mismos = detalle.medios
            .where((m) => m.tipo == _pestana.tipo)
            .length;
        await medioRepository.subir(
          poiId: detalle.poi.id,
          tipo: _pestana.tipo,
          archivo: archivo,
          orden: mismos,
          textoAlt: _pestana.llevaTextoAlt ? _textoAlt.text : null,
          idioma: _pestana.llevaSubtitulos ? _idioma : null,
          subtitulos: _vtt == null
              ? null
              : ArchivoSubida('Subtitulos', _vtt!.bytes, _vtt!.name),
        );
      }
      if (!mounted) return;
      showToast(context, '${_pestana.etiqueta} subido correctamente');
      setState(() {
        _limpiarFormulario();
        _futuroPois = poiRepository.listar();
        _cargarContenido();
      });
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  Future<void> _eliminar(Medio m) async {
    final ok = await confirmDialog(
      context,
      title: '¿Eliminar este archivo?',
      message: 'Se quitará del POI y dejará de verse en la app.',
      confirmLabel: 'Eliminar',
      danger: true,
    );
    if (!ok || !mounted) return;
    try {
      await medioRepository.eliminar(m.id);
      if (!mounted) return;
      showToast(context, 'Archivo eliminado');
      setState(_cargarContenido);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    }
  }

  // --------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return ScrollPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            icon: Icons.cloud_upload_outlined,
            title: 'Subir Multimedia',
            subtitle: 'Carga el contenido de cada POI',
          ),
          if (AppConfig.useMockData) ...[
            const SizedBox(height: 20),
            const SampleDataBanner(
              'Modo maqueta: los archivos no se envían al servidor.',
            ),
          ],
          const SizedBox(height: 20),
          FutureBuilder<List<Poi>>(
            future: _futuroPois,
            builder: (context, snap) {
              if (snap.hasError) {
                return ErrorCard(
                  message: '${snap.error}',
                  onRetry: () => setState(() {
                    _futuroPois = poiRepository.listar();
                  }),
                );
              }
              if (!snap.hasData) return const SkeletonBox(height: 52);
              return _selectorPoi(snap.data!);
            },
          ),
          const SizedBox(height: 20),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UnderlineTabs(
                  labels: [for (final p in _Pestana.values) p.etiqueta],
                  selected: _pestana.index,
                  onSelected: (i) => setState(() {
                    _pestana = _Pestana.values[i];
                    _limpiarFormulario();
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _futuroContenido == null
                      ? const EmptyState(
                          message: 'Selecciona un POI destino para empezar',
                        )
                      : FutureBuilder<(PoiDetalle, Escena?)>(
                          future: _futuroContenido,
                          builder: (context, snap) {
                            if (snap.hasError) {
                              return ErrorCard(
                                message: '${snap.error}',
                                onRetry: () => setState(_cargarContenido),
                              );
                            }
                            if (!snap.hasData) {
                              return const SkeletonBox(height: 200);
                            }
                            final (detalle, escena) = snap.data!;
                            return _contenido(detalle, escena);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectorPoi(List<Poi> pois) {
    final valido = pois.any((p) => p.id == _poiId);
    return Row(
      children: [
        const Text(
          'POI destino',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 16),
        SelectBox<int>(
          width: 320,
          value: valido ? _poiId! : -1,
          items: {
            -1: 'Selecciona un POI',
            for (final p in pois) p.id: '${p.id} · ${p.nombre}',
          },
          onChanged: (v) => setState(() {
            _poiId = v == -1 ? null : v;
            _limpiarFormulario();
            _cargarContenido();
          }),
        ),
      ],
    );
  }

  Widget _contenido(PoiDetalle detalle, Escena? escena) {
    final actuales = _pestana == _Pestana.panorama
        ? <Widget>[_estadoPanorama(escena)]
        : [
            for (final m in detalle.medios.where(
              (m) => m.tipo == _pestana.tipo,
            ))
              _filaMedio(m),
          ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final formulario = _formulario(detalle, escena);
        final lista = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ya cargado',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_sinDetalle)
              const Text(
                'Este lugar está inactivo o sin perfiles visibles: la API aún '
                'no deja leer su contenido desde el panel. Se puede subir, '
                'pero aquí no se verá hasta activarlo.',
                style: TextStyle(color: AppColors.warning),
              )
            else if (actuales.isEmpty)
              const Text(
                'Aún no hay archivos de este tipo.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              ...actuales,
          ],
        );
        if (constraints.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: formulario),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: lista),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [formulario, const SizedBox(height: 24), lista],
        );
      },
    );
  }

  Widget _formulario(PoiDetalle detalle, Escena? escena) {
    final faltante = _faltante(detalle.medios);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _subiendo ? null : _elegirArchivo,
          child: DashedBox(
            color: AppColors.primary,
            child: Container(
              height: 130,
              width: double.infinity,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_pestana.icono, size: 34, color: AppColors.primary),
                  const SizedBox(height: 10),
                  Text(
                    _archivo == null
                        ? 'Haz clic para elegir el archivo'
                        : '${_archivo!.name} · '
                              '${(_archivo!.size / 1048576).toStringAsFixed(1)} MB',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_pestana.extensiones.map((e) => e.toUpperCase()).join(', ')}'
                    ' · máx. ${_pestana.maxBytes ~/ 1048576} MB'
                    '${_pestana == _Pestana.panorama ? ' · proporción 2:1' : ''}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_pestana.llevaTextoAlt)
          TextField(
            controller: _textoAlt,
            maxLines: 2,
            maxLength: 300,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Texto alternativo (obligatorio)',
              hintText: _pestana == _Pestana.panorama
                  ? 'Describe lo que se ve en la panorámica'
                  : 'Describe lo que muestra la foto',
            ),
          ),
        if (_pestana.llevaSubtitulos) ...[
          Row(
            children: [
              const Text(
                'Idioma hablado',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              SelectBox<String>(
                width: 280,
                value: _idioma,
                items: {
                  for (final e in idiomasContenido.entries)
                    if (e.key != 'csn' || _pestana == _Pestana.video)
                      e.key: e.value,
                },
                onChanged: (v) => setState(() => _idioma = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _subiendo ? null : _elegirVtt,
                icon: const Icon(Icons.subtitles_outlined, size: 18),
                label: const Text('Adjuntar subtítulos (.vtt)'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _vtt?.name ?? 'Obligatorio, en el mismo idioma del audio',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _vtt == null
                        ? AppColors.textSecondary
                        : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (_pestana == _Pestana.panorama) ...[
          const SizedBox(height: 4),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _sinRostros,
            onChanged: (v) => setState(() => _sinRostros = v ?? false),
            title: const Text(
              'La panorámica no muestra rostros reconocibles, o ya están '
              'difuminados',
            ),
            subtitle: const Text(
              'El panel no difumina rostros: hazlo antes de subirla '
              '(sección 7 de arquitectura).',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _subiendo || faltante != null
                  ? null
                  : () => _subir(detalle, escena),
              icon: _subiendo
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined, size: 18),
              label: Text(_subiendo ? 'Subiendo…' : 'Subir y publicar'),
            ),
            const SizedBox(width: 12),
            if (faltante != null && _archivo != null)
              Expanded(
                child: Text(
                  faltante,
                  style: const TextStyle(color: AppColors.warning),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _estadoPanorama(Escena? escena) {
    final tiene = escena?.imagenUrl?.isNotEmpty ?? false;
    final alt = escena?.textoAlt?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            StatusBadge(
              escena == null
                  ? 'Sin escena 360°'
                  : tiene
                  ? 'Panorámica cargada'
                  : 'Escena sin panorámica',
              color: tiene ? AppColors.success : AppColors.warning,
            ),
            if (escena != null)
              StatusBadge(
                alt.isEmpty ? 'Falta texto alternativo' : 'Texto alternativo',
                color: alt.isEmpty ? AppColors.danger : AppColors.success,
              ),
          ],
        ),
        if (alt.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            alt,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          tiene
              ? 'Subir otra imagen reemplaza la panorámica actual.'
              : 'Al subirla, el lugar aparece numerado en el recorrido.',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _filaMedio(Medio m) {
    final nombre = (m.url ?? '').split('/').last.split('?').first;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(_pestana.icono, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.tipo == TipoMedio.imagen
                      ? (m.textoAlt ?? nombre)
                      : nombreDeIdioma(m.idioma),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  nombre,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (m.tipo != TipoMedio.imagen) ...[
            const SizedBox(width: 8),
            StatusBadge(
              m.subtitulosUrl == null ? 'Sin subtítulos' : 'Con subtítulos',
              color: m.subtitulosUrl == null
                  ? AppColors.warning
                  : AppColors.success,
            ),
          ],
          IconButton(
            tooltip: 'Eliminar',
            onPressed: () => _eliminar(m),
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

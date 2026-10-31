import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/enums.dart';
import '../../data/models/poi.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/reglas.dart';
import '../widgets/common.dart';

enum _Estado { subiendo, completado, error }

class _Archivo {
  _Archivo({
    required this.nombre,
    required this.pestana,
    required this.tamanoMb,
    this.progreso = 0,
    this.estado = _Estado.subiendo,
  });

  final String nombre;
  final int pestana;
  final double tamanoMb;
  double progreso;
  _Estado estado;
}

const List<String> _etiquetas = ['Foto 360°', 'Fotos', 'Video', 'Audio narrado'];
const List<IconData> _iconos = [
  Icons.threesixty,
  Icons.photo_library_outlined,
  Icons.videocam_outlined,
  Icons.audiotrack_outlined,
];
const List<TipoMedio> _tipos = [
  TipoMedio.imagen,
  TipoMedio.imagen,
  TipoMedio.video,
  TipoMedio.audio,
];
const List<String> _formatos = [
  'JPG o PNG · proporción 2:1',
  'JPG o PNG',
  'MP4',
  'MP3',
];

/// D.1 Subir y previsualizar contenido.
///
/// En esta versión la subida es simulada (no se envía nada al servidor): sirve
/// para ver el diseño. Al conectar el backend, cada archivo se envía con
/// medioRepository.crear() + subirArchivo() (o escenaRepository para la 360°).
class MultimediaScreen extends StatefulWidget {
  const MultimediaScreen({super.key, this.poiIdInicial});

  final int? poiIdInicial;

  @override
  State<MultimediaScreen> createState() => _MultimediaScreenState();
}

class _MultimediaScreenState extends State<MultimediaScreen> {
  late Future<List<Poi>> _futuroPois;
  int? _poiId;
  int _pestana = 0;
  bool _publicado = false;
  _Archivo? _seleccionado;
  final List<Timer> _timers = [];
  int _contador = 0;

  // Empieza vacía: no se muestran archivos inventados. Los medios reales de
  // cada POI se leerán de GET /api/pois/{id} al conectar el backend.
  final List<_Archivo> _archivos = [];

  @override
  void initState() {
    super.initState();
    _poiId = widget.poiIdInicial;
    _futuroPois = poiRepository.listar();
    _seleccionado = _archivos.isEmpty ? null : _archivos.first;
  }

  @override
  void didUpdateWidget(covariant MultimediaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.poiIdInicial != widget.poiIdInicial &&
        widget.poiIdInicial != null) {
      setState(() => _poiId = widget.poiIdInicial);
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _simularSubida(_Archivo archivo) {
    archivo.estado = _Estado.subiendo;
    archivo.progreso = 0;
    late Timer timer;
    timer = Timer.periodic(const Duration(milliseconds: 220), (_) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        archivo.progreso += 0.1;
        if (archivo.progreso >= 1) {
          archivo.progreso = 1;
          archivo.estado = _Estado.completado;
          timer.cancel();
        }
      });
    });
    _timers.add(timer);
  }

  void _agregarArchivo() {
    final tipo = _tipos[_pestana];
    const extensiones = ['jpg', 'jpg', 'mp4', 'mp3'];
    _contador++;
    final nombre = 'archivo_simulado_$_contador.${extensiones[_pestana]}';
    final tamano = switch (tipo) {
      TipoMedio.imagen => 3.0,
      TipoMedio.video => 40.0,
      TipoMedio.audio => 4.0,
    };
    final error = validarTamano(tipo, (tamano * 1024 * 1024).round());
    if (error != null) {
      showToast(context, error, error: true);
      return;
    }
    final archivo = _Archivo(
      nombre: nombre,
      pestana: _pestana,
      tamanoMb: tamano,
    );
    setState(() {
      _archivos.add(archivo);
      _seleccionado = archivo;
      _publicado = false;
    });
    _simularSubida(archivo);
  }

  Future<void> _descartar() async {
    final ok = await confirmDialog(
      context,
      title: '¿Descartar los archivos en borrador?',
      message: 'Se eliminarán los archivos subidos que aún no se han publicado.',
      confirmLabel: 'Descartar',
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() {
      _archivos.clear();
      _seleccionado = null;
    });
    showToast(context, 'Borrador descartado');
  }

  void _publicar() {
    final hayCompletos =
        _archivos.any((a) => a.estado == _Estado.completado);
    if (!hayCompletos) {
      showToast(context, 'No hay archivos completados para publicar.',
          error: true);
      return;
    }
    setState(() => _publicado = true);
    showToast(context, 'Contenido publicado');
  }

  @override
  Widget build(BuildContext context) {
    return ScrollPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            icon: Icons.cloud_upload_outlined,
            title: 'Subir Multimedia',
            subtitle: 'Carga el contenido de cada POI y revisa cómo se verá',
          ),
          const SizedBox(height: 20),
          const SampleDataBanner(
            'Vista de diseño: la subida es simulada. No se envía nada al servidor.',
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Poi>>(
            future: _futuroPois,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SkeletonBox(height: 52);
              }
              if (snapshot.hasError) {
                return ErrorCard(
                  message: '${snapshot.error}',
                  onRetry: () => setState(() {
                    _futuroPois = poiRepository.listar();
                  }),
                );
              }
              return _selectorPoi(snapshot.data ?? const []);
            },
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final izquierda = _panelSubida();
              final derecha = _panelPrevia();
              if (constraints.maxWidth >= 1000) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: izquierda),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: derecha),
                  ],
                );
              }
              return Column(
                children: [izquierda, const SizedBox(height: 16), derecha],
              );
            },
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 12,
              children: [
                OutlinedButton(
                  onPressed: _archivos.isEmpty ? null : _descartar,
                  child: const Text('Descartar'),
                ),
                ElevatedButton(
                  onPressed: _archivos.isEmpty ? null : _publicar,
                  child: const Text('Publicar contenido'),
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
        const Text('POI destino', style: TextStyle(fontWeight: FontWeight.w600)),
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
          }),
        ),
      ],
    );
  }

  Widget _panelSubida() {
    final habilitado = _poiId != null;
    final tipo = _tipos[_pestana];
    final maxMb = maxBytesPara(tipo) ~/ (1024 * 1024);
    final lista = _archivos.where((a) => a.pestana == _pestana).toList();
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UnderlineTabs(
            labels: _etiquetas,
            selected: _pestana,
            onSelected: (i) => setState(() => _pestana = i),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: habilitado
                      ? _agregarArchivo
                      : () => showToast(
                            context,
                            'Selecciona un POI destino antes de subir.',
                            error: true,
                          ),
                  child: DashedBox(
                    color: habilitado
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: habilitado ? 1 : 0.5,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_iconos[_pestana],
                                size: 36, color: AppColors.primary),
                            const SizedBox(height: 10),
                            Text(
                              habilitado
                                  ? 'Arrastra archivos o haz clic para '
                                      'seleccionar'
                                  : 'Selecciona un POI destino para subir',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatos[_pestana]} · máx. $maxMb MB',
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
                ),
                const SizedBox(height: 16),
                if (lista.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Aún no hay archivos de este tipo.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  for (final archivo in lista) _filaArchivo(archivo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaArchivo(_Archivo a) {
    final seleccionado = identical(a, _seleccionado);
    final Color color;
    final String etiqueta;
    switch (a.estado) {
      case _Estado.completado:
        color = AppColors.success;
        etiqueta = 'Completado';
      case _Estado.subiendo:
        color = AppColors.primary;
        etiqueta = '${(a.progreso * 100).round()}%';
      case _Estado.error:
        color = AppColors.danger;
        etiqueta = 'Error';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: seleccionado ? AppColors.primary.withValues(alpha: 0.08) : null,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: seleccionado ? AppColors.primary : AppColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _seleccionado = a),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(_iconos[a.pestana], color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.nombre,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: a.progreso,
                        minHeight: 6,
                        backgroundColor: AppColors.border,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                etiqueta,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
              if (a.estado == _Estado.error) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _simularSubida(a),
                  child: const Text('Reintentar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _panelPrevia() {
    final a = _seleccionado;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Previsualización',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: a == null ? _previaVacia() : _previaArchivo(a),
          ),
          const SizedBox(height: 14),
          StatusBadge(
            _publicado ? 'Publicado' : 'Contenido en preparación',
            color: _publicado ? AppColors.success : AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _previaVacia() => const Center(
        child: Text(
          'Selecciona un archivo',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );

  Widget _previaArchivo(_Archivo a) {
    switch (_tipos[a.pestana]) {
      case TipoMedio.audio:
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_fill,
                  size: 48, color: AppColors.primary),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.25,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '0:34 / 2:15',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      case TipoMedio.video:
        return const Center(
          child: Icon(Icons.play_circle_outline,
              size: 56, color: AppColors.textSecondary),
        );
      case TipoMedio.imagen:
        final es360 = a.pestana == 0;
        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.35),
                      AppColors.purple.withValues(alpha: 0.35),
                    ],
                  ),
                ),
                child: Icon(
                  es360 ? Icons.threesixty : Icons.image_outlined,
                  size: 52,
                  color: Colors.white70,
                ),
              ),
            ),
            if (es360)
              const Positioned(
                left: 10,
                top: 10,
                child: StatusBadge('360°', color: Colors.white),
              ),
            if (es360)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Center(
                  child: Text(
                    'Desliza para mirar',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ),
          ],
        );
    }
  }
}

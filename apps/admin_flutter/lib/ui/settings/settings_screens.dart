import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_state.dart';
import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/api/api_client.dart';
import '../../data/repositories/repositories.dart';
import '../widgets/common.dart';

const List<String> _pestanas = [
  'Cuenta',
  'Administradores',
  'Seguridad',
];
const List<String> _rutas = [
  '/configuracion/cuenta',
  '/configuracion/administradores',
  '/configuracion/seguridad',
];

/// Cabecera común de Configuración y pestañas (guía, área F).
class ConfigShell extends StatelessWidget {
  const ConfigShell({super.key, required this.activa, required this.child});

  final int activa;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                icon: Icons.settings_outlined,
                title: 'Configuración',
                subtitle:
                    'Gestiona los administradores y la configuración del tour virtual',
              ),
              const SizedBox(height: 20),
              UnderlineTabs(
                labels: _pestanas,
                selected: activa,
                onSelected: (i) => context.go(_rutas[i]),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// F.1 Cuenta
// ---------------------------------------------------------------------------

/// Datos de la sesión actual. El perfil vive en Supabase (auth + perfiles);
/// aquí solo se muestra. La contraseña se cambia en la pestaña Seguridad.
class CuentaTab extends StatelessWidget {
  const CuentaTab({super.key});

  @override
  Widget build(BuildContext context) {
    final iniciales = authState.nombre.isEmpty
        ? '?'
        : authState.nombre.substring(0, 1).toUpperCase();

    final perfil = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Perfil', style: _tituloTarjeta),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary,
                child: Text(
                  iniciales,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authState.nombre,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      authState.correo,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.lock_outline,
                  size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cuenta institucional UTB. Para cambiar tu contraseña ve a '
                  'la pestaña Seguridad.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final rol = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rol y permisos', style: _tituloTarjeta),
          const SizedBox(height: 12),
          const StatusBadge('Administrador', color: AppColors.primary),
          const SizedBox(height: 12),
          for (final p in const [
            'Gestionar POIs',
            'Subir multimedia',
            'Ver métricas',
            'Administrar usuarios',
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      size: 18, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(p),
                ],
              ),
            ),
        ],
      ),
    );

    return ScrollPage(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1000) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: perfil),
                const SizedBox(width: 16),
                Expanded(child: rol),
              ],
            );
          }
          return Column(
            children: [perfil, const SizedBox(height: 16), rol],
          );
        },
      ),
    );
  }
}

const TextStyle _tituloTarjeta =
    TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

// ---------------------------------------------------------------------------
// F.2 Administradores
// ---------------------------------------------------------------------------

/// Lista las personas con rol admin en `perfiles` (GET /api/admin/administradores)
/// y da o quita el rol (PUT /api/admin/administradores/{userId}). Las cuentas
/// se crean en Supabase (Authentication > Users); aquí solo se cambia el rol.
/// La API impide quitarse el rol a uno mismo y quitar el último admin.
class AdministradoresTab extends StatefulWidget {
  const AdministradoresTab({super.key});

  @override
  State<AdministradoresTab> createState() => _AdministradoresTabState();
}

class _AdministradoresTabState extends State<AdministradoresTab> {
  late Future<List<Perfil>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = panelRepository.administradores();
  }

  void _recargar() =>
      setState(() => _futuro = panelRepository.administradores());

  Future<void> _darAcceso() async {
    final correo = await showDialog<String>(
      context: context,
      builder: (context) => const _InvitarDialog(),
    );
    if (correo == null || !mounted) return;
    try {
      final perfiles = await panelRepository.administradores(todos: true);
      final perfil =
          perfiles.where((p) => p.correo?.toLowerCase() == correo).firstOrNull;
      if (!mounted) return;
      if (perfil == null) {
        showToast(
          context,
          'Esa persona aún no tiene cuenta. Créala primero en Supabase '
          '(Authentication > Users) y vuelve a intentarlo.',
          error: true,
        );
        return;
      }
      if (perfil.rol == 'admin') {
        showToast(context, 'Ese correo ya tiene acceso.', error: true);
        return;
      }
      await panelRepository.cambiarRol(perfil.userId, 'admin');
      if (!mounted) return;
      showToast(context, 'Acceso de administrador otorgado');
      _recargar();
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    }
  }

  Future<void> _quitar(Perfil admin) async {
    final ok = await confirmDialog(
      context,
      title: '¿Quitar el acceso a ${admin.correo ?? 'esta persona'}?',
      message: 'Esta persona ya no podrá entrar al panel.',
      confirmLabel: 'Quitar acceso',
      danger: true,
    );
    if (!ok || !mounted) return;
    try {
      // Vuelve al rol por defecto de la app (visitante externo).
      await panelRepository.cambiarRol(admin.userId, 'externo');
      if (!mounted) return;
      showToast(context, 'Acceso revocado');
      _recargar();
    } on ApiException catch (e) {
      // 409: es uno mismo o el último admin (el mensaje lo da la API).
      if (mounted) showToast(context, e.message, error: true);
    }
  }

  Widget _fila(Perfil a) {
    final correo = a.correo ?? '(sin correo)';
    final esActual = correo.toLowerCase() == authState.correo.toLowerCase();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Text(correo.substring(0, 1).toUpperCase()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              esActual ? '$correo (tú)' : correo,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          StatusBadge(
            a.verificado ? 'Verificado' : 'Sin verificar',
            color: a.verificado ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 8),
          const StatusBadge('Administrador', color: AppColors.primary),
          const SizedBox(width: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.danger),
              foregroundColor: AppColors.danger,
            ),
            onPressed: esActual ? null : () => _quitar(a),
            child: const Text('Quitar acceso'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollPage(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabla = AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Administradores', style: _tituloTarjeta),
                          SizedBox(height: 2),
                          Text(
                            'Personas con acceso al panel',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _darAcceso,
                      icon: const Icon(Icons.person_add_alt, size: 18),
                      label: const Text('Dar acceso'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<Perfil>>(
                  future: _futuro,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return ErrorCard(
                        message: 'No se pudo cargar la lista: ${snap.error}',
                        onRetry: _recargar,
                      );
                    }
                    if (!snap.hasData) return const SkeletonBox(height: 160);
                    final admins = snap.data!;
                    if (admins.isEmpty) {
                      return const EmptyState(
                        message: 'Sin administradores para mostrar '
                            '(en modo maqueta la lista está vacía).',
                      );
                    }
                    return Column(children: [for (final a in admins) _fila(a)]);
                  },
                ),
              ],
            ),
          );

          const info = AppCard(
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Las cuentas se crean en Supabase (Authentication > '
                    'Users). Aquí solo se da o se quita el rol de '
                    'administrador.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          );

          if (constraints.maxWidth >= 1000) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: tabla),
                const SizedBox(width: 16),
                const Expanded(flex: 1, child: info),
              ],
            );
          }
          return Column(
            children: [tabla, const SizedBox(height: 16), info],
          );
        },
      ),
    );
  }
}

/// Pide el correo institucional; devuelve el correo en minúsculas.
class _InvitarDialog extends StatefulWidget {
  const _InvitarDialog();

  @override
  State<_InvitarDialog> createState() => _InvitarDialogState();
}

class _InvitarDialogState extends State<_InvitarDialog> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();

  @override
  void dispose() {
    _correo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dar acceso de administrador'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _correo,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              final t = (v ?? '').trim().toLowerCase();
              if (t.isEmpty) return 'El correo es obligatorio';
              if (!t.endsWith(AuthState.dominio)) {
                return 'Usa un correo ${AuthState.dominio}';
              }
              return null;
            },
            decoration: const InputDecoration(
              labelText: 'Correo institucional',
              hintText: 'nombre@utb.edu.co',
              helperText: 'La persona ya debe tener cuenta en Supabase.',
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(_correo.text.trim().toLowerCase());
          },
          child: const Text('Dar acceso'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// F.3 Apariencia del tour
//
// FUERA DEL PANEL (15/11/2026): no hay backend que guarde esta configuración
// ni la app móvil la lee. Se deja el diseño por si se conecta más adelante;
// para volver a mostrarla, agregarla a _pestanas/_rutas y a app_router.dart.
// ---------------------------------------------------------------------------

class AparienciaTab extends StatefulWidget {
  const AparienciaTab({super.key});

  @override
  State<AparienciaTab> createState() => _AparienciaTabState();
}

class _AparienciaTabState extends State<AparienciaTab> {
  static const String _tituloDefecto = 'Conoce la UTB';
  static const String _subtituloDefecto = 'Recorrido institucional para visitantes';
  static const Color _acentoDefecto = AppColors.primary;
  static const List<Color> _paleta = [
    Color(0xFF2347D6),
    Color(0xFF3DDC84),
    Color(0xFF8B5CF6),
    Color(0xFFF5A524),
    Color(0xFFE5484D),
    Color(0xFF14B8A6),
  ];

  final _titulo = TextEditingController(text: _tituloDefecto);
  final _subtitulo = TextEditingController(text: _subtituloDefecto);
  final _hex = TextEditingController(text: '#2347D6');
  Color _acento = _acentoDefecto;
  bool _progreso = true;
  bool _mapa = true;
  bool _compartir = true;
  bool _audio = true;
  String _estiloMapa = 'iso';
  String _vista = 'inicio';

  @override
  void initState() {
    super.initState();
    _titulo.addListener(() => setState(() {}));
    _subtitulo.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titulo.dispose();
    _subtitulo.dispose();
    _hex.dispose();
    super.dispose();
  }

  String _aHex(Color c) {
    final v = c.toARGB32() & 0xFFFFFF;
    return '#${v.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  void _alEscribirHex(String texto) {
    final limpio = texto.trim().replaceFirst('#', '');
    if (limpio.length != 6) return;
    final valor = int.tryParse(limpio, radix: 16);
    if (valor == null) return;
    setState(() => _acento = Color(0xFF000000 | valor));
  }

  void _elegirColor(Color c) {
    setState(() {
      _acento = c;
      _hex.text = _aHex(c);
    });
  }

  Future<void> _restablecer() async {
    final ok = await confirmDialog(
      context,
      title: '¿Restablecer los valores?',
      message: 'Se perderán los cambios que no hayas guardado.',
      confirmLabel: 'Restablecer',
      danger: true,
    );
    if (!ok || !mounted) return;
    _titulo.text = _tituloDefecto;
    _subtitulo.text = _subtituloDefecto;
    _elegirColor(_acentoDefecto);
    setState(() {
      _progreso = true;
      _mapa = true;
      _compartir = true;
      _audio = true;
      _estiloMapa = 'iso';
    });
  }

  Widget _interruptor(String texto, bool valor, ValueChanged<bool> alCambiar) {
    return Row(
      children: [
        Switch(value: valor, onChanged: (v) => setState(() => alCambiar(v))),
        const SizedBox(width: 10),
        Expanded(child: Text(texto)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ScrollPage(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final identidad = AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Identidad', style: _tituloTarjeta),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _titulo,
                        maxLength: 40,
                        decoration:
                            const InputDecoration(labelText: 'Título del tour'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _subtitulo,
                        maxLength: 90,
                        decoration:
                            const InputDecoration(labelText: 'Subtítulo'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.image_outlined,
                                color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 14),
                          OutlinedButton(
                            onPressed: () => showToast(context,
                                'La carga del logo se activa al conectar el servicio de archivos.'),
                            child: const Text('Subir logo'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                final colores = AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Colores', style: _tituloTarjeta),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _acento,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 140,
                            child: TextField(
                              controller: _hex,
                              onChanged: _alEscribirHex,
                              decoration: const InputDecoration(
                                labelText: 'Color de acento',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in _paleta)
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _elegirColor(c),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: c == _acento
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Colores por categoría',
                          style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      for (final cat in AppColors.categoriasCampus)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: AppColors.categoria(cat),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(cat),
                            ],
                          ),
                        ),
                    ],
                  ),
                );

                final inicio = AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pantalla de inicio', style: _tituloTarjeta),
                      const SizedBox(height: 8),
                      _interruptor('Mostrar progreso del tour', _progreso,
                          (v) => _progreso = v),
                      _interruptor(
                          'Mostrar pestaña Mapa', _mapa, (v) => _mapa = v),
                      _interruptor('Permitir compartir recorrido', _compartir,
                          (v) => _compartir = v),
                      _interruptor(
                          'Mostrar audio narrado', _audio, (v) => _audio = v),
                    ],
                  ),
                );

                final mapa = AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mapa', style: _tituloTarjeta),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'iso', label: Text('Isométrico 3D')),
                          ButtonSegment(value: 'sat', label: Text('Satelital')),
                        ],
                        selected: {_estiloMapa},
                        onSelectionChanged: (s) =>
                            setState(() => _estiloMapa = s.first),
                      ),
                    ],
                  ),
                );

                final previa = AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Vista previa', style: _tituloTarjeta),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'inicio', label: Text('Inicio')),
                          ButtonSegment(value: 'mapa', label: Text('Mapa')),
                          ButtonSegment(
                              value: 'detalle', label: Text('Detalle')),
                        ],
                        selected: {_vista},
                        onSelectionChanged: (s) =>
                            setState(() => _vista = s.first),
                      ),
                      const SizedBox(height: 16),
                      Center(child: _telefono()),
                    ],
                  ),
                );

                if (constraints.maxWidth >= 1000) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            identidad,
                            const SizedBox(height: 16),
                            colores,
                            const SizedBox(height: 16),
                            inicio,
                            const SizedBox(height: 16),
                            mapa,
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: previa),
                    ],
                  );
                }
                return Column(
                  children: [
                    identidad,
                    const SizedBox(height: 16),
                    colores,
                    const SizedBox(height: 16),
                    inicio,
                    const SizedBox(height: 16),
                    mapa,
                    const SizedBox(height: 16),
                    previa,
                  ],
                );
              },
            ),
          ),
        ),
        SaveBar(
          children: [
            OutlinedButton(
              onPressed: _restablecer,
              child: const Text('Restablecer valores'),
            ),
            OutlinedButton(
              onPressed: () => showToast(context, 'Borrador guardado'),
              child: const Text('Guardar borrador'),
            ),
            ElevatedButton(
              onPressed: () => showToast(context, 'Cambios publicados'),
              child: const Text('Publicar cambios'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _telefono() {
    final titulo = _titulo.text.trim().isEmpty ? 'Título del tour' : _titulo.text;
    final subtitulo = _subtitulo.text;
    final List<Widget> contenido;
    switch (_vista) {
      case 'mapa':
        contenido = [
          Container(
            height: 300,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Icon(Icons.map_outlined, size: 48, color: _acento),
            ),
          ),
        ];
      case 'detalle':
        contenido = [
          Container(
            height: 150,
            color: _acento.withValues(alpha: 0.3),
            child: const Center(child: Icon(Icons.threesixty, size: 44)),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nombre del POI',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Descripción del punto de interés.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                if (_audio) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.play_circle_fill, color: _acento),
                      const SizedBox(width: 8),
                      const Text('Audio narrado',
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ];
      default:
        contenido = [
          Container(
            padding: const EdgeInsets.all(16),
            color: _acento,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitulo, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          if (_progreso)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Progreso del tour: 0/5',
                    style: TextStyle(fontSize: 12)),
              ),
            ),
          if (_mapa)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.map_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Mapa', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          if (_compartir)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.share_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Compartir recorrido', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
        ];
    }
    return PhoneFrame(
      width: 250,
      height: 480,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: contenido,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// F.4 Seguridad
// ---------------------------------------------------------------------------

/// Todo lo de esta pestaña es real: la contraseña y las sesiones van contra
/// Supabase Auth, y el registro sale de la tabla auditoria
/// (GET /api/admin/actividad). Dar o quitar accesos está en Administradores.
class SeguridadTab extends StatefulWidget {
  const SeguridadTab({super.key});

  @override
  State<SeguridadTab> createState() => _SeguridadTabState();
}

class _SeguridadTabState extends State<SeguridadTab> {
  final _formKey = GlobalKey<FormState>();
  final _nueva = TextEditingController();
  final _repetir = TextEditingController();
  bool _guardando = false;
  late Future<List<Actividad>> _registro;

  @override
  void initState() {
    super.initState();
    _registro = panelRepository.actividad(tamano: 15);
  }

  @override
  void dispose() {
    _nueva.dispose();
    _repetir.dispose();
    super.dispose();
  }

  Future<void> _cambiarClave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final error = await authState.cambiarClave(_nueva.text);
    if (!mounted) return;
    setState(() => _guardando = false);
    if (error != null) {
      showToast(context, error, error: true);
      return;
    }
    _nueva.clear();
    _repetir.clear();
    showToast(context, 'Contraseña actualizada');
  }

  Future<void> _cerrarTodas() async {
    final ok = await confirmDialog(
      context,
      title: '¿Cerrar sesión en todos los dispositivos?',
      message: 'Todas tus sesiones, incluida esta, se cerrarán.',
      confirmLabel: 'Cerrar sesiones',
      danger: true,
    );
    if (!ok) return;
    await authState.cerrarSesionGlobal();
  }

  static String _fechaHora(DateTime f) {
    String d(int n) => n.toString().padLeft(2, '0');
    return '${d(f.day)}/${d(f.month)}/${f.year} ${d(f.hour)}:${d(f.minute)}';
  }

  Widget _filaRegistro(Actividad a) {
    final (icono, verbo) = switch (a.accion) {
      'insert' => (Icons.add_circle_outline, 'Creó'),
      'delete' => (Icons.delete_outline, 'Eliminó'),
      _ => (Icons.edit_outlined, 'Editó'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(icono, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              '$verbo ${a.entidad}'
              '${a.entidadId == null ? '' : ' #${a.entidadId}'}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              a.actorCorreo ?? 'Sistema o clave de administración',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(
            _fechaHora(a.fecha),
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final real = AppConfig.loginReal;
    return ScrollPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!real) ...[
            const SampleDataBanner(
              'Sin inicio de sesión real: la contraseña y las sesiones se '
              'activan al correr el panel con SUPABASE_ANON_KEY.',
            ),
            const SizedBox(height: 16),
          ],
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined,
                    color: AppColors.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Autenticación', style: _tituloTarjeta),
                      const SizedBox(height: 2),
                      Text(
                        real
                            ? 'Supabase Auth · ${authState.correo}'
                            : 'Modo de prueba · ${authState.correo}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (real)
                  const StatusBadge('Sesión verificada',
                      color: AppColors.success),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cambiar contraseña', style: _tituloTarjeta),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nueva,
                          obscureText: true,
                          enabled: real,
                          validator: (v) => (v ?? '').length < 8
                              ? 'Mínimo 8 caracteres'
                              : null,
                          decoration: const InputDecoration(
                              labelText: 'Nueva contraseña'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _repetir,
                          obscureText: true,
                          enabled: real,
                          validator: (v) => v != _nueva.text
                              ? 'Las contraseñas no coinciden'
                              : null,
                          decoration: const InputDecoration(
                              labelText: 'Repetir contraseña'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: real && !_guardando ? _cambiarClave : null,
                    child:
                        Text(_guardando ? 'Guardando…' : 'Cambiar contraseña'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Registro de actividad', style: _tituloTarjeta),
                const SizedBox(height: 2),
                const Text(
                  'Últimos cambios hechos desde el panel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<Actividad>>(
                  future: _registro,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return ErrorCard(
                        message:
                            'No se pudo cargar el registro: ${snap.error}',
                        onRetry: () => setState(() {
                          _registro = panelRepository.actividad(tamano: 15);
                        }),
                      );
                    }
                    if (!snap.hasData) return const SkeletonBox(height: 160);
                    if (snap.data!.isEmpty) {
                      return const EmptyState(
                          message: 'Sin cambios registrados');
                    }
                    return Column(
                      children: [
                        for (final a in snap.data!) _filaRegistro(a),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            borderColor: AppColors.danger,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zona de riesgo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Para quitarle el acceso a otra persona, usa la pestaña '
                  'Administradores.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    foregroundColor: AppColors.danger,
                  ),
                  onPressed: real ? _cerrarTodas : null,
                  child: const Text('Cerrar sesión en todos los dispositivos'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

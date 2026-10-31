import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/common.dart';

const List<String> _pestanas = [
  'Cuenta',
  'Administradores',
  'Apariencia del tour',
  'Seguridad',
];
const List<String> _rutas = [
  '/configuracion/cuenta',
  '/configuracion/administradores',
  '/configuracion/apariencia',
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

class CuentaTab extends StatefulWidget {
  const CuentaTab({super.key});

  @override
  State<CuentaTab> createState() => _CuentaTabState();
}

class _CuentaTabState extends State<CuentaTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  final _cargo = TextEditingController();
  final _telefono = TextEditingController();
  String _idioma = 'es';
  String _formatoFecha = 'dmy';
  bool _avisos = true;
  bool _modificado = false;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: authState.nombre);
    for (final c in [_nombre, _cargo, _telefono]) {
      c.addListener(_marcar);
    }
  }

  @override
  void dispose() {
    for (final c in [_nombre, _cargo, _telefono]) {
      c.removeListener(_marcar);
      c.dispose();
    }
    super.dispose();
  }

  void _marcar() {
    if (!_modificado) setState(() => _modificado = true);
  }

  void _descartar() {
    _nombre.text = authState.nombre;
    _cargo.clear();
    _telefono.clear();
    setState(() {
      _idioma = 'es';
      _formatoFecha = 'dmy';
      _avisos = true;
      _modificado = false;
    });
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _modificado = false);
    showToast(context, 'Cambios guardados');
  }

  @override
  Widget build(BuildContext context) {
    final iniciales = authState.nombre.isEmpty
        ? '?'
        : authState.nombre.substring(0, 1).toUpperCase();
    return Column(
      children: [
        Expanded(
          child: ScrollPage(
            child: Form(
              key: _formKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
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
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton(
                              onPressed: () => showToast(
                                context,
                                'La carga de foto se activa al conectar la cuenta.',
                              ),
                              child: const Text('Cambiar foto'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nombre,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.length < 3 || t.length > 80) {
                              return 'Entre 3 y 80 caracteres';
                            }
                            return null;
                          },
                          decoration:
                              const InputDecoration(labelText: 'Nombre completo'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          initialValue: authState.correo,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Correo institucional',
                            prefixIcon: Icon(Icons.lock_outline),
                            helperText:
                                'Gestionado por la cuenta institucional UTB',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _cargo,
                          maxLength: 80,
                          decoration: const InputDecoration(
                            labelText: 'Cargo / Dependencia (opcional)',
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _telefono,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono (opcional)',
                            hintText: '+57 300 0000000',
                          ),
                        ),
                      ],
                    ),
                  );

                  final preferencias = AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Preferencias', style: _tituloTarjeta),
                        const SizedBox(height: 16),
                        const Text('Idioma',
                            style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        SelectBox<String>(
                          width: double.infinity,
                          value: _idioma,
                          items: const {'es': 'Español', 'en': 'English'},
                          onChanged: (v) => setState(() {
                            _idioma = v;
                            _modificado = true;
                          }),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          initialValue: 'America/Bogota',
                          readOnly: true,
                          decoration:
                              const InputDecoration(labelText: 'Zona horaria'),
                        ),
                        const SizedBox(height: 14),
                        const Text('Formato de fecha',
                            style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        SelectBox<String>(
                          width: double.infinity,
                          value: _formatoFecha,
                          items: const {
                            'dmy': 'DD/MM/YYYY',
                            'ymd': 'YYYY-MM-DD',
                          },
                          onChanged: (v) => setState(() {
                            _formatoFecha = v;
                            _modificado = true;
                          }),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Switch(
                              value: _avisos,
                              onChanged: (v) => setState(() {
                                _avisos = v;
                                _modificado = true;
                              }),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Recibir avisos por correo cuando un POI '
                                'quede sin contenido',
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
                        const StatusBadge('Administrador',
                            color: AppColors.primary),
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

                  if (constraints.maxWidth >= 1000) {
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: perfil),
                            const SizedBox(width: 16),
                            Expanded(child: preferencias),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(width: 420, child: rol),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      perfil,
                      const SizedBox(height: 16),
                      preferencias,
                      const SizedBox(height: 16),
                      rol,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        SaveBar(
          children: [
            OutlinedButton(
              onPressed: _modificado ? _descartar : null,
              child: const Text('Descartar cambios'),
            ),
            ElevatedButton(
              onPressed: _modificado ? _guardar : null,
              child: const Text('Guardar cambios'),
            ),
          ],
        ),
      ],
    );
  }
}

const TextStyle _tituloTarjeta =
    TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

// ---------------------------------------------------------------------------
// F.2 Administradores
// ---------------------------------------------------------------------------

class _Admin {
  _Admin(this.nombre, this.correo, this.rol, {this.esActual = false});

  final String nombre;
  final String correo;
  String rol; // Hoy solo existe el rol `admin` en el panel
  final bool esActual;
}

class AdministradoresTab extends StatefulWidget {
  const AdministradoresTab({super.key});

  @override
  State<AdministradoresTab> createState() => _AdministradoresTabState();
}

class _AdministradoresTabState extends State<AdministradoresTab> {
  late final List<_Admin> _admins;

  @override
  void initState() {
    super.initState();
    // La API no tiene endpoint para listar administradores (viven en la tabla
    // `perfiles` de Supabase con rol `admin`). Solo se muestra la sesión
    // actual; no se inventan otras cuentas.
    _admins = [
      _Admin(authState.nombre, authState.correo, 'Administrador',
          esActual: true),
    ];
  }

  int get _cuentaAdmins => _admins.where((a) => a.rol == 'Administrador').length;

  Future<void> _invitar() async {
    final nuevo = await showDialog<_Admin>(
      context: context,
      builder: (context) => const _InvitarDialog(),
    );
    if (nuevo == null || !mounted) return;
    if (_admins.any((a) => a.correo == nuevo.correo)) {
      showToast(context, 'Ese correo ya tiene acceso.', error: true);
      return;
    }
    setState(() => _admins.add(nuevo));
    showToast(context, 'Invitación registrada');
  }

  Future<void> _quitar(_Admin admin) async {
    if (admin.esActual) {
      showToast(context, 'No puedes quitar tu propio acceso.', error: true);
      return;
    }
    if (admin.rol == 'Administrador' && _cuentaAdmins <= 1) {
      showToast(context, 'Debe existir al menos un administrador activo.',
          error: true);
      return;
    }
    final ok = await confirmDialog(
      context,
      title: '¿Quitar el acceso a ${admin.nombre}?',
      message: 'Esta persona ya no podrá entrar al panel.',
      confirmLabel: 'Quitar acceso',
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() => _admins.remove(admin));
    showToast(context, 'Acceso revocado');
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
                      onPressed: _invitar,
                      icon: const Icon(Icons.person_add_alt, size: 18),
                      label: const Text('Invitar administrador'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final a in _admins)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            a.nombre.isEmpty
                                ? '?'
                                : a.nombre.substring(0, 1).toUpperCase(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Text(
                            a.esActual ? '${a.nombre} (tú)' : a.nombre,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            a.correo,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        StatusBadge(
                          a.rol,
                          color: a.rol == 'Administrador'
                              ? AppColors.primary
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.danger),
                            foregroundColor: AppColors.danger,
                          ),
                          onPressed: () => _quitar(a),
                          child: const Text('Quitar acceso'),
                        ),
                      ],
                    ),
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
                    'La autenticación se gestiona con las cuentas '
                    'institucionales de la UTB.',
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

class _InvitarDialog extends StatefulWidget {
  const _InvitarDialog();

  @override
  State<_InvitarDialog> createState() => _InvitarDialogState();
}

class _InvitarDialogState extends State<_InvitarDialog> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  String _rol = 'Administrador';

  @override
  void dispose() {
    _correo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invitar administrador'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
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
                ),
              ),
              const SizedBox(height: 14),
              SelectBox<String>(
                width: 380,
                prefix: 'Rol',
                value: _rol,
                items: const {
                  'Administrador': 'Administrador',
                },
                onChanged: (v) => setState(() => _rol = v),
              ),
            ],
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
            final correo = _correo.text.trim().toLowerCase();
            final usuario = correo.split('@').first;
            final nombre = usuario.isEmpty
                ? correo
                : usuario[0].toUpperCase() + usuario.substring(1);
            Navigator.of(context).pop(_Admin(nombre, correo, _rol));
          },
          child: const Text('Invitar'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// F.3 Apariencia del tour
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

class SeguridadTab extends StatefulWidget {
  const SeguridadTab({super.key});

  @override
  State<SeguridadTab> createState() => _SeguridadTabState();
}

class _SeguridadTabState extends State<SeguridadTab> {
  bool _dosPasos = false;

  Future<void> _accionRiesgo(String titulo, String mensaje) async {
    final ok = await confirmDialog(
      context,
      title: titulo,
      message: mensaje,
      confirmLabel: 'Confirmar',
      danger: true,
    );
    if (!ok || !mounted) return;
    showToast(context, 'Acción registrada (maqueta)');
  }

  @override
  Widget build(BuildContext context) {
    return ScrollPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SampleDataBanner(
            'Vista de diseño: la API actual no tiene sesiones, auditoría ni '
            'control de acceso. El diseño queda listo para conectarlos.',
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined,
                    color: AppColors.success),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Autenticación', style: _tituloTarjeta),
                      SizedBox(height: 2),
                      Text(
                        'Conectado con Firebase Auth · cuenta institucional UTB',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const StatusBadge('Verificado', color: AppColors.success),
                const SizedBox(width: 20),
                Switch(
                  value: _dosPasos,
                  onChanged: (v) => setState(() => _dosPasos = v),
                ),
                const Text('Verificación en dos pasos'),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => showToast(
                    context,
                    'La configuración de 2FA depende del proveedor de autenticación.',
                  ),
                  child: const Text('Configurar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Sesiones activas', style: _tituloTarjeta),
                    ),
                    OutlinedButton(
                      onPressed: () => showToast(
                        context,
                        'Se cerrarán las demás sesiones al conectar la autenticación.',
                      ),
                      child: const Text('Cerrar todas las otras sesiones'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _filaSesion('Esta sesión', 'Navegador actual', 'Ahora',
                    esActual: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child:
                          Text('Registro de actividad', style: _tituloTarjeta),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showToast(
                        context,
                        'La exportación se activa al conectar la auditoría.',
                      ),
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Exportar registro'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const EmptyState(
                  message:
                      'Sin registros: la tabla de auditoría existe en la base, pero la API aún no la expone',
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
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                        foregroundColor: AppColors.danger,
                      ),
                      onPressed: () => _accionRiesgo(
                        '¿Revocar accesos de un administrador?',
                        'Se te pedirá elegir a la persona antes de confirmar.',
                      ),
                      child: const Text('Revocar accesos de un administrador'),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                        foregroundColor: AppColors.danger,
                      ),
                      onPressed: () => _accionRiesgo(
                        '¿Cerrar sesión en todos los dispositivos?',
                        'Todas las sesiones, incluida esta, se cerrarán.',
                      ),
                      child: const Text('Cerrar sesión en todos los dispositivos'),
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

  Widget _filaSesion(String dispositivo, String ubicacion, String acceso,
      {bool esActual = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.computer_outlined, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Flexible(
                  child: Text(dispositivo, overflow: TextOverflow.ellipsis),
                ),
                if (esActual) ...[
                  const SizedBox(width: 8),
                  const StatusBadge('Esta sesión', color: AppColors.success),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(ubicacion,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            flex: 2,
            child: Text(acceso,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          if (!esActual)
            OutlinedButton(
              onPressed: () => showToast(context, 'Sesión cerrada (maqueta)'),
              child: const Text('Cerrar sesión'),
            ),
        ],
      ),
    );
  }

  Widget _evento(IconData icono, String texto, String hora) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icono, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(texto)),
          Text(hora,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

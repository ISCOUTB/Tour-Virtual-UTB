import 'package:flutter/material.dart';

import '../../core/auth/auth_state.dart';
import '../../core/config.dart';
import '../../core/theme/app_theme.dart';

/// A.1 Inicio de sesión (simulado).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  bool _verClave = false;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  String? _validarCorreo(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'El correo es obligatorio';
    final formato = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!formato.hasMatch(v)) return 'Escribe un correo válido';
    if (!v.toLowerCase().endsWith(AuthState.dominio)) {
      return 'Usa tu correo institucional ${AuthState.dominio}';
    }
    return null;
  }

  Future<void> _ingresarConCorreo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    final error = await authState.iniciarConCorreo(_correo.text, _clave.text);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _error = error;
    });
  }

  Future<void> _ingresarConGoogle() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final error = await authState.iniciarConGoogle();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.navy, AppColors.background],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'UTB',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 26,
                                ),
                              ),
                              TextSpan(
                                text: '  |  Tour Virtual',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Panel de administración',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _cargando ? null : _ingresarConGoogle,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 11,
                                backgroundColor: Colors.white,
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  'Iniciar sesión con cuenta institucional',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'o',
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _correo,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validarCorreo,
                          decoration: const InputDecoration(
                            labelText: 'Correo institucional',
                            hintText: 'nombre@utb.edu.co',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _clave,
                          obscureText: !_verClave,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'La contraseña es obligatoria'
                              : null,
                          onFieldSubmitted: (_) => _ingresarConCorreo(),
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _verClave ? 'Ocultar' : 'Mostrar',
                              icon: Icon(
                                _verClave
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _verClave = !_verClave),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.danger),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.danger, size: 20),
                                const SizedBox(width: 10),
                                Expanded(child: Text(_error!)),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _cargando ? null : _ingresarConCorreo,
                          child: _cargando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Text('Iniciar sesión'),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Solo personal autorizado de la UTB',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (AppConfig.useMockData) ...[
                          const SizedBox(height: 10),
                          const Text(
                            'Modo maqueta: usa cualquier correo @utb.edu.co '
                            'y cualquier contraseña.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

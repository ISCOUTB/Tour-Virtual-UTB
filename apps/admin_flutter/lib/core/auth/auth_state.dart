import 'dart:async';

import 'package:flutter/foundation.dart';
// supabase_flutter también define una clase AuthState; se oculta la suya.
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../data/api/api_client.dart';
import '../../data/repositories/repositories.dart';
import '../config.dart';

/// Estado de sesión del panel.
///
/// - Modo real (USE_MOCK=false y SUPABASE_ANON_KEY definida): inicia sesión con
///   Supabase Auth (correo y contraseña). Después pregunta a la API si la
///   persona tiene rol admin en `perfiles`; si no, cierra la sesión.
/// - Modo maqueta: acepta cualquier contraseña si el correo es @utb.edu.co.
class AuthState extends ChangeNotifier {
  static const String dominio = '@utb.edu.co';

  bool _signedIn = false;
  String _nombre = 'Administrador';
  String _correo = '';
  StreamSubscription? _suscripcion;

  bool get signedIn => _signedIn;
  String get nombre => _nombre;
  String get correo => _correo;

  GoTrueClient get _auth => Supabase.instance.client.auth;

  /// Se llama una vez al arrancar, después de Supabase.initialize. Si el
  /// navegador ya tenía una sesión guardada, entra directo.
  void restaurar() {
    if (!AppConfig.loginReal) return;
    final usuario = _auth.currentUser;
    if (_auth.currentSession != null && usuario?.email != null) {
      _entrar(usuario!.email!);
    }
    // Si Supabase cierra la sesión (token vencido sin renovar, cierre en otra
    // pestaña), el panel vuelve al login.
    _suscripcion = _auth.onAuthStateChange.listen((cambio) {
      if (cambio.event == AuthChangeEvent.signedOut && _signedIn) {
        _signedIn = false;
        notifyListeners();
      }
    });
  }

  /// Devuelve un mensaje de error, o null si el ingreso fue correcto.
  Future<String?> iniciarConCorreo(String correo, String clave) async {
    final c = correo.trim().toLowerCase();
    if (!c.endsWith(dominio)) {
      return 'Tu cuenta no tiene permisos de administrador';
    }
    if (clave.isEmpty) return 'Credenciales incorrectas';

    if (!AppConfig.loginReal) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _entrar(c);
      return null;
    }

    try {
      await _auth.signInWithPassword(email: c, password: clave);
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return 'Correo o contraseña incorrectos';
      }
      if (msg.contains('email not confirmed')) {
        return 'Tu correo aún no está confirmado en Supabase';
      }
      return 'No se pudo iniciar sesión: ${e.message}';
    } catch (_) {
      return 'No se pudo conectar con Supabase. Revisa tu conexión.';
    }

    final error = await _verificarAdmin();
    if (error != null) {
      await _auth.signOut();
      return error;
    }
    _entrar(c);
    return null;
  }

  /// La API decide si la persona es admin (tabla perfiles): 403 = no lo es.
  Future<String?> _verificarAdmin() async {
    try {
      await apiClient.get('/api/admin/administradores');
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        return 'Tu cuenta no tiene permisos de administrador';
      }
      if (e.statusCode == 401) {
        return 'El servidor no aceptó tu sesión. Intenta de nuevo.';
      }
      return e.message;
    }
  }

  Future<String?> iniciarConGoogle() async {
    if (AppConfig.loginReal) {
      return 'El ingreso con Google aún no está habilitado. '
          'Usa tu correo y contraseña.';
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _entrar('admin$dominio');
    return null;
  }

  void cerrarSesion() {
    _signedIn = false;
    notifyListeners();
    if (AppConfig.loginReal) unawaited(_auth.signOut());
  }

  void _entrar(String correo) {
    final usuario = correo.split('@').first;
    _correo = correo;
    _nombre = usuario.isEmpty
        ? 'Administrador'
        : usuario[0].toUpperCase() + usuario.substring(1);
    _signedIn = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }
}

final AuthState authState = AuthState();

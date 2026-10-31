import 'package:flutter/foundation.dart';

/// Estado de sesión de la MAQUETA.
///
/// No valida nada contra un servidor: acepta cualquier contraseña si el correo
/// termina en @utb.edu.co. Se reemplaza por Firebase Auth cuando se defina
/// cómo se protege el backend (ver notas del proyecto).
class AuthState extends ChangeNotifier {
  static const String dominio = '@utb.edu.co';

  bool _signedIn = false;
  String _nombre = 'Administrador';
  String _correo = '';

  bool get signedIn => _signedIn;
  String get nombre => _nombre;
  String get correo => _correo;

  /// Devuelve un mensaje de error, o null si el ingreso fue correcto.
  Future<String?> iniciarConCorreo(String correo, String clave) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final c = correo.trim().toLowerCase();
    if (!c.endsWith(dominio)) {
      return 'Tu cuenta no tiene permisos de administrador';
    }
    if (clave.isEmpty) return 'Credenciales incorrectas';
    _entrar(c);
    return null;
  }

  Future<String?> iniciarConGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _entrar('admin$dominio');
    return null;
  }

  void cerrarSesion() {
    _signedIn = false;
    notifyListeners();
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
}

final AuthState authState = AuthState();

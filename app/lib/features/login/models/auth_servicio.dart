import 'package:firebase_auth/firebase_auth.dart';

import 'credenciales_login.dart';

class AuthException implements Exception {
  final String mensaje;
  const AuthException(this.mensaje);

  @override
  String toString() => mensaje;
}

class AuthServicio {
  AuthServicio({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Future<User> iniciarSesion(CredencialesLogin c) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: c.correo.trim(),
        password: c.contrasena,
      );
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_traducir(e.code));
    }
  }

  Future<void> recuperarContrasena(String correo) async {
    try {
      await _auth.sendPasswordResetEmail(email: correo.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_traducir(e.code));
    }
  }

  Future<void> cerrarSesion() => _auth.signOut();

  String _traducir(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'too-many-requests':
        return 'Demasiados intentos. Inténtalo más tarde.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet.';
      default:
        return 'No se pudo iniciar sesión. Inténtalo de nuevo.';
    }
  }
}
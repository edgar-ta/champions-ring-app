import 'package:firebase_auth/firebase_auth.dart';

import '../models/login_credentials.dart';

class AuthException implements Exception {
  final String mensaje;
  const AuthException(this.mensaje);

  @override
  String toString() => mensaje;
}

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Future<User> logIn(LoginCredentials credentials) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: credentials.email.trim(),
        password: credentials.password,
      );
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_translate(e.code));
    }
  }

  Future<void> recoverPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_translate(e.code));
    }
  }

  Future<void> logOut() => _auth.signOut();

  String _translate(String code) {
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

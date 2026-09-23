import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Future<String> createUser({
    required String email,
    required String password,
  }) async {
    final UserCredential credential = await _auth
        .createUserWithEmailAndPassword(email: email, password: password);

    final User? user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-creation-failed',
        message: 'No se pudo obtener el usuario creado.',
      );
    }

    return user.uid;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../../core/result.dart';
import '../enums/user_register_failure.dart';
import '../models/register_user_data.dart';
import '../models/user.dart';
import 'user_repository.dart';

class FirebaseUserRepository implements UserRepository {
  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseUserRepository({
    firebase_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Result<User, UserRegisterFailure>> registerUser(
    RegisterUserData data,
  ) async {
    try {
      // Crear usuario en Firebase Authentication.
      final credential = await _auth.createUserWithEmailAndPassword(
        email: data.correo,
        password: data.contrasena,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        return const Failure<User, UserRegisterFailure>(
          UserRegisterFailure.authenticationError,
        );
      }

      final fechaCreacion = DateTime.now();

      // Crear modelo de usuario.
      final user = User(
        uid: firebaseUser.uid,
        type: data.type,
        nombre: data.nombre,
        apellidos: data.apellidos,
        fechaNacimiento: data.fechaNacimiento,
        correo: data.correo,
        telefono: data.telefono,
        datosLegalesSonPropios: data.datosLegalesSonPropios,
        firmaUrl: data.firmaUrl,
        ineUrl: data.ineUrl,
        fechaCreacion: fechaCreacion,
        fechaEliminacion: null,
      );

      // Guardar información adicional en Firestore.
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'uid': user.uid,
        'type': user.type.name,
        'nombre': user.nombre,
        'apellidos': user.apellidos,
        'fechaNacimiento': Timestamp.fromDate(user.fechaNacimiento),
        'correo': user.correo,
        'telefono': user.telefono,
        'datosLegalesSonPropios': user.datosLegalesSonPropios,
        'firmaUrl': user.firmaUrl,
        'ineUrl': user.ineUrl,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaEliminacion': null,
      });

      return Success<User, UserRegisterFailure>(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Failure<User, UserRegisterFailure>(
        _mapFirebaseAuthError(e),
        exception: e,
      );
    } on FirebaseException catch (e) {
      return Failure<User, UserRegisterFailure>(
        UserRegisterFailure.firestoreError,
        exception: e,
      );
    } catch (e) {
      return const Failure<User, UserRegisterFailure>(
        UserRegisterFailure.unexpectedError,
      );
    }
  }

  UserRegisterFailure _mapFirebaseAuthError(
    firebase_auth.FirebaseAuthException exception,
  ) {
    switch (exception.code) {
      case 'email-already-in-use':
        return UserRegisterFailure.emailAlreadyInUse;

      case 'invalid-email':
        return UserRegisterFailure.invalidEmail;

      case 'weak-password':
        return UserRegisterFailure.weakPassword;

      case 'operation-not-allowed':
        return UserRegisterFailure.operationNotAllowed;

      default:
        return UserRegisterFailure.authenticationError;
    }
  }
}

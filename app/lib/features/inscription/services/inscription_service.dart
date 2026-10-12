import 'dart:async';

import 'package:champions_ring_app/core/models/core_date.dart';
import 'package:champions_ring_app/core/models/core_user.dart';
import 'package:champions_ring_app/core/firebase/firestore_instance.dart';
import 'package:champions_ring_app/core/services/user_storage_service.dart';
import 'package:champions_ring_app/core/utils/result.dart';
import 'package:champions_ring_app/features/inscription/models/user_inscription_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserInscriptionError {
  missingInscriptionData('Faltan datos requeridos para completar el registro.'),
  emailAlreadyInUse('Ese correo electrónico ya está registrado.'),
  invalidEmail('El correo electrónico no es válido.'),
  weakPassword('La contraseña no cumple los requisitos de seguridad.'),
  badInternet('No se pudo completar el registro por un problema de conexión.'),
  profilePictureUploadFailed('No se pudo subir la foto de perfil.'),
  ineFrontUploadFailed('No se pudo subir el anverso de la INE.'),
  ineBackUploadFailed('No se pudo subir el reverso de la INE.'),
  signatureUploadFailed('No se pudo subir la firma de la responsiva.'),
  storageUnauthenticated('La sesión no permite subir archivos.'),
  storageUnauthorized('No hay permisos para subir los archivos.'),
  storageQuotaExceeded('Se agotó la cuota de almacenamiento disponible.'),
  unsupportedImageFormat('Uno de los archivos tiene un formato no compatible.'),
  emptyImage('Uno de los archivos de imagen está vacío.'),
  fileTooLarge('Uno de los archivos supera el tamaño permitido.'),
  uploadCanceled('La subida de un archivo fue cancelada.'),
  storageConfiguration('Firebase Storage no está configurado correctamente.'),
  firestorePermissionDenied('No hay permisos para guardar el usuario.'),
  firestoreUnavailable('Firestore no está disponible en este momento.'),
  firestoreTimeout('Se agotó el tiempo de espera al guardar el usuario.'),
  firestoreFailed('No se pudo guardar el usuario en Firestore.'),
  userCreationFailed('No se pudo crear la cuenta de usuario.'),
  other('Ocurrió un error inesperado durante el registro.');

  final String message;
  const UserInscriptionError(this.message);
}

/// Coordina la creación de la cuenta, la subida de archivos y el perfil Firestore.
class SignupService {
  static SignupService? _instance;
  static SignupService get instance {
    SignupService._instance ??= SignupService();
    return SignupService._instance!;
  }

  Future<Result<UserInscriptionError, String>> signUp(
    UserInscriptionData data,
  ) async {
    final personal = data.personalData;
    final id = data.idData;
    final waiver = data.waiverAgreementData;
    final plan = data.planSelectionData;
    final payment = data.paymentSelectionData;
    if (personal == null ||
        id == null ||
        id.ineFrontBytes == null ||
        id.ineFrontFormat == null ||
        id.ineBackBytes == null ||
        id.ineBackFormat == null ||
        waiver == null ||
        plan == null ||
        payment == null) {
      return Error(errorType: UserInscriptionError.missingInscriptionData);
    }

    User? user;
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: personal.email,
            password: personal.password,
          );
      final authenticatedUser = credential.user;
      if (authenticatedUser == null) {
        return Error(errorType: UserInscriptionError.userCreationFailed);
      }
      user = authenticatedUser;

      final storage = UserStorageService(userId: authenticatedUser.uid);
      final photoUrl = await _uploadUrl(
        storage.uploadProfilePicture(personal.photoBytes, personal.photoFormat),
        UserInscriptionError.profilePictureUploadFailed,
      );
      final ineFrontUrl = await _uploadUrl(
        storage.uploadIneFront(id.ineFrontBytes!, id.ineFrontFormat!),
        UserInscriptionError.ineFrontUploadFailed,
      );
      final ineBackUrl = await _uploadUrl(
        storage.uploadIneBack(id.ineBackBytes!, id.ineBackFormat!),
        UserInscriptionError.ineBackUploadFailed,
      );
      final signatureUrl = await _uploadUrl(
        storage.uploadSignature(waiver.signatureBytes, 'png'),
        UserInscriptionError.signatureUploadFailed,
      );

      final coreUser = CoreUser(
        birthDate: personal.birthDate,
        creationDate: CoreDate.fromFieldValue(FieldValue.serverTimestamp()),
        deletionDate: null,
        email: personal.email,
        guardianName: personal.isOfLegalAge ? null : personal.guardianName,
        guardianPhone: personal.isOfLegalAge ? null : personal.guardianPhone,
        guardianRelationship: personal.isOfLegalAge
            ? null
            : personal.guardianRelationship,
        ineBackUrl: ineBackUrl,
        ineFrontUrl: ineFrontUrl,
        lastName: personal.lastName,
        legalDataAreTheirs: personal.isOfLegalAge,
        membershipPlanId: plan.membershipPlanId,
        name: personal.name,
        paymentMethod: payment.paymentMethod,
        phone: personal.phone,
        photoUrl: photoUrl,
        registrationPayed: false,
        signatureUrl: signatureUrl,
        type: personal.type,
        uid: authenticatedUser.uid,
      );
      await FirestoreInstance.instance
          .collection('users')
          .doc(authenticatedUser.uid)
          .set(coreUser.toFirebaseMap())
          .timeout(const Duration(seconds: 15));

      return Success(result: authenticatedUser.uid);
    } on _UploadFailure catch (failure) {
      await _deleteCreatedUser(user);
      return Error(errorType: failure.error, exception: failure.cause);
    } on FirebaseAuthException catch (exception) {
      await _deleteCreatedUser(user);
      return Error(errorType: _mapAuthError(exception), exception: exception);
    } on TimeoutException catch (exception) {
      await _deleteCreatedUser(user);
      return Error(
        errorType: UserInscriptionError.firestoreTimeout,
        exception: exception,
      );
    } on FirebaseException catch (exception) {
      await _deleteCreatedUser(user);
      return Error(
        errorType: _mapFirestoreError(exception),
        exception: exception,
      );
    } catch (exception) {
      await _deleteCreatedUser(user);
      return Error(
        errorType: UserInscriptionError.other,
        exception: exception is Exception
            ? exception
            : Exception(exception.toString()),
      );
    }
  }

  Future<String> _uploadUrl(
    Future<Result<ImageUploadError, String>> upload,
    UserInscriptionError stageError,
  ) async => switch (await upload) {
    Success<ImageUploadError, String>(:final result) => result,
    Error<ImageUploadError, String>(:final errorType, :final exception) =>
      throw _UploadFailure(_mapStorageError(errorType, stageError), exception),
  };

  UserInscriptionError _mapStorageError(
    ImageUploadError error,
    UserInscriptionError stageError,
  ) => switch (error) {
    ImageUploadError.badInternet => UserInscriptionError.badInternet,
    ImageUploadError.unauthenticatedUser =>
      UserInscriptionError.storageUnauthenticated,
    ImageUploadError.unauthorizedUser =>
      UserInscriptionError.storageUnauthorized,
    ImageUploadError.firebaseStorageQuotaExceeded =>
      UserInscriptionError.storageQuotaExceeded,
    ImageUploadError.invalidFormat =>
      UserInscriptionError.unsupportedImageFormat,
    ImageUploadError.emptyImage => UserInscriptionError.emptyImage,
    ImageUploadError.fileTooLarge => UserInscriptionError.fileTooLarge,
    ImageUploadError.canceled => UserInscriptionError.uploadCanceled,
    ImageUploadError.storageConfiguration =>
      UserInscriptionError.storageConfiguration,
    ImageUploadError.other => stageError,
  };

  UserInscriptionError _mapAuthError(FirebaseAuthException exception) =>
      switch (exception.code) {
        'email-already-in-use' => UserInscriptionError.emailAlreadyInUse,
        'invalid-email' => UserInscriptionError.invalidEmail,
        'weak-password' => UserInscriptionError.weakPassword,
        'network-request-failed' => UserInscriptionError.badInternet,
        _ => UserInscriptionError.userCreationFailed,
      };

  UserInscriptionError _mapFirestoreError(FirebaseException exception) =>
      switch (exception.code) {
        'permission-denied' => UserInscriptionError.firestorePermissionDenied,
        'unavailable' ||
        'deadline-exceeded' => UserInscriptionError.firestoreUnavailable,
        _ => UserInscriptionError.firestoreFailed,
      };

  Future<void> _deleteCreatedUser(User? user) async {
    if (user == null) return;
    try {
      await user.delete();
    } catch (_) {
      // Preserve the original registration error if account cleanup also fails.
    }
  }
}

class _UploadFailure implements Exception {
  final UserInscriptionError error;
  final Exception? cause;

  const _UploadFailure(this.error, this.cause);
}

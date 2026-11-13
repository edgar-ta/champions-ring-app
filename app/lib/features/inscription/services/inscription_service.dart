import 'dart:async';
import 'dart:typed_data';

import 'package:champions_ring_app/core/models/core_client.dart';
import 'package:champions_ring_app/core/models/core_date.dart';
import 'package:champions_ring_app/core/models/core_member.dart';
import 'package:champions_ring_app/core/models/core_payment.dart'
    show CorePaymentCurrency, CorePaymentIssuingEntity, CorePaymentType;
import 'package:champions_ring_app/core/models/core_renewal.dart';
import 'package:champions_ring_app/core/repositories/core_client_repository.dart';
import 'package:champions_ring_app/core/repositories/core_member_repository.dart';
import 'package:champions_ring_app/core/repositories/core_membership_plan_repository.dart';
import 'package:champions_ring_app/core/repositories/core_payment_repository.dart';
import 'package:champions_ring_app/core/repositories/core_renewal_repository.dart';
import 'package:champions_ring_app/core/services/member_storage_service.dart';
import 'package:champions_ring_app/core/utils/result.dart';
import 'package:champions_ring_app/features/inscription/models/member_inscription_data.dart';
import 'package:champions_ring_app/features/inscription/models/payment.dart';
import 'package:champions_ring_app/features/inscription/services/liability_waiver_pdf.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum MemberInscriptionError {
  missingInscriptionData('Faltan datos requeridos para completar el registro.'),
  emailAlreadyInUse('Ese correo electrónico ya está registrado.'),
  invalidEmail('El correo electrónico no es válido.'),
  weakPassword('La contraseña no cumple los requisitos de seguridad.'),
  badInternet('No se pudo completar el registro por un problema de conexión.'),
  profilePictureUploadFailed('No se pudo subir la foto de perfil.'),
  ineFrontUploadFailed('No se pudo subir el anverso de la INE.'),
  ineBackUploadFailed('No se pudo subir el reverso de la INE.'),
  curpUploadFailed('No se pudo subir el CURP del usuario.'),
  signatureUploadFailed('No se pudo subir la firma de la responsiva.'),
  waiverGenerationFailed('No se pudo generar la carta responsiva firmada.'),
  waiverUploadFailed('No se pudo subir la carta responsiva firmada.'),
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
  const MemberInscriptionError(this.message);
}

/// Coordina la creación de la cuenta, la subida de archivos y el perfil Firestore.
class InscriptionService {
  static InscriptionService? _instance;
  static InscriptionService get instance {
    InscriptionService._instance ??= InscriptionService();
    return InscriptionService._instance!;
  }

  MemberInscriptionError? _validateMemberInscriptionData(
    MemberInscriptionData data,
  ) {
    final personal = data.personalData;
    final id = data.idData;
    final previousInscription = data.previousInscriptionData;
    final plan = data.planSelectionData;
    final payment = data.paymentSelectionData;
    if (previousInscription == null ||
        personal == null ||
        id == null ||
        id.ineFrontBytes == null ||
        id.ineFrontFormat == null ||
        id.ineBackBytes == null ||
        id.ineBackFormat == null ||
        (!personal.isOfLegalAge &&
            (id.curpBytes == null || id.curpFormat == null)) ||
        plan == null ||
        (!previousInscription.previouslySignedIn &&
            (payment == null ||
                (payment.paymentMethod == CorePaymentType.directTransfer &&
                    (payment.referenceId?.trim().isNotEmpty ?? false) ==
                        false)))) {
      return MemberInscriptionError.missingInscriptionData;
    }

    return null;
  }

  Future<Result<MemberInscriptionError, String>> signIn(
    MemberInscriptionData data,
  ) async {
    final validationError = _validateMemberInscriptionData(data);
    if (validationError != null) {
      return Error(errorType: validationError);
    }

    final personal = data.personalData!;
    final id = data.idData!;
    final previousInscription = data.previousInscriptionData!;

    User? user;
    try {
      final membershipPlanRepository = CoreMembershipPlanRepository();
      final selectedPlan = await membershipPlanRepository
          .getById(data.planSelectionData!.membershipPlanUid)
          .timeout(const Duration(seconds: 15));
      if (selectedPlan.deletionDate != null) {
        throw StateError(
          'Membership plan "${selectedPlan.uid}" is no longer active.',
        );
      }

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: personal.email,
            password: personal.password,
          );
      final authenticatedUser = credential.user;
      if (authenticatedUser == null) {
        return Error(errorType: MemberInscriptionError.userCreationFailed);
      }
      user = authenticatedUser;

      final storage = MemberStorageService(memberId: authenticatedUser.uid);
      final photoUrl = await _uploadUrl(
        storage.uploadProfilePicture(personal.photoBytes, personal.photoFormat),
        MemberInscriptionError.profilePictureUploadFailed,
      );
      final ineFrontUrl = await _uploadUrl(
        storage.uploadIneFront(id.ineFrontBytes!, id.ineFrontFormat!),
        MemberInscriptionError.ineFrontUploadFailed,
      );
      final ineBackUrl = await _uploadUrl(
        storage.uploadIneBack(id.ineBackBytes!, id.ineBackFormat!),
        MemberInscriptionError.ineBackUploadFailed,
      );
      final curpUrl = !personal.isOfLegalAge
          ? await _uploadUrl(
              storage.uploadCurp(id.curpBytes!, id.curpFormat!),
              MemberInscriptionError.curpUploadFailed,
            )
          : null;

      final uid = authenticatedUser.uid;
      final coreClient = CoreClient(
        uid: uid,
        name: personal.name,
        lastName: personal.lastName,
        email: personal.email,
        creationDate: CoreDate.ofWriteTime(),
      );
      await CoreClientRepository()
          .upsert(coreClient)
          .timeout(const Duration(seconds: 15));

      final coreMember = CoreMember(
        uid: uid,
        birthDate: CoreDate.fromDateTime(personal.birthDate),
        phone: personal.phone,
        photoUrl: photoUrl,
        legalDataAreTheirs: personal.isOfLegalAge,
        inscriptionPayed: false,
        membershipPlanRef: membershipPlanRepository.myCollection.doc(
          selectedPlan.uid,
        ),
        guardianName: personal.isOfLegalAge ? null : personal.guardianName,
        guardianPhone: personal.isOfLegalAge ? null : personal.guardianPhone,
        guardianRelationship: personal.isOfLegalAge
            ? null
            : personal.guardianRelationship,
        curpUrl: curpUrl,
        curpValidated: curpUrl == null ? null : false,
        ineBackUrl: ineBackUrl,
        ineBackValidated: false,
        ineFrontUrl: ineFrontUrl,
        ineFrontValidated: false,
        creationDate: CoreDate.ofWriteTime(),
      );
      final memberRepository = CoreMemberRepository();
      await memberRepository
          .upsert(coreMember)
          .timeout(const Duration(seconds: 15));

      if (!previousInscription.previouslySignedIn) {
        CorePaymentRepository paymentRepository = CorePaymentRepository();
        String paymentUid = paymentRepository.nextUid;

        switch (data.paymentSelectionData!.paymentMethod) {
          case CorePaymentType.cash:
            final cashPayment = CashPayment(
              uid: paymentUid,
              amount: selectedPlan.cost,
              currency: CorePaymentCurrency.mxn,
              payerRef: CoreClientRepository().myCollection.doc(uid),
              creationDate: CoreDate.ofWriteTime(),
            );
            await paymentRepository
                .upsert(cashPayment.toCorePayment())
                .timeout(const Duration(seconds: 15));
            break;
          case CorePaymentType.directTransfer:
            final paymentSelection = data.paymentSelectionData!;
            final directTransferPayment = DirectTransferPayment(
              uid: paymentUid,
              amount: selectedPlan.cost,
              currency: CorePaymentCurrency.mxn,
              referenceId: paymentSelection.referenceId!.trim(),
              issuingEntity: paymentSelection.issuingEntity!,
              issuingEntityName:
                  paymentSelection.issuingEntity ==
                      CorePaymentIssuingEntity.other
                  ? paymentSelection.issuingEntityName!.trim()
                  : null,
              payerRef: CoreClientRepository().myCollection.doc(uid),
              creationDate: CoreDate.ofWriteTime(),
            );
            await paymentRepository
                .upsert(directTransferPayment.toCorePayment())
                .timeout(const Duration(seconds: 15));
            break;
          case CorePaymentType.mercadoPago:
            break;
        }
        CoreRenewalRepository renewalRepository = CoreRenewalRepository(
          memberUid: uid,
        );
        await renewalRepository
            .upsert(
              CoreRenewal(
                uid: renewalRepository.nextUid,
                startDate: CoreDate.ofWriteTime(),
                endDate: CoreDate.ofServerControlledDate(),
                membershipPlanRef: membershipPlanRepository.myCollection.doc(
                  selectedPlan.uid,
                ),
                paymentRef: paymentRepository.myCollection.doc(paymentUid),
                amount: selectedPlan.cost,
                creationDate: CoreDate.ofWriteTime(),
              ),
            )
            .timeout(const Duration(seconds: 15));
      }

      return Success(result: uid);
    } on _UploadFailure catch (failure) {
      await _deleteCreatedUser(user);
      return Error(errorType: failure.error, exception: failure.cause);
    } on FirebaseAuthException catch (exception) {
      await _deleteCreatedUser(user);
      return Error(errorType: _mapAuthError(exception), exception: exception);
    } on TimeoutException catch (exception) {
      await _deleteCreatedUser(user);
      return Error(
        errorType: MemberInscriptionError.firestoreTimeout,
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
        errorType: MemberInscriptionError.other,
        exception: exception is Exception
            ? exception
            : Exception(exception.toString()),
      );
    }
  }

  Future<String> _uploadUrl(
    Future<Result<ImageUploadError, String>> upload,
    MemberInscriptionError stageError,
  ) async => switch (await upload) {
    Success<ImageUploadError, String>(:final result) => result,
    Error<ImageUploadError, String>(:final errorType, :final exception) =>
      throw _UploadFailure(_mapStorageError(errorType, stageError), exception),
  };

  MemberInscriptionError _mapStorageError(
    ImageUploadError error,
    MemberInscriptionError stageError,
  ) => switch (error) {
    ImageUploadError.badInternet => MemberInscriptionError.badInternet,
    ImageUploadError.unauthenticatedUser =>
      MemberInscriptionError.storageUnauthenticated,
    ImageUploadError.unauthorizedUser =>
      MemberInscriptionError.storageUnauthorized,
    ImageUploadError.firebaseStorageQuotaExceeded =>
      MemberInscriptionError.storageQuotaExceeded,
    ImageUploadError.invalidFormat =>
      MemberInscriptionError.unsupportedImageFormat,
    ImageUploadError.emptyImage => MemberInscriptionError.emptyImage,
    ImageUploadError.fileTooLarge => MemberInscriptionError.fileTooLarge,
    ImageUploadError.canceled => MemberInscriptionError.uploadCanceled,
    ImageUploadError.storageConfiguration =>
      MemberInscriptionError.storageConfiguration,
    ImageUploadError.other => stageError,
  };

  MemberInscriptionError _mapAuthError(FirebaseAuthException exception) =>
      switch (exception.code) {
        'email-already-in-use' => MemberInscriptionError.emailAlreadyInUse,
        'invalid-email' => MemberInscriptionError.invalidEmail,
        'weak-password' => MemberInscriptionError.weakPassword,
        'network-request-failed' => MemberInscriptionError.badInternet,
        _ => MemberInscriptionError.userCreationFailed,
      };

  MemberInscriptionError _mapFirestoreError(FirebaseException exception) =>
      switch (exception.code) {
        'permission-denied' => MemberInscriptionError.firestorePermissionDenied,
        'unavailable' ||
        'deadline-exceeded' => MemberInscriptionError.firestoreUnavailable,
        _ => MemberInscriptionError.firestoreFailed,
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
  final MemberInscriptionError error;
  final Exception? cause;

  const _UploadFailure(this.error, this.cause);
}

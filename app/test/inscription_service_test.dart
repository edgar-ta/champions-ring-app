import 'dart:typed_data';

import 'package:champions_ring_app/core/models/core_user.dart';
import 'package:champions_ring_app/core/utils/result.dart';
import 'package:champions_ring_app/features/inscription/models/user_inscription_data.dart';
import 'package:champions_ring_app/features/inscription/services/inscription_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SignupService.signUp', () {
    final service = SignupService();

    UserInscription_PersonalData personalData({required DateTime birthDate}) =>
        UserInscription_PersonalData(
          photoBytes: Uint8List.fromList([1]),
          photoFormat: 'png',
          name: 'Ana',
          lastName: 'López',
          birthDate: birthDate,
          email: 'ana@example.com',
          phone: '5551234567',
          password: 'Secure123!',
        );

    UserInscription_IdData completeIdData() => UserInscription_IdData(
      ineFrontBytes: Uint8List.fromList([1]),
      ineFrontFormat: 'png',
      ineBackBytes: Uint8List.fromList([1]),
      ineBackFormat: 'png',
      curpBytes: Uint8List.fromList([1]),
      curpFormat: 'png',
    );

    UserInscriptionData completeData({
      required UserInscription_PersonalData personal,
      UserInscription_IdData? id,
      UserInscription_PaymentSelectionData? payment,
    }) => UserInscriptionData(
      personalData: personal,
      idData: id ?? completeIdData(),
      waiverAgreementData: UserInscription_WaiverAgreementData(
        signatureBytes: Uint8List.fromList([1]),
      ),
      planSelectionData: UserInscription_PlanSelectionData(
        membershipPlanId: 1,
      ),
      paymentSelectionData:
          payment ??
          UserInscription_PaymentSelectionData(
            paymentMethod: CorePaymentMethod.cash,
          ),
    );

    test('rechaza el estado inicial sin datos', () async {
      // ARRANGE
      const data = UserInscriptionData();

      // ACT
      final result = await service.signUp(data);

      // ASSERT
      expect(result, isA<Error<UserInscriptionError, String>>());
      expect(
        (result as Error<UserInscriptionError, String>).errorType,
        UserInscriptionError.missingInscriptionData,
      );
    });

    test('rechaza si falta la responsiva', () async {
      // ARRANGE
      final incompleteData = UserInscriptionData(
        personalData: personalData(birthDate: DateTime(1990, 1, 1)),
        idData: completeIdData(),
        planSelectionData: UserInscription_PlanSelectionData(
          membershipPlanId: 1,
        ),
        paymentSelectionData: UserInscription_PaymentSelectionData(
          paymentMethod: CorePaymentMethod.cash,
        ),
      );

      // ACT
      final result = await service.signUp(incompleteData);

      // ASSERT
      expect(result, isA<Error<UserInscriptionError, String>>());
      expect(
        (result as Error<UserInscriptionError, String>).errorType,
        UserInscriptionError.missingInscriptionData,
      );
    });

    test('rechaza documentos de identidad incompletos', () async {
      // ARRANGE
      final data = UserInscriptionData(
        personalData: personalData(birthDate: DateTime(1990, 1, 1)),
        idData: UserInscription_IdData(
          ineFrontBytes: Uint8List.fromList([1]),
          ineFrontFormat: 'png',
          ineBackBytes: null,
          ineBackFormat: null,
        ),
        waiverAgreementData: UserInscription_WaiverAgreementData(
          signatureBytes: Uint8List.fromList([1]),
        ),
        planSelectionData: UserInscription_PlanSelectionData(
          membershipPlanId: 1,
        ),
        paymentSelectionData: UserInscription_PaymentSelectionData(
          paymentMethod: CorePaymentMethod.cash,
        ),
      );

      // ACT
      final result = await service.signUp(data);

      // ASSERT
      expect(result, isA<Error<UserInscriptionError, String>>());
      expect(
        (result as Error<UserInscriptionError, String>).errorType,
        UserInscriptionError.missingInscriptionData,
      );
    });

    test('rechaza el CURP ausente para una persona menor de edad', () async {
      // ARRANGE
      final data = completeData(
        personal: personalData(birthDate: DateTime.now()),
        id: UserInscription_IdData(
          ineFrontBytes: Uint8List.fromList([1]),
          ineFrontFormat: 'png',
          ineBackBytes: Uint8List.fromList([1]),
          ineBackFormat: 'png',
        ),
      );

      // ACT
      final result = await service.signUp(data);

      // ASSERT
      expect(result, isA<Error<UserInscriptionError, String>>());
      expect(
        (result as Error<UserInscriptionError, String>).errorType,
        UserInscriptionError.missingInscriptionData,
      );
    });

    test('rechaza datos cuando falta la selección de pago', () async {
      // ARRANGE
      final personal = personalData(birthDate: DateTime(1990, 1, 1));
      final data = UserInscriptionData(
        personalData: personal,
        idData: completeIdData(),
        waiverAgreementData: UserInscription_WaiverAgreementData(
          signatureBytes: Uint8List.fromList([1]),
        ),
        planSelectionData: UserInscription_PlanSelectionData(
          membershipPlanId: 1,
        ),
        paymentSelectionData: null,
      );

      // ACT
      final result = await service.signUp(data);

      // ASSERT
      expect(result, isA<Error<UserInscriptionError, String>>());
      expect(
        (result as Error<UserInscriptionError, String>).errorType,
        UserInscriptionError.missingInscriptionData,
      );
    });
  });
}

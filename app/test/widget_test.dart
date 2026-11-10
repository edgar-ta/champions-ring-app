import 'dart:typed_data';

import 'package:champions_ring_app/core/models/core_payment.dart'
    show CorePaymentType;
import 'package:champions_ring_app/core/utils/result.dart';
import 'package:champions_ring_app/features/inscription/models/member_inscription_data.dart';
import 'package:champions_ring_app/features/inscription/services/inscription_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InscriptionService.signUp', () {
    final service = InscriptionService();

    MemberInscription_PersonalData personalData({
      required DateTime birthDate,
    }) => MemberInscription_PersonalData(
      photoBytes: Uint8List.fromList([1]),
      photoFormat: 'png',
      name: 'Ana',
      lastName: 'López',
      birthDate: birthDate,
      email: 'ana@example.com',
      phone: '5551234567',
      password: 'Secure123!',
    );

    MemberInscription_IdData completeIdData() => MemberInscription_IdData(
      ineFrontBytes: Uint8List.fromList([1]),
      ineFrontFormat: 'png',
      ineBackBytes: Uint8List.fromList([1]),
      ineBackFormat: 'png',
      curpBytes: Uint8List.fromList([1]),
      curpFormat: 'png',
    );

    MemberInscriptionData completeData({
      required MemberInscription_PersonalData personal,
      MemberInscription_IdData? id,
      MemberInscription_PaymentSelectionData? payment,
    }) => MemberInscriptionData(
      previousInscriptionData: MemberInscription_PreviousInscriptionData(
        previouslySignedIn: true,
      ),
      personalData: personal,
      idData: id ?? completeIdData(),
      planSelectionData: MemberInscription_PlanSelectionData(
        membershipPlanId: 1,
      ),
      paymentSelectionData:
          payment ??
          MemberInscription_PaymentSelectionData(
            paymentMethod: CorePaymentType.cash,
          ),
    );

    test('rechaza el estado inicial sin datos', () async {
      // ARRANGE
      const data = MemberInscriptionData();

      // ACT
      final result = await service.signIn(data);

      // ASSERT
      expect(result, isA<Error<MemberInscriptionError, String>>());
      expect(
        (result as Error<MemberInscriptionError, String>).errorType,
        MemberInscriptionError.missingInscriptionData,
      );
    });

    test('rechaza si falta la respuesta de inscripción previa', () async {
      // ARRANGE
      final incompleteData = MemberInscriptionData(
        previousInscriptionData: null,
        personalData: personalData(birthDate: DateTime(1990, 1, 1)),
        idData: completeIdData(),
        planSelectionData: MemberInscription_PlanSelectionData(
          membershipPlanId: 1,
        ),
        paymentSelectionData: MemberInscription_PaymentSelectionData(
          paymentMethod: CorePaymentType.cash,
        ),
      );

      // ACT
      final result = await service.signIn(incompleteData);

      // ASSERT
      expect(result, isA<Error<MemberInscriptionError, String>>());
      expect(
        (result as Error<MemberInscriptionError, String>).errorType,
        MemberInscriptionError.missingInscriptionData,
      );
    });

    test('rechaza documentos de identidad incompletos', () async {
      // ARRANGE
      final data = MemberInscriptionData(
        previousInscriptionData: MemberInscription_PreviousInscriptionData(
          previouslySignedIn: true,
        ),
        personalData: personalData(birthDate: DateTime(1990, 1, 1)),
        idData: MemberInscription_IdData(
          ineFrontBytes: Uint8List.fromList([1]),
          ineFrontFormat: 'png',
          ineBackBytes: null,
          ineBackFormat: null,
        ),
        planSelectionData: MemberInscription_PlanSelectionData(
          membershipPlanId: 1,
        ),
        paymentSelectionData: MemberInscription_PaymentSelectionData(
          paymentMethod: CorePaymentType.cash,
        ),
      );

      // ACT
      final result = await service.signIn(data);

      // ASSERT
      expect(result, isA<Error<MemberInscriptionError, String>>());
      expect(
        (result as Error<MemberInscriptionError, String>).errorType,
        MemberInscriptionError.missingInscriptionData,
      );
    });

    test('rechaza el CURP ausente para una persona menor de edad', () async {
      // ARRANGE
      final data = completeData(
        personal: personalData(birthDate: DateTime.now()),
        id: MemberInscription_IdData(
          ineFrontBytes: Uint8List.fromList([1]),
          ineFrontFormat: 'png',
          ineBackBytes: Uint8List.fromList([1]),
          ineBackFormat: 'png',
        ),
      );

      // ACT
      final result = await service.signIn(data);

      // ASSERT
      expect(result, isA<Error<MemberInscriptionError, String>>());
      expect(
        (result as Error<MemberInscriptionError, String>).errorType,
        MemberInscriptionError.missingInscriptionData,
      );
    });

    test('rechaza datos cuando falta la selección de pago', () async {
      // ARRANGE
      final personal = personalData(birthDate: DateTime(1990, 1, 1));
      final data = MemberInscriptionData(
        previousInscriptionData: MemberInscription_PreviousInscriptionData(
          previouslySignedIn: false,
        ),
        personalData: personal,
        idData: completeIdData(),
        planSelectionData: MemberInscription_PlanSelectionData(
          membershipPlanId: 1,
        ),
        paymentSelectionData: null,
      );

      // ACT
      final result = await service.signIn(data);

      // ASSERT
      expect(result, isA<Error<MemberInscriptionError, String>>());
      expect(
        (result as Error<MemberInscriptionError, String>).errorType,
        MemberInscriptionError.missingInscriptionData,
      );
    });
  });
}

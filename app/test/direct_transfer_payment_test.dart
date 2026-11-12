import 'package:champions_ring_app/core/models/core_date.dart';
import 'package:champions_ring_app/core/models/core_payment.dart'
    show CorePaymentCurrency, CorePaymentIssuingEntity;
import 'package:champions_ring_app/features/inscription/models/payment.dart'
    show DirectTransferPayment;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes the issuing entity using its Firestore value', () {
    final payment = DirectTransferPayment(
      uid: 'payment-uid',
      amount: 100,
      currency: CorePaymentCurrency.mxn,
      referenceId: 'REF-123',
      issuingEntity: CorePaymentIssuingEntity.bancoAzteca,
      issuingEntityName: 'Banco del Barrio',
      creationDate: CoreDate.ofWriteTime(),
    ).toCorePayment();

    final data = payment.toFirebaseMap();

    expect(data['referenceId'], 'REF-123');
    expect(data['issuingEntity'], 'banco-azteca');
    expect(data['issuingEntityName'], 'Banco del Barrio');
  });
}

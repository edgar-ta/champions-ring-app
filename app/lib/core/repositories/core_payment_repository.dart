import 'package:champions_ring_app/core/models/core_date.dart';
import 'package:champions_ring_app/core/models/core_payment.dart';
import 'package:champions_ring_app/core/utils/base_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CorePaymentRepository extends BaseRepository<CorePayment> {
  @override
  String get collectionName => 'payments';

  /// Inserts a new `payment` document in Firestore or updates an already existing
  /// one with the same uid as the object given.
  ///
  /// This method validates the following:
  /// * The `amount` property of the payment is greater than zero.
  /// * The `approver_ref` property of the payment, if present, is a valid
  ///   reference to a `receptionist` document.
  ///
  /// Returns `true` only if the document was just created.
  @override
  Future<bool> upsert(CorePayment payment) async {
    if (!(payment.amount > 0)) {
      throw ArgumentError.value(
        payment.amount,
        'payment.amount',
        'Must be greater than zero.',
      );
    }

    final approverRef = payment.approverRef;
    if (approverRef != null && approverRef.parent.path != 'receptionists') {
      throw ArgumentError.value(
        approverRef.path,
        'payment.approverRef',
        'Must reference a receptionist document.',
      );
    }

    final paymentDocument = myCollection.doc(payment.uid);

    return myCollection.firestore.runTransaction((transaction) async {
      if (approverRef != null) {
        final approverSnapshot = await transaction.get(approverRef);
        if (!approverSnapshot.exists) {
          throw StateError(
            'Receptionist "${approverRef.id}" referenced by payment '
            '"${payment.uid}" was not found.',
          );
        }
      }

      final paymentSnapshot = await transaction.get(paymentDocument);
      transaction.set(paymentDocument, payment.toFirebaseMap());
      return !paymentSnapshot.exists;
    });
  }

  @override
  Future<CorePayment> getById(String uid) async {
    final snapshot = await myCollection.doc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Core payment with id "$uid" was not found.');
    }

    final amount = data['amount'] as num;
    final approvalDate = data['approvalDate'] as Timestamp?;
    final creationDate = data['creationDate'] as Timestamp;
    final deletionDate = data['deletionDate'] as Timestamp?;
    final type = _paymentTypeFromSerialization(data['type'] as String);
    final currency = _currencyFromSerialization(data['currency'] as String);
    final mercadoPagoStatus = data['mercadoPagoStatus'] as String?;

    return CorePayment(
      uid: data['uid'] as String,
      type: type,
      amount: amount.toDouble(),
      currency: currency,
      approvalDate: approvalDate == null
          ? null
          : CoreDate.fromTimestamp(approvalDate),
      checkoutUrl: data['checkoutUrl'] as String?,
      mercadoPagoStatus: mercadoPagoStatus == null
          ? null
          : _mercadoPagoStatusFromSerialization(mercadoPagoStatus),
      mercadoPagoPaymentId: data['mercadoPagoPaymentId'] as String?,
      preferenceId: data['preferenceId'] as String?,
      referenceId: data['referenceId'] as String?,
      approverRef:
          data['approverRef'] as DocumentReference<Map<String, dynamic>>?,
      creationDate: CoreDate.fromTimestamp(creationDate),
      deletionDate: deletionDate == null
          ? null
          : CoreDate.fromTimestamp(deletionDate),
    );
  }

  CorePaymentType _paymentTypeFromSerialization(String value) =>
      switch (value) {
        'cash' => CorePaymentType.cash,
        'direct-transfer' => CorePaymentType.directTransfer,
        'mercado-pago' => CorePaymentType.mercadoPago,
        _ => throw FormatException('Unknown payment type "$value".'),
      };

  CorePaymentCurrency _currencyFromSerialization(String value) =>
      switch (value) {
        'MXN' => CorePaymentCurrency.mxn,
        'USD' => CorePaymentCurrency.usd,
        _ => throw FormatException('Unknown payment currency "$value".'),
      };

  CoreMercadoPagoStatus _mercadoPagoStatusFromSerialization(String value) =>
      switch (value) {
        'approved' => CoreMercadoPagoStatus.approved,
        'rejected' => CoreMercadoPagoStatus.rejected,
        _ => throw FormatException('Unknown Mercado Pago status "$value".'),
      };
}

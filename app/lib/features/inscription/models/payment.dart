import 'package:champions_ring_app/core/models/core_date.dart';
import 'package:champions_ring_app/core/models/core_payment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

sealed class Payment {
  final String uid;
  final double amount;
  final CorePaymentCurrency currency;
  final CoreDate? approvalDate;
  final CoreDate creationDate;
  final CoreDate? deletionDate;

  const Payment({
    required this.uid,
    required this.amount,
    required this.currency,
    this.approvalDate,
    required this.creationDate,
    this.deletionDate,
  });

  CorePayment toCorePayment();
}

class CashPayment extends Payment {
  final DocumentReference<Map<String, dynamic>>? approverRef;

  const CashPayment({
    required super.uid,
    required super.amount,
    required super.currency,
    super.approvalDate,
    this.approverRef,
    required super.creationDate,
    super.deletionDate,
  });

  @override
  CorePayment toCorePayment() => CorePayment(
    uid: uid,
    type: CorePaymentType.cash,
    amount: amount,
    currency: currency,
    approvalDate: approvalDate,
    approverRef: approverRef,
    creationDate: creationDate,
    deletionDate: deletionDate,
  );
}

class DirectTransferPayment extends Payment {
  final String referenceId;
  final DocumentReference<Map<String, dynamic>>? approverRef;

  const DirectTransferPayment({
    required super.uid,
    required super.amount,
    required super.currency,
    super.approvalDate,
    required this.referenceId,
    this.approverRef,
    required super.creationDate,
    super.deletionDate,
  });

  @override
  CorePayment toCorePayment() => CorePayment(
    uid: uid,
    type: CorePaymentType.directTransfer,
    amount: amount,
    currency: currency,
    approvalDate: approvalDate,
    referenceId: referenceId,
    approverRef: approverRef,
    creationDate: creationDate,
    deletionDate: deletionDate,
  );
}

class MercadoPagoPayment extends Payment {
  final String checkoutUrl;
  final CoreMercadoPagoStatus status;
  final String mercadoPagoPaymentId;
  final String preferenceId;

  const MercadoPagoPayment({
    required super.uid,
    required super.amount,
    required super.currency,
    super.approvalDate,
    required this.checkoutUrl,
    required this.status,
    required this.mercadoPagoPaymentId,
    required this.preferenceId,
    required super.creationDate,
    super.deletionDate,
  });

  @override
  CorePayment toCorePayment() => CorePayment(
    uid: uid,
    type: CorePaymentType.mercadoPago,
    amount: amount,
    currency: currency,
    approvalDate: approvalDate,
    checkoutUrl: checkoutUrl,
    mercadoPagoStatus: status,
    mercadoPagoPaymentId: mercadoPagoPaymentId,
    preferenceId: preferenceId,
    creationDate: creationDate,
    deletionDate: deletionDate,
  );
}

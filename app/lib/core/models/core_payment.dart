import 'package:champions_ring_app/core/models/core_date.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum CorePaymentType {
  cash('cash'),
  directTransfer('direct-transfer'),
  mercadoPago('mercado-pago');

  final String serialization;

  const CorePaymentType(this.serialization);
}

enum CorePaymentCurrency {
  mxn('MXN'),
  usd('USD');

  final String serialization;

  const CorePaymentCurrency(this.serialization);
}

enum CoreMercadoPagoStatus {
  approved('approved'),
  rejected('rejected');

  final String serialization;

  const CoreMercadoPagoStatus(this.serialization);
}

class CorePayment {
  final String uid;
  final CorePaymentType type;

  final double amount;
  final CorePaymentCurrency currency;
  final CoreDate? approvalDate;

  // Mercado Pago
  final String? checkoutUrl;
  final CoreMercadoPagoStatus? mercadoPagoStatus;
  final String? mercadoPagoPaymentId;
  final String? preferenceId;

  // Transferencia bancaria
  final String? referenceId;

  // Efectivo y transferencia bancaria
  final DocumentReference<Map<String, dynamic>>? approverRef;

  final CoreDate creationDate;
  final CoreDate? deletionDate;

  const CorePayment({
    required this.uid,
    required this.type,
    required this.amount,
    required this.currency,
    this.approvalDate,
    this.checkoutUrl,
    this.mercadoPagoStatus,
    this.mercadoPagoPaymentId,
    this.preferenceId,
    this.referenceId,
    this.approverRef,
    required this.creationDate,
    this.deletionDate,
  });

  Map<String, dynamic> toFirebaseMap() {
    return {
      'uid': uid,
      'type': type.serialization,
      'amount': amount,
      'currency': currency.serialization,
      'creationDate': creationDate.toFirebaseValue(),

      // Mercado Pago
      if (approvalDate != null) 'approvalDate': approvalDate!.toFirebaseValue(),
      if (checkoutUrl != null) 'checkoutUrl': checkoutUrl,
      if (mercadoPagoStatus != null)
        'mercadoPagoStatus': mercadoPagoStatus!.serialization,
      if (mercadoPagoPaymentId != null)
        'mercadoPagoPaymentId': mercadoPagoPaymentId,
      if (preferenceId != null) 'preferenceId': preferenceId,

      // Transferencia bancaria
      if (referenceId != null) 'referenceId': referenceId,

      // Efectivo y transferencia bancaria
      if (approverRef != null) 'approverRef': approverRef,

      if (deletionDate != null) 'deletionDate': deletionDate!.toFirebaseValue(),
    };
  }
}

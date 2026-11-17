import 'dart:async';

import 'package:champions_ring_app/features/home/models/viewable_membership.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_instance.dart';

class MembershipService {
  final FirebaseFirestore _db;

  MembershipService({FirebaseFirestore? db})
    : _db = db ?? FirestoreInstance.instance;

  /// Emite null si el cliente no tiene un perfil de miembro.
  ///
  /// Una renovación cuenta como pagada cuando su pago relacionado tiene
  /// `approvalDate`. De todas las renovaciones pagadas se usa la que tenga la
  /// fecha de expiración más reciente.
  Stream<UserMembership?> watchMembership(String uid) {
    final member = _db.collection('members').doc(uid);
    final renewalsCollection = member.collection('renewals');

    return Stream<UserMembership?>.multi((controller) {
      var memberLoaded = false;
      var memberExists = false;
      var renewalsLoaded = false;
      final renewals = <String, _Renewal>{};
      final approvedPayments = <String, bool>{};
      final paymentSubscriptions =
          <
            String,
            StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
          >{};

      void emitMembership() {
        if (!memberLoaded || !renewalsLoaded) return;
        if (!memberExists) {
          controller.add(null);
          return;
        }

        final paymentPaths = renewals.values
            .map((renewal) => renewal.paymentPath)
            .toSet();
        if (!approvedPayments.keys.toSet().containsAll(paymentPaths)) return;

        final paidRenewals =
            renewals.values
                .where((renewal) => approvedPayments[renewal.paymentPath]!)
                .toList()
              ..sort((a, b) => b.expiresAt.compareTo(a.expiresAt));
        final latestPaidRenewal = paidRenewals.firstOrNull;
        controller.add(
          UserMembership(
            hasPaidRenewal: latestPaidRenewal != null,
            expiresAt: latestPaidRenewal?.expiresAt,
          ),
        );
      }

      final memberSubscription = member.snapshots().listen((snapshot) {
        memberLoaded = true;
        memberExists = snapshot.exists;
        emitMembership();
      }, onError: controller.addError);

      final renewalsSubscription = renewalsCollection.snapshots().listen((
        snapshot,
      ) {
        try {
          final nextRenewals = <String, _Renewal>{};
          for (final document in snapshot.docs) {
            final data = document.data();
            if (_readOptionalTimestamp(data, 'deletionDate') != null) {
              continue;
            }

            final paymentRef =
                data['paymentRef'] as DocumentReference<Map<String, dynamic>>;
            if (paymentRef.parent.path != 'payments') {
              throw FormatException(
                'La renovación ${document.id} no referencia un pago.',
              );
            }

            nextRenewals[document.reference.path] = _Renewal(
              paymentPath: paymentRef.path,
              paymentRef: paymentRef,
              expiresAt: _readRequiredTimestamp(data, 'endDate'),
            );
          }

          renewals
            ..clear()
            ..addAll(nextRenewals);
          renewalsLoaded = true;

          final paymentPaths = renewals.values
              .map((renewal) => renewal.paymentPath)
              .toSet();
          for (final path in paymentSubscriptions.keys.toList()) {
            if (!paymentPaths.contains(path)) {
              unawaited(paymentSubscriptions.remove(path)!.cancel());
              approvedPayments.remove(path);
            }
          }

          for (final renewal in renewals.values) {
            final path = renewal.paymentPath;
            if (paymentSubscriptions.containsKey(path)) continue;

            paymentSubscriptions[path] = renewal.paymentRef.snapshots().listen((
              paymentSnapshot,
            ) {
              try {
                final data = paymentSnapshot.data();
                if (!paymentSnapshot.exists || data == null) {
                  approvedPayments[path] = false;
                } else {
                  final deleted = _readOptionalTimestamp(data, 'deletionDate');
                  final approvalDate = _readOptionalTimestamp(
                    data,
                    'approvalDate',
                  );
                  approvedPayments[path] =
                      deleted == null && approvalDate != null;
                }
                emitMembership();
              } on Object catch (error, stackTrace) {
                controller.addError(error, stackTrace);
              }
            }, onError: controller.addError);
          }
          emitMembership();
        } on Object catch (error, stackTrace) {
          controller.addError(error, stackTrace);
        }
      }, onError: controller.addError);

      controller.onCancel = () async {
        await memberSubscription.cancel();
        await renewalsSubscription.cancel();
        await Future.wait(
          paymentSubscriptions.values.map((sub) => sub.cancel()),
        );
      };
    });
  }

  /// Emite el estado del pago de Mercado Pago más reciente del cliente.
  Stream<String?> watchCurrentPaymentStatus(String uid) => _db
      .collection('payments')
      .where('payerRef', isEqualTo: _db.collection('clients').doc(uid))
      .snapshots()
      .map((snapshot) {
        final payments =
            snapshot.docs
                .where((document) => document.data()['type'] == 'mercado-pago')
                .toList()
              ..sort((a, b) {
                final aDate = _readRequiredTimestamp(a.data(), 'creationDate');
                final bDate = _readRequiredTimestamp(b.data(), 'creationDate');
                return bDate.compareTo(aDate);
              });
        if (payments.isEmpty) return null;

        final data = payments.first.data();
        final status = data['mercadoPagoStatus'] as String?;
        if (status == 'rejected') return status;
        if (data['approvalDate'] is Timestamp) return 'approved';
        return status ?? 'pending';
      });

  static DateTime _readRequiredTimestamp(
    Map<String, dynamic> data,
    String field,
  ) {
    final value = data[field];
    if (value is! Timestamp) {
      throw FormatException('El campo "$field" debe ser una fecha.');
    }
    return value.toDate();
  }

  static DateTime? _readOptionalTimestamp(
    Map<String, dynamic> data,
    String field,
  ) {
    final value = data[field];
    if (value == null) return null;
    if (value is! Timestamp) {
      throw FormatException('El campo "$field" debe ser una fecha.');
    }
    return value.toDate();
  }
}

class _Renewal {
  final String paymentPath;
  final DocumentReference<Map<String, dynamic>> paymentRef;
  final DateTime expiresAt;

  const _Renewal({
    required this.paymentPath,
    required this.paymentRef,
    required this.expiresAt,
  });
}

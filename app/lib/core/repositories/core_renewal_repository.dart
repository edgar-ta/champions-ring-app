import 'package:champions_ring_app/core/firebase/firestore_instance.dart';
import 'package:champions_ring_app/core/models/core_renewal.dart';

class CoreRenewalRepository {
  /// Inserts a new `renewal` document in Firestore or updates an already existing
  /// one with the same uid as the object given.
  ///
  /// This method validates the following:
  /// * The `payment_ref` property of the renewal is a valid reference to a
  ///   `payment` document.
  /// * The `membership_plan_ref` property of the payment, if present, is a
  ///   valid reference to a `membership_plan` document.
  ///
  /// Returns `true` only if the document was just created.
  Future<bool> upsertCoreRenewal(
    String memberUid,
    CoreRenewal renewal,
  ) async {
    final paymentRef = renewal.paymentRef;
    if (paymentRef.parent.path != 'payments') {
      throw ArgumentError.value(
        paymentRef.path,
        'renewal.paymentRef',
        'Must reference a payment document.',
      );
    }

    final membershipPlanRef = renewal.membershipPlanRef;
    if (membershipPlanRef != null &&
        membershipPlanRef.parent.path != 'membership_plans') {
      throw ArgumentError.value(
        membershipPlanRef.path,
        'renewal.membershipPlanRef',
        'Must reference a membership plan document.',
      );
    }

    final firestore = FirestoreInstance.instance;
    final memberDocument = firestore.collection('members').doc(memberUid);
    final renewalDocument = memberDocument
        .collection('renewals')
        .doc(renewal.uid);

    return firestore.runTransaction((transaction) async {
      final memberSnapshot = await transaction.get(memberDocument);
      if (!memberSnapshot.exists) {
        throw StateError('Member "$memberUid" was not found.');
      }

      final paymentSnapshot = await transaction.get(paymentRef);
      if (!paymentSnapshot.exists) {
        throw StateError('Payment "${paymentRef.path}" was not found.');
      }

      if (membershipPlanRef != null) {
        final membershipPlanSnapshot = await transaction.get(
          membershipPlanRef,
        );
        if (!membershipPlanSnapshot.exists) {
          throw StateError(
            'Membership plan "${membershipPlanRef.path}" was not found.',
          );
        }
      }

      final renewalSnapshot = await transaction.get(renewalDocument);
      transaction.set(renewalDocument, renewal.toFirebaseMap());
      return !renewalSnapshot.exists;
    });
  }
}

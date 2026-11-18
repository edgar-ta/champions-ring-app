import 'package:champions_ring_app/core/firebase/firestore_instance.dart';
import 'package:champions_ring_app/core/models/core_date.dart';
import 'package:champions_ring_app/core/models/core_renewal.dart';
import 'package:champions_ring_app/core/utils/base_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoreRenewalRepository extends BaseRepository<CoreRenewal> {
  final String? memberUid;

  CoreRenewalRepository({this.memberUid});

  @override
  String get collectionName {
    final uid = memberUid;
    if (uid == null) {
      throw StateError(
        'A member uid is required to access a member renewal collection.',
      );
    }
    return 'members/$uid/renewals';
  }

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
  @override
  Future<bool> upsert(CoreRenewal renewal) async {
    if (memberUid == null) {
      throw StateError(
        'A member uid is required to upsert a renewal through the base API.',
      );
    }

    final paymentRef = renewal.paymentRef;
    if (paymentRef.parent.path != 'payments') {
      throw ArgumentError.value(
        paymentRef.path,
        'renewal.paymentRef',
        'Must reference a payment document.',
      );
    }

    final membershipPlanRef = renewal.membershipPlanRef;
    if (membershipPlanRef.parent.path != 'membership_plans') {
      throw ArgumentError.value(
        membershipPlanRef.path,
        'renewal.membershipPlanRef',
        'Must reference a membership plan document.',
      );
    }

    final firestore = FirestoreInstance.instance;
    final memberDocument = firestore.collection('members').doc(memberUid);
    final renewalDocument = myCollection.doc(renewal.uid);

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
        final membershipPlanSnapshot = await transaction.get(membershipPlanRef);
        if (!membershipPlanSnapshot.exists) {
          throw StateError(
            'Membership plan "${membershipPlanRef.path}" was not found.',
          );
        }
      }

      final renewalSnapshot = await transaction.get(renewalDocument);
      transaction.set(
        renewalDocument,
        dataForUpsert(renewal, renewalSnapshot.data()),
      );
      return !renewalSnapshot.exists;
    });
  }

  @override
  Future<CoreRenewal> getById(String uid) async {
    final snapshot = await myCollection.doc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Core renewal with id "$uid" was not found.');
    }

    final startDate = data['startDate'] as Timestamp;
    final endDate = data['endDate'] as Timestamp;
    final creationDate = data['creationDate'] as Timestamp;
    final deletionDate = data['deletionDate'] as Timestamp?;

    return CoreRenewal(
      uid: data['uid'] as String,
      startDate: CoreDate.fromTimestamp(startDate),
      endDate: CoreDate.fromTimestamp(endDate),
      membershipPlanRef:
          data['membershipPlanRef'] as DocumentReference<Map<String, dynamic>>,
      paymentRef: data['paymentRef'] as DocumentReference<Map<String, dynamic>>,
      amount: (data['amount'] as num).toDouble(),
      creationDate: CoreDate.fromTimestamp(creationDate),
      deletionDate: deletionDate == null
          ? null
          : CoreDate.fromTimestamp(deletionDate),
    );
  }
}

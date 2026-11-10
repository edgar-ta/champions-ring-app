import 'package:champions_ring_app/core/firebase/firestore_instance.dart';
import 'package:champions_ring_app/core/models/core_date.dart';
import 'package:champions_ring_app/core/models/core_member.dart';
import 'package:champions_ring_app/core/repositories/core_client_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoreMemberRepository {
  /// Inserts a new `member` document in Firestore or updates an already existing
  /// one with the same uid as the object given.
  ///
  /// In order for a `member` to be created there must exist a client with
  /// the same uid as the `CoreMember` object given, otherwise, the method
  /// throws an error.
  ///
  /// Returns `true` only if the document was just created.
  Future<bool> upsertCoreMember(CoreMember member) async {
    final clientExists = await CoreClientRepository().isCoreClientPresent(
      member.uid,
    );
    if (!clientExists) {
      throw StateError(
        'Cannot create member "${member.uid}" without an existing client.',
      );
    }

    final firestore = FirestoreInstance.instance;
    final memberDocument = firestore.collection('members').doc(member.uid);

    return firestore.runTransaction((transaction) async {
      final memberSnapshot = await transaction.get(memberDocument);
      transaction.set(memberDocument, member.toFirebaseMap());
      return !memberSnapshot.exists;
    });
  }

  Future<CoreMember> getCoreMemberById(String uid) async {
    final snapshot = await FirestoreInstance.instance
        .collection('members')
        .doc(uid)
        .get();
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Core member with id "$uid" was not found.');
    }

    final birthDate = data['birthDate'] as Timestamp;
    final creationDate = data['creationDate'] as Timestamp;
    final deletionDate = data['deletionDate'] as Timestamp?;

    return CoreMember(
      uid: data['uid'] as String,
      birthDate: CoreDate.fromTimestamp(birthDate),
      phone: data['phone'] as String,
      photoUrl: data['photoUrl'] as String?,
      legalDataAreTheirs: data['legalDataAreTheirs'] as bool,
      inscriptionPayed: data['inscriptionPayed'] as bool,
      membershipPlanRef:
          data['membershipPlanRef'] as DocumentReference<Map<String, dynamic>>?,
      latestRenewalRef:
          data['latestRenewalRef'] as DocumentReference<Map<String, dynamic>>?,
      guardianName: data['guardianName'] as String?,
      guardianPhone: data['guardianPhone'] as String?,
      guardianRelationship: data['guardianRelationship'] as String?,
      curpUrl: data['curpUrl'] as String?,
      curpValidated: data['curpValidated'] as bool?,
      ineBackUrl: data['ineBackUrl'] as String,
      ineBackValidated: data['ineBackValidated'] as bool,
      ineFrontUrl: data['ineFrontUrl'] as String,
      ineFrontValidated: data['ineFrontValidated'] as bool,
      waiverAgreementUrl: data['waiverAgreementUrl'] as String?,
      waiverAgreementValidated: data['waiverAgreementValidated'] as bool?,
      creationDate: CoreDate.fromTimestamp(creationDate),
      deletionDate: deletionDate == null
          ? null
          : CoreDate.fromTimestamp(deletionDate),
    );
  }
}

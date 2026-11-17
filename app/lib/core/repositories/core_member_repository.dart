import 'package:champions_ring_app/core/models/core_date.dart';
import 'package:champions_ring_app/core/models/core_member.dart';
import 'package:champions_ring_app/core/repositories/core_client_repository.dart';
import 'package:champions_ring_app/core/utils/base_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoreMemberRepository extends BaseRepository<CoreMember> {
  @override
  String get collectionName => 'members';

  /// Inserts a new `member` document in Firestore or updates an already existing
  /// one with the same uid as the object given.
  ///
  /// In order for a `member` to be created there must exist a client with
  /// the same uid as the `CoreMember` object given, otherwise, the method
  /// throws an error.
  ///
  /// Returns `true` only if the document was just created.
  @override
  Future<bool> upsert(CoreMember member) async {
    final clientExists = await CoreClientRepository().isDocumentPresent(
      member.uid,
    );
    if (!clientExists) {
      throw StateError(
        'Cannot create member "${member.uid}" without an existing client.',
      );
    }

    return super.upsert(member);
  }

  @override
  Future<CoreMember> getById(String uid) async {
    final snapshot = await myCollection.doc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Core member with id "$uid" was not found.');
    }

    final birthDate = data['birthDate'] as Timestamp;
    final creationDate = data['creationDate'] as Timestamp;
    final deletionDate = data['deletionDate'] as Timestamp?;
    final inscriptionPaid = data['inscriptionPaid'] ?? data['inscriptionPayed'];
    if (inscriptionPaid is! bool) {
      throw FormatException('El campo "inscriptionPaid" debe ser booleano.');
    }

    return CoreMember(
      uid: data['uid'] as String,
      birthDate: CoreDate.fromTimestamp(birthDate),
      phone: data['phone'] as String,
      photoUrl: data['photoUrl'] as String?,
      legalDataAreTheirs: data['legalDataAreTheirs'] as bool,
      inscriptionPaid: inscriptionPaid,
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

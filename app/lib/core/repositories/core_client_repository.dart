import 'package:champions_ring_app/core/models/core_date.dart';
import 'package:champions_ring_app/core/models/core_client.dart';
import 'package:champions_ring_app/core/utils/base_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoreClientRepository extends BaseRepository<CoreClient> {
  @override
  String get collectionName => 'clients';

  @override
  Future<CoreClient> getById(String uid) async {
    final snapshot = await myCollection.doc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Core client with id "$uid" was not found.');
    }

    final sampleClassDate = data['sampleClassDate'];
    final deletionDate = data['deletionDate'];
    return CoreClient(
      uid: data['uid'] as String,
      name: data['name'] as String,
      lastName: data['lastName'] as String,
      email: data['email'] as String,
      creationDate: CoreDate.fromTimestamp(data['creationDate'] as Timestamp),
      sampleClassDate: sampleClassDate == null
          ? null
          : CoreDate.fromTimestamp(sampleClassDate as Timestamp),
      deletionDate: deletionDate == null
          ? null
          : CoreDate.fromTimestamp(deletionDate as Timestamp),
    );
  }
}

import 'package:champions_ring_app/core/models/core_date.dart';
import 'package:champions_ring_app/core/models/core_client.dart';
import 'package:champions_ring_app/core/utils/base_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoreClientRepository extends BaseRepository<CoreClient> {
  @override
  String get collectionName => 'clients';

  /// Inserts a new `client` document in Firestore or updates an already existing
  /// one with the same uid as the object given.
  ///
  /// Returns `true` only if the document was just created.
  Future<bool> upsertCoreClient(CoreClient client) => upsert(client);

  Future<CoreClient> getCoreClientById(String uid) => getById(uid);

  @override
  Future<CoreClient> getById(String uid) async {
    final snapshot = await myCollection.doc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Core client with id "$uid" was not found.');
    }

    final sampleClassDate = data['sampleClassDate'];
    return CoreClient(
      uid: data['uid'] as String,
      name: data['name'] as String,
      lastName: data['lastName'] as String,
      email: data['email'] as String,
      sampleClassDate: sampleClassDate == null
          ? null
          : CoreDate.fromTimestamp(sampleClassDate as Timestamp),
    );
  }
}

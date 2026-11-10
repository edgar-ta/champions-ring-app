import 'package:champions_ring_app/core/firebase/firestore_instance.dart';
import 'package:champions_ring_app/core/models/core_date.dart';
import 'package:champions_ring_app/core/models/core_client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoreClientRepository {
  /// Inserts a new `client` document in Firestore or updates an already existing
  /// one with the same uid as the object given.
  ///
  /// Returns `true` only if the document was just created.
  Future<bool> upsertCoreClient(CoreClient client) async {
    final document = FirestoreInstance.instance
        .collection('clients')
        .doc(client.uid);

    return FirestoreInstance.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      transaction.set(document, client.toFirebaseMap());
      return !snapshot.exists;
    });
  }

  Future<CoreClient> getCoreClientById(String uid) async {
    final snapshot = await FirestoreInstance.instance
        .collection('clients')
        .doc(uid)
        .get();
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

  /// Verifies that a `client` document with the given id exists
  Future<bool> isCoreClientPresent(String uid) async {
    final snapshot = await FirestoreInstance.instance
        .collection('clients')
        .doc(uid)
        .get();
    return snapshot.exists;
  }
}

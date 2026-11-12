import 'package:champions_ring_app/core/firebase/firestore_instance.dart';
import 'package:champions_ring_app/core/utils/firestore_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class BaseRepository<Entity extends FirestoreEntity> {
  String get collectionName;
  CollectionReference<Map<String, dynamic>> get myCollection =>
      FirestoreInstance.instance.collection(collectionName);

  /// Inserts a new document in Firestore or updates an already existing
  /// one with the same uid as the object given.
  ///
  /// Returns `true` only if the document was just created.
  Future<bool> upsert(Entity entity) {
    final firestore = FirestoreInstance.instance;
    final memberDocument = myCollection.doc(entity.uid);

    return firestore.runTransaction((transaction) async {
      final memberSnapshot = await transaction.get(memberDocument);
      transaction.set(memberDocument, entity.toFirebaseMap());
      return !memberSnapshot.exists;
    });
  }

  Future<Entity> getById(String uid);
  String get nextUid => myCollection.doc().id;
  Future<bool> isDocumentPresent(String uid) async {
    final snapshot = await myCollection.doc(uid).get();
    return snapshot.exists;
  }
}

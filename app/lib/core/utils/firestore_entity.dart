abstract class FirestoreEntity {
  Map<String, dynamic> toFirebaseMap();
  String get uid;

  const FirestoreEntity();
}

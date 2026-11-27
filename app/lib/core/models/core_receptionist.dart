import 'package:champions_ring_app/core/models/core_date.dart';
import 'package:champions_ring_app/core/utils/firestore_entity.dart';

/// @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ]
class CoreReceptionist extends FirestoreEntity {
  @override
  final String uid;
  final String name;
  final String lastName;
  final String email;

  final CoreDate creationDate;
  final CoreDate? deletionDate;

  const CoreReceptionist({
    required this.uid,
    required this.name,
    required this.lastName,
    required this.email,
    required this.creationDate,
    this.deletionDate,
  });

  @override
  Map<String, dynamic> toFirebaseMap() {
    return {
      'uid': uid,
      'name': name,
      'lastName': lastName,
      'email': email,
      'creationDate': creationDate.toFirebaseValue(),

      if (deletionDate != null) 'deletionDate': deletionDate!.toFirebaseValue(),
    };
  }
}

import 'package:champions_ring_app/core/models/core_date.dart' show CoreDate;
import 'package:champions_ring_app/core/utils/firestore_entity.dart';

/// @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ]
class CoreClient extends FirestoreEntity {
  @override
  final String uid;
  final String name;
  final String lastName;
  final String email;

  final CoreDate? sampleClassDate;
  final CoreDate creationDate;
  final CoreDate? deletionDate;

  const CoreClient({
    required this.uid,
    required this.name,
    required this.lastName,
    required this.email,
    required this.creationDate,
    this.sampleClassDate,
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

      if (sampleClassDate != null)
        'sampleClassDate': sampleClassDate!.toFirebaseValue(),
      if (deletionDate != null) 'deletionDate': deletionDate!.toFirebaseValue(),
    };
  }
}

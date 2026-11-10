import 'package:champions_ring_app/core/models/core_date.dart';

class CoreAdministrator {
  final String uid;
  final String name;
  final String lastName;
  final String email;

  final CoreDate creationDate;
  final CoreDate? deletionDate;

  const CoreAdministrator({
    required this.uid,
    required this.name,
    required this.lastName,
    required this.email,
    required this.creationDate,
    this.deletionDate,
  });

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

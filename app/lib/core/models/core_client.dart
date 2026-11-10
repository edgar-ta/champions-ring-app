import 'package:champions_ring_app/core/models/core_date.dart' show CoreDate;

class CoreClient {
  final String uid;
  final String name;
  final String lastName;
  final String email;

  final CoreDate? sampleClassDate;

  const CoreClient({
    required this.uid,
    required this.name,
    required this.lastName,
    required this.email,
    this.sampleClassDate,
  });

  Map<String, dynamic> toFirebaseMap() {
    return {
      'uid': uid,
      'name': name,
      'lastName': lastName,
      'email': email,

      if (sampleClassDate != null)
        'sampleClassDate': sampleClassDate!.toFirebaseValue(),
    };
  }
}

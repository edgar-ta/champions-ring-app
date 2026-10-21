import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

class FirestoreInstance {
  static Future<void> initialize() async {
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('FIREBASE APP: ${app.name}');
    print('FIREBASE PROJECT ID: ${app.options.projectId}');

    final firestore = FirebaseFirestore.instance;

    print('FIRESTORE DATABASE ID: ${firestore.databaseId}');
  }

  static FirebaseFirestore get instance {
    return FirebaseFirestore.instance;
  }
}

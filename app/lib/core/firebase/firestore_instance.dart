import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

class FirestoreInstance {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  static final FirebaseFirestore instance = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'default',
  );
}

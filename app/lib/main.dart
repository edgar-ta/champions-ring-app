import 'package:flutter/material.dart';

import 'core/firebase/firestore_instance.dart';
import 'features/login/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirestoreInstance.initialize();

  runApp(const ChampionRingApp();
}

class ChampionRingApp extends StatelessWidget {
  const ChampionRingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'core/firebase/firebase_service.dart';
import 'features/login/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home:const LoginScreen(),
    );
  }
}
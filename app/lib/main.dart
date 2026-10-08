import 'package:flutter/material.dart';
import 'package:champions_ring_app/features/authentication/screens/login_screen.dart';

void main() {
  runApp(const ChampionRingApp());
}

class ChampionRingApp extends StatelessWidget {
  const ChampionRingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Champion's Ring",
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF3045)),
        fontFamily: 'Arial',
      ),
      home: const LoginScreen(),
    );
  }
}

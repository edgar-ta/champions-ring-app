import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../login/screens/login_screen.dart';
import '../../registro/widgets/registro_form.dart' show kRojo;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final correo = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: kRojo, size: 72),
                const SizedBox(height: 16),
                const Text(
                  'Sesión iniciada',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  correo,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
                const SizedBox(height: 32),
                OutlinedButton(
                  onPressed: () => _cerrarSesion(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A1A),
                    side: const BorderSide(color: Color(0xFFE3E3E3)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'CERRAR SESIÓN',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, letterSpacing: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
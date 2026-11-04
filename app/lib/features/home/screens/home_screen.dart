import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/logout_button.dart';
import '../widgets/membership_status_view.dart';
import '../widgets/status_card.dart' show kGris;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Mi membresía',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(email, style: const TextStyle(fontSize: 13, color: kGris)),
              const SizedBox(height: 24),
              if (user == null)
                const Text('No hay una sesión iniciada.')
              else
                MembershipStatusView(uid: user.uid),
              const SizedBox(height: 32),
              const LogoutButton(),
            ],
          ),
        ),
      ),
    );
  }
}

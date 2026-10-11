import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../models/user_form_data.dart';
import '../widgets/registro_form.dart';
import '../widgets/registro_pagina.dart';
import 'upload_adult_id_screen.dart';
import 'upload_guardian_id_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isLoading = false;

  // Tu base de datos se llama "default" (sin paréntesis), no "(default)".
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'default',
  );

  Future<void> _registerUser(UserFormData usuario) async {
    setState(() => _isLoading = true);

    try {
      // 1. Crear cuenta en Firebase Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: usuario.email,
        password: usuario.password,
      );
      final user = cred.user!;

      // 2. Guardar datos en Firestore: users/{uid}
      try {
        await _db
            .collection('users')
            .doc(user.uid)
            .set(usuario.toMap(user.uid))
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        // Si falla Firestore, borramos la cuenta de Auth para no dejarla huérfana
        await user.delete();
        rethrow;
      }

      if (!mounted) return;

      // 3. Mayor de edad -> sube su INE. Menor -> datos y documentos del tutor.
      final Widget destino = usuario.isOfLegalAge
          ? const UploadAdultIdScreen()
          : const UploadGuardianIdScreen();
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => destino));
    } on TimeoutException {
      _showSnackbar('No se pudo guardar en Firestore. Revisa tu conexión.');
    } on FirebaseAuthException catch (e) {
      _showSnackbar(_decodeRegistrationError(e.code));
    } on FirebaseException catch (e) {
      _showSnackbar('Error de Firebase: ${e.message}');
    } catch (e) {
      _showSnackbar('Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _decodeRegistrationError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Ese correo ya está registrado';
      case 'invalid-email':
        return 'Correo inválido';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'network-request-failed':
        return 'Sin conexión a internet';
      default:
        return 'Error de autenticación: $code';
    }
  }

  void _showSnackbar(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return RegistroPagina(
      paso: 1,
      nombrePaso: 'Datos personales',
      siguiente: 'Documentos',
      titulo: 'Datos personales',
      subtitulo:
          'Introduce tu información para comenzar con tu alta de estudiante.',
      cargando: _isLoading,
      child: RegistroForm(onSubmit: _registerUser),
    );
  }
}

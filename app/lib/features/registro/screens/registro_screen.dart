import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../widgets/registro_form.dart';
import '../widgets/registro_pagina.dart';
import 'documentos_adulto_screen.dart';
import 'documentos_tutor_screen.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  bool _cargando = false;

  // Tu base de datos se llama "default" (sin paréntesis), no "(default)".
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'default',
  );

  Future<void> _registrar(Usuario usuario) async {
    setState(() => _cargando = true);

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
      final Widget destino = usuario.esMayorDeEdad
          ? const DocumentosAdultoScreen()
          : const DocumentosTutorScreen();
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => destino));
    } on TimeoutException {
      _mostrarMensaje('No se pudo guardar en Firestore. Revisa tu conexión.');
    } on FirebaseAuthException catch (e) {
      _mostrarMensaje(_mensajeAuth(e.code));
    } on FirebaseException catch (e) {
      _mostrarMensaje('Error de Firebase: ${e.message}');
    } catch (e) {
      _mostrarMensaje('Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _mensajeAuth(String code) {
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

  void _mostrarMensaje(String texto) {
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
      cargando: _cargando,
      child: RegistroForm(onSubmit: _registrar),
    );
  }
}
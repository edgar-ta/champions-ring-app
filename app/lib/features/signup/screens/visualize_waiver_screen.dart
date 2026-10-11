import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/liability_waiver.dart';
import '../widgets/registro_form.dart' show kRojo;
import '../widgets/registro_pagina.dart';
import 'sign_waiver_screen.dart';

import '../../login/screens/login_screen.dart';

/// Paso 4: leer la carta responsiva y firmarla.
class VisualizeWaiverScreen extends StatefulWidget {
  const VisualizeWaiverScreen({super.key});

  @override
  State<VisualizeWaiverScreen> createState() => _VisualizeWaiverScreenState();
}

class _VisualizeWaiverScreenState extends State<VisualizeWaiverScreen> {
  Uint8List? _signatureBytes;
  bool _isSaving = false;

  Future<void> _sign() async {
    final bytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => const SignWaiverScreen()),
    );
    if (bytes != null && mounted) setState(() => _signatureBytes = bytes);
  }

  void _showSnackBar(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _saveSignature() async {
    final firma = _signatureBytes;
    final user = FirebaseAuth.instance.currentUser;
    if (firma == null) return;
    if (user == null) {
      _showSnackBar('Tu sesión expiró. Inicia sesión de nuevo.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      // 1. ///

      // 2. Actualizar users/{uid} (misma base "default" que usa RegistroScreen)
      final db = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );
      await db
          .collection('users')
          .doc(user.uid)
          .update({'signature_url': true, 'legal_data_are_theirs': true})
          .timeout(const Duration(seconds: 15));

      // 3. Cerrar la sesión que quedó abierta desde el paso 1 y mandar al login
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on TimeoutException {
      _showSnackBar('No se pudo guardar. Revisa tu conexión.');
    } on FirebaseException catch (e) {
      _showSnackBar('Error de Firebase: ${e.message}');
    } catch (e) {
      _showSnackBar('Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildAlertModal() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1F1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFF2A6AA)),
    ),
    child: const Row(
      children: [
        Icon(Icons.error_outline, color: kRojo, size: 18),
        SizedBox(width: 8),
        Text(
          'Firma requerida para continuar',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: kRojo,
          ),
        ),
      ],
    ),
  );

  Widget _buildSignaturePreview() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE3E3E3)),
    ),
    child: Row(
      children: [
        const Text(
          'Tu firma',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B6B6B),
          ),
        ),
        const Spacer(),
        Image.memory(_signatureBytes!, height: 56),
      ],
    ),
  );

  Widget _buildLiabilityWaiverFormat() => Container(
    height: 280,
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE3E3E3)),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 48),
            child: Column(
              children: [
                const Text(
                  liabilityWaiverTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                for (final p in liabilityWaiverParagraphs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      p,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B6B6B),
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Degradado inferior que sugiere que hay más texto
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withValues(alpha: 0), Colors.white],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final hasBeenSigned = _signatureBytes != null;

    return RegistroPagina(
      paso: 4,
      cargando: _isSaving,
      nombrePaso: 'Responsiva',
      siguiente: 'Finalizar',
      titulo: 'Carta Responsiva',
      subtitulo: 'Por favor revisa el documento legal de deslinde de responsabilidad antes de estampar tu firma digital.',
      pie: const PiePagina(
        texto: '¿Necesitas ayuda? ',
        accion: 'Soporte técnico',
        subrayar: true,
        // TODO: abrir soporte técnico
      ),
      child: Column(
        children: [
          hasBeenSigned ? _buildSignaturePreview() : _buildAlertModal(),
          const SizedBox(height: 14),
          _buildLiabilityWaiverFormat(),
          const SizedBox(height: 18),
          BotonRojo(
            texto: hasBeenSigned ? 'CAMBIAR FIRMA' : 'FIRMAR DOCUMENTO',
            icono: Icons.edit_outlined,
            onPressed: _sign,
          ),
          if (!hasBeenSigned) ...[
            const SizedBox(height: 10),
            const Text(
              'Una vez firmado el documento, podrás avanzar al registro final.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF6B6B6B)),
            ),
          ],
          const SizedBox(height: 14),
          BotonRojo(
            texto: 'CONTINUAR',
            onPressed: hasBeenSigned ? _saveSignature : null,
          ),
        ],
      ),
    );
  }
}

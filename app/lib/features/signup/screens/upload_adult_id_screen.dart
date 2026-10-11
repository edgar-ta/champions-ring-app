import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../widgets/registro_pagina.dart';
import '../widgets/tarjeta_documento.dart';
import 'select_membership_plan_screen.dart';

/// Paso 2 para mayores de edad: subir su propia INE.
class UploadAdultIdScreen extends StatefulWidget {
  const UploadAdultIdScreen({super.key});

  @override
  State<UploadAdultIdScreen> createState() => _UploadAdultIdScreenState();
}

class _UploadAdultIdScreenState extends State<UploadAdultIdScreen> {
  Uint8List? _ineBytes;

  void _moveToNextRegistrationStep() {
    if (_ineBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sube la foto de tu INE para continuar')),
      );
      return;
    }
    // TODO: subir _ine al almacenamiento y guardar ine_url en users/{uid}.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SelectMembershipPlanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RegistroPagina(
      paso: 2,
      nombrePaso: 'Documentos',
      siguiente: 'Membresías',
      titulo: 'Datos personales',
      subtitulo: 'Por favor, sube una imagen clara de tu identificación oficial vigente para validar tu identidad en el sistema escolar.',
      child: Column(
        children: [
          TarjetaDocumento(
            icono: Icons.photo_camera_outlined,
            titulo: 'Subir fotografía de INE',
            descripcion: 'Asegúrate de que la imagen sea legible y tenga buena iluminación.',
            onSeleccionado: (bytes) => _ineBytes = bytes,
          ),
          const SizedBox(height: 24),
          BotonRojo(texto: 'CONTINUAR', onPressed: _moveToNextRegistrationStep),
        ],
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../widgets/registro_pagina.dart';
import '../widgets/tarjeta_documento.dart';
import 'membresia_screen.dart';

/// Paso 2 para mayores de edad: subir su propia INE.
class DocumentosAdultoScreen extends StatefulWidget {
  const DocumentosAdultoScreen({super.key});

  @override
  State<DocumentosAdultoScreen> createState() => _DocumentosAdultoScreenState();
}

class _DocumentosAdultoScreenState extends State<DocumentosAdultoScreen> {
  Uint8List? _ine;

  void _continuar() {
    if (_ine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sube la foto de tu INE para continuar')),
      );
      return;
    }
    // TODO: subir _ine al almacenamiento y guardar ine_url en users/{uid}.
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const MembresiaScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return RegistroPagina(
      paso: 2,
      nombrePaso: 'Documentos',
      siguiente: 'Membresías',
      titulo: 'Datos personales',
      subtitulo:
          'Por favor, sube una imagen clara de tu identificación oficial vigente para validar tu identidad en el sistema escolar.',
      child: Column(
        children: [
          TarjetaDocumento(
            icono: Icons.photo_camera_outlined,
            titulo: 'Subir fotografía de INE',
            descripcion:
                'Asegúrate de que la imagen sea legible y tenga buena iluminación.',
            onSeleccionado: (bytes) => _ine = bytes,
          ),
          const SizedBox(height: 24),
          BotonRojo(texto: 'CONTINUAR', onPressed: _continuar),
        ],
      ),
    );
  }
}
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/registro_form.dart' show kRojo;
import '../widgets/registro_pagina.dart';
import '../widgets/tarjeta_documento.dart';
import 'membresia_screen.dart';

/// Paso 2 para menores de edad: datos y documentos del tutor legal.
class DocumentosTutorScreen extends StatefulWidget {
  const DocumentosTutorScreen({super.key});

  @override
  State<DocumentosTutorScreen> createState() => _DocumentosTutorScreenState();
}

class _DocumentosTutorScreenState extends State<DocumentosTutorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _parentescoCtrl = TextEditingController();

  Uint8List? _ineTutor;
  Uint8List? _fotoTutor;
  Uint8List? _curpEstudiante;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _parentescoCtrl.dispose();
    super.dispose();
  }

  void _continuar() {
    if (!_formKey.currentState!.validate()) return;
    if (_ineTutor == null || _fotoTutor == null || _curpEstudiante == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sube los tres documentos requeridos')),
      );
      return;
    }
    // TODO: subir documentos y guardar los datos del tutor.
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const MembresiaScreen()));
  }

  // ---------- estilos ----------
  OutlineInputBorder _borde(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c),
      );

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: _borde(const Color(0xFFE3E3E3)),
        focusedBorder: _borde(kRojo),
        errorBorder: _borde(Colors.red.shade700),
        focusedErrorBorder: _borde(Colors.red.shade700),
      );

  Widget _campo(String etiqueta, Widget campo) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(etiqueta,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B6B6B),
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            campo,
          ],
        ),
      );

  String? _requerido(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null;

  Widget _alerta() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF2A6AA)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: kRojo, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Autorización del tutor requerida',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFFB3202A))),
                  SizedBox(height: 4),
                  Text(
                    'Es necesario registrar los datos y la documentación del tutor legal para autorizar la participación y alta del menor.',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFFC5424B), height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return RegistroPagina(
      paso: 2,
      nombrePaso: 'Documentos',
      siguiente: 'Membresías',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _alerta(),
            const SizedBox(height: 22),
            const Text('Datos del tutor',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            _campo(
              'Nombre completo del tutor',
              TextFormField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _deco('Ej. María González Pérez'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  if (v.trim().split(RegExp(r'\s+')).length < 2) {
                    return 'Escribe nombre y apellido(s)';
                  }
                  return null;
                },
              ),
            ),
            _campo(
              'Teléfono del tutor',
              TextFormField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: _deco('Ej. 55 1234 5678'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  if (v.trim().length != 10) return 'Debe tener 10 dígitos';
                  return null;
                },
              ),
            ),
            _campo(
              'Parentesco con el estudiante',
              TextFormField(
                controller: _parentescoCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: _deco('Ej. Madre, Padre, Tutor legal'),
                validator: _requerido,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Documentos requeridos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TarjetaDocumento(
              icono: Icons.photo_camera_outlined,
              titulo: 'Subir fotografía del INE del tutor',
              descripcion:
                  'Asegúrate de que la imagen sea legible y tenga buena iluminación.',
              onSeleccionado: (b) => _ineTutor = b,
            ),
            const SizedBox(height: 14),
            TarjetaDocumento(
              icono: Icons.description_outlined,
              titulo: 'Fotografía del tutor',
              descripcion: 'Formatos JPG, PNG. Rostro visible sin gorra ni lentes.',
              onSeleccionado: (b) => _fotoTutor = b,
            ),
            const SizedBox(height: 14),
            TarjetaDocumento(
              icono: Icons.insert_drive_file_outlined,
              titulo: 'Fotografía del CURP del estudiante',
              descripcion: 'Formato oficial legible de la clave CURP',
              onSeleccionado: (b) => _curpEstudiante = b,
            ),
            const SizedBox(height: 24),
            BotonRojo(texto: 'CONTINUAR', onPressed: _continuar),
          ],
        ),
      ),
    );
  }
}
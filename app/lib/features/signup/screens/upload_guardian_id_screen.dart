import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/registro_form.dart' show kRojo;
import '../widgets/registro_pagina.dart';
import '../widgets/tarjeta_documento.dart';
import 'select_membership_plan_screen.dart';

/// Paso 2 para menores de edad: datos y documentos del tutor legal.
class UploadGuardianIdScreen extends StatefulWidget {
  const UploadGuardianIdScreen({super.key});

  @override
  State<UploadGuardianIdScreen> createState() => _UploadGuardianIdScreenState();
}

class _UploadGuardianIdScreenState extends State<UploadGuardianIdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _relationshipCtrl = TextEditingController();

  Uint8List? _guardianIneBytes;
  Uint8List? _guardianPhotoBytes;
  Uint8List? _studentCurpBytes;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _phoneCtrl.dispose();
    _relationshipCtrl.dispose();
    super.dispose();
  }

  void _moveToNextRegistrationStep() {
    if (!_formKey.currentState!.validate()) return;
    if (_guardianIneBytes == null ||
        _guardianPhotoBytes == null ||
        _studentCurpBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sube los tres documentos requeridos')),
      );
      return;
    }
    // TODO: subir documentos y guardar los datos del tutor.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SelectMembershipPlanScreen()),
    );
  }

  // ---------- estilos ----------
  OutlineInputBorder __buildInputBorder(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c),
  );

  InputDecoration _buildInputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 14),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    enabledBorder: __buildInputBorder(const Color(0xFFE3E3E3)),
    focusedBorder: __buildInputBorder(kRojo),
    errorBorder: __buildInputBorder(Colors.red.shade700),
    focusedErrorBorder: __buildInputBorder(Colors.red.shade700),
  );

  Widget _buildField(String etiqueta, Widget campo) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B6B6B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        campo,
      ],
    ),
  );

  String? _isRequired(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null;

  Widget _buildAlertModal() => Container(
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
              Text(
                'Autorización del tutor requerida',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFFB3202A),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Es necesario registrar los datos y la documentación del tutor legal para autorizar la participación y alta del menor.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFC5424B),
                  height: 1.3,
                ),
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
            _buildAlertModal(),
            const SizedBox(height: 22),
            const Text(
              'Datos del tutor',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _buildField(
              'Nombre completo del tutor',
              TextFormField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _buildInputDecoration('Ej. María González Pérez'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  if (v.trim().split(RegExp(r'\s+')).length < 2) {
                    return 'Escribe nombre y apellido(s)';
                  }
                  return null;
                },
              ),
            ),
            _buildField(
              'Teléfono del tutor',
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: _buildInputDecoration('Ej. 55 1234 5678'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  if (v.trim().length != 10) return 'Debe tener 10 dígitos';
                  return null;
                },
              ),
            ),
            _buildField(
              'Parentesco con el estudiante',
              TextFormField(
                controller: _relationshipCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: _buildInputDecoration(
                  'Ej. Madre, Padre, Tutor legal',
                ),
                validator: _isRequired,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Documentos requeridos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TarjetaDocumento(
              icono: Icons.photo_camera_outlined,
              titulo: 'Subir fotografía del INE del tutor',
              descripcion: 'Asegúrate de que la imagen sea legible y tenga buena iluminación.',
              onSeleccionado: (b) => _guardianIneBytes = b,
            ),
            const SizedBox(height: 14),
            TarjetaDocumento(
              icono: Icons.description_outlined,
              titulo: 'Fotografía del tutor',
              descripcion:
                  'Formatos JPG, PNG. Rostro visible sin gorra ni lentes.',
              onSeleccionado: (b) => _guardianPhotoBytes = b,
            ),
            const SizedBox(height: 14),
            TarjetaDocumento(
              icono: Icons.insert_drive_file_outlined,
              titulo: 'Fotografía del CURP del estudiante',
              descripcion: 'Formato oficial legible de la clave CURP',
              onSeleccionado: (b) => _studentCurpBytes = b,
            ),
            const SizedBox(height: 24),
            BotonRojo(
              texto: 'CONTINUAR',
              onPressed: _moveToNextRegistrationStep,
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_form_data.dart';

const Color kRojo = Color(0xFFEA3A3F);
const Color _gris = Color(0xFF6B6B6B);

class PersonalDataForm extends StatefulWidget {
  final void Function(UserFormData usuario) onSubmit;

  const PersonalDataForm({super.key, required this.onSubmit});

  @override
  State<PersonalDataForm> createState() => _PersonalDataFormState();
}

class _PersonalDataFormState extends State<PersonalDataForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmationCtrl = TextEditingController();

  final _picker = ImagePicker();
  Uint8List? _photoBytes;
  DateTime? _birthDate;
  bool _seePassword = false;
  bool _seePasswordConfirmation = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dateCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final imagen = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (imagen == null) return;
    final bytes = await imagen.readAsBytes();
    setState(() => _photoBytes = bytes);
  }

  Future<void> _pickBirthDate() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(hoy.year - 18),
      firstDate: DateTime(1900),
      lastDate: hoy,
    );
    if (fecha != null) {
      setState(() {
        _birthDate = fecha;
        _dateCtrl.text =
            '${fecha.day.toString().padLeft(2, '0')} / ${fecha.month.toString().padLeft(2, '0')} / ${fecha.year}';
      });
    }
  }

  /// "Juan Pérez Alcedo" -> nombre "Juan", apellidos "Pérez Alcedo".
  /// Con 3 o más palabras, las dos últimas se toman como apellidos.
  ({String nombre, String apellidos}) _separateName(String completo) {
    final p = completo.trim().split(RegExp(r'\s+'));
    if (p.length == 2) return (nombre: p[0], apellidos: p[1]);
    final n = p.length - 2;
    return (
      nombre: p.sublist(0, n).join(' '),
      apellidos: p.sublist(n).join(' '),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final nombre = _separateName(_nameCtrl.text);

    widget.onSubmit(
      UserFormData(
        name: nombre.nombre,
        lastName: nombre.apellidos,
        birthDate: _birthDate!,
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
        photoBytes: _photoBytes,
      ),
    );
  }

  // ---------- estilos ----------
  OutlineInputBorder _buildInputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );

  InputDecoration _buildInputDecoration(
    String hint,
    IconData icono, {
    Widget? sufijo,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 14),
    prefixIcon: Icon(icono, color: const Color(0xFF555555), size: 20),
    suffixIcon: sufijo,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 16),
    enabledBorder: _buildInputBorder(const Color(0xFFE3E3E3)),
    focusedBorder: _buildInputBorder(kRojo),
    errorBorder: _buildInputBorder(Colors.red.shade700),
    focusedErrorBorder: _buildInputBorder(Colors.red.shade700),
  );

  Widget _buildInputField(String etiqueta, Widget campo) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            fontSize: 13,
            color: _gris,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        campo,
      ],
    ),
  );

  Widget _buildVisibilityIndicator(bool visible, VoidCallback onTap) =>
      IconButton(
        icon: Icon(
          visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: _gris,
          size: 20,
        ),
        onPressed: onTap,
      );

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputField('Fotografía del estudiante', _buildImageInput()),

          _buildInputField(
            'Nombre completo',
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _buildInputDecoration(
                'Juan Pérez Alcedo',
                Icons.person_outline,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                if (v.trim().split(RegExp(r'\s+')).length < 2) {
                  return 'Escribe nombre y apellido(s)';
                }
                return null;
              },
            ),
          ),

          _buildInputField(
            'Fecha de nacimiento',
            TextFormField(
              controller: _dateCtrl,
              readOnly: true,
              onTap: _pickBirthDate,
              decoration: _buildInputDecoration(
                'DD / MM / AAAA',
                Icons.calendar_today_outlined,
              ),
              validator: (_) =>
                  _birthDate == null ? 'Selecciona una fecha' : null,
            ),
          ),

          // Aviso azul
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBD4FA)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF2B6CD4), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Calculamos automáticamente tu mayoría de edad a partir de esta fecha para generar tu formato responsivo legal correspondiente.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2B5FB8),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildInputField(
            'Correo electrónico',
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _buildInputDecoration(
                'tu-correo@ejemplo.com',
                Icons.mail_outline,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                if (!v.contains('@') || !v.contains('.'))
                  return 'Correo inválido';
                return null;
              },
            ),
          ),

          _buildInputField(
            'Número de teléfono',
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: _buildInputDecoration(
                '10 dígitos',
                Icons.phone_outlined,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                if (v.trim().length != 10) return 'Debe tener 10 dígitos';
                return null;
              },
            ),
          ),

          _buildInputField(
            'Contraseña',
            TextFormField(
              controller: _passwordCtrl,
              obscureText: !_seePassword,
              decoration: _buildInputDecoration(
                'Crea una contraseña segura',
                Icons.lock_outline,
                sufijo: _buildVisibilityIndicator(
                  _seePassword,
                  () => setState(() => _seePassword = !_seePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo requerido';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
          ),

          _buildInputField(
            'Confirmar contraseña',
            TextFormField(
              controller: _passwordConfirmationCtrl,
              obscureText: !_seePasswordConfirmation,
              decoration: _buildInputDecoration(
                'Repite tu contraseña anterior',
                Icons.lock_outline,
                sufijo: _buildVisibilityIndicator(
                  _seePasswordConfirmation,
                  () => setState(
                    () => _seePasswordConfirmation = !_seePasswordConfirmation,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo requerido';
                if (v != _passwordCtrl.text)
                  return 'Las contraseñas no coinciden';
                return null;
              },
            ),
          ),

          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: kRojo,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'CONTINUAR',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageInput() {
    return GestureDetector(
      onTap: _pickPhoto,
      child: CustomPaint(
        painter: _DiscontinuousBorderPainter(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFFE0E0E0),
                    backgroundImage: _photoBytes != null
                        ? MemoryImage(_photoBytes!)
                        : null,
                    child: _photoBytes == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 36,
                          )
                        : null,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: kRojo,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sube una selfie o foto clara',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Formatos JPG, PNG. Rostro visible sin gorra ni lentes.',
                      style: TextStyle(fontSize: 11, color: _gris),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fondo gris claro con borde discontinuo y esquinas redondeadas.
class _DiscontinuousBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFF7F7F7));

    final paint = Paint()
      ..color = const Color(0xFFCFCFCF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

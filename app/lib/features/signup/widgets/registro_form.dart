import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/usuario.dart';

const Color kRojo = Color(0xFFEA3A3F);
const Color _gris = Color(0xFF6B6B6B);

class RegistroForm extends StatefulWidget {
  final void Function(Usuario usuario) onSubmit;

  const RegistroForm({super.key, required this.onSubmit});

  @override
  State<RegistroForm> createState() => _RegistroFormState();
}

class _RegistroFormState extends State<RegistroForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _picker = ImagePicker();
  Uint8List? _fotoBytes;
  DateTime? _fechaNacimiento;
  bool _verPassword = false;
  bool _verConfirm = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _fechaCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto() async {
    final imagen = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (imagen == null) return;
    final bytes = await imagen.readAsBytes();
    setState(() => _fotoBytes = bytes);
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(hoy.year - 18),
      firstDate: DateTime(1900),
      lastDate: hoy,
    );
    if (fecha != null) {
      setState(() {
        _fechaNacimiento = fecha;
        _fechaCtrl.text =
            '${fecha.day.toString().padLeft(2, '0')} / ${fecha.month.toString().padLeft(2, '0')} / ${fecha.year}';
      });
    }
  }

  /// "Juan Pérez Alcedo" -> nombre "Juan", apellidos "Pérez Alcedo".
  /// Con 3 o más palabras, las dos últimas se toman como apellidos.
  ({String nombre, String apellidos}) _separarNombre(String completo) {
    final p = completo.trim().split(RegExp(r'\s+'));
    if (p.length == 2) return (nombre: p[0], apellidos: p[1]);
    final n = p.length - 2;
    return (nombre: p.sublist(0, n).join(' '), apellidos: p.sublist(n).join(' '));
  }

  void _enviar() {
    if (!_formKey.currentState!.validate()) return;
    final nombre = _separarNombre(_nombreCtrl.text);

    widget.onSubmit(
      Usuario(
        name: nombre.nombre,
        lastName: nombre.apellidos,
        birthDate: _fechaNacimiento!,
        email: _correoCtrl.text.trim(),
        phone: _telefonoCtrl.text.trim(),
        password: _passwordCtrl.text,
        fotoBytes: _fotoBytes,
      ),
    );
  }

  // ---------- estilos ----------
  OutlineInputBorder _borde(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  InputDecoration _deco(String hint, IconData icono, {Widget? sufijo}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 14),
        prefixIcon: Icon(icono, color: const Color(0xFF555555), size: 20),
        suffixIcon: sufijo,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: _borde(const Color(0xFFE3E3E3)),
        focusedBorder: _borde(kRojo),
        errorBorder: _borde(Colors.red.shade700),
        focusedErrorBorder: _borde(Colors.red.shade700),
      );

  Widget _campo(String etiqueta, Widget campo) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(etiqueta,
                style: const TextStyle(
                    fontSize: 13, color: _gris, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            campo,
          ],
        ),
      );

  Widget _ojo(bool visible, VoidCallback onTap) => IconButton(
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
          _campo('Fotografía del estudiante', _cajaFoto()),

          _campo(
            'Nombre completo',
            TextFormField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _deco('Juan Pérez Alcedo', Icons.person_outline),
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
            'Fecha de nacimiento',
            TextFormField(
              controller: _fechaCtrl,
              readOnly: true,
              onTap: _elegirFecha,
              decoration:
                  _deco('DD / MM / AAAA', Icons.calendar_today_outlined),
              validator: (_) =>
                  _fechaNacimiento == null ? 'Selecciona una fecha' : null,
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
                        fontSize: 12, color: Color(0xFF2B5FB8), height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          _campo(
            'Correo electrónico',
            TextFormField(
              controller: _correoCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _deco('tu-correo@ejemplo.com', Icons.mail_outline),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                if (!v.contains('@') || !v.contains('.')) return 'Correo inválido';
                return null;
              },
            ),
          ),

          _campo(
            'Número de teléfono',
            TextFormField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: _deco('10 dígitos', Icons.phone_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                if (v.trim().length != 10) return 'Debe tener 10 dígitos';
                return null;
              },
            ),
          ),

          _campo(
            'Contraseña',
            TextFormField(
              controller: _passwordCtrl,
              obscureText: !_verPassword,
              decoration: _deco(
                'Crea una contraseña segura',
                Icons.lock_outline,
                sufijo:
                    _ojo(_verPassword, () => setState(() => _verPassword = !_verPassword)),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo requerido';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
          ),

          _campo(
            'Confirmar contraseña',
            TextFormField(
              controller: _confirmCtrl,
              obscureText: !_verConfirm,
              decoration: _deco(
                'Repite tu contraseña anterior',
                Icons.lock_outline,
                sufijo:
                    _ojo(_verConfirm, () => setState(() => _verConfirm = !_verConfirm)),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo requerido';
                if (v != _passwordCtrl.text) return 'Las contraseñas no coinciden';
                return null;
              },
            ),
          ),

          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _enviar,
              style: ElevatedButton.styleFrom(
                backgroundColor: kRojo,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'CONTINUAR',
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cajaFoto() {
    return GestureDetector(
      onTap: _elegirFoto,
      child: CustomPaint(
        painter: _BordeDiscontinuo(),
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
                    backgroundImage:
                        _fotoBytes != null ? MemoryImage(_fotoBytes!) : null,
                    child: _fotoBytes == null
                        ? const Icon(Icons.person, color: Colors.white, size: 36)
                        : null,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                          color: kRojo, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sube una selfie o foto clara',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    SizedBox(height: 4),
                    Text('Formatos JPG, PNG. Rostro visible sin gorra ni lentes.',
                        style: TextStyle(fontSize: 11, color: _gris)),
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
class _BordeDiscontinuo extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(16));
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
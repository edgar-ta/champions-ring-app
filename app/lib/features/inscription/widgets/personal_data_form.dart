import 'dart:typed_data';

import 'package:champions_ring_app/core/models/core_user.dart'
    show CoreUserType;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_inscription_data.dart';
import '../../../shared/widgets/phone_number_input.dart';

const Color kRojo = Color(0xFFEA3A3F);
const Color _gris = Color(0xFF6B6B6B);

class PersonalDataForm extends StatefulWidget {
  final void Function(UserInscription_PersonalData usuario) onSubmit;
  final UserInscription_PersonalData? initialData;

  const PersonalDataForm({super.key, required this.onSubmit, this.initialData});

  @override
  State<PersonalDataForm> createState() => _PersonalDataFormState();
}

class _PersonalDataFormState extends State<PersonalDataForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _guardianNameCtrl = TextEditingController();
  final _guardianRelationshipCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmationCtrl = TextEditingController();

  final _picker = ImagePicker();
  Uint8List? _photoBytes;
  String? _photoFormat;
  DateTime? _birthDate;
  String? _phoneValue;
  String? _guardianPhoneValue;
  bool _seePassword = false;
  bool _seePasswordConfirmation = false;

  @override
  void initState() {
    super.initState();
    _restoreData(widget.initialData);
  }

  @override
  void didUpdateWidget(covariant PersonalDataForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.initialData, widget.initialData)) {
      _restoreData(widget.initialData);
    }
  }

  void _restoreData(UserInscription_PersonalData? data) {
    if (data == null) return;
    _firstNameCtrl.text = data.name;
    _lastNameCtrl.text = data.lastName;
    _birthDate = data.birthDate;
    _dateCtrl.text = _formatDate(data.birthDate);
    _emailCtrl.text = data.email;
    _phoneValue = data.phone;
    _passwordCtrl.text = data.password;
    _passwordConfirmationCtrl.text = data.password;
    _guardianNameCtrl.text = data.guardianName ?? '';
    _guardianPhoneValue = data.guardianPhone;
    _guardianRelationshipCtrl.text = data.guardianRelationship ?? '';
    _photoBytes = data.photoBytes;
    _photoFormat = data.photoFormat;
  }

  // Formato de fecha: día/mes/año.
  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  bool get _isOfLegalAge {
    final birthDate = _birthDate;
    if (birthDate == null) return true;

    final today = DateTime.now();
    var age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age >= 18;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _guardianNameCtrl.dispose();
    _guardianRelationshipCtrl.dispose();
    _dateCtrl.dispose();
    _emailCtrl.dispose();
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

    if (bytes.length > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La foto de perfil no debe superar 5 MB.'),
          ),
        );
      }
      return;
    }

    setState(() {
      _photoBytes = bytes;
      final regexp = RegExp(r'\.([^.]+)$');
      _photoFormat = regexp.firstMatch(imagen.name)?.group(1)?.toLowerCase();
    });
  }

  // Abre el calendario en español de México.
  Future<void> _pickBirthDate() async {
    final hoy = DateTime.now();

    final fecha = await showDatePicker(
      context: context,
      locale: const Locale('es', 'MX'),
      initialDate: _birthDate ?? DateTime(hoy.year - 18),
      firstDate: DateTime(1900),
      lastDate: hoy,
    );

    if (fecha != null) {
      setState(() {
        _birthDate = fecha;
        _dateCtrl.text = _formatDate(fecha);
      });
    }
  }

  void _submit() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final birthDate = _birthDate;
    final phone = _phoneValue;
    final photoBytes = _photoBytes;
    final photoFormat = _photoFormat;

    if (birthDate == null || phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa tu fecha y teléfono.')),
      );
      return;
    }

    if (photoBytes == null || photoFormat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una foto de perfil.')),
      );
      return;
    }

    final isMinor = !_isOfLegalAge;
    final guardianName = _guardianNameCtrl.text.trim();
    final guardianPhone = _guardianPhoneValue;
    final guardianRelationship = _guardianRelationshipCtrl.text.trim();

    if (isMinor &&
        (guardianName.isEmpty ||
            guardianPhone == null ||
            guardianPhone.isEmpty ||
            guardianRelationship.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los datos del tutor.')),
      );
      return;
    }

    widget.onSubmit(
      UserInscription_PersonalData(
        name: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        type: widget.initialData?.type ?? CoreUserType.member,
        birthDate: birthDate,
        email: _emailCtrl.text.trim(),
        phone: phone,
        password: _passwordCtrl.text,
        photoBytes: photoBytes,
        photoFormat: photoFormat,
        guardianName: isMinor ? guardianName : null,
        guardianPhone: isMinor ? guardianPhone : null,
        guardianRelationship: isMinor ? guardianRelationship : null,
      ),
    );
  }

  // ---------- Estilos ----------

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

  // ---------- Interfaz del formulario ----------

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputField('Fotografía', _buildImageInput()),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInputField(
                  'Nombre(s)',
                  TextFormField(
                    controller: _firstNameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _buildInputDecoration(
                      'Juan',
                      Icons.person_outline,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Campo requerido'
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  'Apellidos',
                  TextFormField(
                    controller: _lastNameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _buildInputDecoration(
                      'Pérez Alcedo',
                      Icons.person_outline,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Campo requerido'
                        : null,
                  ),
                ),
              ),
            ],
          ),

          _buildInputField(
            'Fecha de nacimiento',
            TextFormField(
              controller: _dateCtrl,
              readOnly: true,
              onTap: _pickBirthDate,
              decoration: _buildInputDecoration(
                'DD/MM/AAAA',
                Icons.calendar_today_outlined,
              ),
              validator: (_) =>
                  _birthDate == null ? 'Selecciona una fecha' : null,
            ),
          ),

          if (_birthDate != null && !_isOfLegalAge) ...[
            const SizedBox(height: 2),
            _buildInputField(
              'Nombre completo del tutor',
              TextFormField(
                controller: _guardianNameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _buildInputDecoration(
                  'Nombre y apellidos',
                  Icons.person_outline,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Campo requerido'
                    : null,
              ),
            ),
            _buildInputField(
              'Teléfono del tutor',
              PhoneNumberInput(
                initialValue: widget.initialData?.guardianPhone,
                onChanged: (value) => _guardianPhoneValue = value,
              ),
            ),
            _buildInputField(
              'Parentesco del tutor',
              TextFormField(
                controller: _guardianRelationshipCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: _buildInputDecoration(
                  'Madre, padre, tutor legal',
                  Icons.people_outline,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Campo requerido'
                    : null,
              ),
            ),
          ],

          _buildInputField(
            _isOfLegalAge
                ? 'Correo electrónico'
                : 'Correo electrónico de contacto',
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _buildInputDecoration(
                'tu-correo@ejemplo.com',
                Icons.mail_outline,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Campo requerido';
                }
                if (!v.contains('@') || !v.contains('.')) {
                  return 'Correo inválido';
                }
                return null;
              },
            ),
          ),

          _buildInputField(
            _isOfLegalAge
                ? 'Número de teléfono'
                : 'Número de teléfono personal',
            PhoneNumberInput(
              initialValue: widget.initialData?.phone,
              onChanged: (value) => _phoneValue = value,
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
                if (v != _passwordCtrl.text) {
                  return 'Las contraseñas no coinciden';
                }
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

import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/member_inscription_data.dart';
import '../../../shared/widgets/phone_number_input.dart';
import '../../../shared/ui/text_styles.dart';
import '../../../shared/ui/colors.dart';

const Color _gris = Color(0xFF6B6B6B);
final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

class PersonalDataForm extends StatefulWidget {
  final void Function(MemberInscription_PersonalData usuario) onSubmit;
  final MemberInscription_PersonalData? initialData;
  final bool showContinueButton;
  final VoidCallback? onChanged;
  final Future<bool?> Function(String email)? checkEmailAvailability;

  const PersonalDataForm({
    super.key,
    required this.onSubmit,
    this.initialData,
    this.showContinueButton = true,
    this.onChanged,
    this.checkEmailAvailability,
  });

  @override
  PersonalDataFormState createState() => PersonalDataFormState();
}

class PersonalDataFormState extends State<PersonalDataForm> {
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

  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  // Último resultado de checkEmailAvailable, por correo normalizado.
  String? _checkedEmail;
  bool? _checkedEmailAvailable;
  bool _checkingEmail = false;
  bool _submitting = false;
  Timer? _emailCheckDebounce;
  int _emailCheckGeneration = 0;

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

  void _restoreData(MemberInscription_PersonalData? data) {
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
    _emailCheckDebounce?.cancel();
    super.dispose();
  }

  String get _normalizedEmail => _emailCtrl.text.trim().toLowerCase();

  Future<void> submit() => _submit();

  /// Consulta en el servidor si el correo ya tiene cuenta. Devuelve null si
  /// no se pudo verificar (sin conexión, etc.); en ese caso se deja
  /// continuar y el error se detecta al crear la cuenta.
  void _onEmailChanged(String value) {
    _emailCheckDebounce?.cancel();
    final generation = ++_emailCheckGeneration;
    final email = value.trim().toLowerCase();

    setState(() {
      _checkingEmail = false;
    });

    if (!_emailPattern.hasMatch(email)) return;
    if (email == _checkedEmail) {
      _emailFieldKey.currentState?.validate();
      return;
    }

    _emailCheckDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || generation != _emailCheckGeneration) return;
      unawaited(_checkEmail(email, generation: generation));
    });
  }

  Future<bool?> _checkEmail(String? requestedEmail, {int? generation}) async {
    final email = requestedEmail ?? _normalizedEmail;
    if (!_emailPattern.hasMatch(email)) return null;
    if (email == _checkedEmail) return _checkedEmailAvailable;

    _emailCheckDebounce?.cancel();
    final requestGeneration = generation ?? ++_emailCheckGeneration;
    setState(() => _checkingEmail = true);
    bool? available;
    try {
      final checkEmailAvailability = widget.checkEmailAvailability;
      if (checkEmailAvailability != null) {
        available = await checkEmailAvailability(email);
      } else {
        final response =
            await FirebaseFunctions.instanceFor(region: 'us-central1')
                .httpsCallable('checkEmailAvailable')
                .call<Map<String, dynamic>>({'email': email});
        available = response.data['available'] as bool?;
      }
    } catch (e) {
      debugPrint('No se pudo verificar el correo: $e');
    }
    if (!mounted) return available;

    if (requestGeneration == _emailCheckGeneration) {
      setState(() {
        _checkingEmail = false;
        // Solo se guarda si el usuario no cambió el correo mientras tanto.
        if (available != null && email == _normalizedEmail) {
          _checkedEmail = email;
          _checkedEmailAvailable = available;
        }
      });
      _emailFieldKey.currentState?.validate();
    }
    return available;
  }

  String? _validateEmail(String? v) {
    final email = v?.trim().toLowerCase() ?? '';
    if (email.isEmpty) return 'Campo requerido';
    if (!_emailPattern.hasMatch(email)) return 'Correo inválido';
    if (email == _checkedEmail && _checkedEmailAvailable == false) {
      return 'Este correo ya está registrado. ';
    }
    return null;
  }

  Widget? _buildEmailStatusIcon() {
    if (_checkingEmail) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_normalizedEmail == _checkedEmail && _checkedEmailAvailable == true) {
      return const Icon(Icons.check_circle, color: Color(0xFF2E9E5B));
    }
    return null;
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
    widget.onChanged?.call();
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
      widget.onChanged?.call();
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final form = _formKey.currentState;
    if (form == null) return;

    if (!form.validate()) return;

    // Por si escribió el correo y tocó CONTINUAR sin salir del campo.
    setState(() => _submitting = true);
    final email = _normalizedEmail;
    final available = await _checkEmail(email);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (email != _normalizedEmail) return;
    if (available == false) {
      _emailFieldKey.currentState?.validate();
      return;
    }

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
      MemberInscription_PersonalData(
        name: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
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
    hintStyle: SharedTextStyles.inputHint,
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
        Text(etiqueta, style: SharedTextStyles.formSupporting),
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
      onChanged: widget.onChanged,
      autovalidateMode: AutovalidateMode.disabled,
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
                    style: SharedTextStyles.input,
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
                    style: SharedTextStyles.input,
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
              style: SharedTextStyles.input,
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
                style: SharedTextStyles.input,
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
                style: SharedTextStyles.input,
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
              key: _emailFieldKey,
              controller: _emailCtrl,
              style: SharedTextStyles.input,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              onChanged: _onEmailChanged,
              decoration: _buildInputDecoration(
                'tu-correo@ejemplo.com',
                Icons.mail_outline,
                sufijo: _buildEmailStatusIcon(),
              ),
              validator: _validateEmail,
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
              style: SharedTextStyles.input,
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
              style: SharedTextStyles.input,
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

          if (widget.showContinueButton) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
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
                      style: SharedTextStyles.inputHint,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Formatos JPG, PNG. Rostro visible sin gorra ni lentes.',
                      style: SharedTextStyles.inputHint,
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

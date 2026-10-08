import 'package:flutter/material.dart';

import '../widgets/authentication_header.dart';
import '../widgets/register_progress.dart';
import '../widgets/register_text_field.dart';
import '../widgets/document_upload_card.dart';
import 'register_documents_screen.dart';

class RegisterPersonalDataScreen extends StatefulWidget {
  const RegisterPersonalDataScreen({super.key});

  @override
  State<RegisterPersonalDataScreen> createState() =>
      _RegisterPersonalDataScreenState();
}

class _RegisterPersonalDataScreenState
    extends State<RegisterPersonalDataScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _fechaNacimientoController =
      TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _photoUploaded = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _fechaNacimientoController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        _fechaNacimientoController.text =
            '${selectedDate.day.toString().padLeft(2, '0')}/'
            '${selectedDate.month.toString().padLeft(2, '0')}/'
            '${selectedDate.year}';
      });
    }
  }

  void _uploadPhoto() {
    setState(() {
      _photoUploaded = true;
    });
  }

  void _goToDocuments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterDocumentsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthenticationHeader(
                showBackButton: true,
                onBackPressed: () {
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 28),

              const RegisterProgress(currentStep: 1, totalSteps: 4),

              const SizedBox(height: 30),

              const Text(
                'Datos personales',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F1F1F),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Introduce tu información para comenzar con tu registro.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF777777),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Fotografía del estudiante',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF777777),
                ),
              ),

              const SizedBox(height: 8),

              if (!_photoUploaded)
                DocumentUploadCard(
                  title: 'Sube una fotografía',
                  description:
                      'Utiliza una fotografía clara y reciente del estudiante.',
                  icon: Icons.person_outline,
                  buttonText: 'Subir fotografía',
                  onPressed: _uploadPhoto,
                )
              else
                UploadedPhotoCard(
                  onChange: () {
                    setState(() {
                      _photoUploaded = false;
                    });
                  },
                ),

              const SizedBox(height: 24),

              RegisterTextField(
                label: 'Nombre',
                hintText: 'Ingresa tu nombre',
                controller: _nombreController,
                prefixIcon: Icons.person_outline,
              ),

              const SizedBox(height: 18),

              RegisterTextField(
                label: 'Apellidos',
                hintText: 'Ingresa tus apellidos',
                controller: _apellidosController,
                prefixIcon: Icons.person_outline,
              ),

              const SizedBox(height: 18),

              RegisterTextField(
                label: 'Fecha de nacimiento',
                hintText: 'DD/MM/AAAA',
                controller: _fechaNacimientoController,
                prefixIcon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: _selectBirthDate,
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 19,
                      color: Color(0xFF777777),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Si el estudiante es menor de edad, será necesario registrar la información de su tutor.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              RegisterTextField(
                label: 'Correo electrónico',
                hintText: 'ejemplo@correo.com',
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),

              const SizedBox(height: 18),

              RegisterTextField(
                label: 'Contraseña',
                hintText: 'Ingresa tu contraseña',
                controller: _passwordController,
                obscureText: _obscurePassword,
                prefixIcon: Icons.lock_outline,
                suffixIcon: _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onSuffixPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),

              const SizedBox(height: 18),

              RegisterTextField(
                label: 'Confirmar contraseña',
                hintText: 'Repite tu contraseña',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                prefixIcon: Icons.lock_outline,
                suffixIcon: _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onSuffixPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _goToDocuments,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3044),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'CONTINUAR',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 13,
                    ),
                    children: [
                      const TextSpan(text: '¿Ya tienes una cuenta? '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Inicia sesión',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}

class UploadedPhotoCard extends StatelessWidget {
  const UploadedPhotoCard({super.key, required this.onChange});

  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E1E1)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFF3044),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fotografía cargada',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Fotografía agregada correctamente',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFFF3044),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: const Text(
              'Cambiar',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../widgets/authentication_header.dart';
import '../widgets/register_progress.dart';
import '../widgets/document_upload_card.dart';
import '../widgets/uploaded_document_card.dart';
import 'register_membership_screen.dart';

class RegisterDocumentsScreen extends StatefulWidget {
  const RegisterDocumentsScreen({super.key});

  @override
  State<RegisterDocumentsScreen> createState() =>
      _RegisterDocumentsScreenState();
}

class _RegisterDocumentsScreenState extends State<RegisterDocumentsScreen> {
  bool _studentDocumentUploaded = false;
  bool _tutorDocumentUploaded = false;

  void _uploadStudentDocument() {
    setState(() {
      _studentDocumentUploaded = true;
    });
  }

  void _uploadTutorDocument() {
    setState(() {
      _tutorDocumentUploaded = true;
    });
  }

  void _goToMembership() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterMembershipScreen()),
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

              const RegisterProgress(currentStep: 2, totalSteps: 4),

              const SizedBox(height: 30),

              const Text(
                'Documentos',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F1F1F),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Carga los documentos necesarios para completar tu registro.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF777777),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Documentación del estudiante',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Estos documentos son necesarios para completar el registro.',
                style: TextStyle(fontSize: 13, color: Color(0xFF777777)),
              ),

              const SizedBox(height: 18),

              if (!_studentDocumentUploaded)
                DocumentUploadCard(
                  title: 'Identificación del estudiante',
                  description:
                      'Sube una fotografía clara de la identificación oficial.',
                  icon: Icons.badge_outlined,
                  buttonText: 'Subir documento',
                  onPressed: _uploadStudentDocument,
                )
              else
                UploadedDocumentCard(
                  title: 'Identificación del estudiante',
                  onChange: () {
                    setState(() {
                      _studentDocumentUploaded = false;
                    });
                  },
                ),

              const SizedBox(height: 28),

              const Text(
                'Documentación del tutor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'En caso de que el estudiante sea menor de edad, se solicitará la documentación del tutor.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF777777),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 18),

              if (!_tutorDocumentUploaded)
                DocumentUploadCard(
                  title: 'Identificación del tutor',
                  description: 'Sube una fotografía clara de la identificación oficial del tutor.',
                  icon: Icons.family_restroom_outlined,
                  buttonText: 'Subir documento',
                  onPressed: _uploadTutorDocument,
                )
              else
                UploadedDocumentCard(
                  title: 'Identificación del tutor',
                  onChange: () {
                    setState(() {
                      _tutorDocumentUploaded = false;
                    });
                  },
                ),

              const SizedBox(height: 20),

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
                        'Asegúrate de que las fotografías sean claras, estén completas y sean legibles.',
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

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _goToMembership,
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

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}

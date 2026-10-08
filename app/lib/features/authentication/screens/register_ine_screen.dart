import 'package:flutter/material.dart';

import '../widgets/authentication_header.dart';
import '../widgets/register_progress.dart';
import '../widgets/document_upload_card.dart';
import '../widgets/uploaded_document_card.dart';

class RegisterIneScreen extends StatefulWidget {
  const RegisterIneScreen({super.key});

  @override
  State<RegisterIneScreen> createState() => _RegisterIneScreenState();
}

class _RegisterIneScreenState extends State<RegisterIneScreen> {
  bool _frontUploaded = false;
  bool _backUploaded = false;

  void _uploadFront() {
    setState(() {
      _frontUploaded = true;
    });
  }

  void _uploadBack() {
    setState(() {
      _backUploaded = true;
    });
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
                'Identificación oficial',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F1F1F),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Carga ambos lados de tu identificación oficial para continuar.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF777777),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'INE / Identificación oficial',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Asegúrate de que todos los datos sean visibles y legibles.',
                style: TextStyle(fontSize: 13, color: Color(0xFF777777)),
              ),

              const SizedBox(height: 18),

              if (!_frontUploaded)
                DocumentUploadCard(
                  title: 'Frente de la identificación',
                  description: 'Toma o sube una fotografía de la parte frontal de tu INE.',
                  icon: Icons.credit_card_outlined,
                  buttonText: 'Subir fotografía',
                  onPressed: _uploadFront,
                )
              else
                UploadedDocumentCard(
                  title: 'Frente de la identificación',
                  onChange: () {
                    setState(() {
                      _frontUploaded = false;
                    });
                  },
                ),

              const SizedBox(height: 18),

              if (!_backUploaded)
                DocumentUploadCard(
                  title: 'Reverso de la identificación',
                  description: 'Toma o sube una fotografía de la parte posterior de tu INE.',
                  icon: Icons.credit_card_outlined,
                  buttonText: 'Subir fotografía',
                  onPressed: _uploadBack,
                )
              else
                UploadedDocumentCard(
                  title: 'Reverso de la identificación',
                  onChange: () {
                    setState(() {
                      _backUploaded = false;
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
                        'La identificación debe estar vigente y las fotografías no deben estar borrosas ni cortadas.',
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
                  onPressed: () {},
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

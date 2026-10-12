import 'package:flutter/material.dart';

import '../models/user_inscription_data.dart';
import '../widgets/document_input.dart';
import '../widgets/registration_scaffold.dart';

/// Paso 2: carga el anverso y reverso de la INE del usuario o de su tutor.
class RegisterIdScreen extends StatefulWidget {
  final UserInscription_PersonalData personalData;
  final UserInscription_IdData? data;
  final ValueChanged<UserInscription_IdData> onDataChanged;
  final VoidCallback onContinue;

  const RegisterIdScreen({
    super.key,
    required this.personalData,
    required this.data,
    required this.onDataChanged,
    required this.onContinue,
  });

  @override
  State<RegisterIdScreen> createState() => _RegisterIdScreenState();
}

class _RegisterIdScreenState extends State<RegisterIdScreen> {
  static const _maxBytes = 20 * 1024 * 1024;

  bool get _isComplete {
    if (widget.data?.ineFrontBytes == null ||
        widget.data?.ineBackBytes == null) {
      return false;
    }
    final personalData = widget.personalData;
    return personalData.isOfLegalAge ||
        ((personalData.guardianName?.trim().isNotEmpty ?? false) &&
            RegExp(r'^\+(52|1)\d{10}$')
                .hasMatch(personalData.guardianPhone ?? '') &&
            (personalData.guardianRelationship?.trim().isNotEmpty ?? false));
  }

  void _pickFront(PickedDocument document) {
    widget.onDataChanged(
      (widget.data ?? UserInscription_IdData()).copyWith(
        ineFrontBytes: document.bytes,
        ineFrontFormat: document.format,
      ),
    );
  }

  void _pickBack(PickedDocument document) {
    widget.onDataChanged(
      (widget.data ?? UserInscription_IdData()).copyWith(
        ineBackBytes: document.bytes,
        ineBackFormat: document.format,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMinor = !widget.personalData.isOfLegalAge;
    final owner = isMinor ? 'del tutor' : 'del usuario';
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                DocumentInput(
                  icon: Icons.badge_outlined,
                  title: 'Anverso de la INE $owner',
                  description: 'Imagen legible y bien iluminada. Máximo 20 MB.',
                  maxBytes: _maxBytes,
                  initialBytes: widget.data?.ineFrontBytes,
                  onDocumentPicked: _pickFront,
                ),
                const SizedBox(height: 12),
                DocumentInput(
                  icon: Icons.badge_outlined,
                  title: 'Reverso de la INE $owner',
                  description: 'Imagen legible y bien iluminada. Máximo 20 MB.',
                  maxBytes: _maxBytes,
                  initialBytes: widget.data?.ineBackBytes,
                  onDocumentPicked: _pickBack,
                ),
              ],
            ),
          ),
        ),
        RedButton(
          text: 'CONTINUAR',
          onPressed: _isComplete ? widget.onContinue : null,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../models/user_inscription_data.dart';
import '../widgets/document_input.dart';
import '../widgets/registration_scaffold.dart';

/// Paso 2: carga la identificación del usuario o de su tutor y, para menores, su CURP.
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
  static const _ineMaxBytes = 5 * 1024 * 1024;
  static const _curpMaxBytes = 20 * 1024 * 1024;

  bool get _isComplete {
    if (widget.data?.ineFrontBytes == null ||
        widget.data?.ineBackBytes == null) {
      return false;
    }
    final personalData = widget.personalData;
    return personalData.isOfLegalAge ||
        (widget.data?.curpBytes != null &&
            widget.data?.curpFormat != null &&
            (personalData.guardianName?.trim().isNotEmpty ?? false) &&
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

  void _pickCurp(PickedDocument document) {
    widget.onDataChanged(
      (widget.data ?? UserInscription_IdData()).copyWith(
        curpBytes: document.bytes,
        curpFormat: document.format,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMinor = !widget.personalData.isOfLegalAge;
    final owner = isMinor ? 'del tutor' : '';
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                DocumentInput(
                  icon: Icons.badge_outlined,
                  title: 'Parte frontal de la INE $owner',
                  description: 'Imagen legible y bien iluminada. Máximo 5 MB.',
                  maxBytes: _ineMaxBytes,
                  initialBytes: widget.data?.ineFrontBytes,
                  onDocumentPicked: _pickFront,
                ),
                const SizedBox(height: 12),
                DocumentInput(
                  icon: Icons.badge_outlined,
                  title: 'Parte trasera de la INE $owner',
                  description: 'Imagen legible y bien iluminada. Máximo 5 MB.',
                  maxBytes: _ineMaxBytes,
                  initialBytes: widget.data?.ineBackBytes,
                  onDocumentPicked: _pickBack,
                ),
                if (isMinor) ...[
                  const SizedBox(height: 12),
                  DocumentInput(
                    icon: Icons.assignment_ind_outlined,
                    title: 'CURP del menor',
                    description:
                        'Imagen legible y bien iluminada. Máximo 20 MB.',
                    maxBytes: _curpMaxBytes,
                    initialBytes: widget.data?.curpBytes,
                    onDocumentPicked: _pickCurp,
                  ),
                ],
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

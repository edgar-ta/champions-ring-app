import 'package:flutter/material.dart';

import '../models/liability_waiver.dart';
import '../models/user_inscription_data.dart';
import '../widgets/personal_data_form.dart' show kRojo;
import '../widgets/registration_scaffold.dart';
import '../widgets/signature_canvas.dart';

/// Paso 3: lectura y firma de la carta responsiva.
class RegisterWaiverAgreementScreen extends StatefulWidget {
  final UserInscription_WaiverAgreementData? data;
  final ValueChanged<UserInscription_WaiverAgreementData?> onDataChanged;
  final VoidCallback onContinue;

  const RegisterWaiverAgreementScreen({
    super.key,
    required this.data,
    required this.onDataChanged,
    required this.onContinue,
  });

  @override
  State<RegisterWaiverAgreementScreen> createState() =>
      _RegisterWaiverAgreementScreenState();
}

class _RegisterWaiverAgreementScreenState
    extends State<RegisterWaiverAgreementScreen> {
  static const _maxBytes = 20 * 1024 * 1024;
  final _signature = SignatureController();

  @override
  void dispose() {
    _signature.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (widget.data != null) {
      widget.onContinue();
      return;
    }

    final bytes = await _signature.exportPng();
    if (bytes == null) {
      _showMessage('Dibuja tu firma antes de continuar.');
      return;
    }
    if (bytes.length > _maxBytes) {
      _showMessage('La firma no debe superar 20 MB.');
      return;
    }
    if (!mounted) return;
    widget.onDataChanged(
      UserInscription_WaiverAgreementData(signatureBytes: bytes),
    );
    widget.onContinue();
  }

  void _clear() {
    _signature.clear();
    widget.onDataChanged(null);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                liabilityWaiverTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              for (final paragraph in liabilityWaiverParagraphs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(paragraph, textAlign: TextAlign.justify),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Firma digital (máximo 20 MB)'),
                  TextButton(
                    onPressed: widget.data == null ? _signature.clear : _clear,
                    child: Text(
                      widget.data == null ? 'BORRAR TRAZO' : 'BORRAR FIRMA',
                      style: const TextStyle(color: kRojo),
                    ),
                  ),
                ],
              ),
              SignatureCanvas(
                ctrl: _signature,
                savedSignature: widget.data?.signatureBytes,
              ),
            ],
          ),
        ),
      ),
      RedButton(text: 'CONTINUAR', onPressed: _continue),
    ],
  );
}

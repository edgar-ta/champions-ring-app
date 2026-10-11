import 'package:flutter/material.dart';

import '../widgets/signature_canvas.dart';
import '../widgets/personal_data_form.dart' show kRojo;
import '../widgets/registration_scaffold.dart';

/// Pantalla "Firma digital". Al confirmar devuelve la firma como PNG
/// (Uint8List) con Navigator.pop; al cancelar devuelve null.
class SignWaiverScreen extends StatefulWidget {
  const SignWaiverScreen({super.key});

  @override
  State<SignWaiverScreen> createState() => _SignWaiverScreenState();
}

class _SignWaiverScreenState extends State<SignWaiverScreen> {
  final _ctrl = SignatureController();
  bool _isDrawing = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _confirmSignature() async {
    if (_ctrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dibuja tu firma para continuar')),
      );
      return;
    }
    final bytes = await _ctrl.exportPng();
    if (!mounted) return;
    Navigator.of(context).pop(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationScaffold(
      stepIndex: 4,
      stepName: 'Responsiva',
      nextStepName: 'Finalizar',
      headerTitle: 'FIRMA DIGITAL',
      title: 'Firma digital',
      subtitle: 'Por favor dibuja tu firma con el dedo en el espacio indicado para autorizar legalmente tu responsiva escolar.',
      showFooter: true,
      blockScrolling: _isDrawing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lienzo de firma',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B6B6B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton.icon(
                onPressed: _ctrl.clear,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.refresh, size: 16, color: kRojo),
                label: const Text(
                  'LIMPIAR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kRojo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SignatureCanvas(
            ctrl: _ctrl,
            onDrawing: (v) => setState(() => _isDrawing = v),
          ),
          const SizedBox(height: 14),
          Container(
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
                    'La firma se estampará automáticamente en el documento en formato PDF para el archivo escolar definitivo.',
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
          const SizedBox(height: 20),
          RedButton(text: 'CONFIRMAR FIRMA', onPressed: _confirmSignature),
          const SizedBox(height: 12),
          WhiteButton(
            text: 'CANCELAR',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

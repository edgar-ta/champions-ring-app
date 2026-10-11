import 'package:flutter/material.dart';

class RegisterProgress extends StatelessWidget {
  const RegisterProgress({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(totalSteps, (index) {
            final bool isActive = index < currentStep;

            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFFF3044)
                      : const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                children: [
                  TextSpan(
                    text: 'Paso $currentStep de $totalSteps: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF3044),
                    ),
                  ),
                  TextSpan(
                    text: _stepName(currentStep),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Text(
              'Siguiente: ${_nextStepName(currentStep)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  String _stepName(int step) {
    switch (step) {
      case 1:
        return 'Datos personales';
      case 2:
        return 'Documentos';
      case 3:
        return 'Membresías';
      case 4:
        return 'Confirmación';
      default:
        return '';
    }
  }

  String _nextStepName(int step) {
    switch (step) {
      case 1:
        return 'Documentos';
      case 2:
        return 'Membresías';
      case 3:
        return 'Confirmación';
      case 4:
        return 'Finalizar';
      default:
        return '';
    }
  }
}

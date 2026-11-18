import 'package:flutter/material.dart';

import '../widgets/registration_scaffold.dart';

class RegisterAccountValidationNoticeScreen extends StatelessWidget {
  final VoidCallback onContinue;
  final bool showContinueButton;

  const RegisterAccountValidationNoticeScreen({
    super.key,
    required this.onContinue,
    this.showContinueButton = true,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final imageHeight = (constraints.maxHeight * 0.52)
                .clamp(160.0, 320.0)
                .toDouble();

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/Gym_Verification_ 3_Days_Waiting.png',
                        width: constraints.maxWidth,
                        height: imageHeight,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Como ya te habías inscrito anteriormente, debes acudir al '
                        'gimnasio dentro de los próximos 3 días para que recepción '
                        'valide tu cuenta. Si no lo haces, tu cuenta será bloqueada.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      if (showContinueButton)
        RedButton(text: 'CONTINUAR', onPressed: onContinue),
    ],
  );
}

import 'package:flutter/material.dart';

import '../widgets/registration_scaffold.dart';

class RegisterAccountValidationNoticeScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const RegisterAccountValidationNoticeScreen({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 56, color: Color(0xFFEA3A3F)),
              SizedBox(height: 16),
              Text(
                'Como ya te habías inscrito anteriormente, debes acudir al '
                'gimnasio dentro de los próximos 4 días para que recepción '
                'valide tu cuenta. Si no lo haces, tu cuenta será bloqueada.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
            ],
          ),
        ),
      ),
      RedButton(text: 'CONTINUAR', onPressed: onContinue),
    ],
  );
}

import 'package:flutter/material.dart';

import '../models/member_inscription_data.dart';
import '../widgets/selectable_card.dart';
import '../widgets/registration_scaffold.dart';

/// Paso 1: pregunta si el usuario ya se había inscrito presencialmente.
class RegisterPreviousInscriptionScreen extends StatelessWidget {
  final MemberInscription_PreviousInscriptionData? data;
  final ValueChanged<MemberInscription_PreviousInscriptionData> onDataChanged;
  final VoidCallback onContinue;

  const RegisterPreviousInscriptionScreen({
    super.key,
    required this.data,
    required this.onDataChanged,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: ListView(
          children: [
            _AnswerButton(
              text: 'Sí, ya estoy inscrito al gimnasio',
              description: 'Ya he realizado mi proceso de inscripción y cuento o contaba con una suscripción activa.',
              imagePath: 'assets/images/Usuario_con_inscripcion.png',
              isSelected: data?.previouslySignedIn == true,
              onPressed: () => onDataChanged(
                MemberInscription_PreviousInscriptionData(
                  previouslySignedIn: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _AnswerButton(
              text: 'No, no estoy inscrito',
              description: 'Nunca he realizado el proceso de inscripción al gimnasio y me gustaría comenzarlo.',
              imagePath: 'assets/images/Usuario_sin_inscripcion.png',
              isSelected: data?.previouslySignedIn == false,
              onPressed: () => onDataChanged(
                MemberInscription_PreviousInscriptionData(
                  previouslySignedIn: false,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Nota: pagar la visita al gimnasio no es lo mismo que estar inscrito',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      RedButton(text: 'CONTINUAR', onPressed: data == null ? null : onContinue),
    ],
  );
}

class _AnswerButton extends StatelessWidget {
  final String text;
  final String description;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onPressed;

  const _AnswerButton({
    required this.text,
    required this.description,
    required this.imagePath,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SelectableCard(
    isSelected: isSelected,
    onTap: onPressed,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          imagePath,
          width: 104,
          height: 104,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: SelectionRadioIndicator(isSelected: isSelected),
              ),
              const SizedBox(height: 8),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B6B6B),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

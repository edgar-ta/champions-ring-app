import 'package:flutter/material.dart';

import '../models/user_inscription_data.dart';
import '../widgets/personal_data_form.dart';

/// Paso 1 del registro: captura de los datos personales y foto de perfil.
class RegisterPersonalDataScreen extends StatelessWidget {
  final UserInscription_PersonalData? initialData;
  final ValueChanged<UserInscription_PersonalData> onContinue;

  const RegisterPersonalDataScreen({
    super.key,
    required this.initialData,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: PersonalDataForm(initialData: initialData, onSubmit: onContinue),
  );
}

import 'package:flutter/material.dart';

import '../models/membership_plan.dart';
import '../widgets/registration_scaffold.dart';
import '../widgets/membership_card_plan.dart';
import 'visualize_waiver_screen.dart';

/// Paso 3: elegir la membresía.
class SelectMembershipPlanScreen extends StatefulWidget {
  const SelectMembershipPlanScreen({super.key});

  @override
  State<SelectMembershipPlanScreen> createState() =>
      _SelectMembershipPlanScreenState();
}

class _SelectMembershipPlanScreenState
    extends State<SelectMembershipPlanScreen> {
  // La membresía mensual viene seleccionada por defecto, como en el diseño.
  int _selectedPlan = 3;

  void _moveToNextRegistrationStep() {
    final elegida = memberships.firstWhere((m) => m.id == _selectedPlan);
    debugPrint('Membresía elegida: ${elegida.title} (\$${elegida.price} MXN)');
    // TODO: guardar la membresía elegida en Firestore.
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const VisualizeWaiverScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationScaffold(
      stepIndex: 3,
      stepName: 'Membresía',
      nextStepName: 'Responsiva',
      title: 'Elige tu membresía',
      subtitle: 'Selecciona la opción de entrenamiento que mejor se adapte a tus metas en el ring.',
      child: Column(
        children: [
          for (final m in memberships) ...[
            MembershipPlanCard(
              membershipPlan: m,
              isSelected: m.id == _selectedPlan,
              onTap: () => setState(() => _selectedPlan = m.id),
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 10),
          RedButton(text: 'CONTINUAR', onPressed: _moveToNextRegistrationStep),
        ],
      ),
    );
  }
}

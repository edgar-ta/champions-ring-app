import 'package:flutter/material.dart';

import '../models/membership_plan.dart';
import '../models/user_inscription_data.dart';
import '../widgets/membership_card_plan.dart';
import '../widgets/registration_scaffold.dart';

/// Paso 4: selección del plan de membresía.
class RegisterPlanSelectionScreen extends StatelessWidget {
  final UserInscription_PlanSelectionData? data;
  final ValueChanged<UserInscription_PlanSelectionData> onDataChanged;
  final VoidCallback onContinue;

  const RegisterPlanSelectionScreen({
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
            for (final plan in memberships) ...[
              MembershipPlanCard(
                membershipPlan: plan,
                isSelected: data?.membershipPlanId == plan.id,
                onTap: () => onDataChanged(
                  UserInscription_PlanSelectionData(membershipPlanId: plan.id),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
      RedButton(text: 'CONTINUAR', onPressed: data == null ? null : onContinue),
    ],
  );
}

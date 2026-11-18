import 'package:flutter/material.dart';

import '../../../core/models/core_membership_plan.dart';
import '../models/member_inscription_data.dart';
import '../widgets/membership_card_plan.dart';
import '../../../shared/widgets/red_button.dart';

/// Paso 4: selección del plan de membresía.
class RegisterPlanSelectionScreen extends StatelessWidget {
  final List<CoreMembershipPlan>? plans;
  final bool isLoading;
  final Object? loadError;
  final VoidCallback onRetry;
  final MemberInscription_PlanSelectionData? data;
  final ValueChanged<MemberInscription_PlanSelectionData> onDataChanged;
  final VoidCallback onContinue;
  final bool showContinueButton;

  const RegisterPlanSelectionScreen({
    super.key,
    required this.plans,
    required this.isLoading,
    required this.loadError,
    required this.onRetry,
    required this.data,
    required this.onDataChanged,
    required this.onContinue,
    this.showContinueButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final availablePlans = plans ?? const <CoreMembershipPlan>[];
    final hasSelectedPlan = availablePlans.any(
      (plan) => plan.uid == data?.membershipPlanUid,
    );

    return Column(
      children: [
        Expanded(child: _buildPlanContent(availablePlans)),
        if (showContinueButton)
          RedButton(
            text: 'CONTINUAR',
            onPressed: hasSelectedPlan ? onContinue : null,
          ),
      ],
    );
  }

  Widget _buildPlanContent(List<CoreMembershipPlan> availablePlans) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No se pudieron cargar los planes de membresía.'),
            TextButton(onPressed: onRetry, child: const Text('REINTENTAR')),
          ],
        ),
      );
    }
    if (availablePlans.isEmpty) {
      return const Center(
        child: Text('No hay planes de membresía activos disponibles.'),
      );
    }

    return ListView(
      children: [
        for (final plan in availablePlans) ...[
          MembershipPlanCard(
            membershipPlan: plan,
            isSelected: data?.membershipPlanUid == plan.uid,
            onTap: () => onDataChanged(
              MemberInscription_PlanSelectionData(membershipPlanUid: plan.uid),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

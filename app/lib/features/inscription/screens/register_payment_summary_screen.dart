import 'package:flutter/material.dart';

import '../models/membership_plan.dart';
import '../models/user_inscription_data.dart';
import '../widgets/registration_scaffold.dart';

/// Paso 5: revisa el plan y el importe antes de elegir cómo pagar.
class RegisterPaymentSummaryScreen extends StatelessWidget {
  static const _enrollmentCost = 120;

  final UserInscription_PlanSelectionData? data;
  final VoidCallback onContinue;

  const RegisterPaymentSummaryScreen({
    super.key,
    required this.data,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final selectedPlan = memberships.where(
      (plan) => plan.id == data?.membershipPlanId,
    );
    final plan = selectedPlan.isEmpty ? null : selectedPlan.first;
    final planCost = plan?.price ?? 0;
    final total = planCost + _enrollmentCost;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Plan de entrenamiento',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(plan?.title ?? 'Sin plan seleccionado'),
                        if (plan != null) ...[
                          const SizedBox(height: 4),
                          Text(plan.validity),
                          if (plan.benefits.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Beneficios incluidos',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            for (final benefit in plan.benefits)
                              _BenefitRow(text: benefit),
                          ],
                        ],
                        const Divider(height: 24),
                        const Text(
                          'Inscripción: kit de bienvenida',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Incluye un protector bucal y un par de vendas.',
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _SummaryRow(label: 'Plan', amount: planCost),
                        const SizedBox(height: 8),
                        const _SummaryRow(
                          label: 'Inscripción',
                          amount: _enrollmentCost,
                        ),
                        const Divider(height: 24),
                        _SummaryRow(
                          label: 'Total',
                          amount: total,
                          emphasized: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        RedButton(
          text: 'CONTINUAR',
          onPressed: data == null ? null : onContinue,
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String text;

  const _BenefitRow({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, size: 16, color: Color(0xFFEA3A3F)),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final int amount;
  final bool emphasized;

  const _SummaryRow({
    required this.label,
    required this.amount,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(fontWeight: emphasized ? FontWeight.w700 : null),
      ),
      Text(
        '\$$amount MXN',
        style: TextStyle(fontWeight: emphasized ? FontWeight.w700 : null),
      ),
    ],
  );
}

import 'package:flutter/material.dart';

import '../../../core/models/core_membership_plan.dart';
import '../models/member_inscription_data.dart';
import '../widgets/registration_scaffold.dart';

/// Paso 5: revisa el plan y el importe antes de elegir cómo pagar.
class RegisterPaymentSummaryScreen extends StatelessWidget {
  static const double _enrollmentCost = 120;

  final List<CoreMembershipPlan>? plans;
  final bool isLoading;
  final Object? loadError;
  final VoidCallback onRetry;
  final MemberInscription_PlanSelectionData? data;
  final VoidCallback onContinue;

  const RegisterPaymentSummaryScreen({
    super.key,
    required this.plans,
    required this.isLoading,
    required this.loadError,
    required this.onRetry,
    required this.data,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final selectedPlans = (plans ?? const <CoreMembershipPlan>[]).where(
      (plan) => plan.uid == data?.membershipPlanUid,
    );
    final plan = selectedPlans.isEmpty ? null : selectedPlans.first;
    final planCost = plan?.cost ?? 0.0;
    final total = planCost + _enrollmentCost;

    return Column(
      children: [
        Expanded(child: _buildSummaryContent(plan, planCost, total)),
        RedButton(
          text: 'CONTINUAR',
          onPressed: isLoading || loadError != null || plan == null
              ? null
              : onContinue,
        ),
      ],
    );
  }

  Widget _buildSummaryContent(
    CoreMembershipPlan? plan,
    double planCost,
    double total,
  ) {
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

    return SingleChildScrollView(
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
                  Text(
                    plan?.name ?? 'El plan seleccionado ya no está disponible',
                  ),
                  if (plan != null) ...[
                    const SizedBox(height: 4),
                    Text(_durationDescription(plan.duration)),
                    if (plan.benefits.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Beneficios incluidos',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      _BenefitRow(text: plan.benefits),
                    ],
                  ],
                  const Divider(height: 24),
                  const Text(
                    'Inscripción: kit de bienvenida',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text('Incluye un protector bucal y un par de vendas.'),
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
                  _SummaryRow(label: 'Total', amount: total, emphasized: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _durationDescription(CoreMembershipPlanDuration duration) =>
      switch (duration) {
        CoreMembershipPlanDuration.oneDay => 'Válido por 1 día natural',
        CoreMembershipPlanDuration.oneWeek => 'Válido por 7 días naturales',
        CoreMembershipPlanDuration.oneMonth => 'Válido por 1 mes',
      };
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
  final double amount;
  final bool emphasized;

  const _SummaryRow({
    required this.label,
    required this.amount,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final formattedAmount = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: emphasized ? FontWeight.w700 : null),
        ),
        Text(
          '\$$formattedAmount MXN',
          style: TextStyle(fontWeight: emphasized ? FontWeight.w700 : null),
        ),
      ],
    );
  }
}

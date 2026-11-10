import 'package:flutter/material.dart';

import '../../../core/models/core_membership_plan.dart';
import 'selectable_card.dart';

/// Tarjeta seleccionable de una membresía (con radio, precio y beneficios).
class MembershipPlanCard extends StatelessWidget {
  final CoreMembershipPlan membershipPlan;
  final bool isSelected;
  final VoidCallback onTap;

  const MembershipPlanCard({
    super.key,
    required this.membershipPlan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isSelected
        ? const Color(0xFFEA3A3F)
        : const Color(0xFF7A7A7A);
    final price = membershipPlan.cost == membershipPlan.cost.roundToDouble()
        ? membershipPlan.cost.toStringAsFixed(0)
        : membershipPlan.cost.toStringAsFixed(2);

    return SelectableCard(
      isSelected: isSelected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEA3A3F)
                      : const Color(0xFFECECEC),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  membershipPlan.duration.serialization.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isSelected ? Colors.white : const Color(0xFF555555),
                  ),
                ),
              ),
              SelectionRadioIndicator(isSelected: isSelected),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            membershipPlan.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            _durationDescription(membershipPlan.duration),
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B)),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$$price',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'MXN',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B6B6B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isSelected
                ? const Color(0xFFF2C4C7)
                : const Color(0xFFE3E3E3),
          ),
          if (membershipPlan.benefits.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, size: 16, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    membershipPlan.benefits,
                    style: const TextStyle(fontSize: 12.5, height: 1.2),
                  ),
                ),
              ],
            ),
          ],
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

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../inscription/models/membership_plan.dart';

/// Datos de membresía de users/{uid}. Los campos membership_* los escribe
/// el webhook de Mercado Pago (functions/src/index.ts) al aprobar un pago.
class UserMembership {
  final MembershipPlan? plan;
  final DateTime? expiresAt;
  final String? paymentMethod;
  final bool registrationPaid;

  /// Estado del cobro automático en Mercado Pago ('pending', 'authorized',
  /// 'paused', 'cancelled'), o null si nunca lo activó.
  final String? subscriptionStatus;
  final DateTime? subscriptionNextPaymentAt;

  const UserMembership({
    required this.plan,
    required this.expiresAt,
    required this.paymentMethod,
    required this.registrationPaid,
    this.subscriptionStatus,
    this.subscriptionNextPaymentAt,
  });

  factory UserMembership.fromFirestore(Map<String, dynamic> data) {
    final expira = data['membership_expires_at'];
    final proximoCobro = data['subscription_next_payment_at'];
    return UserMembership(
      plan: _planPorId((data['membership_plan_id'] as num?)?.toInt()),
      expiresAt: expira is Timestamp ? expira.toDate() : null,
      paymentMethod: data['payment_method'] as String?,
      registrationPaid: data['registration_payed'] == true,
      subscriptionStatus: data['subscription_status'] as String?,
      subscriptionNextPaymentAt: proximoCobro is Timestamp
          ? proximoCobro.toDate()
          : null,
    );
  }

  /// La fecha la calcula el servidor al confirmar el pago
  /// (fecha de pago + duración del plan).
  bool get isActive => expiresAt != null && expiresAt!.isAfter(DateTime.now());

  /// Tuvo una membresía y ya venció.
  bool get isExpired => expiresAt != null && !isActive;

  /// Eligió un plan de pago (día, semana o mes).
  bool get hasPlan => plan != null && plan!.id != 0;

  bool get paysWithMercadoPago => paymentMethod == 'mercadoPago';

  /// Solo semana y mes se pueden renovar con cobro automático.
  bool get canAutoRenew => plan?.id == 2 || plan?.id == 3;

  /// Mercado Pago sigue cobrando el plan automáticamente.
  bool get autoRenewActive =>
      subscriptionStatus == 'authorized' || subscriptionStatus == 'paused';

  /// Se pidió la autorización pero el alumno no la ha completado.
  bool get autoRenewPending => subscriptionStatus == 'pending';

  static MembershipPlan? _planPorId(int? id) {
    for (final plan in memberships) {
      if (plan.id == id) return plan;
    }
    return null;
  }
}

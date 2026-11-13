import 'package:flutter/material.dart';

import '../models/user_membership.dart';
import '../services/membership_service.dart';
import '../utils/membership_formatters.dart';
import 'auto_renew_section.dart';
import 'mercado_pago_status_view.dart';
import 'status_card.dart';

/// Decide qué tarjeta mostrar según el estado de la membresía del usuario.
class MembershipStatusView extends StatelessWidget {
  final String uid;
  final MembershipService service;

  MembershipStatusView({
    super.key,
    required this.uid,
    MembershipService? service,
  }) : service = service ?? MembershipService();

  @override
  Widget build(BuildContext context) => StreamBuilder<UserMembership?>(
    stream: service.watchMembership(uid),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const StatusCard(
          color: kRojo,
          icono: Icons.error_outline,
          titulo: 'No se pudo cargar tu membresía',
          descripcion: 'Revisa tu conexión e inténtalo de nuevo.',
        );
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final membership = snapshot.data;
      if (membership == null) {
        return const StatusCard(
          color: kRojo,
          icono: Icons.person_off_outlined,
          titulo: 'Perfil no encontrado',
          descripcion: 'No encontramos los datos de tu inscripción.',
        );
      }

      return _buildFor(membership);
    },
  );

  Widget _buildFor(UserMembership membership) {
    final plan = membership.plan;
    final vencimiento = membership.expiresAt;

    if (membership.isActive) {
      return StatusCard(
        color: kVerde,
        icono: Icons.verified,
        titulo: 'Membresía activa',
        descripcion: 'Tu pago fue confirmado.',
        filas: [
          if (plan != null) ('Plan', plan.title),
          if (plan != null) ('Duración', duracionTexto(plan.durationDays)),
          ('Vence el', formatearFecha(vencimiento!)),
          (
            'Tiempo restante',
            tiempoRestante(vencimiento.difference(DateTime.now())),
          ),
          ('Inscripción', membership.registrationPaid ? 'Pagada' : 'No aplica'),
        ],
        accion: membership.paysWithMercadoPago && membership.canAutoRenew
            ? AutoRenewSection(membership: membership)
            : null,
      );
    }

    // Venció mientras Mercado Pago reintenta el cobro automático: no se
    // ofrece pagar a mano para no cobrar dos veces.
    if (membership.autoRenewActive && membership.canAutoRenew) {
      return StatusCard(
        color: kAmbar,
        icono: Icons.autorenew,
        titulo: 'Renovación en proceso',
        descripcion:
            'Mercado Pago está procesando el cobro automático de tu plan. '
            'Tu membresía se renovará en cuanto se apruebe.',
        filas: [
          if (vencimiento != null) ('Venció el', formatearFecha(vencimiento)),
          ('Plan', plan!.title),
        ],
        accion: AutoRenewSection(membership: membership),
      );
    }

    if (!membership.hasPlan) {
      return StatusCard(
        color: kGris,
        icono: Icons.info_outline,
        titulo: membership.isExpired ? 'Membresía vencida' : 'Sin membresía',
        descripcion: membership.isExpired
            ? 'Tu membresía venció el ${formatearFecha(vencimiento!)}.'
            : 'No seleccionaste un plan. Puedes contratarlo en recepción.',
      );
    }

    final filasPlan = [
      if (membership.isExpired)
        ('Membresía anterior', 'Venció el ${formatearFecha(vencimiento!)}'),
      ('Plan', plan!.title),
      ('Duración', duracionTexto(plan.durationDays)),
      (
        'Si se activa hoy, vence el',
        formatearFecha(DateTime.now().add(Duration(days: plan.durationDays))),
      ),
    ];

    if (membership.paysWithMercadoPago) {
      return MercadoPagoStatusView(
        uid: uid,
        plan: plan,
        vencida: membership.isExpired,
        filasPlan: filasPlan,
        service: service,
      );
    }

    return StatusCard(
      color: kAmbar,
      icono: Icons.storefront_outlined,
      titulo: 'Pendiente de pago en recepción',
      descripcion:
          'Elegiste pagar en mostrador. Tu membresía se '
          'activará cuando recepción registre tu pago.',
      filas: filasPlan,
    );
  }
}

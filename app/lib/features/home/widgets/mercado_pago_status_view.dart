import 'package:flutter/material.dart';

import '../../inscription/models/membership_plan.dart';
import '../services/membership_service.dart';
import 'pay_button.dart';
import 'status_card.dart';

/// Para quien eligió Mercado Pago y aún no tiene membresía activa:
/// muestra el estado de su pago más reciente.
class MercadoPagoStatusView extends StatelessWidget {
  final String uid;
  final MembershipPlan plan;
  final bool vencida;
  final List<(String, String)> filasPlan;
  final MembershipService service;

  const MercadoPagoStatusView({
    super.key,
    required this.uid,
    required this.plan,
    required this.vencida,
    required this.filasPlan,
    required this.service,
  });

  @override
  Widget build(BuildContext context) => StreamBuilder<String?>(
    stream: service.watchCurrentPaymentStatus(uid),
    builder: (context, snapshot) => switch (snapshot.data) {
      'approved' => StatusCard(
        color: kVerde,
        icono: Icons.hourglass_top,
        titulo: 'Pago confirmado',
        descripcion:
            'Estamos activando tu membresía. '
            'Esto toma unos segundos.',
        filas: filasPlan,
      ),
      'pending' || 'in_process' || 'authorized' => StatusCard(
        color: kAmbar,
        icono: Icons.schedule,
        titulo: 'Pago pendiente',
        descripcion:
            'Si ya pagaste en Mercado Pago, espera la '
            'confirmación. Tu membresía se activará automáticamente.',
        filas: filasPlan,
      ),
      'rejected' || 'cancelled' => StatusCard(
        color: kRojo,
        icono: Icons.cancel_outlined,
        titulo: 'Pago no completado',
        descripcion:
            'Mercado Pago no aprobó tu pago. No se realizó '
            'ningún cargo. Puedes intentarlo de nuevo o pagar '
            'en recepción.',
        filas: filasPlan,
        accion: PayButton(planId: plan.id, texto: 'REINTENTAR PAGO'),
      ),
      // Sin pago en curso: nunca pagó, falló al crear el checkout,
      // o su último pago ya se usó en una membresía que venció.
      _ => StatusCard(
        color: kRojo,
        icono: Icons.payments_outlined,
        titulo: vencida ? 'Renueva tu membresía' : 'Pago no realizado',
        descripcion: vencida
            ? 'Paga con Mercado Pago para volver a activar tu plan.'
            : 'Elegiste pagar con Mercado Pago, pero aún no '
                  'recibimos tu pago.',
        filas: filasPlan,
        accion: PayButton(
          planId: plan.id,
          texto: vencida ? 'RENOVAR CON MERCADO PAGO' : 'REINTENTAR PAGO',
        ),
      ),
    },
  );
}

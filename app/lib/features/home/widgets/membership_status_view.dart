import 'package:champions_ring_app/features/home/models/viewable_membership.dart';
import 'package:flutter/material.dart';

import '../services/membership_service.dart';
import '../utils/membership_formatters.dart';
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
    final vencimiento = membership.expiresAt;

    if (membership.isActive) {
      return StatusCard(
        color: kVerde,
        icono: Icons.verified,
        titulo: 'Membresía activa',
        descripcion: 'Tu pago fue confirmado.',
        filas: [
          ('Vence el', formatearFecha(vencimiento!)),
          (
            'Tiempo restante',
            tiempoRestante(vencimiento.difference(DateTime.now())),
          ),
        ],
      );
    }

    if (!membership.hasPaidRenewal) {
      return StatusCard(
        color: kGris,
        icono: Icons.info_outline,
        titulo: 'Sin membresía',
        descripcion: 'No encontramos una renovación con pago confirmado.',
      );
    }

    if (vencimiento == null) {
      return const StatusCard(
        color: kRojo,
        icono: Icons.error_outline,
        titulo: 'No se pudo determinar el vencimiento',
        descripcion: 'Revisa tu conexión e inténtalo de nuevo.',
      );
    }

    return StatusCard(
      color: kGris,
      icono: Icons.event_busy,
      titulo: 'Membresía vencida',
      descripcion: 'Tu membresía venció el ${formatearFecha(vencimiento)}.',
      filas: [('Vencimiento', formatearFecha(vencimiento))],
    );
  }
}

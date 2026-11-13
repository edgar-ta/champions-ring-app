import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../core/services/mercado_pago_checkout_service.dart';
import '../../inscription/widgets/registration_scaffold.dart' show RedButton;
import '../models/user_membership.dart';
import '../utils/membership_formatters.dart';
import 'status_card.dart';

/// Activar, continuar o cancelar el cobro automático del plan
/// (semana o mes). Los estados los escribe el webhook en users/{uid}.
class AutoRenewSection extends StatefulWidget {
  final UserMembership membership;

  const AutoRenewSection({super.key, required this.membership});

  @override
  State<AutoRenewSection> createState() => _AutoRenewSectionState();
}

class _AutoRenewSectionState extends State<AutoRenewSection> {
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    // Si el alumno ya autorizó pero el webhook no avisó, esto lo corrige
    // en cuanto vuelve a la app (el StreamBuilder mostrará el nuevo estado).
    if (widget.membership.autoRenewPending) {
      MercadoPagoCheckoutService.syncSubscription().ignore();
    }
  }

  /// Primero revisa si ya quedó autorizada; si no, vuelve a abrir
  /// Mercado Pago para terminar la autorización.
  Future<void> _continuar() async {
    setState(() => _cargando = true);
    String? estado;
    try {
      estado = await MercadoPagoCheckoutService.syncSubscription();
    } catch (_) {
      // Si no se pudo consultar, se ofrece abrir Mercado Pago igualmente.
    } finally {
      if (mounted) setState(() => _cargando = false);
    }

    if (!mounted) return;
    if (estado == 'authorized' || estado == 'paused') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu cobro automático ya está activo.')),
      );
      return;
    }
    await _activar();
  }

  Future<void> _ejecutar(Future<void> Function() accion, String exito) async {
    setState(() => _cargando = true);
    String? error;
    try {
      await accion();
    } on FirebaseFunctionsException catch (e) {
      error = e.message ?? e.code;
    } catch (e) {
      error = '$e';
    } finally {
      if (mounted) setState(() => _cargando = false);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? exito)));
  }

  Future<void> _activar() => _ejecutar(
    () => MercadoPagoCheckoutService.openSubscription(
      widget.membership.plan!.id,
    ),
    'Autoriza el cobro automático en Mercado Pago. Esta pantalla se '
        'actualizará cuando se confirme.',
  );

  Future<void> _cancelar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar cobro automático'),
        content: const Text(
          'Ya no se cobrará tu plan automáticamente. Tu membresía actual '
          'seguirá vigente hasta su fecha de vencimiento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('VOLVER'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CANCELAR COBRO', style: TextStyle(color: kRojo)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    await _ejecutar(
      MercadoPagoCheckoutService.cancelSubscription,
      'Cancelamos tu cobro automático.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final membership = widget.membership;
    final plan = membership.plan!;
    final proximoCobro = membership.subscriptionNextPaymentAt;

    final String texto;
    final Widget boton;

    if (membership.autoRenewActive) {
      texto = membership.subscriptionStatus == 'paused'
          ? 'Tu cobro automático está pausado en Mercado Pago.'
          : proximoCobro == null
          ? 'Activo: se cobrarán \$${plan.price} '
                '${periodoTexto(plan.durationDays)}.'
          : 'Activo: el próximo cobro de \$${plan.price} será el '
                '${formatearFecha(proximoCobro)}.';
      boton = OutlinedButton(
        onPressed: _cancelar,
        style: OutlinedButton.styleFrom(
          foregroundColor: kRojo,
          side: const BorderSide(color: kRojo),
          minimumSize: const Size.fromHeight(48),
        ),
        child: const Text('CANCELAR COBRO AUTOMÁTICO'),
      );
    } else if (membership.autoRenewPending) {
      texto =
          'Falta autorizar tu tarjeta en Mercado Pago. Si ya lo hiciste, '
          'espera unos segundos.';
      boton = RedButton(
        text: 'CONTINUAR AUTORIZACIÓN',
        icon: Icons.autorenew,
        onPressed: _continuar,
      );
    } else {
      final vencimiento = membership.expiresAt;
      texto = membership.isActive && vencimiento != null
          ? 'Renueva sin hacer nada: se cobrarán \$${plan.price} a tu '
                'tarjeta el ${formatearFecha(vencimiento)} y luego '
                '${periodoTexto(plan.durationDays)}. Puedes cancelar '
                'cuando quieras.'
          : 'Se cobrarán \$${plan.price} hoy y luego '
                '${periodoTexto(plan.durationDays)}. Puedes cancelar '
                'cuando quieras.';
      boton = RedButton(
        text: 'ACTIVAR COBRO AUTOMÁTICO',
        icon: Icons.autorenew,
        onPressed: _activar,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Cobro automático',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(texto, style: const TextStyle(height: 1.4)),
        const SizedBox(height: 12),
        if (_cargando)
          const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          )
        else
          boton,
      ],
    );
  }
}

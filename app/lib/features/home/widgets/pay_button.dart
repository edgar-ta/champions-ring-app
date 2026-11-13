import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../core/services/mercado_pago_checkout_service.dart';
import '../../inscription/widgets/registration_scaffold.dart' show RedButton;

/// Crea un checkout nuevo (o reutiliza uno reciente) y abre Mercado Pago.
class PayButton extends StatefulWidget {
  final int planId;
  final String texto;

  const PayButton({super.key, required this.planId, required this.texto});

  @override
  State<PayButton> createState() => _PayButtonState();
}

class _PayButtonState extends State<PayButton> {
  bool _cargando = false;

  Future<void> _pagar() async {
    setState(() => _cargando = true);
    String? error;
    try {
      await MercadoPagoCheckoutService.open(widget.planId);
    } on FirebaseFunctionsException catch (e) {
      error = e.message ?? e.code;
    } catch (e) {
      error = '$e';
    } finally {
      if (mounted) setState(() => _cargando = false);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? 'Completa tu pago en Mercado Pago. Esta pantalla se '
                    'actualizará cuando se confirme.'
              : 'No se pudo abrir el pago: $error',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _cargando
      ? const SizedBox(
          height: 52,
          child: Center(child: CircularProgressIndicator()),
        )
      : RedButton(
          text: widget.texto,
          icon: Icons.credit_card,
          onPressed: _pagar,
        );
}

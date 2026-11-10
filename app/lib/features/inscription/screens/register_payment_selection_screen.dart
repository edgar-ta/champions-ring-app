import 'package:champions_ring_app/core/models/core_payment.dart'
    show CorePaymentType;
import 'package:flutter/material.dart';

import '../models/member_inscription_data.dart';
import '../widgets/registration_scaffold.dart';

/// Paso 6: selección del método de pago.
class RegisterPaymentSelectionScreen extends StatelessWidget {
  final MemberInscription_PaymentSelectionData? data;
  final ValueChanged<MemberInscription_PaymentSelectionData> onDataChanged;
  final VoidCallback onContinue;

  const RegisterPaymentSelectionScreen({
    super.key,
    required this.data,
    required this.onDataChanged,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: Column(
          children: [
            RadioListTile<CorePaymentType>(
              value: CorePaymentType.cash,
              groupValue: data?.paymentMethod,
              activeColor: const Color(0xFFEA3A3F),
              title: const Text('Pagar en efectivo'),
              subtitle: const Text('Realiza el pago en recepción.'),
              onChanged: (method) {
                if (method != null) {
                  onDataChanged(
                    MemberInscription_PaymentSelectionData(
                      paymentMethod: method,
                    ),
                  );
                }
              },
            ),
            RadioListTile<CorePaymentType>(
              value: CorePaymentType.mercadoPago,
              groupValue: data?.paymentMethod,
              title: const Text('Pagar con tarjeta'),
              subtitle: const Text('Próximamente con Mercado Pago'),
              onChanged: null,
            ),
          ],
        ),
      ),
      RedButton(
        text: 'FINALIZAR REGISTRO',
        onPressed: data == null ? null : onContinue,
      ),
    ],
  );
}

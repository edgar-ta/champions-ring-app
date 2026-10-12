import 'package:champions_ring_app/core/models/core_user.dart'
    show CorePaymentMethod;
import 'package:flutter/material.dart';

import '../models/user_inscription_data.dart';
import '../widgets/registration_scaffold.dart';

/// Paso 6: selección del método de pago.
class RegisterPaymentSelectionScreen extends StatelessWidget {
  final UserInscription_PaymentSelectionData? data;
  final ValueChanged<UserInscription_PaymentSelectionData> onDataChanged;
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
            RadioListTile<CorePaymentMethod>(
              value: CorePaymentMethod.cash,
              groupValue: data?.paymentMethod,
              activeColor: const Color(0xFFEA3A3F),
              title: const Text('Pagar en efectivo'),
              subtitle: const Text('Realiza el pago en recepción.'),
              onChanged: (method) {
                if (method != null) {
                  onDataChanged(
                    UserInscription_PaymentSelectionData(paymentMethod: method),
                  );
                }
              },
            ),
            RadioListTile<CorePaymentMethod>(
              value: CorePaymentMethod.card,
              groupValue: data?.paymentMethod,
              title: const Text('Pagar con tarjeta'),
              subtitle: const Text('Próximamente'),
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

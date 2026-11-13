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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  '¿Cómo deseas realizar tu pago?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              RadioListTile<CorePaymentMethod>(
                value: CorePaymentMethod.cash,
                groupValue: data?.paymentMethod,
                activeColor: const Color(0xFFEA3A3F),
                secondary: const Icon(
                  Icons.storefront_outlined,
                  color: Color(0xFFEA3A3F),
                ),
                title: const Text(
                  'Pagar en recepción',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Realiza el pago presencialmente en el gimnasio.',
                ),
                onChanged: (method) {
                  if (method != null) {
                    onDataChanged(
                      UserInscription_PaymentSelectionData(
                        paymentMethod: method,
                      ),
                    );
                  }
                },
              ),

              const Divider(indent: 16, endIndent: 16),

              RadioListTile<CorePaymentMethod>(
                value:CorePaymentMethod.mercadoPago,
                groupValue: data?.paymentMethod,
                activeColor: const Color(0xFFEA3A3F),
                secondary: const Icon(
                  Icons.credit_card_outlined,
                  color: Color(0xFFEA3A3F),
                ),
                title: const Text(
                  'Pagar con Mercado Pago',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Paga en línea con tarjeta o transferencia, '
                  'según los métodos disponibles.',
                ),
                onChanged: (method) {
                  if (method != null) {
                    onDataChanged(
                      UserInscription_PaymentSelectionData(
                        paymentMethod: method,
                      ),
                    );
                  }
                },
              ),

              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Tu membresía se activará cuando se confirme '
                  'el pago correspondiente.',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),

      RedButton(
        text: 'FINALIZAR REGISTRO',
        onPressed: data == null ? null : onContinue,
      ),
    ],
  );
}
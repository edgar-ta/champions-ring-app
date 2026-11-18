import 'package:champions_ring_app/core/models/core_payment.dart'
    show CorePaymentIssuingEntity, CorePaymentType;
import 'package:flutter/material.dart';

import '../models/member_inscription_data.dart';
import '../../../shared/widgets/red_button.dart';

/// Paso 6: selección del método de pago.
class RegisterPaymentSelectionScreen extends StatelessWidget {
  final MemberInscription_PaymentSelectionData? data;
  final ValueChanged<MemberInscription_PaymentSelectionData> onDataChanged;
  final VoidCallback onContinue;
  final bool showContinueButton;

  const RegisterPaymentSelectionScreen({
    super.key,
    required this.data,
    required this.onDataChanged,
    required this.onContinue,
    this.showContinueButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDirectTransfer =
        data?.paymentMethod == CorePaymentType.directTransfer;
    final hasReference = data?.referenceId?.trim().isNotEmpty ?? false;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                RadioListTile<CorePaymentType>(
                  value: CorePaymentType.cash,
                  groupValue: data?.paymentMethod,
                  activeColor: const Color(0xFFEA3A3F),
                  title: const Text('Pagar en efectivo'),
                  subtitle: const Text('Realiza el pago en recepción.'),
                  onChanged: _selectPaymentMethod,
                ),
                RadioListTile<CorePaymentType>(
                  value: CorePaymentType.directTransfer,
                  groupValue: data?.paymentMethod,
                  activeColor: const Color(0xFFEA3A3F),
                  title: const Text('Pagar por transferencia directa'),
                  subtitle: const Text(
                    'Ingresa la referencia bancaria de tu transferencia.',
                  ),
                  onChanged: _selectPaymentMethod,
                ),
                if (isDirectTransfer)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                key: const ValueKey('bank-reference'),
                                initialValue: data?.referenceId,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.done,
                                autocorrect: false,
                                enableSuggestions: false,
                                decoration: const InputDecoration(
                                  labelText: 'Referencia bancaria *',
                                  helperText: 'Este dato es obligatorio.',
                                ),
                                onChanged: (referenceId) {
                                  onDataChanged(
                                    MemberInscription_PaymentSelectionData(
                                      paymentMethod:
                                          CorePaymentType.directTransfer,
                                      referenceId: referenceId,
                                      issuingEntity: data?.issuingEntity,
                                      issuingEntityName:
                                          data?.issuingEntityName,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child:
                                  DropdownButtonFormField<
                                    CorePaymentIssuingEntity
                                  >(
                                    key: const ValueKey('issuing-entity'),
                                    initialValue: data?.issuingEntity,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Entidad emisora',
                                    ),
                                    items: CorePaymentIssuingEntity.values
                                        .map(
                                          (entity) => DropdownMenuItem(
                                            value: entity,
                                            child: Text(
                                              entity.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (issuingEntity) {
                                      onDataChanged(
                                        MemberInscription_PaymentSelectionData(
                                          paymentMethod:
                                              CorePaymentType.directTransfer,
                                          referenceId: data?.referenceId,
                                          issuingEntity: issuingEntity,
                                          issuingEntityName:
                                              issuingEntity ==
                                                  CorePaymentIssuingEntity.other
                                              ? data?.issuingEntityName
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                            ),
                          ],
                        ),
                        if (data?.issuingEntity ==
                            CorePaymentIssuingEntity.other)
                          TextFormField(
                            key: const ValueKey('issuing-entity-name'),
                            initialValue: data?.issuingEntityName,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de la entidad emisora',
                            ),
                            onChanged: (issuingEntityName) {
                              onDataChanged(
                                MemberInscription_PaymentSelectionData(
                                  paymentMethod: CorePaymentType.directTransfer,
                                  referenceId: data?.referenceId,
                                  issuingEntity: data?.issuingEntity,
                                  issuingEntityName: issuingEntityName,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                RadioListTile<CorePaymentType>(
                  value: CorePaymentType.mercadoPago,
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
                        MemberInscription_PaymentSelectionData(
                          paymentMethod: method,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        if (showContinueButton)
          RedButton(
            text: 'FINALIZAR REGISTRO',
            onPressed: data == null || (isDirectTransfer && !hasReference)
                ? null
                : onContinue,
          ),
      ],
    );
  }

  void _selectPaymentMethod(CorePaymentType? method) {
    if (method == null) return;
    onDataChanged(
      MemberInscription_PaymentSelectionData(
        paymentMethod: method,
        referenceId: data?.referenceId,
        issuingEntity: data?.issuingEntity,
        issuingEntityName: data?.issuingEntityName,
      ),
    );
  }
}

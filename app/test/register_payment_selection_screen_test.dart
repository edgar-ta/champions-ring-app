import 'package:champions_ring_app/core/models/core_payment.dart'
    show CorePaymentIssuingEntity, CorePaymentType;
import 'package:champions_ring_app/features/inscription/models/member_inscription_data.dart';
import 'package:champions_ring_app/features/inscription/screens/register_payment_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'requires a bank reference before finishing a direct transfer payment',
    (tester) async {
      MemberInscription_PaymentSelectionData? data;
      var continued = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: RegisterPaymentSelectionScreen(
                data: data,
                onDataChanged: (newData) => setState(() => data = newData),
                onContinue: () => continued = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pagar por transferencia directa'));
      await tester.pump();

      expect(find.byType(TextFormField), findsOneWidget);
      var finishButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'FINALIZAR REGISTRO'),
      );
      expect(finishButton.onPressed, isNull);

      await tester.enterText(find.byType(TextFormField), 'REF-123');
      await tester.pump();

      expect(data?.paymentMethod, CorePaymentType.directTransfer);
      expect(data?.referenceId, 'REF-123');

      await tester.tap(find.byKey(const ValueKey('issuing-entity')));
      await tester.pumpAndSettle();
      expect(find.text('BBVA'), findsOneWidget);
      expect(find.text('Santander'), findsOneWidget);
      expect(find.text('Banco Azteca'), findsOneWidget);
      expect(find.text('Elektra'), findsOneWidget);
      await tester.tap(find.text('Otra').last);
      await tester.pumpAndSettle();

      expect(data?.issuingEntity, CorePaymentIssuingEntity.other);
      expect(find.byKey(const ValueKey('issuing-entity-name')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('issuing-entity-name')),
        'Banco del Barrio',
      );
      await tester.pump();
      expect(data?.issuingEntityName, 'Banco del Barrio');

      finishButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'FINALIZAR REGISTRO'),
      );
      expect(finishButton.onPressed, isNotNull);

      await tester.tap(find.text('FINALIZAR REGISTRO'));
      expect(continued, isTrue);
    },
  );
}

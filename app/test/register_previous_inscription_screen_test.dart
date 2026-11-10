import 'package:champions_ring_app/features/inscription/models/member_inscription_data.dart';
import 'package:champions_ring_app/features/inscription/screens/register_previous_inscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('requires an answer and passes the selected value', (
    tester,
  ) async {
    MemberInscription_PreviousInscriptionData? selectedData;
    var continued = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              height: 300,
              child: RegisterPreviousInscriptionScreen(
                data: selectedData,
                onDataChanged: (data) => selectedData = data,
                onContinue: () => continued = true,
              ),
            ),
          ),
        ),
      ),
    );

    final continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'CONTINUAR'),
    );
    expect(continueButton.onPressed, isNull);

    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await tester.pumpAndSettle();
    final noOption = find.text('No, no estoy inscrito');
    await tester.tap(noOption);
    expect(selectedData?.previouslySignedIn, isFalse);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              height: 300,
              child: RegisterPreviousInscriptionScreen(
                data: selectedData,
                onDataChanged: (data) => selectedData = data,
                onContinue: () => continued = true,
              ),
            ),
          ),
        ),
      ),
    );

    final note = find.text(
      'Nota: pagar la visita al gimnasio no es lo mismo que estar inscrito',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(note, findsOneWidget);

    await tester.tap(find.text('CONTINUAR'));
    expect(continued, isTrue);
  });
}

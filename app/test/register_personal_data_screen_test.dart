import 'dart:async';

import 'package:champions_ring_app/features/inscription/screens/register_personal_data_screen.dart';
import 'package:champions_ring_app/features/inscription/widgets/personal_data_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('checks a valid email after the user stops typing', (
    tester,
  ) async {
    final checkedEmails = <String>[];
    final emailCheck = Completer<bool?>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PersonalDataForm(
              onSubmit: (_) {},
              checkEmailAvailability: (email) {
                checkedEmails.add(email);
                return emailCheck.future;
              },
            ),
          ),
        ),
      ),
    );

    final emailField = find.byType(TextFormField).at(3);
    await tester.enterText(emailField, 'ana@');
    await tester.pump(const Duration(seconds: 1));
    expect(checkedEmails, isEmpty);

    await tester.enterText(emailField, 'ana@example.com');
    await tester.pump(const Duration(milliseconds: 499));
    expect(checkedEmails, isEmpty);

    await tester.pump(const Duration(milliseconds: 1));
    expect(checkedEmails, ['ana@example.com']);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    emailCheck.complete(true);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Campo requerido'), findsNothing);
  });

  testWidgets('validates personal data only after continuing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegisterPersonalDataScreen(
            initialData: null,
            onContinue: (_) {},
          ),
        ),
      ),
    );

    final emailField = find.byType(TextFormField).at(3);
    await tester.enterText(emailField, 'ana@example.com');
    await tester.pump();
    await tester.tap(find.byType(TextFormField).first);
    await tester.pump();

    expect(find.text('Campo requerido'), findsNothing);

    await tester.ensureVisible(find.text('CONTINUAR'));
    await tester.tap(find.text('CONTINUAR'));
    await tester.pump();

    expect(find.text('Campo requerido'), findsWidgets);
  });
}

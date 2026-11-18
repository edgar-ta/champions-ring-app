import 'package:champions_ring_app/features/inscription/screens/inscription_screen.dart';
import 'package:champions_ring_app/features/inscription/widgets/selectable_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('previous members see the account validation notice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: InscriptionScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SelectableCard).first);
    await tester.pump();
    await tester.tap(find.text('CONTINUAR').first);
    await tester.pumpAndSettle();

    expect(find.text('Paso 2 de 5: Validación de cuenta'), findsOneWidget);
    expect(
      find.textContaining('dentro de los próximos 3 días'),
      findsOneWidget,
    );
    expect(find.textContaining('será bloqueada'), findsOneWidget);
    expect(
      find.image(
        const AssetImage('assets/images/Gym_Verification_ 3_Days_Waiting.png'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('CONTINUAR').first);
    await tester.pumpAndSettle();

    expect(find.text('Paso 3 de 5: Datos personales'), findsOneWidget);
    expect(
      find.textContaining('Confirma tus datos para crear tu cuenta.'),
      findsOneWidget,
    );
  });

  testWidgets('new members skip the validation notice', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: InscriptionScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SelectableCard).last);
    await tester.pump();
    await tester.tap(find.text('CONTINUAR').first);
    await tester.pumpAndSettle();

    expect(find.text('Paso 2 de 6: Datos personales'), findsOneWidget);
    expect(find.text('Validación de cuenta'), findsNothing);
  });

  testWidgets('bottom back button is only shown after the first step', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: InscriptionScreen()));
    await tester.pumpAndSettle();

    expect(find.text('REGRESAR'), findsNothing);
    await tester.tap(find.byType(SelectableCard).last);
    await tester.pump();
    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();

    expect(find.text('REGRESAR'), findsOneWidget);
    await tester.tap(find.text('REGRESAR'));
    await tester.pumpAndSettle();

    expect(find.text('Paso 1 de 6: Inscripción previa'), findsOneWidget);
    expect(find.text('REGRESAR'), findsNothing);
  });

  testWidgets('top back confirms exit after unsaved personal data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: InscriptionScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SelectableCard).last);
    await tester.pump();
    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Ana');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text('¿Salir del registro?'), findsOneWidget);
    await tester.tap(find.text('Continuar registrándome'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 2 de 6: Datos personales'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
  });
}

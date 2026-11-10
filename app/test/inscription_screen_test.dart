import 'package:champions_ring_app/features/inscription/screens/inscription_screen.dart';
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

    await tester.tap(find.text('Sí, ya estoy inscrito al gimnasio'));
    await tester.pump();
    await tester.tap(find.text('CONTINUAR').first);
    await tester.pumpAndSettle();

    expect(find.text('Paso 2 de 5: Validación de cuenta'), findsOneWidget);
    expect(
      find.textContaining('dentro de los próximos 4 días'),
      findsOneWidget,
    );
    expect(find.textContaining('será bloqueada'), findsOneWidget);

    await tester.tap(find.text('CONTINUAR').first);
    await tester.pumpAndSettle();

    expect(find.text('Paso 3 de 5: Datos personales'), findsOneWidget);
    expect(find.textContaining('el sistema lo tiene presente'), findsOneWidget);
  });

  testWidgets('new members skip the validation notice', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: InscriptionScreen()));

    await tester.tap(find.text('No, no estoy inscrito'));
    await tester.pump();
    await tester.tap(find.text('CONTINUAR').first);
    await tester.pumpAndSettle();

    expect(find.text('Paso 2 de 6: Datos personales'), findsOneWidget);
    expect(find.text('Validación de cuenta'), findsNothing);
  });
}

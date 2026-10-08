import 'package:flutter_test/flutter_test.dart';
import 'package:champions_ring_app/main.dart';

void main() {
  testWidgets('La aplicación muestra la pantalla de inicio de sesión', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ChampionRingApp());

    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
  });
}

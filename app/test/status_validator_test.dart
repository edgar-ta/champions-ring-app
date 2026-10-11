import 'package:flutter_test/flutter_test.dart';
import 'package:champions_ring_app/features/authentication/validators/status_validator.dart';

void main() {
  group('Prueba 3: Validación de estados permitidos', () {
    test('El estado completado es válido', () {
      expect(StatusValidator.esEstadoValido('completado'), isTrue);
    });

    test('El estado incompleto es válido', () {
      expect(StatusValidator.esEstadoValido('incompleto'), isTrue);
    });

    test('Un estado no reconocido es inválido', () {
      expect(StatusValidator.esEstadoValido('pendiente'), isFalse);
    });
  });
}

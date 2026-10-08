import 'package:flutter_test/flutter_test.dart';
import 'package:champions_ring_app/features/validation/invalid_data_validator.dart';

void main() {
  group('Prueba 5: Validación de datos incompletos o inválidos', () {
    test('Un texto vacío debe ser identificado como inválido', () {
      expect(InvalidDataValidator.textoEsValido(''), isFalse);
    });

    test('Un correo electrónico inválido debe ser rechazado', () {
      expect(InvalidDataValidator.correoEsValido('correo-invalido'), isFalse);
    });

    test('Una fecha nula debe ser identificada como inválida', () {
      expect(InvalidDataValidator.fechaEsValida(null), isFalse);
    });

    test('Un número negativo debe ser rechazado', () {
      expect(InvalidDataValidator.numeroEsValido(-10), isFalse);
    });

    test('Un estado desconocido debe ser rechazado', () {
      expect(
        InvalidDataValidator.estadoEsValido('pendiente', [
          'completado',
          'incompleto',
        ]),
        isFalse,
      );
    });

    test('Un valor booleano nulo debe ser identificado como inválido', () {
      expect(InvalidDataValidator.booleanoEsValido(null), isFalse);
    });

    test('Los datos válidos deben ser aceptados', () {
      expect(InvalidDataValidator.textoEsValido('Santiago'), isTrue);

      expect(
        InvalidDataValidator.correoEsValido('santiago@example.com'),
        isTrue,
      );

      expect(InvalidDataValidator.fechaEsValida(DateTime(2005, 1, 14)), isTrue);

      expect(InvalidDataValidator.numeroEsValido(100), isTrue);

      expect(
        InvalidDataValidator.estadoEsValido('completado', [
          'completado',
          'incompleto',
        ]),
        isTrue,
      );

      expect(InvalidDataValidator.booleanoEsValido(true), isTrue);
    });
  });
}

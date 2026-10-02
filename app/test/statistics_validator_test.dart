import 'package:flutter_test/flutter_test.dart';
import 'package:champions_ring_app/features/statistics/statistics_validator.dart';

void main() {
  group('Prueba 4: Validación de datos estadísticos', () {
    test('Los datos estadísticos válidos son aceptados', () {
      final resultado = StatisticsValidator.sonDatosValidos(
        estudiantesActivos: 25,
        ingresosSuscripciones: 3500.00,
        ingresosVentas: 1200.00,
      );

      expect(resultado, isTrue);
    });

    test('Los datos estadísticos no deben contener valores negativos', () {
      final resultado = StatisticsValidator.sonDatosValidos(
        estudiantesActivos: -5,
        ingresosSuscripciones: 3500.00,
        ingresosVentas: 1200.00,
      );

      expect(resultado, isFalse);
    });

    test('Los valores estadísticos pueden ser cero', () {
      final resultado = StatisticsValidator.sonDatosValidos(
        estudiantesActivos: 0,
        ingresosSuscripciones: 0,
        ingresosVentas: 0,
      );

      expect(resultado, isTrue);
    });
  });
}

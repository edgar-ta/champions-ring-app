import 'package:flutter_test/flutter_test.dart';
import 'package:champions_ring_app/features/authentication/models/member.dart';

void main() {
  group('Prueba 2: Validación de estructura de miembro', () {
    test('El miembro contiene los datos requeridos', () {
      final member = Member(
        id: 'member-001',
        nombre: 'Santiago Barreto',
        correo: 'santiago@example.com',
        telefono: '4421234567',
        estadoMembresia: 'activa',
        fechaInicio: DateTime(2026, 10, 1),
        fechaVencimiento: DateTime(2026, 10, 31),
      );

      expect(member.id, isNotEmpty);
      expect(member.nombre, isNotEmpty);
      expect(member.correo, isNotEmpty);
      expect(member.telefono, isNotEmpty);
      expect(member.estadoMembresia, isNotEmpty);
    });

    test('La fecha de vencimiento es posterior a la fecha de inicio', () {
      final member = Member(
        id: 'member-002',
        nombre: 'Juan Pérez',
        correo: 'juan@example.com',
        telefono: '4429876543',
        estadoMembresia: 'activa',
        fechaInicio: DateTime(2026, 10, 1),
        fechaVencimiento: DateTime(2026, 10, 31),
      );

      expect(member.fechaVencimiento.isAfter(member.fechaInicio), isTrue);
    });

    test('El estado de la membresía está presente', () {
      final member = Member(
        id: 'member-003',
        nombre: 'Carlos Gómez',
        correo: 'carlos@example.com',
        telefono: '4421112233',
        estadoMembresia: 'vencida',
        fechaInicio: DateTime(2026, 9, 1),
        fechaVencimiento: DateTime(2026, 9, 30),
      );

      expect(member.estadoMembresia, isNotEmpty);
    });
  });
}

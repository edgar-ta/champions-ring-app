import 'package:flutter_test/flutter_test.dart';
import 'package:champions_ring_app/features/authentication/enums/user_type.dart';
import 'package:champions_ring_app/features/authentication/models/user.dart';

void main() {
  group('Prueba 1: Validación de estructura de usuario', () {
    test('El usuario contiene los datos mínimos requeridos', () {
      final user = User(
        uid: 'user-001',
        type: UserType.member,
        nombre: 'Santiago',
        apellidos: 'Barreto Ocampo',
        fechaNacimiento: DateTime(2005, 1, 14),
        correo: 'santiago@example.com',
        telefono: '4421234567',
        datosLegalesSonPropios: true,
        firmaUrl: 'firma.jpg',
        ineUrl: 'ine.jpg',
        fechaCreacion: DateTime(2026, 10, 1),
      );

      expect(user.uid, isNotEmpty);
      expect(user.nombre, isNotEmpty);
      expect(user.correo, isNotEmpty);
      expect(user.telefono, isNotEmpty);
    });

    test('El correo electrónico tiene un formato válido', () {
      final user = User(
        uid: 'user-002',
        type: UserType.member,
        nombre: 'Juan',
        apellidos: 'Pérez',
        fechaNacimiento: DateTime(2004, 5, 20),
        correo: 'juan@example.com',
        telefono: '4429876543',
        datosLegalesSonPropios: true,
        firmaUrl: 'firma.jpg',
        ineUrl: 'ine.jpg',
        fechaCreacion: DateTime(2026, 10, 1),
      );

      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

      expect(emailRegex.hasMatch(user.correo), isTrue);
    });

    test('El teléfono está presente como dato de contacto', () {
      final user = User(
        uid: 'user-003',
        type: UserType.member,
        nombre: 'Carlos',
        apellidos: 'Gómez',
        fechaNacimiento: DateTime(2003, 8, 10),
        correo: 'carlos@example.com',
        telefono: '4421112233',
        datosLegalesSonPropios: true,
        firmaUrl: 'firma.jpg',
        ineUrl: 'ine.jpg',
        fechaCreacion: DateTime(2026, 10, 1),
      );

      expect(user.telefono, isNotEmpty);
    });
  });
}

import 'package:champions_ring_app/features/authentication/enums/user_type.dart';

class RegisterUserData {
  final UserType type;
  final String nombre;
  final String apellidos;
  final DateTime fechaNacimiento;
  final String correo;
  final String contrasena;
  final String telefono;
  final bool datosLegalesSonPropios;
  final String firmaUrl;
  final String ineUrl;

  RegisterUserData({
    required this.type,
    required this.nombre,
    required this.apellidos,
    required this.fechaNacimiento,
    required this.correo,
    required this.contrasena,
    required this.telefono,
    required this.datosLegalesSonPropios,
    required this.firmaUrl,
    required this.ineUrl,
  });
}

enum UserType { member, receptionist, owner }

class User {
  UserType type;
  String nombre;
  String apellidos;
  DateTime fechaNacimiento;
  String correo;
  String telefono;

  DateTime fechaCreacion;
  DateTime fechaEliminacion;

  String firma;
  String ine;

  String contrasena;

  User({
    required this.type,
    required this.nombre,
    required this.apellidos,
    required this.fechaNacimiento,
    required this.correo,
    required this.telefono,
    required this.fechaCreacion,
    required this.fechaEliminacion,
    required this.firma,
    required this.ine,
    required this.contrasena,
  });
}

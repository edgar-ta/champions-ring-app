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

  Blob firma;
  Blob ine;

  String contrasena;
}

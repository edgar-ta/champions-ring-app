class Member {
  final String id;
  final String nombre;
  final String correo;
  final String telefono;
  final String estadoMembresia;
  final DateTime fechaInicio;
  final DateTime fechaVencimiento;

  Member({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.estadoMembresia,
    required this.fechaInicio,
    required this.fechaVencimiento,
  });
}

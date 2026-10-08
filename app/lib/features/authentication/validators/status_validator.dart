class StatusValidator {
  static const List<String> estadosPermitidos = ['completado', 'incompleto'];

  static bool esEstadoValido(String estado) {
    return estadosPermitidos.contains(estado);
  }
}

class InvalidDataValidator {
  static bool textoEsValido(String texto) {
    return texto.trim().isNotEmpty;
  }

  static bool correoEsValido(String correo) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    return regex.hasMatch(correo);
  }

  static bool fechaEsValida(DateTime? fecha) {
    return fecha != null;
  }

  static bool numeroEsValido(num? numero) {
    return numero != null && numero >= 0;
  }

  static bool estadoEsValido(String estado, List<String> estadosPermitidos) {
    return estadosPermitidos.contains(estado);
  }

  static bool booleanoEsValido(bool? valor) {
    return valor != null;
  }
}

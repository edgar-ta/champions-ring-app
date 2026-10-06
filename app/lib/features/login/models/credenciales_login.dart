class CredencialesLogin {
  final String correo;
  final String contrasena;

  const CredencialesLogin({required this.correo, required this.contrasena});

  static String? validarCorreo(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Ingresa tu correo electrónico';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
    return ok ? null : 'Correo electrónico no válido';
  }

  static String? validarContrasena(String? v) {
    if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
    if (v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }
}
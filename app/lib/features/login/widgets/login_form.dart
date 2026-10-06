import 'package:flutter/material.dart';

import '../../registro/widgets/registro_form.dart' show kRojo;
import '../models/auth_servicio.dart';
import '../models/credenciales_login.dart';
import 'campo_login.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key, required this.onExito, AuthServicio? auth})
      : _auth = auth;

  final VoidCallback onExito;
  final AuthServicio? _auth;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  late final AuthServicio _auth = widget._auth ?? AuthServicio();

  bool _ocultar = true;
  bool _cargando = false;

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _iniciarSesion() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    try {
      await _auth.iniciarSesion(CredencialesLogin(
        correo: _correoCtrl.text,
        contrasena: _passCtrl.text,
      ));
      if (!mounted) return;
      widget.onExito();
    } on AuthException catch (e) {
      if (mounted) _mensaje(e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _olvideContrasena() async {
    final error = CredencialesLogin.validarCorreo(_correoCtrl.text);
    if (error != null) {
      _mensaje('Escribe tu correo para enviarte el enlace de recuperación');
      return;
    }
    try {
      await _auth.recuperarContrasena(_correoCtrl.text);
      if (mounted) _mensaje('Te enviamos un correo para restablecer tu contraseña');
    } on AuthException catch (e) {
      if (mounted) _mensaje(e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CampoLogin(
            etiqueta: 'Correo electrónico',
            controller: _correoCtrl,
            icono: Icons.mail_outline,
            hint: 'ejemplo@templo.com',
            teclado: TextInputType.emailAddress,
            accion: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: CredencialesLogin.validarCorreo,
          ),
          const SizedBox(height: 16),
          CampoLogin(
            etiqueta: 'Contraseña',
            controller: _passCtrl,
            icono: Icons.lock_outline,
            ocultar: _ocultar,
            accion: TextInputAction.done,
            onSubmitted: (_) => _iniciarSesion(),
            autofillHints: const [AutofillHints.password],
            validator: CredencialesLogin.validarContrasena,
            sufijo: IconButton(
              icon: Icon(
                _ocultar ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF6B6B6B),
                size: 20,
              ),
              onPressed: () => setState(() => _ocultar = !_ocultar),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _cargando ? null : _olvideContrasena,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1A1A1A),
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _cargando ? null : _iniciarSesion,
              style: ElevatedButton.styleFrom(
                backgroundColor: kRojo,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _cargando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'INICIAR SESIÓN',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../../inscription/widgets/personal_data_form.dart' show kRojo;
import '../services/auth_service.dart';
import '../models/login_credentials.dart';
import 'login_field.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key, required this.onSuccess, AuthService? auth})
    : _auth = auth;

  final VoidCallback onSuccess;
  final AuthService? _auth;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  late final AuthService _auth = widget._auth ?? AuthService();

  bool _hidePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _showSnackbar(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _logIn() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _auth.logIn(
        LoginCredentials(email: _emailCtrl.text, password: _passCtrl.text),
      );
      if (!mounted) return;
      widget.onSuccess();
    } on AuthException catch (e) {
      if (mounted) _showSnackbar(e.mensaje);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _recoverPassword() async {
    final error = LoginCredentials.validateEmail(_emailCtrl.text);
    if (error != null) {
      _showSnackbar(
        'Escribe tu correo para enviarte el enlace de recuperación',
      );
      return;
    }
    try {
      await _auth.recoverPassword(_emailCtrl.text);
      if (mounted)
        _showSnackbar('Te enviamos un correo para restablecer tu contraseña');
    } on AuthException catch (e) {
      if (mounted) _showSnackbar(e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LoginField(
            label: 'Correo electrónico',
            controller: _emailCtrl,
            icon: Icons.mail_outline,
            hint: 'ejemplo@templo.com',
            keyboard: TextInputType.emailAddress,
            action: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: LoginCredentials.validateEmail,
          ),
          const SizedBox(height: 16),
          LoginField(
            label: 'Contraseña',
            controller: _passCtrl,
            icon: Icons.lock_outline,
            hideText: _hidePassword,
            action: TextInputAction.done,
            onSubmitted: (_) => _logIn(),
            autofillHints: const [AutofillHints.password],
            validator: LoginCredentials.validatePassword,
            suffix: IconButton(
              icon: Icon(
                _hidePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF6B6B6B),
                size: 20,
              ),
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : _recoverPassword,
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
              onPressed: _isLoading ? null : _logIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: kRojo,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
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

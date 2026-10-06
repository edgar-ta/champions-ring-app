import 'package:flutter/material.dart';

class CampoLogin extends StatelessWidget {
  const CampoLogin({
    super.key,
    required this.etiqueta,
    required this.controller,
    required this.icono,
    this.hint,
    this.ocultar = false,
    this.sufijo,
    this.validator,
    this.teclado,
    this.accion,
    this.onSubmitted,
    this.autofillHints,
  });

  final String etiqueta;
  final TextEditingController controller;
  final IconData icono;
  final String? hint;
  final bool ocultar;
  final Widget? sufijo;
  final String? Function(String?)? validator;
  final TextInputType? teclado;
  final TextInputAction? accion;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder borde([Color color = Colors.transparent]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B6B6B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: ocultar,
          validator: validator,
          keyboardType: teclado,
          textInputAction: accion,
          onFieldSubmitted: onSubmitted,
          autofillHints: autofillHints,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9A9A9A)),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(icono, color: const Color(0xFF6B6B6B), size: 20),
            suffixIcon: sufijo,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            border: borde(),
            enabledBorder: borde(),
            focusedBorder: borde(const Color(0xFFFF2D3F)),
            errorBorder: borde(Colors.red),
            focusedErrorBorder: borde(Colors.red),
          ),
        ),
      ],
    );
  }
}
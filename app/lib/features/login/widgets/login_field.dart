import 'package:flutter/material.dart';

class LoginField extends StatelessWidget {
  const LoginField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.hideText = false,
    this.suffix,
    this.validator,
    this.keyboard,
    this.action,
    this.onSubmitted,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final bool hideText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputType? keyboard;
  final TextInputAction? action;
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
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B6B6B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: hideText,
          validator: validator,
          keyboardType: keyboard,
          textInputAction: action,
          onFieldSubmitted: onSubmitted,
          autofillHints: autofillHints,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9A9A9A)),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(icon, color: const Color(0xFF6B6B6B), size: 20),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
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
